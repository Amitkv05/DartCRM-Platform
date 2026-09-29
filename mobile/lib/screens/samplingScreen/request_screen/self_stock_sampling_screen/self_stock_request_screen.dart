import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/sampling_models/request/self_stock_sampling_models/self_stock_request_response.dart';
import 'package:dart_crm/models/sampling_models/request/self_stock_sampling_models/self_stock_sampling.dart'
    as self_stock;
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/providers/samplingProvider/request/self_stock_sampling_provider/self_stock_request_provider.dart';
import 'package:dart_crm/screens/homeScreen/widget/userHeader.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/action_button.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/address_card.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/book_container.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/dropdown_widget.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/tabbar.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/text_field.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfStockRequestScreen extends ConsumerStatefulWidget {
  const SelfStockRequestScreen({super.key});

  @override
  _SelfStockRequestScreenState createState() => _SelfStockRequestScreenState();
}

class _SelfStockRequestScreenState extends ConsumerState<SelfStockRequestScreen>
    with TickerProviderStateMixin {
  String? selectedExecutiveName = 'Select';
  String? selectedShipTo;
  String? selectedShipmentMode;
  final shippingInstructionsController = TextEditingController();
  final remarksController = TextEditingController();
  final searchController = TextEditingController();
  final transportOfficeAddressController = TextEditingController();
  List<Map<String, dynamic>> titleInSeriesData = [];
  List<Map<String, dynamic>> titleNotInSeriesData = [];
  sampling.SeriesAndClassLevelResponse? classLevelResponse;
  int selectionCount = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  late Future<void> _initialLoadFuture;
  bool _isSubmitting = false;
  // Optional: Track deleted series to prevent re-adding (uncomment if needed)
  // Set<String> deletedSeries = {};

  String? executiveNameError;
  String? shipmentModeError;
  String? shipToError;
  String? tradeAddressError;
  String? transportOfficeAddressError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _tabController = TabController(length: 2, vsync: this);
    _animationController.forward();
    _initialLoadFuture = _loadInitialData();
    transportOfficeAddressController
        .addListener(_validateTransportOfficeAddress);
  }

  Future<void> _loadInitialData() async {
    await Future.microtask(() async {
      final authState = ref.read(authProvider);
      final token = authState.token ?? '';
      final executiveId =
          authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;

      if (executiveId == 0) {
        print(
            'Warning: Executive ID is 0, data might not load. Check authProvider.');
      }
      if (token.isEmpty) {
        print('Warning: Token is empty, data may not load.');
      }

      await Future.wait([
        ref.read(selfStockRequestProvider.notifier).fetchSelfStockRequestData(
              token: token,
              executiveId: executiveId.toString(),
            ),
      ]);

      final response = await ref
          .read(dsrEntryProvider.notifier)
          .fetchSeriesAndClassLevel(
            request: sampling.SeriesAndClassLevelRequest(
              profileId:
                  authState.loginResponse?.executiveBasicData?[0].profileId ??
                      5,
              executiveId: executiveId,
            ),
            token: token,
          )
          .catchError((e) {
        print('Series and Class Level Error: $e');
      });

      if (mounted) {
        setState(() {
          classLevelResponse = response;
        });
      }
    });
  }

  @override
  void dispose() {
    shippingInstructionsController.dispose();
    remarksController.dispose();
    searchController.dispose();
    transportOfficeAddressController.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _buildSelfStockDetailsXml() {
    final details = [
      ...titleInSeriesData.map((data) {
        final subjectId =
            int.tryParse(data['subjectId']?.toString() ?? '0') ?? 0;
        final seriesId = int.tryParse(data['seriesId']?.toString() ?? '0') ?? 0;
        final bookId = int.tryParse(data['bookId']?.toString() ?? '0') ?? 0;
        final requestedQty = int.tryParse(data['qty']?.toString() ?? '1') ?? 1;

        if (subjectId == 0) {
          print(
              'Warning: Invalid subjectId for book: ${data['title']}, ISBN: ${data['ISBN']}');
        }

        print(
            'Processing Series item: ${data['title']}, SubjectId: $subjectId, SeriesId: $seriesId, BookId: $bookId, Qty: $requestedQty');

        return self_stock.SelfStockRequestDetail(
          subjectId: subjectId,
          seriesId: seriesId,
          bookId: bookId,
          requestedQty: requestedQty,
        );
      }),
      ...titleNotInSeriesData.map((data) {
        final subjectId =
            int.tryParse(data['subjectId']?.toString() ?? '0') ?? 0;
        final bookId = int.tryParse(data['bookId']?.toString() ?? '0') ?? 0;
        final requestedQty = int.tryParse(data['qty']?.toString() ?? '1') ?? 1;

        if (subjectId == 0) {
          print(
              'Warning: Invalid subjectId for book: ${data['title']}, ISBN: ${data['ISBN']}');
        }

        print(
            'Processing Non-Series item: ${data['title']}, SubjectId: $subjectId, SeriesId: 0, BookId: $bookId, Qty: $requestedQty');

        return self_stock.SelfStockRequestDetail(
          subjectId: subjectId,
          seriesId: 0,
          bookId: bookId,
          requestedQty: requestedQty,
        );
      }),
    ];

    if (details.isEmpty) {
      print('Warning: No details to include in XML');
      return '';
    }

    if (details.any((d) => d.subjectId == 0)) {
      print(
          'Error: One or more books have invalid subjectId (0). Submission blocked.');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid subjectId detected. Please check book data.'),
        ),
      );
      return '';
    }

    final xml =
        '<DocumentElement>${details.map((d) => d.toXml()).join()}</DocumentElement>';
    print('Generated XML: $xml');
    return xml;
  }

  void _handleSelection(List<Map<String, dynamic>> newData, String type) {
    setState(() {
      final targetList =
          type == 'Series' ? titleInSeriesData : titleNotInSeriesData;
      // Remove existing entries for the selected books
      for (var item in newData) {
        final bookId = item['bookId'];
        final seriesName = item['series']?.toString() ?? 'Unknown';
        targetList.removeWhere(
            (data) => data['bookId'] == bookId && data['series'] == seriesName);
      }
      // Add new/updated entries, excluding those with quantity == 0
      for (var item in newData) {
        final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
        if (qty <= 0) {
          print('Skipping book with zero quantity: ${item['title']}');
          continue; // Skip items with zero quantity
        }
        print(
            'Processing $type item: ${item['title']}, series: ${item['series']}, ISBN: ${item['ISBN']}, SubjectId: ${item['subjectId']}, Qty: ${item['qty']}');
        selectionCount++;
        final updatedItem = {
          ...item,
          'sno': selectionCount.toString(),
        };
        targetList.add(updatedItem);
        print(
            'Added/Updated book: ${item['title']}, series: ${item['series']}, qty: ${item['qty']}, subjectId: ${item['subjectId']}');
      }
      // Remove duplicates (optional, kept for safety)
      final uniqueList = <Map<String, dynamic>>[];
      final seenKeys = <String>{};
      for (var item in targetList) {
        final key = '${item['bookId']}_${item['series']}';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          uniqueList.add(item);
        }
      }
      targetList.clear();
      targetList.addAll(uniqueList);
      print('Updated $type Data: $targetList');
      // Reset selectionCount if both lists are empty
      if (titleInSeriesData.isEmpty && titleNotInSeriesData.isEmpty) {
        selectionCount = 0;
        print('Both lists are empty, resetting selectionCount to 0');
      }
    });
  }

  void _validateExecutiveName() {
    final authState = ref.read(authProvider);
    final executiveName =
        authState.loginResponse?.executiveBasicData?[0].executiveName ??
            'Unknown';
    setState(() {
      executiveNameError = (selectedExecutiveName == null ||
                  selectedExecutiveName!.isEmpty ||
                  selectedExecutiveName == 'Select') &&
              selectedExecutiveName != executiveName
          ? 'Please select an executive name'
          : null;
    });
  }

  void _validateShipmentMode() {
    setState(() {
      shipmentModeError =
          selectedShipmentMode == null || selectedShipmentMode == 'Select'
              ? 'Please select a shipment mode'
              : null;
    });
  }

  void _validateShipTo() {
    setState(() {
      shipToError = selectedShipTo == null || selectedShipTo == 'Select'
          ? 'Please select a ship to address'
          : null;
    });
  }

  void _validateTradeAddress() {
    final selfStockState = ref.read(selfStockRequestProvider);
    setState(() {
      tradeAddressError = selectedShipTo == 'Trade' &&
              (selfStockState.selectedTradeAddress == null ||
                  selfStockState.selectedTradeAddress == 'Select' ||
                  selfStockState.selectedTradeAddress!.isEmpty)
          ? 'Please select a trade address'
          : null;
    });
  }

  void _validateTransportOfficeAddress() {
    setState(() {
      transportOfficeAddressError = selectedShipTo == 'Transport Office' &&
              transportOfficeAddressController.text.trim().isEmpty
          ? 'Please enter a transport Official Address'
          : null;
    });
  }

  void _validateTitles() {
    setState(() {
      if (titleInSeriesData.isEmpty && titleNotInSeriesData.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one title before submitting')),
        );
      }
    });
  }

  bool _validateAllFields() {
    _validateExecutiveName();
    _validateShipmentMode();
    _validateShipTo();
    _validateTradeAddress();
    _validateTransportOfficeAddress();
    _validateTitles();

    return executiveNameError == null &&
        shipmentModeError == null &&
        shipToError == null &&
        tradeAddressError == null &&
        transportOfficeAddressError == null &&
        (titleInSeriesData.isNotEmpty || titleNotInSeriesData.isNotEmpty);
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    print('Submitting Self Stock Request...');

    if (!_validateAllFields()) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final authState = ref.read(authProvider);
    final selfStockState = ref.read(selfStockRequestProvider);

    final xml = _buildSelfStockDetailsXml();
    if (xml.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one title or fix invalid data')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    const maxQtyAllowed = 999;
    final totalQty = [...titleInSeriesData, ...titleNotInSeriesData].fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item['qty'] ?? '1') ?? 1),
    );
    if (totalQty > maxQtyAllowed) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Total requested quantity ($totalQty) exceeds maximum allowed ($maxQtyAllowed)'),
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    ShipmentMode? selectedMode;
    try {
      selectedMode =
          selfStockState.selfStockRequestResponse!.shipmentMode.firstWhere(
        (mode) => mode.shipmentMode == selectedShipmentMode,
        orElse: () =>
            selfStockState.selfStockRequestResponse!.shipmentMode.first,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error: Invalid shipment mode selected or no modes available.')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final shipmentModeId = selectedMode.shipmentModeId?.toString() ?? '1';
    final shippingAddress = selectedShipTo == 'Trade'
        ? selfStockState.selectedTradeAddress!.split('_')[1]
        : selectedShipTo == 'Transport Office'
            ? transportOfficeAddressController.text.trim()
            : selfStockState.selfStockRequestResponse?.shipmentAddress
                    ?.firstWhere(
                      (addr) => addr.addressType == 'Residence Address',
                      orElse: () => ShipmentAddress(
                          addressType: 'Residence Address',
                          shipmentAddress: 'No Residence Address Found'),
                    )
                    .shipmentAddress ??
                'No Residence Address Found';

    final request = self_stock.SelfStockRequest(
      loggedInExecutiveId: authState
          .loginResponse!.executiveBasicData![0].executiveId
          .toString(),
      profileCode: AppUtils.getProfileCodeStr(),
      executiveId: authState.loginResponse!.executiveBasicData![0].executiveId
          .toString(),
      selfStockDetailsXml: xml,
      shippingAddress: shippingAddress,
      shipTo: selectedShipTo ?? '',
      shipmentModeId: shipmentModeId,
      enteredBy:
          authState.loginResponse!.executiveBasicData![0].userId.toString(),
      shippingInstructions: shippingInstructionsController.text,
      remarks: remarksController.text,
    );

    await ref.read(selfStockRequestProvider.notifier).submitSelfStockRequest(
          request: request,
          token: authState.token ?? '',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updatedState = ref.read(selfStockRequestProvider);
      print('Updated state submitResponse: ${updatedState.submitResponse}');
      if (updatedState.submitResponse != null) {
        if (updatedState.submitResponse!.status == 'Success') {
          final message = updatedState
                      .submitResponse!.returnMessage.isNotEmpty &&
                  updatedState.submitResponse!.returnMessage[0]['MsgText'] !=
                      null
              ? updatedState.submitResponse!.returnMessage[0]['MsgText']
                  .toString()
              : 'Self Stock Request submitted';
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
              duration: const Duration(seconds: 5),
            ),
          );
          print('Self Stock Request Submitted Successfully: $message');
          ref.read(selfStockRequestProvider.notifier).clearSubmitResponse();
        } else {
          final message = updatedState
                      .submitResponse!.returnMessage.isNotEmpty &&
                  updatedState.submitResponse!.returnMessage[0]['MsgText'] !=
                      null
              ? updatedState.submitResponse!.returnMessage[0]['MsgText']
                  .toString()
              : 'Failed to submit Self Stock Request';
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $message')),
          );
        }
      } else if (updatedState.error != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${updatedState.error}')),
        );
      }
      setState(() {
        _isSubmitting = false;
        Navigator.pop(context);
      });
    });
  }

  Widget _buildAddressContainer(SelfStockRequestState selfStockState) {
    if (selectedShipTo == null ||
        selectedShipTo == 'Select' ||
        selectedShipTo == 'Transport Office') {
      return const SizedBox.shrink();
    }

    if (selectedShipTo == 'Residence Address') {
      final residenceAddress =
          selfStockState.selfStockRequestResponse?.shipmentAddress
              ?.firstWhere(
                (addr) => addr.addressType == 'Residence Address',
                orElse: () => ShipmentAddress(
                    addressType: 'Residence Address',
                    shipmentAddress: 'No Address Found'),
              )
              .shipmentAddress;
      return AddressCard(
        title: 'Residence Address',
        address: residenceAddress ?? 'No Address Found',
      );
    }

    if (selectedShipTo == 'Trade' &&
        selfStockState.selectedTradeAddress != null &&
        selfStockState.selectedTradeAddress != 'Select') {
      final selectedTrade = selfStockState.tradeAddresses.firstWhere(
        (addr) => addr['value'] == selfStockState.selectedTradeAddress,
        orElse: () => {
          'customerName': 'Unknown',
          'shippingAddress': 'No address selected',
        },
      );
      final tradeAddressDetails =
          '${selectedTrade['customerName']}\n${selectedTrade['shippingAddress']}';
      return AddressCard(title: 'Trade Address', address: tradeAddressDetails);
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selfStockState = ref.watch(selfStockRequestProvider);

    final executiveId =
        authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
    final token = authState.token ?? '';
    final executiveName =
        authState.loginResponse?.executiveBasicData?[0].executiveName ??
            'Unknown';

    final shipmentModes = selfStockState.selfStockRequestResponse != null &&
            selfStockState.selfStockRequestResponse!.shipmentMode.isNotEmpty
        ? [
            'Select',
            ...selfStockState.selfStockRequestResponse!.shipmentMode
                .map((mode) => mode.shipmentMode)
                .toList()
          ]
        : ['Select'];
    final shipToOptions = selfStockState.selfStockRequestResponse != null &&
            selfStockState.selfStockRequestResponse!.shipTo.isNotEmpty
        ? [
            'Select',
            ...selfStockState.selfStockRequestResponse!.shipTo
                .map((ship) => ship.shipTo)
                .toList()
          ]
        : ['Select'];
    final tradeAddressItems = selfStockState.tradeAddresses.isNotEmpty
        ? [
            'Select',
            ...selfStockState.tradeAddresses
                .map((addr) => addr['value'] as String)
                .toList()
          ]
        : ['Select'];
    final tradeAddressDisplayItems = selfStockState.tradeAddresses.isNotEmpty
        ? [
            'Select',
            ...selfStockState.tradeAddresses
                .map((addr) => addr['label'] as String)
                .toList()
          ]
        : ['Select'];

    final seriesGroups = <String, List<Map<String, dynamic>>>{};
    for (var data in titleInSeriesData) {
      final seriesName = data['series']?.toString() ?? 'Unknown Series';
      print(
          'Grouping book ${data['title']} with series: $seriesName, subjectId: ${data['subjectId']}');
      seriesGroups.putIfAbsent(seriesName, () => []).add(data);
    }

    final notInSeriesGroups = <String, List<Map<String, dynamic>>>{};
    for (var data in titleNotInSeriesData) {
      final seriesName =
          data['series']?.toString() ?? data['title']?.toString() ?? 'Unknown';
      print(
          'Grouping non-series book ${data['title']} with series: $seriesName, subjectId: ${data['subjectId']}');
      notInSeriesGroups.putIfAbsent(seriesName, () => []).add(data);
    }

    print('Current seriesGroups: ${seriesGroups.keys.toList()}');
    print('Current notInSeriesGroups: ${notInSeriesGroups.keys.toList()}');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Self Stock Request',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 22, color: Colors.black87),
        ),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(252, 242, 219, 1),
                Color.fromRGBO(252, 242, 219, 0.85),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Userheader(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[50]!, Colors.white],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FutureBuilder<void>(
                  future: _initialLoadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          DropdownRow(
                            label: 'Executive Name',
                            value: selectedExecutiveName,
                            items: ['Select', executiveName],
                            onChanged: (value) {
                              setState(() => selectedExecutiveName = value);
                              _validateExecutiveName();
                            },
                            errorText: executiveNameError,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          TabBar(
                            controller: _tabController,
                            indicatorColor: TColors.buttonPrimary,
                            labelColor: Colors.black87,
                            unselectedLabelColor: Colors.grey,
                            tabs: const [
                              Tab(text: 'Title in Series'),
                              Tab(text: 'Title not in Series'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: MediaQuery.sizeOf(context).height * 0.157,
                            child: TabBarViewWidget(
                              tabController: _tabController,
                              classLevelResponse: classLevelResponse,
                              onSelectionSeries: (selectedBooks) =>
                                  _handleSelection(selectedBooks, 'Series'),
                              onSelectionNotInSeries: (selectedBooks) =>
                                  _handleSelection(
                                      selectedBooks, 'Not in Series'),
                              currentSeriesData: titleInSeriesData,
                              currentNotSeriesData: titleNotInSeriesData,
                            ),
                          ),
                          if (titleInSeriesData.isNotEmpty ||
                              titleNotInSeriesData.isNotEmpty)
                            Column(
                              children: [
                                if (titleInSeriesData.isNotEmpty)
                                  const SizedBox(height: 10),
                                if (titleInSeriesData.isNotEmpty)
                                  Column(
                                    children: seriesGroups.entries
                                        .map(
                                          (entry) => BookContainer(
                                            key: ValueKey(entry.key),
                                            seriesName: entry.key,
                                            books: entry.value,
                                            onRemove: (data) {
                                              setState(() {
                                                titleInSeriesData.remove(data);
                                                ScaffoldMessenger.of(context)
                                                    .hideCurrentSnackBar();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Removed ${data['title']}')),
                                                );
                                                if (titleInSeriesData.isEmpty &&
                                                    titleNotInSeriesData
                                                        .isEmpty) {
                                                  selectionCount = 0;
                                                  print(
                                                      'Both lists are empty, resetting selectionCount to 0');
                                                }
                                              });
                                            },
                                            onQuantityChange: (data, newQty) {
                                              setState(() {
                                                final index = titleInSeriesData
                                                    .indexOf(data);
                                                if (index != -1) {
                                                  titleInSeriesData[index] = {
                                                    ...data,
                                                    'qty': newQty.toString(),
                                                  };
                                                }
                                              });
                                            },
                                            onRemoveContainer: () {
                                              setState(() {
                                                // Optional: Track deleted series
                                                // deletedSeries.add(entry.key);
                                                titleInSeriesData.removeWhere(
                                                    (data) =>
                                                        data['series']
                                                            ?.toString() ==
                                                        entry.key);
                                                ScaffoldMessenger.of(context)
                                                    .hideCurrentSnackBar();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Removed ${entry.key}')),
                                                );
                                                if (titleInSeriesData.isEmpty &&
                                                    titleNotInSeriesData
                                                        .isEmpty) {
                                                  selectionCount = 0;
                                                  print(
                                                      'Both lists are empty, resetting selectionCount to 0');
                                                }
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                if (titleNotInSeriesData.isNotEmpty)
                                  const SizedBox(height: 5),
                                if (titleNotInSeriesData.isNotEmpty)
                                  Column(
                                    children: notInSeriesGroups.entries
                                        .map((entry) => BookContainer(
                                              key: ValueKey(entry.key),
                                              seriesName: entry.key,
                                              books: entry.value,
                                              onRemove: (data) {
                                                setState(() {
                                                  titleNotInSeriesData
                                                      .remove(data);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Removed ${data['title']}')),
                                                  );
                                                  if (titleInSeriesData
                                                          .isEmpty &&
                                                      titleNotInSeriesData
                                                          .isEmpty) {
                                                    selectionCount = 0;
                                                    print(
                                                        'Both lists are empty, resetting selectionCount to 0');
                                                  }
                                                });
                                              },
                                              onQuantityChange: (data, newQty) {
                                                setState(() {
                                                  final index =
                                                      titleNotInSeriesData
                                                          .indexOf(data);
                                                  if (index != -1) {
                                                    titleNotInSeriesData[
                                                        index] = {
                                                      ...data,
                                                      'qty': newQty.toString(),
                                                    };
                                                  }
                                                });
                                              },
                                              onRemoveContainer: () {
                                                setState(() {
                                                  // Optional: Track deleted series
                                                  // deletedSeries.add(entry.key);
                                                  titleNotInSeriesData
                                                      .removeWhere((data) =>
                                                          data['series']
                                                                  ?.toString() ==
                                                              entry.key ||
                                                          data['title']
                                                                  ?.toString() ==
                                                              entry.key);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Removed container for ${entry.key}')),
                                                  );
                                                  if (titleInSeriesData
                                                          .isEmpty &&
                                                      titleNotInSeriesData
                                                          .isEmpty) {
                                                    selectionCount = 0;
                                                    print(
                                                        'Both lists are empty, resetting selectionCount to 0');
                                                  }
                                                });
                                              },
                                            ))
                                        .toList(),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          DropdownRow(
                            label: 'Shipment Mode',
                            value: selectedShipmentMode,
                            items: shipmentModes,
                            onChanged: (value) {
                              setState(() => selectedShipmentMode = value);
                              _validateShipmentMode();
                            },
                            errorText: shipmentModeError,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          DropdownRow(
                            label: 'Ship To',
                            value: selectedShipTo,
                            items: shipToOptions,
                            onChanged: (value) {
                              setState(() {
                                final previousShipTo = selectedShipTo;
                                selectedShipTo = value;
                                if (value == 'Trade' &&
                                    value != previousShipTo &&
                                    executiveId != 0) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) async {
                                    ref
                                        .read(selfStockRequestProvider.notifier)
                                        .setSelectedTradeAddress('Select');
                                    await ref
                                        .read(selfStockRequestProvider.notifier)
                                        .fetchTradeAddresses(
                                          executiveId: executiveId.toString(),
                                          shipTo: 'Trade',
                                          token: token,
                                        );
                                    ref
                                        .read(selfStockRequestProvider.notifier)
                                        .setSelectedTradeAddress('Select');
                                  });
                                } else if (value != 'Trade') {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ref
                                        .read(selfStockRequestProvider.notifier)
                                        .setSelectedTradeAddress(null);
                                  });
                                  transportOfficeAddressController.clear();
                                }
                              });
                              _validateShipTo();
                              if (value != 'Trade') _validateTradeAddress();
                            },
                            errorText: shipToError,
                            isRequired: true,
                          ),
                          const SizedBox(height: 10),
                          if (selectedShipTo == 'Trade')
                            DropdownRow(
                              label: 'Trade Address',
                              value: selfStockState.selectedTradeAddress ??
                                  'Select',
                              items: tradeAddressItems,
                              displayItems: tradeAddressDisplayItems,
                              onChanged: (value) {
                                ref
                                    .read(selfStockRequestProvider.notifier)
                                    .setSelectedTradeAddress(value);
                                _validateTradeAddress();
                              },
                              errorText: tradeAddressError,
                              isRequired: true,
                            ),
                          if (selectedShipTo == 'Transport Office')
                            TextFieldWidget(
                              label: 'Transport Official Address',
                              controller: transportOfficeAddressController,
                              isRequired: true,
                              wordLimit: 0,
                              errorText: transportOfficeAddressError,
                            ),
                          _buildAddressContainer(selfStockState),
                          const SizedBox(height: 16),
                          TextFieldWidget(
                            label: 'Shipping Instructions',
                            controller: shippingInstructionsController,
                            isRequired: false,
                            wordLimit: 0,
                            errorText: null,
                          ),
                          const SizedBox(height: 16),
                          TextFieldWidget(
                            label: 'Remarks',
                            controller: remarksController,
                            isRequired: false,
                            wordLimit: 0,
                            errorText: null,
                          ),
                          const SizedBox(height: 24),
                          ActionButtons(
                            isSubmitting: _isSubmitting,
                            onSubmit: _submitRequest,
                            validateFields: _validateAllFields,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
