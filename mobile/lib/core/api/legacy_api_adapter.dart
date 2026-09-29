import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// Compatibility bridge for the unfinished legacy Flutter screens.
///
/// The original app was written against a legacy API endpoint namespace and many of
/// its models still expect the original PascalCase response keys. Backend V2
/// intentionally exposes cleaner REST endpoints and camel/snake-case data.
/// This adapter lets us migrate the networking layer without rewriting every
/// screen at once. New code should call [CrmApiClient] directly.
class LegacyApiAdapter {
  LegacyApiAdapter._();

  static final LegacyApiAdapter instance = LegacyApiAdapter._();
  final CrmApiClient _api = CrmApiClient.instance;

  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final name = _endpointName(endpoint);
    final body = _asMap(data);

    switch (name) {
      case 'geographyapi':
        return _geography(body);
      case 'customerentrymasterapi':
        return _customerMasterData();
      case 'customerlistapi':
        return _customerList(body);
      case 'fetchcustomerdetails':
        return _customerDetails(body);
      case 'customercreationapi':
        return _saveCustomer(body);
      case 'fetchcustomercontactlist':
        return _contactList(body);
      case 'fetchcustomercontactdetails':
        return _contactDetails(body);
      case 'contactentryorupdateapi':
        return _saveContact(body);
      case 'deletecustomerapi':
        return _deleteCustomer(body);
      case 'deletecustomercontactapi':
        return _deleteContact(body);
      case 'booksellersearchapi':
        return _bookSellerSearch(body);
      case 'citylistforsearchcustomer':
        return _searchCities();
      case 'searchcustomerresult':
        return _searchCustomers(body);
      case 'seriesandclasslevellist':
        return _seriesAndClassLevels();
      case 'fetchtitles':
        return _titles(body);
      case 'titlenotinseries':
        return _titleSearch(body);
      case 'samplingdetails':
        return _samplingDetails(body);
      case 'shipmentmode':
        return _shipmentModes();
      case 'shipto':
        return _shipTo(body);
      case 'customersampling':
        return _createCustomerSampling(body);
      case 'selfstockrequestapi':
        return _selfStockMasterData();
      case 'selfstockrequesttradeapi':
        return _selfStockTradeAddresses(body);
      case 'selfstocksampling':
        return _createSelfStock(body);
      case 'customersamplingapprovallist':
        return _customerSamplingApprovalList();
      case 'customersamplingapprovaldetails':
        return _customerSamplingApprovalDetails(body);
      case 'submitcustomersamplingrequestapproval':
        return _customerSamplingApprovalAction(body);
      case 'submitcustomersamplingrequestbulkapproval':
        return _customerSamplingBulkAction(body);
      case 'selfstockapprovallist':
        return _selfStockApprovalList();
      case 'selfstocksamplingapprovaldetails':
        return _selfStockApprovalDetails(body);
      case 'submitselfstocksamplingapproval':
        return _selfStockApprovalAction(body);
      case 'submitselfstocksamplingbulkapproval':
        return _selfStockBulkAction(body);
      case 'productlistbybrandid':
        return _eProductListByBrand(body);
      case 'productdetailsbyeproductid':
        return _eProductDetails(body);
      case 'apivisitentry':
        return _createVisit(body);
      case 'visitdetails':
        return _visitDetails(body);
      case 'citypincodeapi':
        return _cityPincode(body);
      case 'savefile':
        return _uploadFile(body);
      default:
        final response = await _api.post(
          _pathOnly(endpoint),
          data: data,
          queryParameters: queryParameters,
        );
        return _asMap(response.data);
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final name = _endpointName(endpoint);
    switch (name) {
      case 'citypincodeapi':
        return _cityPincode(queryParameters ?? const <String, dynamic>{});
      default:
        final response = await _api.get(
          _pathOnly(endpoint),
          queryParameters: queryParameters,
        );
        return _asMap(response.data);
    }
  }

  String _endpointName(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    final path = uri?.path ?? endpoint;
    final segments = path.split('/').where((e) => e.trim().isNotEmpty).toList();
    return segments.isEmpty ? path.toLowerCase() : segments.last.toLowerCase();
  }

  String _pathOnly(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri != null && uri.hasScheme) {
      return uri.path.startsWith('/api/')
          ? uri.path.substring('/api'.length)
          : uri.path;
    }
    if (endpoint.startsWith('/api/')) return endpoint.substring(4);
    return endpoint.startsWith('/') ? endpoint : '/$endpoint';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    try {
      final decoded = jsonDecode(jsonEncode(value));
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? List<dynamic>.from(value) : <dynamic>[];

  int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final match = RegExp(r'-?\d+').firstMatch(value.toString());
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  double? _double(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''));
  }

  String _string(dynamic value, [String fallback = '']) => value?.toString() ?? fallback;

  String _displayStatus(dynamic value) {
    final text = _string(value).trim();
    if (text.isEmpty) return '';
    switch (text.toUpperCase()) {
      case 'VALIDATED':
        return 'Yes';
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        if (text.toUpperCase().startsWith('PENDING_LEVEL_')) {
          final level = text.split('_').last;
          return 'Pending for Level $level';
        }
        return text;
    }
  }

  String _formatDate(dynamic value) {
    final text = _string(value).trim();
    if (text.isEmpty) return '';
    final date = DateTime.tryParse(text);
    if (date != null) return DateFormat('dd MMM yyyy').format(date.toLocal());
    return text;
  }

  String? _isoDate(dynamic value) {
    final text = _string(value).trim();
    if (text.isEmpty) return null;
    final direct = DateTime.tryParse(text);
    if (direct != null) return DateFormat('yyyy-MM-dd').format(direct);
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
    return null;
  }

  List<int> _idsFromXml(String? xml, String element) {
    if (xml == null || xml.trim().isEmpty) return <int>[];
    try {
      return XmlDocument.parse(xml)
          .findAllElements(element)
          .map((e) => int.tryParse(e.innerText.trim()))
          .whereType<int>()
          .toSet()
          .toList();
    } catch (_) {
      return RegExp(r'\d+')
          .allMatches(xml)
          .map((m) => int.tryParse(m.group(0)!))
          .whereType<int>()
          .toSet()
          .toList();
    }
  }

  List<XmlElement> _xmlRows(String? xml, String element) {
    if (xml == null || xml.trim().isEmpty) return const <XmlElement>[];
    try {
      return XmlDocument.parse(xml).findAllElements(element).toList();
    } catch (_) {
      return const <XmlElement>[];
    }
  }

  String? _child(XmlElement row, String name) {
    final elements = row.findElements(name);
    if (elements.isEmpty) return null;
    final text = elements.first.innerText.trim();
    return text.isEmpty ? null : text;
  }

  Future<Map<String, dynamic>> _geography(Map<String, dynamic> body) async {
    final response = await _api.get(ApiEndpoints.geography);
    final data = _asMap(response.data);
    final rows = _list(data['geography']);
    return {
      'Status': 'Success',
      'Geography': rows.map((raw) {
        final row = _asMap(raw);
        return {
          'CountryId': _int(row['country_id']),
          'Country': row['country'],
          'StateId': _int(row['state_id']),
          'State': row['state'],
          'DistrictId': _int(row['district_id']),
          'District': row['district'],
          'CityId': _int(row['city_id']),
          'City': row['city'],
        };
      }).toList(),
      'GeographyData': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _customerMasterData() async {
    final response = await _api.get(ApiEndpoints.customerMasterData);
    final data = _asMap(response.data);

    List<Map<String, dynamic>> renameList(
      String key,
      String idKey,
      String nameKey,
    ) {
      return _list(data[key]).map((raw) {
        final row = _asMap(raw);
        return {idKey: _int(row['id']), nameKey: _string(row['name'])};
      }).toList();
    }

    return {
      'Status': 'Success',
      'BoardMaster': renameList('boards', 'BoardId', 'BoardName'),
      'Classes': _list(data['classes']).map((raw) {
        final row = _asMap(raw);
        return {
          // The legacy Flutter screens use ClassNumId (-3=Nry, -2=LKG,
          // -1=UKG, 1..12), not the database primary key.
          'ClassNumId': _int(row['class_num_id'] ?? row['id']),
          'ClassName': _string(row['name']),
        };
      }).toList(),
      'ChainSchool': renameList('chainSchools', 'ChainSchoolId', 'ChainSchoolName'),
      'DataSource': renameList('dataSources', 'DataSourceId', 'DataSourceName'),
      'AccountableExecutive': _list(data['accountableExecutives']).map((raw) {
        final row = _asMap(raw);
        return {'SNo': _int(row['id']), 'ExecutiveName': _string(row['name'])};
      }).toList(),
      'SalutationMaster': renameList('salutations', 'SalutationId', 'SalutationName'),
      'ContactDesignation': renameList('contactDesignations', 'ContactDesignationId', 'ContactDesignationName'),
      'Subject': renameList('subjects', 'SubjectId', 'SubjectName'),
      'Department': renameList('departments', 'DepartmentId', 'DepartmentName'),
      'AdoptionRoleMaster': renameList('adoptionRoles', 'AdoptionRoleId', 'AdoptionRole'),
      'CustomerCategory': renameList('customerCategories', 'CustomerCategoryId', 'CustomerCategoryName'),
      'Months': List.generate(12, (index) => {
            'ID': index + 1,
            'Name': DateFormat('MMMM').format(DateTime(2024, index + 1, 1)),
          }),
      'PurchaseMode': _list(data['purchaseModes']).map((raw) {
        final row = _asMap(raw);
        final name = _string(row['name']);
        return {'ModeValue': name, 'ModeName': name, 'Id': _int(row['id'])};
      }).toList(),
      'InstituteType': _list(data['instituteTypes']).map((raw) {
        final row = _asMap(raw);
        final name = _string(row['name']);
        return {'ID': name, 'InstituteType': name, 'NumericId': _int(row['id'])};
      }).toList(),
      'InstituteLevel': _list(data['instituteLevels']).map((raw) {
        final row = _asMap(raw);
        final name = _string(row['name']);
        return {'ID': name, 'InstituteLevel': name, 'NumericId': _int(row['id'])};
      }).toList(),
      'AffiliateType': _list(data['affiliateTypes']).map((raw) {
        final row = _asMap(raw);
        final name = _string(row['name']);
        return {'ID': name, 'AffiliateType': name, 'NumericId': _int(row['id'])};
      }).toList(),
      'CustomerEntryData': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _customerList(Map<String, dynamic> body) async {
    final type = _string(body['CustomerType']).toUpperCase();
    final response = await _api.get(
      ApiEndpoints.customers,
      queryParameters: {
        if (type.isNotEmpty) 'customerType': type,
        if (_int(body['CityId']) != null) 'cityId': _int(body['CityId']),
      },
    );
    final data = _asMap(response.data);
    final customers = _list(data['customers']);
    final geography = await _geography(const <String, dynamic>{});
    final geoByCity = <int, Map<String, dynamic>>{};
    for (final raw in _list(geography['Geography'])) {
      final row = _asMap(raw);
      final id = _int(row['CityId']);
      if (id != null) geoByCity[id] = row;
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < customers.length; i++) {
      final row = _asMap(customers[i]);
      final id = _int(row['id']) ?? 0;
      final cityId = _int(row['city_id']);
      final geo = cityId == null ? null : geoByCity[cityId];
      final name = _string(row['customer_name']);
      final code = _string(row['customer_code']);
      result.add({
        'SNo': i + 1,
        'CustomerId': id,
        'SchoolCode': code,
        'CustomerCode': code,
        'SchoolName': name,
        'CustomerName': name,
        'RefCode': _string(row['ref_code']),
        'Address': _string(row['address']),
        'City': _string(row['city']),
        'State': _string(geo?['State']),
        'District': _string(geo?['District']),
        'ValidationStatus': _displayStatus(row['validation_status']),
        'Existence': 1,
        'Action': 'A$id',
        'resCity': cityId,
        'resState': _int(geo?['StateId']),
        'resCountry': _int(geo?['CountryId']),
      });
    }
    return {
      'Status': 'Success',
      'CustomerList': result,
      'CustomerCount': result.length.toString(),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _customerDetails(Map<String, dynamic> body) async {
    final id = _int(body['CustomerId']);
    if (id == null) throw ApiException('CustomerId is required');
    final response = await _api.get('${ApiEndpoints.customers}/$id');
    final data = _asMap(response.data);
    final customer = _asMap(data['customer']);
    final school = _asMap(data['school']);
    final executives = _list(data['executives']);
    final categories = _list(data['categories']);
    final geoResponse = await _api.get(
      ApiEndpoints.geography,
      queryParameters: {'cityId': _int(customer['city_id'])},
    );
    final geoRows = _list(_asMap(geoResponse.data)['geography']);
    final geo = geoRows.isEmpty ? <String, dynamic>{} : _asMap(geoRows.first);
    final master = await _api.get(ApiEndpoints.customerMasterData);
    final masterData = _asMap(master.data);
    String purchaseMode = '';
    final purchaseModeId = _int(school['purchase_mode_id']);
    if (purchaseModeId != null) {
      for (final raw in _list(masterData['purchaseModes'])) {
        final row = _asMap(raw);
        if (_int(row['id']) == purchaseModeId) {
          purchaseMode = _string(row['name']);
          break;
        }
      }
    }

    final legacy = <String, dynamic>{
      'SchoolId': id,
      'CustomerId': id,
      'SchoolName': _string(customer['customer_name']),
      'CustomerName': _string(customer['customer_name']),
      'SchoolCode': _string(customer['customer_code']),
      'CustomerCode': _string(customer['customer_code']),
      'RefCode': _string(customer['ref_code']),
      'Address': _string(customer['address']),
      'CityId': _int(customer['city_id']),
      'StateId': _int(geo['state_id']),
      'DistrictId': _int(geo['district_id']),
      'CountryId': _int(geo['country_id']),
      'ValidationStatus': _displayStatus(customer['validation_status']),
      'EmailId': _string(customer['email']),
      'Mobile': _string(customer['mobile']),
      'KeyCustomer': _int(customer['key_customer']) == 1 ? 'Y' : 'N',
      'CustomerStatus': _string(customer['customer_status']),
      'Pincode': _string(customer['pincode']),
      'LatEntry': _string(customer['latitude']),
      'longEntry': _string(customer['longitude']),
      'StartClassId': _int(school['start_class_num_id'] ?? school['start_class_id']),
      'EndClassId': _int(school['end_class_num_id'] ?? school['end_class_id']),
      'BoardId': _int(school['board_id']),
      'ChainSchoolId': _int(school['chain_school_id']),
      'MediumInstruction': _string(school['medium_instruction']),
      'Ranking': _string(school['ranking']),
      'SamplingMonth': _int(school['sampling_month']),
      'DecisionMonth': _int(school['decision_month']),
      'PurchaseMode': purchaseMode,
      'xmlAccountTableExecutiveId': executives
          .map((e) => _int(_asMap(e)['id']))
          .whereType<int>()
          .join(','),
      'xmlCustomerCategoryId': categories
          .map((e) => _int(_asMap(e)['id']))
          .whereType<int>()
          .join(','),
      'MsgWarning': 'N',
      'Existence': 1,
      'PanNumber': customer['pan_number'],
      'GstNumber': customer['gst_number'],
    };

    final customerType = _string(customer['customer_type']).toUpperCase();
    return {
      'Status': 'Success',
      if (customerType == 'SCHOOL') 'SchoolDetails': [legacy],
      if (customerType != 'SCHOOL') 'CustomerDetails': [legacy],
      'BookSellerList': <dynamic>[],
      'EnrolmentList': <dynamic>[],
      'SchoolFacility': <dynamic>[],
      'Comments': <dynamic>[],
      'List': <dynamic>[],
    };
  }

  Future<int?> _purchaseModeId(String? purchaseMode) async {
    if (purchaseMode == null || purchaseMode.trim().isEmpty) return null;
    final response = await _api.get(ApiEndpoints.customerMasterData);
    final rows = _list(_asMap(response.data)['purchaseModes']);
    for (final raw in rows) {
      final row = _asMap(raw);
      if (_string(row['name']).trim().toLowerCase() == purchaseMode.trim().toLowerCase()) {
        return _int(row['id']);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _saveCustomer(Map<String, dynamic> body) async {
    final id = _int(body['CustomerId']) ?? 0;
    final type = _string(body['CustomerType']).toUpperCase();
    final categoryIds = _idsFromXml(
      body['xmlCustomerCategoryId']?.toString(),
      'CustomerCategoryId',
    );
    final executiveIds = _idsFromXml(
      body['xmlAccountTableExecutiveId']?.toString(),
      'AccountTableExecutiveId',
    );
    if (executiveIds.isEmpty) {
      final csv = _string(body['xmlAccountTableExecutiveId']);
      executiveIds.addAll(RegExp(r'\d+')
          .allMatches(csv)
          .map((e) => int.tryParse(e.group(0)!))
          .whereType<int>());
    }

    final purchaseModeId = await _purchaseModeId(body['PurchaseMode']?.toString());

    // The legacy UI uses business class numbers (-3, -2, -1, 1..12),
    // while Backend V2 stores foreign keys to classes.id. Resolve them here.
    int? startClassDbId;
    int? endClassDbId;
    if (type == 'SCHOOL') {
      final startClassNumId = _int(body['StartClassId']);
      final endClassNumId = _int(body['EndClassId']);
      final masterResponse = await _api.get(ApiEndpoints.customerMasterData);
      final classRows = _list(_asMap(masterResponse.data)['classes']);
      for (final raw in classRows) {
        final row = _asMap(raw);
        final classNumId = _int(row['class_num_id'] ?? row['id']);
        if (classNumId == startClassNumId) startClassDbId = _int(row['id']);
        if (classNumId == endClassNumId) endClassDbId = _int(row['id']);
      }
    }

    final payload = <String, dynamic>{
      'customerType': type,
      'customerName': _string(body['CustomerName']),
      'refCode': body['RefCode'],
      'email': body['EmailId'],
      'mobile': body['Mobile'],
      'address': _string(body['Address']),
      'cityId': _int(body['CityId']),
      'pincode': _string(body['Pincode']),
      'keyCustomer': body['KeyCustomer'],
      'customerStatus': _string(body['CustomerStatus'], 'ACTIVE').toUpperCase(),
      'latitude': _double(body['latEntry']),
      'longitude': _double(body['longEntry']),
      'gstNumber': body['GSTNumber'] ?? body['GstNumber'],
      'panNumber': body['PANNumber'] ?? body['PanNumber'],
      if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
      if (executiveIds.isNotEmpty) 'executiveIds': executiveIds,
      if (type == 'SCHOOL')
        'school': {
          'boardId': _int(body['BoardId']),
          'chainSchoolId': _int(body['ChainSchoolId']),
          'startClassId': startClassDbId,
          'endClassId': endClassDbId,
          'mediumInstruction': body['MediumInstruction'],
          'ranking': body['Ranking'],
          'samplingMonth': _int(body['SamplingMonth']),
          'decisionMonth': _int(body['DecisionMonth']),
          'purchaseModeId': purchaseModeId,
        },
    };

    final hasContact = _string(body['FirstName']).isNotEmpty ||
        _string(body['LastName']).isNotEmpty ||
        _string(body['ContactEmailId']).isNotEmpty ||
        _string(body['ContactMobile']).isNotEmpty;
    if (id == 0 && hasContact) {
      payload['primaryContact'] = {
        'primaryContact': body['PrimaryContact'],
        'salutationId': _int(body['SalutationId']),
        'designationId': _int(body['ContactDesignationId']),
        'firstName': body['FirstName'],
        'lastName': body['LastName'],
        'email': body['ContactEmailId'],
        'mobile': body['ContactMobile'],
        'contactStatus': _string(body['ContactStatus'], 'ACTIVE').toUpperCase(),
        'residentialAddress': body['resAddress'],
        'residentialCityId': _int(body['resCity']),
        'residentialPincode': body['resPincode'],
        'birthday': _isoDate(body['BirthDay']),
        'anniversary': _isoDate(body['Anniversary']),
      };
    }

    if (id > 0) {
      final response = await _api.put('${ApiEndpoints.customers}/$id', data: payload);
      return {
        'Status': 'Success',
        's': _string(_asMap(response.data)['message'], 'Customer updated successfully'),
        'CustomerData': <dynamic>[],
      };
    }
    final response = await _api.post(ApiEndpoints.customers, data: payload);
    final data = _asMap(response.data);
    final validation = _displayStatus(data['validationStatus']);
    return {
      'Status': 'Success',
      's': validation == 'Yes'
          ? 'Customer created and validated successfully'
          : 'Customer created successfully and sent for approval',
      'CustomerId': data['customerId'],
      'CustomerData': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _contactList(Map<String, dynamic> body) async {
    final customerId = _int(body['CustomerId']);
    if (customerId == null) throw ApiException('CustomerId is required');
    final response = await _api.get('${ApiEndpoints.contacts}/customer/$customerId');
    final contacts = _list(_asMap(response.data)['contacts']);
    return {
      'Status': 'Success',
      'ContactList': List.generate(contacts.length, (index) {
        final row = _asMap(contacts[index]);
        final id = _int(row['id']) ?? 0;
        final name = '${_string(row['first_name'])} ${_string(row['last_name'])}'.trim();
        return {
          'SNo': index + 1,
          'ContactName': name,
          'Designation': _string(row['designation']),
          'Mobile': _string(row['mobile']),
          'Email': _string(row['email']),
          'PrimaryContact': _int(row['primary_contact']) == 1 ? 'Yes' : 'No',
          'ValidationStatus': _displayStatus(row['validation_status']),
          'Edit': 'A$id',
          'Delete': 'D$id',
        };
      }),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _contactDetails(Map<String, dynamic> body) async {
    final id = _int(body['CustomerContactId']);
    if (id == null) throw ApiException('CustomerContactId is required');
    final response = await _api.get('${ApiEndpoints.contacts}/$id');
    final row = _asMap(_asMap(response.data)['contact']);
    Map<String, dynamic> geo = <String, dynamic>{};
    final cityId = _int(row['residential_city_id']);
    if (cityId != null) {
      final geoResponse = await _api.get(ApiEndpoints.geography, queryParameters: {'cityId': cityId});
      final rows = _list(_asMap(geoResponse.data)['geography']);
      if (rows.isNotEmpty) geo = _asMap(rows.first);
    }
    final legacy = {
      'PrimaryContact': _int(row['primary_contact']) == 1 ? 'Y' : 'N',
      'ContactStatus': _string(row['contact_status']),
      'FirstName': _string(row['first_name']),
      'LastName': _string(row['last_name']),
      'SalutationId': _int(row['salutation_id']),
      'ContactDesignationId': _int(row['designation_id']),
      'ContactEmailId': row['email'],
      'ContactMobile': row['mobile'],
      'SchoolContactId': 'A$id',
      'resAddress': row['residential_address'],
      'resCountry': _int(geo['country_id']),
      'resState': _int(geo['state_id']),
      'resDistrict': _int(geo['district_id']),
      'resCity': cityId,
      'resPincode': row['residential_pincode'],
      'DataSourceId': _int(row['data_source_id']),
      'BirthDay': _formatDate(row['birthday']),
      'Anniversary': _formatDate(row['anniversary']),
      'MsgWarning': 'N',
      'Existence': 1,
    };
    final type = _string(body['CustomerType']).toUpperCase();
    return {
      'Status': 'Success',
      if (type == 'SCHOOL') 'SchoolContactDetails': [legacy] else 'CustomerContactDetails': [legacy],
      'TeacherSubjects': <dynamic>[],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _saveContact(Map<String, dynamic> body) async {
    final contactId = _int(body['CustomerContactId']);
    final payload = {
      'customerId': _int(body['CustomerId']),
      'customerType': _string(body['CustomerType']).toUpperCase(),
      'primaryContact': body['PrimaryContact'],
      'salutationId': _int(body['SalutationId']),
      'designationId': _int(body['ContactDesignationId']),
      'firstName': body['FirstName'],
      'lastName': body['LastName'],
      'email': body['ContactEmailId'],
      'mobile': body['ContactMobile'],
      'contactStatus': _string(body['ContactStatus'], 'ACTIVE').toUpperCase(),
      'residentialAddress': body['resAddress'],
      'residentialCityId': _int(body['resCity']),
      'residentialPincode': body['resPincode'],
      'birthday': _isoDate(body['BirthDay']),
      'anniversary': _isoDate(body['Anniversary']),
      'dataSourceId': _int(body['DataSourceId']),
    };
    if (contactId != null && contactId > 0) {
      final response = await _api.put('${ApiEndpoints.contacts}/$contactId', data: payload);
      return {
        'Status': 'Success',
        's': _string(_asMap(response.data)['message'], 'Customer contact updated successfully'),
        'ContactsEntry': <dynamic>[],
      };
    }
    final response = await _api.post(ApiEndpoints.contacts, data: payload);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      's': _displayStatus(data['validationStatus']) == 'Yes'
          ? 'Contact inserted successfully'
          : 'Contact inserted successfully and sent for approval',
      'ContactId': data['contactId'],
      'ContactsEntry': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _deleteCustomer(Map<String, dynamic> body) async {
    final id = _int(body['CustomerId']);
    if (id == null) throw ApiException('CustomerId is required');
    final response = await _api.post(
      '${ApiEndpoints.customers}/$id/delete-request',
      data: {'remarks': body['Remarks']},
    );
    final message = _string(_asMap(response.data)['message'], 'Customer delete request submitted');
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': message}
      ],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _deleteContact(Map<String, dynamic> body) async {
    final id = _int(body['CustomerContactId']);
    if (id == null) throw ApiException('CustomerContactId is required');
    final response = await _api.delete('${ApiEndpoints.contacts}/$id');
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {
          'MsgType': 's',
          'MsgText': _string(_asMap(response.data)['message'], 'Customer contact deleted successfully'),
        }
      ],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _bookSellerSearch(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.bookSellers,
      queryParameters: {
        if (_int(body['CityId']) != null) 'cityId': _int(body['CityId']),
        if (_string(body['BookSellerName']).isNotEmpty) 'name': body['BookSellerName'],
        if (_string(body['BookSellerCode']).isNotEmpty) 'code': body['BookSellerCode'],
      },
    );
    final rows = _list(_asMap(response.data)['bookSellers']);
    return {
      'Status': 'Success',
      'BookSellers': List.generate(rows.length, (index) {
        final row = _asMap(rows[index]);
        return {
          'SNo': index + 1,
          'BookSellerName': '${_string(row['book_seller_name'])} (${_string(row['customer_code'])})',
          'Address': _string(row['address']),
          'City': _string(row['city']),
          'State': '',
          'Country': '',
          'Action': _int(row['book_seller_id']) ?? 0,
        };
      }),
      'BookSellerData': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _searchCities() async {
    final response = await _api.get(ApiEndpoints.customerSearchCities);
    final rows = _list(_asMap(response.data)['cities']);
    return {
      'Status': 'Success',
      'CityList': rows.map((raw) {
        final row = _asMap(raw);
        return {'CityId': _int(row['id']), 'CityName': _string(row['name'])};
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _searchCustomers(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.customerSearch,
      queryParameters: {
        if (_int(body['CityId']) != null && _int(body['CityId']) != 0)
          'cityId': _int(body['CityId']),
        if (_string(body['CustomerType']).isNotEmpty)
          'customerType': _string(body['CustomerType']).toUpperCase(),
        if (_string(body['CustomerName']).isNotEmpty)
          'customerName': body['CustomerName'],
        if (_string(body['CustomerCode']).isNotEmpty)
          'customerCode': body['CustomerCode'],
        if (_string(body['CustomerContactName']).isNotEmpty)
          'search': body['CustomerContactName'],
      },
    );
    final rows = _list(_asMap(response.data)['customers']);
    final result = List<Map<String, dynamic>>.generate(rows.length, (index) {
      final row = _asMap(rows[index]);
      final id = _int(row['id']) ?? 0;
      return {
        'SNo': index + 1,
        'CustomerId': id,
        'CustomerCode': _string(row['customer_code']),
        'SchoolCode': _string(row['customer_code']),
        'CustomerName': _string(row['customer_name']),
        'SchoolName': _string(row['customer_name']),
        'CustomerType': _string(row['customer_type']),
        'CustomerContactName': _string(row['contact_name']),
        'RefCode': _string(row['ref_code']),
        'Address': _string(row['address']),
        'CityId': _int(row['city_id']),
        'City': _string(row['city']),
        'State': _string(row['state']),
        'ValidationStatus': _displayStatus(row['validation_status']),
        'Existence': 1,
        'Action': 'A$id',
      };
    });
    return {
      'Status': 'Success',
      'Result': result,
      'CustomerList': result,
      'SearchCustomerResult': result,
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _seriesAndClassLevels() async {
    final response = await _api.get(ApiEndpoints.seriesClassLevels);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ClassLavelList': _list(data['classLevels']).map((raw) {
        final row = _asMap(raw);
        return {'ClassLevelId': _int(row['id']), 'ClassLevelName': _string(row['name'])};
      }).toList(),
      'SeriesList': _list(data['series']).map((raw) {
        final row = _asMap(raw);
        return {'SeriesId': _int(row['id']), 'SeriesName': _string(row['name'])};
      }).toList(),
      'List': <dynamic>[],
    };
  }

  Map<String, dynamic> _legacyTitle(Map<String, dynamic> row) => {
        'BookId': _int(row['book_id'] ?? row['id']),
        'Title': _string(row['title']),
        'ISBN': _string(row['isbn']),
        'Author': _string(row['author']),
        'Price': _double(row['price'] ?? row['list_price']) ?? 0,
        'ListPrice': _double(row['list_price'] ?? row['price']) ?? 0,
        'Booknum': _string(row['book_num']),
        'Image': '',
        'ImageUrl': '',
        'BookType': _string(row['book_type']),
        'PhysicalStock': _int(row['physical_stock']) ?? 0,
        'SeriesId': _int(row['series_id']),
        'SubjectId': _int(row['subject_id']),
        'ClassLevelId': _int(row['class_level_id']),
        'SeriesName': _string(row['series_name']),
        'MaxSamplingQty': _int(row['max_sampling_qty']),
      };

  Future<Map<String, dynamic>> _titles(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.titles,
      queryParameters: {
        if (_int(body['SeriesId']) != null) 'seriesId': _int(body['SeriesId']),
        if (_string(body['BookISBN']).isNotEmpty) 'bookISBN': body['BookISBN'],
        if (_int(body['ClassLevel']) != null) 'classLevelId': _int(body['ClassLevel']),
      },
    );
    final rows = _list(_asMap(response.data)['titles']);
    return {'Status': 'Success', 'TitleList': rows.map((e) => _legacyTitle(_asMap(e))).toList(), 'List': <dynamic>[]};
  }

  Future<Map<String, dynamic>> _titleSearch(Map<String, dynamic> body) async {
    final query = _string(body['TitleOrISBN'] ?? body['BookISBN']);
    final response = await _api.get(ApiEndpoints.titleSearch, queryParameters: {'query': query});
    final rows = _list(_asMap(response.data)['titles']);
    return {'Status': 'Success', 'TitleList': rows.map((e) => _legacyTitle(_asMap(e))).toList(), 'List': <dynamic>[]};
  }

  Future<Map<String, dynamic>> _samplingDetails(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.samplingDetails,
      queryParameters: {
        'customerId': _int(body['CustomerId']),
        if (_int(body['TitleId']) != null) 'titleId': _int(body['TitleId']),
        if (_int(body['SeriesId']) != null) 'seriesId': _int(body['SeriesId']),
        if (_int(body['ClassLavelId'] ?? body['ClassLevelId']) != null)
          'classLevelId': _int(body['ClassLavelId'] ?? body['ClassLevelId']),
      },
    );
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'SamplingType': _list(data['samplingTypes']).map((raw) {
        final row = _asMap(raw);
        final name = _string(row['name']);
        return {'SamplingType': name, 'SamplingTypeValue': name, 'SamplingTypeId': _int(row['id'])};
      }).toList(),
      'SampleGiven': _list(data['sampleGiven']).map((raw) {
        final row = _asMap(raw);
        return {'SampleGiven': _string(row['label']), 'SampleGivenValue': _string(row['value'])};
      }).toList(),
      'TitleList': _list(data['titles']).map((e) => _legacyTitle(_asMap(e))).toList(),
      'SampleTo': _list(data['sampleTo']).map((raw) {
        final row = _asMap(raw);
        return {
          'CustomerName': _string(row['customer_name']),
          'CustomerContactId': _int(row['customer_contact_id']),
        };
      }).toList(),
      'SamleTo': _list(data['sampleTo']).map((raw) {
        final row = _asMap(raw);
        return {
          'CustomerName': _string(row['customer_name']),
          'CustomerContactId': _int(row['customer_contact_id']),
        };
      }).toList(),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _shipmentModes() async {
    final response = await _api.get(ApiEndpoints.shipmentModes);
    final rows = _list(_asMap(response.data)['shipmentModes']);
    return {
      'Status': 'Success',
      'ShipmentMode': rows.map((raw) {
        final row = _asMap(raw);
        return {
          'ShipmentModeId': _int(row['shipment_mode_id']),
          'ShipmentMode': _string(row['shipment_mode']),
        };
      }).toList(),
      'ShipmentModes': rows.map((raw) {
        final row = _asMap(raw);
        return {
          'ShipmentModeId': _int(row['shipment_mode_id']),
          'ShipmentMode': _string(row['shipment_mode']),
        };
      }).toList(),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _shipTo(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.samplingShipTo,
      queryParameters: {
        'customerId': _int(body['CustomerId']),
        'customerContactId': _int(body['CustomerContactId']),
        'sampleGiven': _string(body['SampleGiven']),
      },
    );
    final ship = _asMap(_asMap(response.data)['shipTo']);
    return {
      'Status': 'Success',
      'ShipTo': [
        {'ResAddress': ship['residentialAddress'], 'OfficeAddress': ship['officeAddress']}
      ],
      'List': <dynamic>[],
    };
  }

  String _normalizeSampleGiven(dynamic value) {
    final text = _string(value).trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    if (text.contains('GIVEN') && !text.contains('DISPATCH')) return 'SAMPLE_GIVEN';
    return 'TO_BE_DISPATCHED';
  }

  List<Map<String, dynamic>> _customerSamplingItems(String? xml) {
    return _xmlRows(xml, 'CustomerSamplingRequestDetails').map((row) {
      return {
        'seriesId': _int(_child(row, 'SeriesId')),
        'bookId': _int(_child(row, 'BookId')),
        'requestedQty': _double(_child(row, 'RequestedQty')) ?? 0,
        'shipTo': _child(row, 'ShipTo'),
        'shippingAddress': _child(row, 'ShippingAddress'),
        'samplingTypeName': _child(row, 'SamplingType'),
        'sampleToContactId': _int(_child(row, 'SampleTo')),
        'sampleGiven': _normalizeSampleGiven(_child(row, 'SampleGiven')),
        'unitPrice': _double(_child(row, 'MRP')) ?? 0,
      };
    }).where((e) => e['bookId'] != null && (e['requestedQty'] as num) > 0).toList();
  }

  Future<Map<String, dynamic>> _createCustomerSampling(Map<String, dynamic> body) async {
    final items = body['items'] is List
        ? _list(body['items']).map((e) => _asMap(e)).toList()
        : _customerSamplingItems(body['CustomerSamplingDetailsXML']?.toString());
    final payload = {
      'customerId': _int(body['CustomerId'] ?? body['customerId']),
      'customerType': _string(body['CustomerType'] ?? body['customerType']).toUpperCase(),
      'executiveId': _int(body['ExecutiveId'] ?? body['executiveId']),
      'shipmentModeId': _int(body['ShipmentMode'] ?? body['shipmentModeId']),
      'shippingInstructions': body['ShippingInstructions'] ?? body['shippingInstructions'],
      'requestRemarks': body['RequestRemarks'] ?? body['requestRemarks'],
      'items': items,
    };
    final response = await _api.post(ApiEndpoints.samplingCustomer, data: payload);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {
          'MsgType': 's',
          'MsgText': 'Customer Sampling Details Submitted successfully. Request Number : ${_string(data['requestNumber'])}',
        }
      ],
      'RequestId': data['id'],
      'RequestNumber': data['requestNumber'],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockMasterData() async {
    final response = await _api.get(ApiEndpoints.selfStockMasterData);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ShipmentMode': _list(data['shipmentModes']).map((raw) {
        final row = _asMap(raw);
        return {'ShipmentModeId': _int(row['shipment_mode_id']), 'ShipmentMode': _string(row['shipment_mode'])};
      }).toList(),
      'ShipTo': _list(data['shipTo']).map((value) {
        final raw = _string(value);
        final label = raw.split('_').map((e) => e.isEmpty ? e : '${e[0]}${e.substring(1).toLowerCase()}').join(' ');
        return {'ID': raw, 'ShipTo': label, 'AddressType': label};
      }).toList(),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockTradeAddresses(Map<String, dynamic> body) async {
    final response = await _api.get(ApiEndpoints.selfStockTradeAddresses);
    final rows = _list(_asMap(response.data)['shipmentAddresses']);
    return {
      'Status': 'Success',
      'ShipmentAddress': rows.map((raw) {
        final row = _asMap(raw);
        return {
          'CustomerId': _int(row['customer_id']),
          'CustomerName': _string(row['customer_name']),
          'CustomerCode': _string(row['customer_code']),
          'CustomerType': _string(row['customer_type']),
          'CustomerCity': _string(row['customer_city']),
          'ShippingAddress': _string(row['shipping_address']),
          'CustomerAddress': _string(row['shipping_address']),
        };
      }).toList(),
      'List': <dynamic>[],
    };
  }

  List<Map<String, dynamic>> _selfStockItems(String? xml) {
    return _xmlRows(xml, 'SelfStockRequestDetails').map((row) => {
          'subjectId': _int(_child(row, 'SubjectId')),
          'seriesId': _int(_child(row, 'SeriesId')),
          'bookId': _int(_child(row, 'BookId')),
          'requestedQty': _double(_child(row, 'RequestedQty')) ?? 0,
        }).where((e) => e['bookId'] != null && (e['requestedQty'] as num) > 0).toList();
  }

  Future<Map<String, dynamic>> _createSelfStock(Map<String, dynamic> body) async {
    final items = body['items'] is List
        ? _list(body['items']).map((e) => _asMap(e)).toList()
        : _selfStockItems((body['SelfStockDetailsxml'] ?? body['SelfStockDetailsXML'])?.toString());
    final payload = {
      'executiveId': _int(body['ExecutiveId'] ?? body['executiveId']),
      'tradeCustomerId': _int(body['TradeId'] ?? body['tradeCustomerId']),
      'shipTo': _string(body['ShipTo'] ?? body['shipTo']).toUpperCase().replaceAll(' ', '_'),
      'shippingAddress': body['ShippingAddress'] ?? body['shippingAddress'],
      'shipmentModeId': _int(body['ShipmentModeId'] ?? body['shipmentModeId']),
      'shippingInstructions': body['ShippingInstructions'] ?? body['shippingInstructions'],
      'remarks': body['Remarks'] ?? body['remarks'],
      'items': items,
    };
    final response = await _api.post(ApiEndpoints.selfStockRequests, data: payload);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': 'Self Stock Request submitted successfully - ${_string(data['requestNumber'])}'}
      ],
      'RequestId': data['id'],
      'RequestNumber': data['requestNumber'],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _customerSamplingApprovalList() async {
    final response = await _api.get(ApiEndpoints.samplingApprovals);
    final rows = _list(_asMap(response.data)['approvalList']);
    return {
      'Status': 'Success',
      'ApprovalList': List.generate(rows.length, (index) {
        final row = _asMap(rows[index]);
        return {
          'SNo': index + 1,
          'ApprovalId': _int(row['approval_id']),
          'RequestId': _int(row['request_id']),
          'RequestDate': _formatDate(row['request_date']),
          'RequestNumber': _string(row['request_number']),
          'ExecutiveName': _string(row['executive_name']),
          'CustomerName': _string(row['customer_name']),
          'CustomerId': _int(row['customer_id']) ?? 0,
          'CustomerType': _string(row['customer_type']),
          'CustomerCode': _string(row['customer_code']),
          'RefCode': '',
          'Address': _string(row['address']),
          'City': '',
          'State': '',
          'RequestStatus': _displayStatus(row['request_status']),
          'InBudget': _int(row['in_budget']) == 1 ? 'Y' : 'N',
          'FinalBudget': _double(row['requested_budget']) ?? 0,
          'AvailableBudget': _int(row['available_budget']) ?? 0,
        };
      }),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _samplingRequestV2(int requestId) async {
    final response = await _api.get('${ApiEndpoints.samplingRequests}/$requestId');
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> _customerSamplingApprovalDetails(Map<String, dynamic> body) async {
    final requestId = _int(body['RequestId']);
    if (requestId == null) throw ApiException('RequestId is required');
    final data = await _samplingRequestV2(requestId);
    final request = _asMap(data['request']);
    final items = _list(data['items']);
    return {
      'Status': 'Success',
      'RequestDetails': [
        {
          'RequestId': requestId,
          'RequestNumber': _string(request['request_number']),
          'RequestDate': _formatDate(request['created_at']),
          'ExecutiveName': _string(request['executive_name']),
          'CustomerId': _int(request['customer_id']) ?? 0,
          'CustomerName': _string(request['customer_name']),
          'CustomerType': _string(request['customer_type']),
          'RefCode': '',
          'AreaName': '',
          'WareHouseName': '',
          'ShippingAddress': items.isEmpty ? '' : _string(_asMap(items.first)['shipping_address']),
          'ShippingInstructions': request['shipping_instructions'],
          'RequestRemarks': request['request_remarks'],
          'RequestStatus': _displayStatus(request['request_status']),
          'ShipmentStatus': request['shipment_status'],
          'ShipmentMode': _string(request['shipment_mode']),
          'RequestedBudget': _double(request['requested_budget']) ?? 0,
          'Budget': _double(request['available_budget']) ?? 0,
        }
      ],
      'TitleDetails': items.map((raw) {
        final row = _asMap(raw);
        return {
          'ItemId': _int(row['id']),
          'RequestId': requestId,
          'RequestedQty': _int(row['requested_qty']) ?? 0,
          'ShippedQty': _int(row['shipped_qty']) ?? 0,
          'ShipmentRejectQty': 0,
          'ISBN': _string(row['isbn']),
          'BookId': _int(row['book_id']) ?? 0,
          'Title': _string(row['title']),
          'PreviousApprovedQty': _int(row['previous_approved_qty']),
          'Author': _string(row['author']),
          'Series': _string(row['series_name']),
          'ApprovedQty': _int(row['approved_qty']) ?? _int(row['requested_qty']) ?? 0,
          'Budget': 0.0,
          'RequestedBudget': (_double(row['unit_price']) ?? 0) * (_double(row['requested_qty']) ?? 0),
          'BookMRP': _double(row['unit_price']) ?? 0,
        };
      }).toList(),
      'Approval': data['approval'],
      'List': <dynamic>[],
    };
  }

  List<Map<String, dynamic>> _approvedItemsFromXml(String? xml, List<dynamic> requestItems) {
    final byBookId = <int, int>{};
    for (final raw in requestItems) {
      final row = _asMap(raw);
      final bookId = _int(row['book_id']);
      final itemId = _int(row['id']);
      if (bookId != null && itemId != null) byBookId[bookId] = itemId;
    }
    return _xmlRows(xml, 'ApprovedBooksAndQty').map((row) {
      final bookId = _int(_child(row, 'BookId'));
      return {
        'itemId': bookId == null ? null : byBookId[bookId],
        'approvedQty': _double(_child(row, 'ApprovedQty')) ?? 0,
      };
    }).where((e) => e['itemId'] != null).toList();
  }

  Future<Map<String, dynamic>> _customerSamplingApprovalAction(Map<String, dynamic> body) async {
    final requestId = _int(body['RequestId']);
    if (requestId == null) throw ApiException('RequestId is required');
    final requestData = await _samplingRequestV2(requestId);
    final approval = _asMap(requestData['approval']);
    final approvalId = _int(approval['id']);
    if (approvalId == null) throw ApiException('Approval request not found');
    final action = _string(body['ApprovalFor']).toUpperCase();
    final payload = <String, dynamic>{
      'action': action,
      'remarks': body['ApporvalRemarks'] ?? body['ApprovalRemarks'],
      if (action == 'APPROVE')
        'items': _approvedItemsFromXml(
          body['ApprovedBooksAndQtyXML']?.toString(),
          _list(requestData['items']),
        ),
    };
    final response = await _api.post('${ApiEndpoints.approvals}/$approvalId/action', data: payload);
    final result = _asMap(response.data);
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': _string(result['message'], action == 'REJECT' ? 'Customer Sampling request rejected successfully' : 'Customer Sampling request approved successfully')}
      ],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _customerSamplingBulkAction(Map<String, dynamic> body) async {
    final requestIds = RegExp(r'\d+')
        .allMatches(_string(body['RequestIds']))
        .map((e) => int.parse(e.group(0)!))
        .toList();
    final approvalIds = <int>[];
    for (final requestId in requestIds) {
      final data = await _samplingRequestV2(requestId);
      final id = _int(_asMap(data['approval'])['id']);
      if (id != null) approvalIds.add(id);
    }
    final response = await _api.post(
      ApiEndpoints.approvalBulkAction,
      data: {
        'action': _string(body['ApprovalFor']).toUpperCase(),
        'remarks': body['ApporvalRemarks'] ?? body['ApprovalRemarks'],
        'approvalIds': approvalIds,
      },
    );
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': 'Bulk approval action completed for ${_list(_asMap(response.data)['results']).length} request(s)'}
      ],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockApprovalList() async {
    final response = await _api.get(ApiEndpoints.selfStockApprovals);
    final rows = _list(_asMap(response.data)['approvalList']);
    return {
      'Status': 'Success',
      'ApprovalList': List.generate(rows.length, (index) {
        final row = _asMap(rows[index]);
        return {
          'SNo': index + 1,
          'ApprovalId': _int(row['approval_id']),
          'RequestId': _int(row['request_id']),
          'RequestNumber': _string(row['request_number']),
          'RequestDate': _formatDate(row['request_date']),
          'ExecutiveName': _string(row['executive_name']),
          'ExecutiveCode': _string(row['executive_code']),
          'Mobile': _string(row['mobile']),
          'EmailId': _string(row['email']),
          'RequestStatus': _displayStatus(row['request_status']),
          'Column1': _string(row['request_date']),
          'InBudget': 'N',
          'FinalBudget': 0.0,
          'AvailableBudget': 0,
        };
      }),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockRequestV2(int requestId) async {
    final response = await _api.get('${ApiEndpoints.selfStockRequests}/$requestId');
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> _selfStockApprovalDetails(Map<String, dynamic> body) async {
    final requestId = _int(body['RequestId']);
    if (requestId == null) throw ApiException('RequestId is required');
    final data = await _selfStockRequestV2(requestId);
    final request = _asMap(data['request']);
    final items = _list(data['items']);
    return {
      'Status': 'Success',
      'RequestDetails': [
        {
          'RequestId': requestId,
          'RequestNumber': _string(request['request_number']),
          'RequestDate': _formatDate(request['created_at']),
          'ExecutiveId': _int(request['executive_id']) ?? 0,
          'ExecutiveName': _string(request['executive_name']),
          'ExecutiveCode': _string(request['executive_code']),
          'ShipmentModeId': _int(request['shipment_mode_id']) ?? 0,
          'ShipmentMode': _string(request['shipment_mode']),
          'ShipTo': _string(request['ship_to']),
          'BooksellerId': _int(request['trade_customer_id']),
          'BooksellerName': request['trade_customer_name'],
          'BooksellerCode': null,
          'AreaId': 0,
          'AreaName': '',
          'WareHouseId': 0,
          'WareHouseName': '',
          'ShippingAddress': _string(request['shipping_address']),
          'ShippingInstructions': request['shipping_instructions'],
          'RequestRemarks': request['request_remarks'],
          'ApprovalStatus': _displayStatus(request['approval_status']),
          'ShipmentStatus': request['shipment_status'],
          'RequestStatus': _displayStatus(request['request_status']),
          'RequestedBudget': _double(request['requested_budget']) ?? 0,
          'Budget': _int(request['available_budget']) ?? 0,
        }
      ],
      'TitleDetails': items.map((raw) {
        final row = _asMap(raw);
        return {
          'ItemId': _int(row['id']),
          'RequestId': requestId,
          'BookId': _int(row['book_id']) ?? 0,
          'ISBN': _string(row['isbn']),
          'Title': _string(row['title']),
          'Author': _string(row['author']),
          'BookTypeName': _string(row['book_type']),
          'BookNum': _string(row['book_num']),
          'SeriesName': _string(row['series_name']),
          'RequestedQty': _int(row['requested_qty']) ?? 0,
          'PreviousApprovedQty': _int(row['previous_approved_qty']),
          'ApprovedQty': _int(row['approved_qty']) ?? _int(row['requested_qty']),
          'ShippedQty': _int(row['shipped_qty']) ?? 0,
          'Budget': 0,
          'RequestedBudget': (_double(row['unit_price']) ?? 0) * (_double(row['requested_qty']) ?? 0),
          'BookMRP': _double(row['unit_price']) ?? 0,
        };
      }).toList(),
      'Approval': data['approval'],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockApprovalAction(Map<String, dynamic> body) async {
    final requestId = _int(body['SelfStockRequestIds']);
    if (requestId == null) throw ApiException('SelfStockRequestIds is required');
    final data = await _selfStockRequestV2(requestId);
    final approvalId = _int(_asMap(data['approval'])['id']);
    if (approvalId == null) throw ApiException('Approval request not found');
    final action = _string(body['RequestFor']).toUpperCase();
    final payload = <String, dynamic>{
      'action': action,
      'remarks': body['Remarks'],
      if (action == 'APPROVE')
        'items': _approvedItemsFromXml(
          body['SelfStockDetailsxml']?.toString(),
          _list(data['items']),
        ),
    };
    final response = await _api.post('${ApiEndpoints.approvals}/$approvalId/action', data: payload);
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': _string(_asMap(response.data)['message'], 'Self Stock approval action completed')}
      ],
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _selfStockBulkAction(Map<String, dynamic> body) async {
    final requestIds = RegExp(r'\d+')
        .allMatches(_string(body['SelfStockRequestIds']))
        .map((e) => int.parse(e.group(0)!))
        .toList();
    final approvalIds = <int>[];
    for (final requestId in requestIds) {
      final data = await _selfStockRequestV2(requestId);
      final id = _int(_asMap(data['approval'])['id']);
      if (id != null) approvalIds.add(id);
    }
    final response = await _api.post(
      ApiEndpoints.approvalBulkAction,
      data: {
        'action': _string(body['RequestFor']).toUpperCase(),
        'remarks': body['Remarks'],
        'approvalIds': approvalIds,
      },
    );
    return {
      'Status': 'Success',
      'ReturnMessage': [
        {'MsgType': 's', 'MsgText': 'Bulk Self Stock action completed for ${_list(_asMap(response.data)['results']).length} request(s)'}
      ],
      'List': <dynamic>[],
    };
  }

  List<Map<String, dynamic>> _documentsFromXml(String? xml) {
    return _xmlRows(xml, 'UploadedDocument').map((row) => {
          'documentName': _child(row, 'DocumentName') ?? 'Document',
          'fileName': _child(row, 'FileName') ?? '',
          'fileSize': _int(_child(row, 'FileSize')),
        }).where((e) => _string(e['fileName']).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _followUpsFromXml(String? xml) {
    return _xmlRows(xml, 'FollowUpAction').map((row) => {
          'departmentId': _int(_child(row, 'Department')),
          'followUpExecutiveId': _int(_child(row, 'FollowUpExecutive')),
          'action': _child(row, 'FollowUpAction') ?? '',
          'followUpDate': _isoDate(_child(row, 'FollowUpDate')),
        }).where((e) => e['departmentId'] != null && e['followUpExecutiveId'] != null && _string(e['action']).isNotEmpty && e['followUpDate'] != null).toList();
  }

  List<Map<String, dynamic>> _eProductPromotionsFromXml(String? xml) {
    final rows = _xmlRows(xml, 'EProductPromotionDetails');
    return rows.map((row) {
      final classes = (_child(row, 'Classes') ?? _child(row, 'ClassNumId') ?? '')
          .split(',')
          .map((value) => int.tryParse(value.trim()))
          .whereType<int>()
          .toSet()
          .toList();
      return <String, dynamic>{
        'brandId': _int(_child(row, 'BrandId')),
        'eProductId': _int(_child(row, 'eProductId') ?? _child(row, 'EProductId')),
        'salesStageId': _int(_child(row, 'SalesStageId') ?? _child(row, 'CurrentSalesStage')),
        'prospectId': _int(_child(row, 'ProspectId')),
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

  List<Map<String, dynamic>> _eProductPromotionsFromBody(Map<String, dynamic> body) {
    final direct = body['EProductPromotions'] ?? body['eProductPromotions'];
    if (direct is List) {
      return direct
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return _eProductPromotionsFromXml(body['EProductPromotionDetailsXML']?.toString());
  }

  Future<Map<String, dynamic>> _eProductListByBrand(Map<String, dynamic> body) async {
    final brandId = _int(body['BrandId'] ?? body['brandId']);
    if (brandId == null) throw ArgumentError('BrandId is required');
    final response = await _api.get('/e-products/brands/$brandId/products');
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ProductList': _list(data['productList']).map((raw) {
        final row = _asMap(raw);
        final code = _string(row['productCode']).trim();
        final name = _string(row['productName']);
        return {
          'Id': _int(row['id']),
          'ProductName': code.isEmpty ? name : '$name ($code)',
          'BrandName': _string(row['brandName']),
        };
      }).toList(),
      'Products': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _eProductDetails(Map<String, dynamic> body) async {
    final eProductId = _int(body['eProductId'] ?? body['EProductId']);
    final academicSessionId = _int(body['AcademicSessionId'] ?? body['academicSessionId']);
    final customerId = _int(body['Customerid'] ?? body['CustomerId'] ?? body['customerId']);
    if (eProductId == null || academicSessionId == null || customerId == null) {
      throw ArgumentError('eProductId, AcademicSessionId and Customerid are required');
    }
    final response = await _api.get(
      '/e-products/$eProductId/details',
      queryParameters: {
        'academicSessionId': academicSessionId,
        'customerId': customerId,
      },
    );
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      'ProductDetails': _list(data['productDetails']).map((raw) {
        final row = _asMap(raw);
        return {
          'eProductId': _int(row['eProductId']),
          'eProductName': _string(row['eProductName']),
          'ListPrice': _double(row['listPrice']),
          'SubjectName': _string(row['subjectName']),
          'PreviousSalesStage': _string(row['previousSalesStage']),
          'PreviousStageSequenceNum': _int(row['previousStageSequenceNum']) ?? 0,
        };
      }).toList(),
      'classes': _list(data['classes']).map((raw) {
        final row = _asMap(raw);
        return {
          'ClassNumId': _int(row['classNumId']),
          'ClassName': _string(row['className']),
        };
      }).toList(),
      'Products': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _uploadFile(Map<String, dynamic> body) async {
    final response = await _api.post(
      ApiEndpoints.filesUpload,
      data: {
        'fileName': body['FileName'] ?? body['fileName'],
        'fileExtension': body['FileExtension'] ?? body['fileExtension'],
        'module': body['Module'] ?? body['module'] ?? 'visit',
        'base64String': body['Base64String'] ?? body['base64String'],
      },
    );
    final file = _asMap(_asMap(response.data)['file']);
    return {
      'Status': 'Success',
      's': 'Document uploaded successfully',
      'ReturnDetails': [
        {
          'FileName': _string(file['fileName']),
          'Module': _string(file['module']),
          'FileUrl': _string(file['url']),
          'FileSize': _int(file['fileSize']),
        }
      ],
    };
  }

  Future<Map<String, dynamic>> _createVisit(Map<String, dynamic> body) async {
    final samplingItems = _customerSamplingItems(
      (body['VisitDetailsXMLforToBeDispatched'] ?? body['VisitDetailsXMLforSampleGiven'])?.toString(),
    );
    final payload = <String, dynamic>{
      'executiveId': _int(body['ExecutiveId']),
      'customerId': _int(body['CustomerId']),
      'customerType': _string(body['CustomerType']).toUpperCase(),
      'customerContactId': _int(body['CustomerContact']),
      if ((_int(body['AcademicSessionId']) ?? 0) > 0) 'academicSessionId': _int(body['AcademicSessionId']),
      'visitPurposeId': _int(body['VisitPurpose']),
      'visitFeedback': _string(body['VisitFeedBack']),
      'visitDate': _isoDate(body['VisitDate']),
      'address': _string(body['addressEntry']),
      'longitude': _double(body['LongEntry']) ?? 0,
      'latitude': _double(body['LatEntry']) ?? 0,
      if (_string(body['JointVisitWith']).isNotEmpty)
        'jointExecutiveIds': RegExp(r'\d+')
            .allMatches(_string(body['JointVisitWith']))
            .map((m) => int.parse(m.group(0)!))
            .toSet()
            .toList(),
      if (_string(body['RequestRemarks']).isNotEmpty) 'requestRemarks': body['RequestRemarks'],
      if (_int(body['BackdateRequestId']) != null) 'backdateRequestId': _int(body['BackdateRequestId']),
      'documents': _documentsFromXml(body['UploadedDocumentXML']?.toString()),
      'followUps': _followUpsFromXml(body['FollowUpActionXML']?.toString()),
      'eProductPromotions': _eProductPromotionsFromBody(body),
      if (_string(body['OtherVisitPurpose']).isNotEmpty)
        'otherVisitPurpose': body['OtherVisitPurpose'],
      'sendThankyouMail': body['SendThankyouMail'],
      'mailContentType': body['MailContentType'],
      'mailBody': body['MailBody'],
      'webEntry': body['WebEntry'],
      'competingDataPayload': body['CompetingDataXML'],
      if (samplingItems.isNotEmpty)
        'sampling': {
          'executiveId': _int(body['ExecutiveId']),
          'shipmentModeId': _int(body['ShipmentMode']),
          'shippingInstructions': body['ShippingInstructions'],
          'requestRemarks': body['RequestRemarks'],
          'items': samplingItems,
        },
    };
    final response = await _api.post(ApiEndpoints.visits, data: payload);
    final data = _asMap(response.data);
    return {
      'Status': 'Success',
      's': data['sampling'] == null
          ? 'Visit Details inserted successfully'
          : 'Visit Details inserted successfully. Sampling Details inserted successfully with Request number(s) - ${_string(_asMap(data['sampling'])['requestNumber'])}',
      'VisitId': data['visitId'],
      'VisitEntryData': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _visitDetails(Map<String, dynamic> body) async {
    final response = await _api.get(
      ApiEndpoints.visitDetails,
      queryParameters: {
        if (_int(body['VisitId']) != null) 'visitId': _int(body['VisitId']),
        if (_int(body['CustomerId']) != null) 'customerId': _int(body['CustomerId']),
      },
    );
    return _legacyVisitDetails(_asMap(response.data));
  }

  Map<String, dynamic> _legacyVisitDetails(Map<String, dynamic> data) {
    final visits = _list(data['visits'] ?? data['visitDetails']);
    final documents = _list(data['documents'] ?? data['uploadedDocuments']);
    final jointRows = _list(data['jointExecutives']);
    final jointByVisit = <int, List<String>>{};
    for (final raw in jointRows) {
      final row = _asMap(raw);
      final visitId = _int(row['visit_id']);
      final name = _string(row['executive_name']);
      if (visitId != null && name.isNotEmpty) {
        jointByVisit.putIfAbsent(visitId, () => <String>[]).add(name);
      }
    }

    Map<String, dynamic> customer = _asMap(data['customer'] ?? data['customerDetails']);
    if (customer.isEmpty && visits.isNotEmpty) {
      final first = _asMap(visits.first);
      customer = {
        'id': first['customer_id'],
        'customer_name': first['customer_name'],
        'address': first['customer_address'],
        'contact_name': first['person_met'],
        'email': first['customer_email'],
        'mobile': first['customer_mobile'],
      };
    }

    String documentUrl(Map<String, dynamic> row) {
      final explicit = _string(row['file_url']);
      if (explicit.isNotEmpty) return explicit;
      final fileName = _string(row['file_name']);
      if (fileName.isEmpty) return '';
      if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
        return fileName;
      }
      final clean = fileName.startsWith('/') ? fileName.substring(1) : fileName;
      return '${AppConfig.serverBaseUrl}/uploads/visit/$clean';
    }

    return {
      'Status': 'Success',
      'CustomerDetails': customer.isEmpty
          ? <dynamic>[]
          : [
              {
                'CustomerId': _int(customer['id'] ?? customer['customer_id']),
                'CustomerName': _string(customer['customer_name']),
                'Address': _string(customer['address']),
                'Name': _string(customer['contact_name']),
                'EmailId': _string(customer['email']),
                'Mobile': _string(customer['mobile']),
              }
            ],
      'VisitDetails': visits.map((raw) {
        final row = _asMap(raw);
        final visitId = _int(row['visit_id'] ?? row['id']) ?? 0;
        return {
          'ExecutiveId': _int(row['executive_id']) ?? 0,
          'VisitId': visitId,
          'ExecutiveName': _string(row['executive_name']),
          'JointVisitWith': (jointByVisit[visitId] ?? const <String>[]).join(', '),
          'PersonMet': _string(row['person_met']),
          'VisitDate': _formatDate(row['visit_date']),
          'VisitPurpose': _string(row['visit_purpose']),
          'VisitEntryDate': _formatDate(row['created_at'] ?? row['visit_entry_date']),
          'VisitFeedback': _string(row['visit_feedback']),
          'CustomerId': _int(row['customer_id']) ?? 0,
          'CustomerContactId': _int(row['customer_contact_id']) ?? 0,
          'CustomerType': _string(row['customer_type']),
          'WebEntry': 'No',
          'Lat': _string(row['latitude']),
          'Long': _string(row['longitude']),
        };
      }).toList(),
      'UploadedDocuments': List.generate(documents.length, (index) {
        final row = _asMap(documents[index]);
        return {
          'SNO': index + 1,
          'DocumentName': _string(row['document_name']),
          'UploadedFile': _string(row['file_name']),
          'Action': documentUrl(row),
        };
      }),
      'List': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _cityPincode(Map<String, dynamic> body) async {
    final cityId = _int(body['CityId'] ?? body['cityId']);
    if (cityId == null || cityId == 0) {
      return {'Status': 'Success', 'CityList': <dynamic>[], 'List': <dynamic>[]};
    }
    final response = await _api.get(ApiEndpoints.geography, queryParameters: {'cityId': cityId});
    final rows = _list(_asMap(response.data)['geography']);
    return {
      'Status': 'Success',
      'CityList': rows.map((raw) {
        final row = _asMap(raw);
        return {
          'CityId': _int(row['city_id']),
          'CityName': _string(row['city']),
          'StateId': _int(row['state_id']),
          'StateName': _string(row['state']),
          'DistrictId': _int(row['district_id']),
          'DistrictName': _string(row['district']),
          'CountryId': _int(row['country_id']),
          'CountryName': _string(row['country']),
        };
      }).toList(),
      'List': <dynamic>[],
    };
  }
}
