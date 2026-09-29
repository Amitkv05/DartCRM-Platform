import 'dart:convert';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/models/shipment_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/widgets/sampling_done_widget.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xml/xml.dart';
import 'package:dart_crm/core/api/legacy_http.dart' as http;

final sampleToAndShipToProvider = FutureProvider.family<
    ({
      List<sampling.SamplingContact> sampleToList,
      List<ShipTo> shipToList,
      Map<String, dynamic>? selectedCustomer
    }),
    ({int executiveId, Map<String, dynamic> customer, String? seriesId})>(
  (ref, params) async {
    final authState = ref.watch(authProvider);
    final token = authState.token;
    if (token == null) {
      print('Error: No authentication token available');
      return (
        sampleToList: [
          sampling.SamplingContact(
            customerContactId:
                int.parse(params.customer['CustomerId']?.toString() ?? '0'),
            customerName:
                params.customer['CustomerName']?.toString() ?? 'Unknown',
          ),
        ],
        shipToList: [
          ShipTo(
            shipToId: '0_default',
            shipToName: 'No address available',
            shipToAddress: null,
          ),
        ],
        selectedCustomer: params.customer,
      );
    }

    final samplingResponse =
        await ref.read(dsrEntryProvider.notifier).fetchSamplingDetails(
              request: sampling.SamplingDetailsRequest(
                customerId: params.customer['CustomerId'],
                requestType: 'SampleTo',
                profileId: params.customer['ProfileId'] ??
                    authState.loginResponse?.executiveBasicData?[0].profileId,
                customerType: params.customer['CustomerType'],
                executiveId: params.executiveId,
                titleId: null,
                seriesId: params.seriesId,
                classLevelId: null,
              ),
              token: token,
            );

    print('SampleTo API Response: ${samplingResponse.toString()}');
    print('SampleTo List: ${samplingResponse.sampleTo}');
    print(
        'SamplingType List: ${samplingResponse.samplingType}'); // Added for debugging

    List<sampling.SamplingContact> sampleToList = samplingResponse.status ==
                'Success' &&
            samplingResponse.sampleTo.isNotEmpty
        ? samplingResponse.sampleTo
        : [
            sampling.SamplingContact(
              customerContactId:
                  int.parse(params.customer['CustomerId']?.toString() ?? '0'),
              customerName:
                  params.customer['CustomerName']?.toString() ?? 'Unknown',
            ),
          ];

    final initialContactId = sampleToList.isNotEmpty
        ? sampleToList.first.customerContactId
        : int.tryParse(params.customer['CustomerId']?.toString() ?? '') ?? 0;

    final shipToResponse =
        await ref.read(dsrEntryProvider.notifier).fetchShipTo(
              request: ShipToRequest(
                executiveId: params.executiveId,
                customerId: params.customer['CustomerId'],
                customerType: params.customer['CustomerType'],
                customerContactId: initialContactId,
                sampleGiven: 'Yes',
              ),
              token: token,
            );

    print('ShipTo API Response: ${shipToResponse.toString()}');
    print('ShipTo List: ${shipToResponse.shipTo}');

    List<ShipTo> shipToList =
        shipToResponse.status == 'Success' && shipToResponse.shipTo.isNotEmpty
            ? shipToResponse.shipTo
            : [
                ShipTo(
                  shipToId: '0_default',
                  shipToName: 'No address available',
                  shipToAddress: null,
                ),
              ];

    Map<String, dynamic> selectedCustomer = params.customer;

    print('Generated Sample To List: $sampleToList');
    print('Generated Ship To List: $shipToList');
    print('Selected Customer: $selectedCustomer');

    return (
      sampleToList: sampleToList,
      shipToList: shipToList,
      selectedCustomer: selectedCustomer,
    );
  },
);

extension IterableIndexed<T> on Iterable<T> {
  Iterable<U> mapIndexed<U>(U Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index++, item);
    }
  }
}

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  String? selectedSamplingType;
  String? selectedSampleGiven = 'Yes';
  int? selectedClassLevelId;
  String? selectedSeriesId;
  String? selectedClassLevelName = 'All Class Levels';
  String? shipmentMode;
  String? shippingInstructions;
  String? remarks;
  TabController? _tabController;
  late Future<dsrsampling.dsrSamplingDetailsResponse> _samplingDetailsFuture;
  late Future<dsrsampling.dsrSeriesAndClassLevelResponse> _classLevelFuture;
  late Future<dsrsampling.TitlesResponse> _titlesFuture;
  late Future<ShipmentModeResponse> _shipmentModeFuture;
  late Future<
      ({
        List<sampling.SamplingContact> sampleToList,
        List<ShipTo> shipToList,
        Map<String, dynamic>? selectedCustomer
      })> _sampleToAndShipToFuture;
  List<dsrsampling.TitleData> selectedTitles = [];
  List<List<dsrsampling.TitleData>> selectedTitleGroups = [];
  List<Map<String, dynamic>> containerDetails = [];
  List<dsrsampling.Series> seriesList = [];
  bool isLoadingSeries = false;
  bool samplingDone = true;
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  List<String> samplingTypeOptions = [];
  List<String> sampleGivenOptions = [];
  bool _showSamplingTypeFallbackSnackBar = false;
  bool _showSampleGivenFallbackSnackBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(authProvider.notifier).getSetupValues());

    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;
    final token = authState.token ?? '';

    _samplingDetailsFuture =
        ref.read(dsrEntryProvider.notifier).dsrfetchSamplingDetails(
              request: dsrsampling.dsrSamplingDetailsRequest(
                titleId: null,
                classLevelId: null,
                seriesId: null,
                customerId: widget.customer['CustomerId'],
                requestType: 'Approval',
                profileId: AppUtils.getProfileIdStr(),
                customerType: widget.customer['CustomerType'],
                executiveId: AppUtils.getExecutiveStr(),
              ),
              token: token,
            );

    // Initialize samplingTypeOptions after fetching sampling details
    _samplingDetailsFuture.then((samplingResponse) {
      setState(() {
        samplingTypeOptions = samplingResponse.samplingType
            .map((type) => type.samplingType.trim())
            .toSet()
            .toList();
        _initializeDropdownValues();
        print(
            'SamplingType Options (from samplingResponse): $samplingTypeOptions');
      });
    });

    _classLevelFuture =
        ref.read(dsrEntryProvider.notifier).dsrfetchSeriesAndClassLevel(
              request: dsrsampling.dsrSeriesAndClassLevelRequest(
                profileId: AppUtils.getProfileIdStr(),
                executiveId: AppUtils.getExecutiveStr(),
              ),
              token: token,
            );

    _shipmentModeFuture =
        ref.read(dsrEntryProvider.notifier).fetchShipmentMode(token: token);

    _sampleToAndShipToFuture = ref.read(sampleToAndShipToProvider(
      (executiveId: executiveId, customer: widget.customer, seriesId: null),
    ).future);

    _fetchSeries(executiveId, token);
    _titlesFuture = _fetchTitles(executiveId, token);
  }

  void _initializeDropdownValues() {
    final authState = ref.read(authProvider);
    final setupValues = authState.setupValues ?? [];

    // Fallback to setupValues for sampleGivenOptions
    sampleGivenOptions = setupValues
        .where((setup) => setup.keyName == 'SampleGiven')
        .map((setup) => setup.keyValue.trim())
        .toSet()
        .toList();

    if (samplingTypeOptions.isEmpty && selectedTitles.isNotEmpty) {
      _showSamplingTypeFallbackSnackBar = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No SamplingType options available, please try again later'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
    if (sampleGivenOptions.isEmpty && selectedTitles.isNotEmpty) {
      _showSampleGivenFallbackSnackBar = true;
      selectedSampleGiven = 'Yes';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No SampleGiven options available, using "Yes"'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }

    print('Setup Values: $setupValues');
    print('SamplingType Options (deduplicated): $samplingTypeOptions');
    print('SampleGiven Options (deduplicated): $sampleGivenOptions');

    // Sanitize containerDetails samplingType values
    for (var i = 0; i < containerDetails.length; i++) {
      final samplingType = containerDetails[i]['samplingType'] as String?;
      if (samplingType != null && !samplingTypeOptions.contains(samplingType)) {
        print(
            'Resetting invalid samplingType "$samplingType" for container $i');
        containerDetails[i]['samplingType'] = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Invalid sampling type "$samplingType" reset to Not Selected for container $i'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  void _fetchSeries(int executiveId, String token) async {
    setState(() {
      isLoadingSeries = true;
    });
    final response =
        await ref.read(dsrEntryProvider.notifier).dsrfetchSeriesAndClassLevel(
              request: dsrsampling.dsrSeriesAndClassLevelRequest(
                profileId: AppUtils.getProfileIdStr(),
                executiveId: AppUtils.getExecutiveStr(),
              ),
              token: token,
            );
    if (response.status == 'Success') {
      setState(() {
        seriesList = response.seriesList;
        isLoadingSeries = false;
      });
    } else {
      setState(() {
        isLoadingSeries = false;
      });
    }
  }

  Future<int?> _getClassLevelId(String? classLevelName) async {
    if (classLevelName == null || classLevelName == 'All Class Levels') {
      return null;
    }
    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;
    final token = authState.token ?? '';
    final response =
        await ref.read(dsrEntryProvider.notifier).fetchSeriesAndClassLevel(
              request: sampling.SeriesAndClassLevelRequest(
                  profileId: authState
                          .loginResponse!.executiveBasicData?[0].profileId ??
                      5,
                  executiveId: executiveId),
              token: token,
            );
    if (response.status == 'Success') {
      return response.classLevelList
          .firstWhere(
            (level) => level.classLevelName == classLevelName,
            orElse: () => response.classLevelList.first,
          )
          .classLevelId;
    }
    return null;
  }

  Future<dsrsampling.TitlesResponse> _fetchTitles(
      int executiveId, String token) async {
    final classLevelId = selectedClassLevelName == 'All Class Levels'
        ? null
        : await _getClassLevelId(selectedClassLevelName);
    final response = await ref.read(dsrEntryProvider.notifier).fetchTitles(
          request: dsrsampling.FetchTitlesRequest(
            executiveId: executiveId,
            seriesId: selectedSeriesId,
            classLevel: classLevelId,
          ),
          token: token,
        );
    print('Fetched Titles: ${response.titleList}');
    return response;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customer['CustomerType'] != widget.customer['CustomerType']) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _titlesFuture = _fetchTitles(
              ref
                      .read(authProvider)
                      .loginResponse
                      ?.executiveBasicData?[0]
                      .executiveId ??
                  110,
              ref.read(authProvider).token ?? '');
        });
      });
    }
  }

  void _onFetchSamplingDetails() {
    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;
    final token = authState.token ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _samplingDetailsFuture =
            ref.read(dsrEntryProvider.notifier).dsrfetchSamplingDetails(
                  request: dsrsampling.dsrSamplingDetailsRequest(
                    titleId: null,
                    classLevelId: selectedClassLevelId,
                    seriesId: selectedSeriesId,
                    customerId: widget.customer['CustomerId'],
                    requestType: 'Approval',
                    profileId: AppUtils.getProfileIdStr(),
                    customerType: widget.customer['CustomerType'],
                    executiveId: AppUtils.getExecutiveStr(),
                  ),
                  token: token,
                );
      });
    });
  }

  String _buildSamplingDetailsXML() {
    String cleanAddress(String? address) {
      if (address == null || address.isEmpty) {
        return '';
      }
      return address
          .replaceAll(RegExp(r'[\r\n]+|(\\r\\n)+'), ', ')
          .replaceAll(RegExp(r',\s*,+'), ', ')
          .replaceAll(RegExp(r'^,'), '')
          .replaceAll(RegExp(r',$'), '')
          .trim();
    }

    final buffer = StringBuffer('<DocumentElement>');

    for (var groupIndex = 0;
        groupIndex < selectedTitleGroups.length;
        groupIndex++) {
      final titles = selectedTitleGroups[groupIndex];
      final container = containerDetails[groupIndex];
      final sampleTo = container['sampleTo']?.toString();
      final shipToId = container['shipTo']?.toString();
      final samplingType = container['samplingType']?.toString() ?? 'Unknown';
      final shipToList = container['shipToList'] as List<ShipTo>;
      print(
          'Container $groupIndex: shipToId=$shipToId, samplingType=$samplingType');
      print('Container $groupIndex: shipToList=$shipToList');
      final shipTo = shipToList.firstWhere(
        (s) => s.shipToId == shipToId,
        orElse: () {
          print(
              'Warning: No matching ShipTo found for shipToId=$shipToId in shipToList=$shipToList');
          return ShipTo(
            shipToId: '0_default',
            shipToName: 'No address available',
            shipToAddress: null,
          );
        },
      );

      for (var title in titles) {
        print(
            'Container $groupIndex, Title: ${title.title}, listPrice: ${title.listPrice}, price: ${title.price}, quantity: ${title.quantity}, bookId: ${title.bookId}, seriesId: ${title.seriesId}, subjectId: ${title.subjectId}, samplingType: $samplingType');
        buffer.write('<CustomerSamplingRequestDetails>');
        buffer.write('<SeriesId>${title.seriesId ?? '0'}</SeriesId>');
        buffer.write(
            '<SubjectId>${int.tryParse(title.subjectId?.toString() ?? '0')}</SubjectId>');
        buffer.write('<BookId>${title.bookId ?? 0}</BookId>');
        buffer.write('<RequestedQty>${title.quantity}</RequestedQty>');
        buffer.write('<ShipTo>${shipTo.shipToName}</ShipTo>');
        buffer.write(
            '<ShippingAddress>${cleanAddress(shipTo.shipToAddress)}</ShippingAddress>');
        buffer.write('<SamplingType>$samplingType</SamplingType>');
        buffer.write('<SampleTo>$sampleTo</SampleTo>');
        buffer.write('<MRP>${title.listPrice.toStringAsFixed(2)}</MRP>');
        buffer.write('</CustomerSamplingRequestDetails>');
      }
    }

    buffer.write('</DocumentElement>');
    final xmlString = buffer.toString();
    print('Generated CustomerSamplingDetailsXML: $xmlString');

    try {
      final document = XmlDocument.parse(xmlString);
      print('XML is valid: ${document.toString()}');
    } catch (e) {
      print('XML validation error: $e');
    }

    return xmlString;
  }

  Map<String, dynamic> _calculateTotals() {
    final allTitles = selectedTitleGroups.expand((group) => group).toList();
    int totalQty = allTitles.fold(0, (sum, title) => sum + title.quantity);
    double totalPrice = allTitles.fold(
        0.0, (sum, title) => sum + (title.listPrice * title.quantity));
    print('Calculated Totals: Qty=$totalQty, Price=$totalPrice');
    return {'totalQty': totalQty, 'totalPrice': totalPrice};
  }

  Future<void> _submitSamplingRequest() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    List<String> errors = [];
    if (selectedTitleGroups.isEmpty) {
      errors.add('Please select at least one title');
    }
    if (containerDetails.length != selectedTitleGroups.length) {
      errors.add(
          'Container details mismatch with selected titles. Please re-add containers.');
    }
    for (var i = 0; i < selectedTitleGroups.length; i++) {
      if (i >= containerDetails.length || selectedTitleGroups[i].isEmpty) {
        continue;
      }
      if (containerDetails[i]['sampleTo'] == null) {
        errors.add('Please select Sample To for container ${i + 1}');
      }
      if (containerDetails[i]['shipTo'] == null) {
        errors.add('Please select Ship To for container ${i + 1}');
      }
      if (containerDetails[i]['samplingType'] == null) {
        errors.add('Please select Sampling Type for container ${i + 1}');
      }
      final availableShipTo =
          (containerDetails[i]['shipToList'] as List<ShipTo>?) ?? const <ShipTo>[];
      if (availableShipTo.isEmpty) {
        errors.add('No Ship To addresses available for container ${i + 1}');
      } else if (containerDetails[i]['shipTo'] != null) {
        final selectedShipToId = containerDetails[i]['shipTo'].toString();
        final selectedAddress = availableShipTo
            .where((item) => item.shipToId == selectedShipToId)
            .map((item) => item.shipToAddress?.trim())
            .whereType<String>()
            .firstOrNull;
        if (selectedAddress == null || selectedAddress.isEmpty) {
          errors.add('Please select a valid shipping address for container ${i + 1}');
        }
      }
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.join(', '))),
      );
      print('Validation errors: $errors');
      return;
    }

    final confirmSubmission = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
            'Are you sure you want to submit this sampling request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.buttonPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmSubmission != true) {
      print('Submission cancelled by user');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;
    final userId =
        authState.loginResponse?.executiveBasicData?[0].userId ?? 110;
    final profileCode =
        authState.loginResponse?.executiveBasicData?[0].profileCode ?? 'L1';
    final token = authState.token ?? '';
    final totals = _calculateTotals();

    final requestBody = {
      'CustomerId': widget.customer['CustomerId']?.toString() ?? '0',
      'LoggedInExecutiveid': executiveId.toString(),
      'LoggedInExecutiveProfileCode': profileCode,
      'ExecutiveId': executiveId.toString(),
      'CustomerSamplingDetailsXML': _buildSamplingDetailsXML(),
      'CustomerType': widget.customer['CustomerType']?.toString() ?? 'School',
      'RequestRemarks': remarks ?? '',
      'ShippingInstructions': shippingInstructions ?? '',
      'ShipmentMode': shipmentMode!,
      'TotalPrice': totals['totalPrice'].toStringAsFixed(2),
      'TotalQty': totals['totalQty'].toString(),
      'EnteredBy': userId.toString(),
    };

    print('CustomerSampling API Request: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/CustomerSampling'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('CustomerSampling API Response: ${response.body}');

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      final data = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
      final returnMessages = data['ReturnMessage'] is List
          ? List<dynamic>.from(data['ReturnMessage'])
          : const <dynamic>[];
      final firstMessage = returnMessages.isNotEmpty && returnMessages.first is Map
          ? Map<String, dynamic>.from(returnMessages.first as Map)
          : const <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300 &&
          (data['Status']?.toString().toLowerCase() == 'success')) {
        final message = firstMessage['MsgText']?.toString() ??
            data['message']?.toString() ??
            'Sampling request submitted successfully';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
      } else {
        final message = firstMessage['MsgText']?.toString() ??
            data['Message']?.toString() ??
            data['message']?.toString() ??
            data['error']?.toString() ??
            'Sampling request could not be submitted';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to Submit: $message')),
          );
        }
        print('CustomerSampling API Error (${response.statusCode}): $message');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Network Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authProvider);
    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 110;
    final token = authState.token ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${widget.customer['CustomerType']} Sampling',
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: TColors.primary,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Userheader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: TColors.primary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer['CustomerName']?.toString() ??
                                  'Unknown Customer',
                              style: TextStyle(
                                  color: TColors.headerText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Customer Type: ',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  widget.customer['CustomerType']?.toString() ??
                                      'Unknown',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.customer['Address']
                                  .replaceAll('\\r\\n', ', '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<dsrsampling.dsrSamplingDetailsResponse>(
                      future: _samplingDetailsFuture,
                      builder: (context, samplingSnapshot) {
                        return FutureBuilder<
                            dsrsampling.dsrSeriesAndClassLevelResponse>(
                          future: _classLevelFuture,
                          builder: (context, classLevelSnapshot) {
                            if (samplingSnapshot.connectionState ==
                                    ConnectionState.waiting ||
                                classLevelSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (samplingSnapshot.hasError ||
                                classLevelSnapshot.hasError) {
                              return Center(
                                  child: Text(
                                      'Error: ${samplingSnapshot.error ?? classLevelSnapshot.error}'));
                            } else if (!samplingSnapshot.hasData ||
                                !classLevelSnapshot.hasData ||
                                samplingSnapshot.data!.status != 'Success' ||
                                classLevelSnapshot.data!.status != 'Success') {
                              return const Center(
                                  child: Text('No data available'));
                            }

                            final samplingData = samplingSnapshot.data!;
                            final classLevelData = classLevelSnapshot.data!;

                            return FutureBuilder<
                                ({
                                  List<sampling.SamplingContact> sampleToList,
                                  List<ShipTo> shipToList,
                                  Map<String, dynamic>? selectedCustomer
                                })>(
                              future: _sampleToAndShipToFuture,
                              builder: (context, sampleToSnapshot) {
                                List<sampling.SamplingContact> sampleToList = [
                                  sampling.SamplingContact(
                                    customerContactId: int.parse(widget
                                            .customer['CustomerId']
                                            ?.toString() ??
                                        '0'),
                                    customerName: widget
                                            .customer['CustomerName']
                                            ?.toString() ??
                                        'Unknown Customer',
                                  ),
                                ];
                                List<ShipTo> shipToList = [
                                  ShipTo(
                                    shipToId: '0_default',
                                    shipToName: 'No address available',
                                    shipToAddress: null,
                                  ),
                                ];

                                if (sampleToSnapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (sampleToSnapshot.hasData &&
                                      sampleToSnapshot
                                          .data!.sampleToList.isNotEmpty) {
                                    sampleToList =
                                        sampleToSnapshot.data!.sampleToList;
                                    shipToList =
                                        sampleToSnapshot.data!.shipToList;
                                  }
                                }

                                print(
                                    'Rendering SamplingDoneWidget with shipToList: $shipToList');

                                return SamplingDoneWidget(
                                  contextType: 'Customer',
                                  samplingDone: samplingDone,
                                  samplingResponse: samplingData,
                                  classLevelResponse: classLevelData,
                                  selectedTitles: selectedTitles,
                                  selectedSamplingType: selectedSamplingType,
                                  selectedClassLevel: selectedClassLevelId,
                                  selectedSeriesId: selectedSeriesId,
                                  seriesList: seriesList,
                                  isLoadingSeries: isLoadingSeries,
                                  customerId: widget.customer['CustomerId'],
                                  customerType: widget.customer['CustomerType'],
                                  customerContactId: int.parse(widget
                                          .customer['CustomerId']
                                          ?.toString() ??
                                      '0'),
                                  executiveId: executiveId,
                                  token: token,
                                  onRemoveGroup: (int groupIndex) {
                                    setState(() {
                                      if (groupIndex <
                                              selectedTitleGroups.length &&
                                          groupIndex <
                                              containerDetails.length) {
                                        selectedTitleGroups
                                            .removeAt(groupIndex);
                                        containerDetails.removeAt(groupIndex);
                                        selectedTitles = selectedTitleGroups
                                            .expand((group) => group)
                                            .toList();
                                      }
                                    });
                                  },
                                  onFetchSamplingDetails:
                                      _onFetchSamplingDetails,
                                  onContainerDetailsChanged: (groupIndex,
                                      sampleTo,
                                      shipTo,
                                      samplingType,
                                      titles,
                                      shipToList) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        print(
                                            'onContainerDetailsChanged called: groupIndex=$groupIndex, sampleTo=$sampleTo, shipTo=$shipTo, samplingType=$samplingType, titles=$titles');
                                        while (containerDetails.length <=
                                            groupIndex) {
                                          containerDetails.add({
                                            'sampleTo': null,
                                            'shipTo': null,
                                            'shipToList': <ShipTo>[],
                                            'isLoadingShipTo': false,
                                            'seriesId': '0',
                                            'classLevelId':
                                                selectedClassLevelId,
                                            'samplingType': null,
                                          });
                                          selectedTitleGroups.add([]);
                                        }
                                        // Validate samplingType
                                        final validSamplingType =
                                            samplingType != null &&
                                                    samplingData.samplingType
                                                        .map((type) =>
                                                            type.samplingType)
                                                        .contains(samplingType)
                                                ? samplingType
                                                : null;
                                        if (samplingType != null &&
                                            validSamplingType == null) {
                                          print(
                                              'Invalid samplingType "$samplingType" for groupIndex=$groupIndex, resetting to null');
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Invalid sampling type "$samplingType" reset to Not Selected'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          });
                                        }
                                        containerDetails[groupIndex] = {
                                          'sampleTo': sampleTo,
                                          'shipTo': shipTo,
                                          'shipToList':
                                              List<ShipTo>.from(shipToList),
                                          'isLoadingShipTo': false,
                                          'seriesId': titles.isNotEmpty &&
                                                  titles[0].seriesId != null
                                              ? titles[0].seriesId.toString()
                                              : selectedSeriesId ?? '0',
                                          'classLevelId':
                                              containerDetails[groupIndex]
                                                      ['classLevelId'] ??
                                                  selectedClassLevelId,
                                          'samplingType': validSamplingType,
                                        };
                                        selectedTitleGroups[groupIndex] =
                                            titles;
                                        selectedTitles = selectedTitleGroups
                                            .expand((group) => group)
                                            .toList();
                                        print(
                                            'Updated containerDetails: $containerDetails');
                                        print(
                                            'Updated selectedTitleGroups: $selectedTitleGroups');
                                        print(
                                            'Selected Titles: $selectedTitles');
                                      });
                                    });
                                  },
                                  onSamplingTypeChanged: (String? newValue) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (newValue != null) {
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                      }
                                      setState(() {
                                        print(
                                            'onSamplingTypeChanged called: $newValue');
                                        selectedSamplingType = newValue;
                                      });
                                    });
                                  },
                                  onClassLevelChanged: (int? newValue) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        print(
                                            'onClassLevelChanged called: $newValue');
                                        selectedClassLevelId = newValue;
                                        selectedClassLevelName =
                                            newValue == null
                                                ? 'All Class Levels'
                                                : classLevelData.classLevelList
                                                    .firstWhere((level) =>
                                                        level.classLevelId ==
                                                        newValue)
                                                    .classLevelName;
                                        _titlesFuture =
                                            _fetchTitles(executiveId, token);
                                        selectedTitles = selectedTitleGroups
                                            .expand((groupList) => groupList)
                                            .toList();
                                        print(
                                            'Selected Titles: $selectedTitles');
                                      });
                                    });
                                  },
                                  onSeriesChanged: (String? newValue) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        print(
                                            'onSeriesChanged called: $newValue');
                                        selectedSeriesId = newValue;
                                        selectedTitles = selectedTitleGroups
                                            .expand((groupList) => groupList)
                                            .toList();
                                        _titlesFuture =
                                            _fetchTitles(executiveId, token);
                                        _sampleToAndShipToFuture =
                                            ref.read(sampleToAndShipToProvider(
                                          (
                                            executiveId: executiveId,
                                            customer: widget.customer,
                                            seriesId: newValue
                                          ),
                                        ).future);
                                        print(
                                            'Series changed: $newValue, preserved selectedTitleGroups and containerDetails');
                                        print(
                                            'Container Details: $containerDetails');
                                        print(
                                            'Selected Title Groups: $selectedTitleGroups');
                                        print(
                                            'Selected Titles: $selectedTitles');
                                      });
                                    });
                                  },
                                  onTitlesSelected:
                                      (List<dsrsampling.TitleData> titles) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      setState(() {
                                        print(
                                            'onTitlesSelected called: $titles');
                                        selectedTitles = titles;
                                        print(
                                            'Selected Titles: $selectedTitles');
                                        print(
                                            'Selected Title Groups: $selectedTitleGroups');
                                        print(
                                            'Container Details: $containerDetails');
                                      });
                                    });
                                  },
                                  samplingTypeOptions: samplingTypeOptions,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<ShipmentModeResponse>(
                      future: _shipmentModeFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Error loading shipment modes: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.status != 'Success' ||
                            snapshot.data!.shipmentModes.isEmpty) {
                          return const Center(
                              child: Text('No shipment modes available'));
                        }

                        final response = snapshot.data!;
                        return _buildShipmentModeDropdown(response);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Shipping Instructions',
                      onChanged: (value) => setState(() =>
                          shippingInstructions = value.isEmpty ? null : value),
                      semanticLabel: 'Shipping Instructions',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Remarks',
                      onChanged: (value) => setState(
                          () => remarks = value.isEmpty ? null : value),
                      semanticLabel: 'Remarks',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitSamplingRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.buttonPrimary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Sampling Request',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentModeDropdown(ShipmentModeResponse response) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Shipment Mode',
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.borderColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      dropdownColor: Colors.white,
      value: shipmentMode,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select'),
        ),
        ...response.shipmentModes.map((mode) {
          return DropdownMenuItem<String>(
            value: mode.shipmentModeId.toString(),
            child: Text(mode.shipmentModeName),
          );
        }).toList(),
      ],
      onChanged: (String? value) {
        print('Selected Shipment Mode: $value');
        setState(() {
          shipmentMode = value;
          ScaffoldMessenger.of(context).clearSnackBars();
          _formKey.currentState?.validate();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a shipment mode';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required ValueChanged<String> onChanged,
    required String semanticLabel,
  }) {
    return TextFormField(
      minLines: 2,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: TColors.borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColors.borderColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      keyboardAppearance: Brightness.light,
      textInputAction: TextInputAction.newline,
    );
  }
}


extension _FirstOrNullShipTo<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
