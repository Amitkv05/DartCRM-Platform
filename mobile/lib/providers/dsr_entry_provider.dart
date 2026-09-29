import 'dart:io';

import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/newShip/NewShipToResponse.dart';
import 'package:dart_crm/models/planList/EProduct_visit_entry_request.dart';
import 'package:dart_crm/models/planList/dsr_entry_model.dart';
import 'package:dart_crm/models/planList/eProduct_details.dart';
import 'package:dart_crm/models/planList/eproduct_list.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart' as dsrsampling;
import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/models/planList/visit_entry.dart';
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/models/shipment_model.dart';
import 'package:dart_crm/models/visit_details.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/riverpod.dart';
import 'package:xml/xml.dart';

/// Backend V2 implementation of the Visit / DSR provider.
///
/// The public method signatures intentionally remain compatible with the old
/// screens. The [token] arguments are ignored because [CrmApiClient] injects
/// both `x-api-token` and the logged-in JWT automatically.
class DsrEntryProvider extends StateNotifier<Map<String, dynamic>> {
  DsrEntryProvider() : super({});

  final CrmApiClient _api = CrmApiClient.instance;

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _isoDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return text;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
    for (final pattern in const [
      'dd MMM yyyy',
      'd MMM yyyy',
      'dd MMMM yyyy',
      'd MMMM yyyy',
      'dd/MM/yyyy',
      'd/M/yyyy',
    ]) {
      try {
        return DateFormat('yyyy-MM-dd').format(DateFormat(pattern).parseStrict(text));
      } catch (_) {}
    }
    return text;
  }

  List<int> _csvInts(dynamic value) => (value?.toString() ?? '')
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .toSet()
      .toList();

  Iterable<XmlElement> _xmlRows(String? xml, String tag) {
    if (xml == null || xml.trim().isEmpty) return const <XmlElement>[];
    try {
      return XmlDocument.parse(xml).findAllElements(tag).toList();
    } catch (_) {
      return const <XmlElement>[];
    }
  }

  String? _child(XmlElement row, String name) {
    final nodes = row.findElements(name);
    if (nodes.isEmpty) return null;
    final value = nodes.first.innerText.trim();
    return value.isEmpty ? null : value;
  }

  List<Map<String, dynamic>> _documentsFromXml(String? xml) {
    return _xmlRows(xml, 'UploadedDocument')
        .map((row) => {
              'documentName': _child(row, 'DocumentName') ?? 'Document',
              'fileName': _child(row, 'FileName') ?? '',
              'fileSize': int.tryParse(_child(row, 'FileSize') ?? ''),
            })
        .where((row) => (row['fileName'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _followUpsFromXml(String? xml) {
    return _xmlRows(xml, 'FollowUpAction')
        .map((row) => {
              'departmentId': int.tryParse(_child(row, 'Department') ?? ''),
              'followUpExecutiveId':
                  int.tryParse(_child(row, 'FollowUpExecutive') ?? ''),
              'action': _child(row, 'FollowUpAction') ?? '',
              'followUpDate': _isoDate(_child(row, 'FollowUpDate')),
            })
        .where((row) =>
            row['departmentId'] != null &&
            row['followUpExecutiveId'] != null &&
            (row['action'] as String).isNotEmpty &&
            (row['followUpDate'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _eProductPromotionsFromXml(String? xml) {
    if (xml == null || xml.trim().isEmpty) return const <Map<String, dynamic>>[];
    final rows = _xmlRows(xml, 'EProductPromotionDetails').toList();
    if (rows.isEmpty) return const <Map<String, dynamic>>[];

    return rows.map((row) {
      final classes = (_child(row, 'Classes') ?? _child(row, 'ClassNumId') ?? '')
          .split(',')
          .map((value) => int.tryParse(value.trim()))
          .whereType<int>()
          .toSet()
          .toList();
      return <String, dynamic>{
        'brandId': int.tryParse(_child(row, 'BrandId') ?? ''),
        'eProductId': int.tryParse(
          _child(row, 'eProductId') ?? _child(row, 'EProductId') ?? '',
        ),
        'salesStageId': int.tryParse(
          _child(row, 'SalesStageId') ?? _child(row, 'CurrentSalesStage') ?? '',
        ),
        'prospectId': int.tryParse(_child(row, 'ProspectId') ?? ''),
        'classIds': classes,
        'remarks': _child(row, 'Remarks') ?? _child(row, 'Remark') ?? '',
      };
    }).where((row) =>
        row['brandId'] != null &&
        row['eProductId'] != null &&
        row['salesStageId'] != null &&
        row['prospectId'] != null &&
        (row['classIds'] as List).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _eProductPromotionsFromData(
    dynamic direct,
    String? xml,
  ) {
    if (direct is List) {
      return direct
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return _eProductPromotionsFromXml(xml);
  }

  String _normalizeSampleGiven(String? raw) {
    final value = (raw ?? '').trim().toLowerCase().replaceAll('-', ' ');
    if (value.contains('given') && !value.contains('dispatch')) {
      return 'SAMPLE_GIVEN';
    }
    return 'TO_BE_DISPATCHED';
  }

  List<Map<String, dynamic>> _samplingItemsFromXml(String? xml) {
    return _xmlRows(xml, 'CustomerSamplingRequestDetails')
        .map((row) => {
              'seriesId': int.tryParse(_child(row, 'SeriesId') ?? ''),
              'subjectId': int.tryParse(_child(row, 'SubjectId') ?? ''),
              'bookId': int.tryParse(_child(row, 'BookId') ?? ''),
              'requestedQty':
                  num.tryParse(_child(row, 'RequestedQty') ?? '') ?? 0,
              // Backend V2 accepts the name and resolves its master ID.
              'samplingTypeName': _child(row, 'SamplingType'),
              'sampleToContactId': int.tryParse(_child(row, 'SampleTo') ?? ''),
              'sampleGiven': _normalizeSampleGiven(_child(row, 'SampleGiven')),
              'shipTo': _child(row, 'ShipTo'),
              'shippingAddress': _child(row, 'ShippingAddress'),
              'unitPrice': num.tryParse(_child(row, 'MRP') ?? '') ?? 0,
            })
        .where((row) => row['bookId'] != null && (row['requestedQty'] as num) > 0)
        .toList();
  }

  Map<String, dynamic> _visitPayloadFromRequest(VisitEntryRequest request) {
    final samplingItems =
        _samplingItemsFromXml(request.visitDetailsXMLforToBeDispatched);
    return {
      'executiveId': request.executiveId,
      'customerId': request.customerId,
      'customerType': request.customerType.toUpperCase(),
      if (request.customerContact > 0)
        'customerContactId': request.customerContact,
      if (request.academicSessionId > 0)
        'academicSessionId': request.academicSessionId,
      'visitPurposeId': request.visitPurpose,
      'visitFeedback': request.visitFeedBack,
      'visitDate': _isoDate(request.visitDate),
      'address': request.addressEntry,
      'longitude': num.tryParse(request.longEntry) ?? 0,
      'latitude': num.tryParse(request.latEntry) ?? 0,
      if ((request.jointVisitWith ?? '').trim().isNotEmpty)
        'jointExecutiveIds': _csvInts(request.jointVisitWith),
      if (request.requestRemarks.trim().isNotEmpty)
        'requestRemarks': request.requestRemarks,
      'documents': _documentsFromXml(request.uploadedDocumentXML),
      'followUps': _followUpsFromXml(request.followUpActionXML),
      if (samplingItems.isNotEmpty)
        'sampling': {
          'executiveId': request.executiveId,
          'requestRemarks': request.requestRemarks,
          'items': samplingItems,
        },
    };
  }

  Future<DSREntryResponse> getDSREntry({
    required String executiveId,
    required String customerType,
    required int customerId,
    required String upHierarchy,
    required String downHierarchy,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/visits/dsr-entry',
        queryParameters: {
          'customerId': customerId,
          if (int.tryParse(executiveId) != null) 'executiveId': int.parse(executiveId),
        },
      );
      var parsed = DSREntryResponse.fromJson(_map(response.data));

      // Some legacy customer records may not expose PersonMet in the DSR
      // response even though customer contacts exist. Fall back to the
      // customer-contact endpoint so the dropdown never becomes silently empty.
      if (parsed.personMet.isEmpty && customerId > 0) {
        try {
          final contactsResponse = await _api.get('/contacts/customer/$customerId');
          final contactsData = _map(contactsResponse.data);
          final rows = contactsData['contacts'] is List
              ? List<dynamic>.from(contactsData['contacts'])
              : <dynamic>[];
          final contacts = rows
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .where((row) =>
                  (row['contact_status'] ?? '').toString().toUpperCase() !=
                  'DELETED')
              .map((row) {
                final name = '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'
                    .trim();
                return PersonMet(
                  customerContactId:
                      int.tryParse((row['id'] ?? 0).toString()) ?? 0,
                  customerContactName:
                      name.isEmpty ? 'Contact ${row['id'] ?? ''}' : name,
                );
              })
              .where((contact) => contact.customerContactId > 0)
              .toList();

          if (contacts.isNotEmpty) {
            parsed = DSREntryResponse(
              status: parsed.status,
              visitPurpose: parsed.visitPurpose,
              customerSummary: parsed.customerSummary,
              personMet: contacts,
              joinVisit: parsed.joinVisit,
              department: parsed.department,
              brand: parsed.brand,
              eProductDetails: parsed.eProductDetails,
              prospect: parsed.prospect,
              saleStage: parsed.saleStage,
              academicSession: parsed.academicSession,
              applicationSetupKeyValue: parsed.applicationSetupKeyValue,
              allowedDateRange: parsed.allowedDateRange,
            );
          }
        } catch (_) {
          // Keep the original DSR response; the UI will show an actionable
          // message instead of crashing or presenting a blank dropdown.
        }
      }

      return parsed;
    } catch (_) {
      return DSREntryResponse(
        status: 'error',
        customerSummary: const [],
        visitPurpose: const [],
        joinVisit: const [],
        brand: const [],
        personMet: const [],
        department: const [],
      );
    }
  }

  Future<FollowUpActionResponse> getFollowUpAction({
    required int executiveDepartmentId,
    required String executiveId,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/visits/follow-up-executives',
        queryParameters: {'departmentId': executiveDepartmentId},
      );
      return FollowUpActionResponse.fromJson(_map(response.data));
    } catch (_) {
      return FollowUpActionResponse(status: 'Error', executives: const []);
    }
  }

  Future<sampling.SamplingDetailsResponse> fetchSamplingDetails({
    required sampling.SamplingDetailsRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/sampling/details',
        queryParameters: {
          'customerId': request.customerId,
          if (request.titleId != null) 'titleId': request.titleId,
          if (request.seriesId != null && request.seriesId!.isNotEmpty)
            'seriesId': request.seriesId,
          if (request.classLevelId != null)
            'classLevelId': request.classLevelId,
        },
      );
      return sampling.SamplingDetailsResponse.fromJson(_map(response.data));
    } catch (_) {
      return sampling.SamplingDetailsResponse(
        status: 'error',
        samplingType: const [],
        sampleGiven: const [],
        titleList: const [],
        sampleTo: const [],
      );
    }
  }

  Future<dsrsampling.dsrSamplingDetailsResponse> dsrfetchSamplingDetails({
    required dsrsampling.dsrSamplingDetailsRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/sampling/details',
        queryParameters: {
          'customerId': request.customerId,
          if (request.titleId != null) 'titleId': request.titleId,
          if (request.seriesId != null && request.seriesId!.isNotEmpty)
            'seriesId': request.seriesId,
          if (request.classLevelId != null)
            'classLevelId': request.classLevelId,
        },
      );
      return dsrsampling.dsrSamplingDetailsResponse.fromJson(_map(response.data));
    } catch (_) {
      return dsrsampling.dsrSamplingDetailsResponse(
        status: 'error',
        samplingType: const [],
        sampleGiven: const [],
        titleList: const [],
        sampleTo: const [],
      );
    }
  }

  Future<PlanResponse> getPlanList({
    required int executiveId,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/plans',
        queryParameters: {'executiveId': executiveId},
      );
      return PlanResponse.fromJson(_map(response.data));
    } catch (_) {
      return PlanResponse(
        status: 'error',
        todayPlan: const [],
        tomorrowPlan: const [],
        travelPlan: const [],
      );
    }
  }

  Future<ShipmentModeResponse> fetchShipmentMode({
    required String token,
    int? executiveId,
  }) async {
    try {
      final response = await _api.get('/catalog/shipment-modes');
      return ShipmentModeResponse.fromJson(_map(response.data));
    } catch (_) {
      return ShipmentModeResponse(status: 'error', shipmentModes: const []);
    }
  }

  Future<ShipToResponse> fetchShipTo({
    required ShipToRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/sampling/ship-to',
        queryParameters: {
          'customerId': request.customerId,
          'customerContactId': request.customerContactId,
          'sampleGiven': request.sampleGiven ?? 'TO_BE_DISPATCHED',
        },
      );
      return ShipToResponse.fromJson(_map(response.data));
    } catch (_) {
      return ShipToResponse(status: 'error', shipTo: const []);
    }
  }

  Future<NewShipToResponse> dsrfetchShipTo({
    required ShipToRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/sampling/ship-to',
        queryParameters: {
          'customerId': request.customerId,
          'customerContactId': request.customerContactId,
          'sampleGiven': request.sampleGiven ?? 'TO_BE_DISPATCHED',
        },
      );
      return NewShipToResponse.fromJson(_map(response.data));
    } catch (_) {
      return NewShipToResponse(status: 'error', dsrshipTo: const []);
    }
  }

  Future<dsrsampling.TitlesResponse> fetchTitles({
    required dsrsampling.FetchTitlesRequest request,
    required String token,
  }) async => dsrfetchTitles(request: request, token: token);

  Future<dsrsampling.TitlesResponse> dsrfetchTitles({
    required dsrsampling.FetchTitlesRequest request,
    required String token,
  }) async {
    try {
      final query = <String, dynamic>{
        if (request.seriesId != null && request.seriesId!.isNotEmpty)
          'seriesId': request.seriesId,
        if (request.bookISBN != null && request.bookISBN!.isNotEmpty)
          'bookISBN': request.bookISBN,
        if (request.classLevel != null) 'classLevelId': request.classLevel,
      };
      var response = await _api.get('/catalog/titles', queryParameters: query);
      var parsed = dsrsampling.TitlesResponse.fromJson(_map(response.data));

      // Older CRM data does not always have a reliable class-level mapping.
      // If a valid series has books but the class filter returns none, retry
      // with the selected series only instead of incorrectly showing
      // "No titles found for this series".
      if (parsed.titleList.isEmpty &&
          request.classLevel != null &&
          request.seriesId != null &&
          request.seriesId!.isNotEmpty) {
        response = await _api.get(
          '/catalog/titles',
          queryParameters: {'seriesId': request.seriesId},
        );
        parsed = dsrsampling.TitlesResponse.fromJson(_map(response.data));
      }
      return parsed;
    } catch (_) {
      return dsrsampling.TitlesResponse(status: 'error', titleList: const []);
    }
  }

  Future<sampling.TitlesResponse> fetchTitlesNotInSeries({
    required sampling.TitleNotInSeriesRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/catalog/titles/search',
        queryParameters: {'query': request.titleOrISBN},
      );
      return sampling.TitlesResponse.fromJson(_map(response.data));
    } catch (_) {
      return sampling.TitlesResponse(status: 'error', titleList: const []);
    }
  }

  Future<dsrsampling.TitlesResponse> dsrfetchTitlesNotInSeries({
    required dsrsampling.TitleNotInSeriesRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/catalog/titles/search',
        queryParameters: {'query': request.titleOrISBN},
      );
      return dsrsampling.TitlesResponse.fromJson(_map(response.data));
    } catch (_) {
      return dsrsampling.TitlesResponse(status: 'error', titleList: const []);
    }
  }

  Future<sampling.SeriesAndClassLevelResponse> fetchSeriesAndClassLevel({
    required sampling.SeriesAndClassLevelRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get('/catalog/series-class-levels');
      return sampling.SeriesAndClassLevelResponse.fromJson(_map(response.data));
    } catch (_) {
      return sampling.SeriesAndClassLevelResponse(
        status: 'error',
        classLevelList: const [],
        seriesList: const [],
      );
    }
  }

  Future<dsrsampling.dsrSeriesAndClassLevelResponse>
      dsrfetchSeriesAndClassLevel({
    required dsrsampling.dsrSeriesAndClassLevelRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get('/catalog/series-class-levels');
      return dsrsampling.dsrSeriesAndClassLevelResponse.fromJson(_map(response.data));
    } catch (_) {
      return dsrsampling.dsrSeriesAndClassLevelResponse(
        status: 'error',
        classLevelList: const [],
        seriesList: const [],
      );
    }
  }

  Future<VisitEntryResponse> submitVisitEntry({
    required VisitEntryRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.post(
        '/visits',
        data: _visitPayloadFromRequest(request),
      );
      return VisitEntryResponse.fromJson(_map(response.data));
    } catch (e) {
      return VisitEntryResponse(
        status: 'error',
        message: CrmApiClient.messageFrom(e),
      );
    }
  }

  Future<VisitDetailsResponse> getVisitDetails({
    required VisitDetailsRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/visits/details',
        queryParameters: {
          if (request.visitId != null) 'visitId': request.visitId,
          if (request.customerId != null) 'customerId': request.customerId,
        },
      );
      return VisitDetailsResponse.fromJson(_map(response.data));
    } catch (_) {
      return VisitDetailsResponse(
        status: 'error',
        customerDetails: const [],
        visitDetails: const [],
        uploadedDocuments: const [],
      );
    }
  }

  Future<EProductVisitEntryResponse> submitEProductVisitEntry({
    required EProductVisitEntryRequest request,
    required String token,
  }) async {
    try {
      final samplingItems = _samplingItemsFromXml(
        request.visitDetailsXMLforToBeDispatched ??
            request.visitDetailsXMLforSampleGiven,
      );
      final payload = <String, dynamic>{
        'executiveId': int.tryParse(request.executiveId) ?? 0,
        'customerId': int.tryParse(request.customerId) ?? 0,
        'customerType': request.customerType.toUpperCase(),
        'customerContactId': int.tryParse(request.customerContact) ?? 0,
        if (int.tryParse(request.academicSessionId ?? '') != null)
          'academicSessionId': int.parse(request.academicSessionId!),
        'visitPurposeId': int.tryParse(request.visitPurpose) ?? 0,
        'visitFeedback': request.visitFeedBack,
        'visitDate': _isoDate(request.visitDate),
        'address': request.addressEntry,
        'longitude': num.tryParse(request.longEntry) ?? 0,
        'latitude': num.tryParse(request.latEntry) ?? 0,
        if ((request.jointVisitWith ?? '').trim().isNotEmpty)
          'jointExecutiveIds': _csvInts(request.jointVisitWith),
        if ((request.requestRemarks ?? '').trim().isNotEmpty)
          'requestRemarks': request.requestRemarks,
        if ((request.otherVisitPurpose ?? '').trim().isNotEmpty)
          'otherVisitPurpose': request.otherVisitPurpose,
        'sendThankyouMail': request.sendThankyouMail,
        'mailContentType': request.mailContentType,
        'mailBody': request.mailBody,
        'webEntry': request.webEntry,
        'competingDataPayload': request.competingDataXML,
        'documents': _documentsFromXml(request.uploadedDocumentXML),
        'followUps': _followUpsFromXml(request.followUpActionXML),
        'eProductPromotions': _eProductPromotionsFromXml(
          request.eProductPromotionDetailsXML,
        ),
        if (samplingItems.isNotEmpty)
          'sampling': {
            'executiveId': int.tryParse(request.executiveId) ?? 0,
            'shipmentModeId': int.tryParse(request.shipmentMode ?? ''),
            'shippingInstructions': request.shippingInstructions,
            'requestRemarks': request.requestRemarks,
            'items': samplingItems,
          },
      };
      final response = await _api.post('/visits', data: payload);
      final data = _map(response.data);
      return EProductVisitEntryResponse(
        status: 'Success',
        message: (data['message'] ?? 'Visit Details inserted successfully').toString(),
        visitEntryData: const [],
      );
    } catch (e) {
      return EProductVisitEntryResponse(
        status: 'error',
        message: CrmApiClient.messageFrom(e),
        visitEntryData: const [],
      );
    }
  }

  Future<EProductListResponse> getEProductListByBrand({
    required EProductListRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/e-products/brands/${request.brandId}/products',
      );
      return EProductListResponse.fromJson(_map(response.data));
    } catch (_) {
      return EProductListResponse(
        status: 'error',
        productList: const [],
        products: const [],
      );
    }
  }

  Future<EProductDetailsResponse> getEProductDetails({
    required EProductDetailsRequest request,
    required String token,
  }) async {
    try {
      final response = await _api.get(
        '/e-products/${request.eProductId}/details',
        queryParameters: {
          'academicSessionId': request.academicSessionId,
          'customerId': request.customerId,
        },
      );
      return EProductDetailsResponse.fromJson(_map(response.data));
    } catch (_) {
      return EProductDetailsResponse(
        status: 'error',
        productDetails: const [],
        classes: const [],
        products: const [],
      );
    }
  }

  Future<VisitEntryResponse> submitDSREntry({
    required int executiveId,
    required int customerId,
    required String customerType,
    required Map<dynamic, dynamic> submissionData,
    required String token,
    required List<File> documents,
    required List<String> fileNames,
  }) async {
    try {
      final data = submissionData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final samplingItems = _samplingItemsFromXml(
        data['VisitDetailsXMLforToBeDispatched']?.toString(),
      );
      final documentRows = <Map<String, dynamic>>[
        ..._documentsFromXml(data['UploadedDocumentXML']?.toString()),
        for (var i = 0; i < documents.length; i++)
          {
            'documentName': i < fileNames.length ? fileNames[i] : 'Document ${i + 1}',
            'fileName': i < fileNames.length ? fileNames[i] : documents[i].path.split(Platform.pathSeparator).last,
            'fileSize': await documents[i].length(),
          },
      ];
      final payload = <String, dynamic>{
        'executiveId': executiveId,
        'customerId': customerId,
        'customerType': customerType.toUpperCase(),
        'customerContactId': int.tryParse(
                (data['CustomerContact'] ?? data['customerContactId'] ?? 0)
                    .toString()) ??
            0,
        'visitPurposeId': int.tryParse(
                (data['VisitPurpose'] ?? data['visitPurposeId'] ?? 0)
                    .toString()) ??
            0,
        if ((int.tryParse((data['AcademicSessionId'] ?? data['academicSessionId'] ?? '').toString()) ?? 0) > 0)
          'academicSessionId': int.tryParse(
              (data['AcademicSessionId'] ?? data['academicSessionId']).toString()),
        'visitFeedback':
            (data['VisitFeedBack'] ?? data['visitFeedback'] ?? '').toString(),
        'visitDate': _isoDate(data['VisitDate'] ?? data['visitDate']),
        'address':
            (data['addressEntry'] ?? data['address'] ?? '').toString(),
        'longitude': num.tryParse(
                (data['LongEntry'] ?? data['longitude'] ?? 0).toString()) ??
            0,
        'latitude': num.tryParse(
                (data['LatEntry'] ?? data['latitude'] ?? 0).toString()) ??
            0,
        if ((data['JointVisitWith'] ?? '').toString().trim().isNotEmpty)
          'jointExecutiveIds': _csvInts(data['JointVisitWith']),
        if ((data['RequestRemarks'] ?? '').toString().trim().isNotEmpty)
          'requestRemarks': data['RequestRemarks'].toString(),
        if ((int.tryParse((data['BackdateRequestId'] ?? '').toString()) ?? 0) > 0)
          'backdateRequestId': int.tryParse(data['BackdateRequestId'].toString()),
        'documents': documentRows,
        'followUps': _followUpsFromXml(data['FollowUpActionXML']?.toString()),
        'eProductPromotions': _eProductPromotionsFromData(
          data['EProductPromotions'],
          data['EProductPromotionDetailsXML']?.toString(),
        ),
        if ((data['OtherVisitPurpose'] ?? '').toString().trim().isNotEmpty)
          'otherVisitPurpose': data['OtherVisitPurpose'].toString(),
        'sendThankyouMail': data['SendThankyouMail'],
        'mailContentType': data['MailContentType'],
        'mailBody': data['MailBody'],
        'webEntry': data['WebEntry'],
        'competingDataPayload': data['CompetingDataXML'],
        if (samplingItems.isNotEmpty)
          'sampling': {
            'executiveId': executiveId,
            'shipmentModeId': int.tryParse(
                (data['ShipmentMode'] ?? data['shipmentModeId'] ?? '').toString()),
            'shippingInstructions':
                (data['ShippingInstructions'] ?? data['shippingInstructions'])?.toString(),
            'requestRemarks': data['RequestRemarks']?.toString(),
            'items': samplingItems,
          },
      };
      final response = await _api.post('/visits', data: payload);
      return VisitEntryResponse.fromJson(_map(response.data));
    } catch (e) {
      return VisitEntryResponse(
        status: 'error',
        message: CrmApiClient.messageFrom(e),
      );
    }
  }
}

final dsrEntryProvider =
    StateNotifierProvider<DsrEntryProvider, Map<String, dynamic>>(
  (ref) => DsrEntryProvider(),
);
