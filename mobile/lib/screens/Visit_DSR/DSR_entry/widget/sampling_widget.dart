import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/edit/utils/click_button_widget.dart';
import 'package:dart_crm/edit/utils/cross_button_widget.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/setup_value.dart';
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/Visit_DSR/DSR_entry/widget/book_search_popup.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SamplingWidget extends ConsumerStatefulWidget {
  final dsrsampling.dsrSamplingDetailsResponse? samplingResponse;
  final dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;
  final int customerId;
  final String customerType;
  final int customerContactId;
  final int executiveId;
  final String token;
  final String contextType;

  const SamplingWidget({
    super.key,
    required this.samplingResponse,
    required this.classLevelResponse,
    required this.customerId,
    required this.customerType,
    required this.customerContactId,
    required this.executiveId,
    required this.token,
    required this.contextType,
  });

  @override
  ConsumerState<SamplingWidget> createState() => _SamplingDoneWidgetState();
}

class _SamplingDoneWidgetState extends ConsumerState<SamplingWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController isbnSearchController = TextEditingController();

  bool isLoadingSampleTo = false;
  bool isLoadingSearch = false;
  String? sampleToError;

  dsrsampling.dsrSamplingDetailsResponse? samplingData;

  List<StateResponse> sampleToNewList = [];
  List<StateResponse> shipToNewList = [];

  StateResponse? selectedSampleType;
  StateResponse? selectedSampleGiven;
  StateResponse? selectSeries;
  StateResponse? selectedClassLevel;

  List<StateResponse> sampleTypeData = [];
  List<StateResponse> sampleGivenData = [];
  List<StateResponse> seriesData = [];
  List<StateResponse> classData = [];
  late int maxQuantityAllowed;
  late int maxSamplingTitles;

  @override
  void initState() {
    samplingData = widget.samplingResponse;
    samplingData?.samplingType.forEach((action) {
      StateResponse s = StateResponse();
      s.text = action.samplingType;
      s.label = action.samplingTypeValue;
      sampleTypeData.add(s);
    });

    samplingData?.sampleGiven.forEach((action) {
      StateResponse s = StateResponse();
      s.text = action.sampleGiven;
      s.label = action.sampleGivenValue;
      sampleGivenData.add(s);
    });

    widget.classLevelResponse?.seriesList.forEach((action) {
      StateResponse s = StateResponse();
      s.text = action.seriesName;
      s.label = '${action.seriesId}';
      seriesData.add(s);
    });

    widget.classLevelResponse?.classLevelList.forEach((action) {
      StateResponse s = StateResponse();
      s.text = action.classLevelName;
      s.label = '${action.classLevelId}';
      classData.add(s);
    });

    samplingData?.sampleTo.forEach((action) {
      final s = StateResponse();
      s.text = action.customerName;
      // ClickButtonWidget consumers read `value`, so keep the contact id here.
      s.value = action.customerContactId;
      s.label = action.customerContactId.toString();
      sampleToNewList.add(s);
    });

    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // No filtering for "To Be Dispatched" to allow zero-stock books
    _loadSetupValues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sampleToNewList.isEmpty) {
        _refreshSampleToOptions();
      }
    });
  }

  Future<void> _refreshSampleToOptions() async {
    if (!mounted || widget.customerId <= 0) return;
    setState(() {
      isLoadingSampleTo = true;
      sampleToError = null;
    });
    try {
      final authState = ref.read(authProvider);
      final response = await ref.read(dsrEntryProvider.notifier).dsrfetchSamplingDetails(
        request: dsrsampling.dsrSamplingDetailsRequest(
          titleId: null,
          classLevelId: null,
          seriesId: null,
          customerId: widget.customerId,
          requestType: 'visit',
          profileId: AppUtils.getProfileIdStr(),
          customerType: widget.customerType,
          executiveId: AppUtils.getExecutiveStr(),
        ),
        token: authState.token ?? widget.token,
      );
      if (!mounted) return;
      final options = <StateResponse>[];
      for (final contact in response.sampleTo) {
        final item = StateResponse();
        item.value = contact.customerContactId;
        item.label = contact.customerContactId.toString();
        item.text = contact.customerName;
        options.add(item);
      }
      setState(() {
        sampleToNewList = options;
        isLoadingSampleTo = false;
        if (options.isEmpty) {
          sampleToError = 'No Sample To option is configured for this customer';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingSampleTo = false;
        sampleToError = CrmApiClient.messageFrom(error);
      });
    }
  }

  void _loadSetupValues() {
    final authState = ref.read(authProvider);
    final setupValues = authState.setupValues ?? [];

    setState(() {
      int samplingSelfStockMaxQtyAllowed =
          _getSetupInt(setupValues, 'SamplingSelfStockMaxQtyAllowed', 10);
      int samplingCustomerMaxQtyAllowed =
          _getSetupInt(setupValues, 'SamplingCustomerMaxQtyAllowed', 10);
      maxSamplingTitles =
          _getSetupInt(setupValues, 'DSR_MAX_SAMPLING_TITLES', 10);

      switch (widget.contextType) {
        case 'selfStock':
          maxQuantityAllowed = samplingSelfStockMaxQtyAllowed;
          break;
        case 'customer':
          maxQuantityAllowed = samplingCustomerMaxQtyAllowed;
          break;
        case 'dsr':
        default:
          maxQuantityAllowed = samplingCustomerMaxQtyAllowed;
          break;
      }
    });
  }

  int _getSetupInt(List<SetupValue> setupValues, String key, int defaultValue) {
    final value = setupValues
        .firstWhere(
          (setup) => setup.keyName == key,
          orElse: () => SetupValue(
              id: 0,
              keyName: key,
              keyValue: defaultValue.toString(),
              keyStatus: true,
              keyDescription: ''),
        )
        .keyValue;
    return int.tryParse(value) ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: TColors.icon),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sampling Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(color: Colors.black),
                const SizedBox(height: 10),
                CrossButtonWidget(
                  required: '*',
                  field: 'Sample Type',
                  value: selectedSampleType?.text,
                  resourceList: sampleTypeData,
                  onSelected: (data) {
                    selectedSampleType = data;
                    setState(() {});
                  },
                  onRemove: () {
                    selectedSampleType = null;
                    setState(() {});
                  },
                ),
                CrossButtonWidget(
                  required: '*',
                  field: 'Sample Given',
                  value: selectedSampleGiven?.text,
                  resourceList: sampleGivenData,
                  onSelected: (data) {
                    selectedSampleGiven = data;
                    setState(() {});
                  },
                  onRemove: () {
                    selectedSampleGiven = null;
                    setState(() {});
                  },
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      text: "Titles in Series",
                    ),
                    Tab(text: "Titles not in Series"),
                  ],
                  labelColor: TColors.icon,
                  unselectedLabelColor: Colors.grey,
                ),
                ContentSizeTabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        children: [
                          CrossButtonWidget(
                            field: 'Series',
                            value: selectSeries?.text,
                            required: '*',
                            resourceList: seriesData,
                            onSelected: (data) {
                              selectSeries = data;
                              setState(() {});
                            },
                            onRemove: () {
                              selectSeries = null;
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: CrossButtonWidget(
                                  field: 'Class Level',
                                  value: selectedClassLevel?.text,
                                  resourceList: classData,
                                  onSelected: (data) {
                                    selectedClassLevel = data;
                                    setState(() {});
                                  },
                                  onRemove: () {
                                    selectedClassLevel = null;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: ElevatedButton(
                                  onPressed:
                                      isLoadingSampleTo || isLoadingSearch
                                          ? null
                                          : () => _showBookSearchDialog(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TColors.buttonPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: isLoadingSearch
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text("Search",
                                          style:
                                              TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: isbnSearchController,
                              decoration: InputDecoration(
                                labelText: "Search ISBN/Title",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.blue.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: TColors.icon),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isLoadingSampleTo || isLoadingSearch
                                ? null
                                : () => _showBookSearchDialog(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.buttonPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoadingSearch
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Search",
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _widgetForSeries(),
        _widgetForNotSeries(),
      ],
    );
  }

  Future<List<ShipTo>> _fetchShipToList(
      String? sampleTo, String? sampleGiven) async {
    print('object sampleTo $sampleTo $sampleGiven');

    final request = ShipToRequest(
      executiveId: widget.executiveId,
      customerId: widget.customerId,
      customerType: widget.customerType,
      customerContactId: int.tryParse(sampleTo ?? '') ??
          (widget.customerContactId > 0 ? widget.customerContactId : 0),
      sampleGiven: (sampleGiven == null || sampleGiven.trim().isEmpty)
          ? 'TO_BE_DISPATCHED'
          : sampleGiven,
    );

    final response = await ref.read(dsrEntryProvider.notifier).dsrfetchShipTo(
          request: request,
          token: widget.token,
        );

    print('response ${response.dsrshipTo?.length}');

    List<ShipTo> shipToList = [];
    if (response.status == 'Success' &&
        response.dsrshipTo?.isNotEmpty == true) {
      shipToNewList.clear();
      response.dsrshipTo?.forEach((action) {
        var office = action.officeAddress;

        if (!AppUtils.isBlank(office)) {
          StateResponse s = StateResponse();
          s.text = 'Official Address:\n\n$office';
          s.label = office;
          s.section = 'Official Address';
          shipToNewList.add(s);
        }

        var res = action.resAddress;

        if (!AppUtils.isBlank(res)) {
          StateResponse s = StateResponse();
          s.text = 'Residence Address:\n\n: $res';
          s.label = res;
          s.section = 'Residence Address';
          shipToNewList.add(s);
        }
      });
    } else {
      shipToNewList.clear();
      sampleToError = 'No shipping address is available for the selected customer/contact';
    }

    setState(() {});
    return shipToList;
  }

  @override
  void dispose() {
    _tabController.dispose();
    isbnSearchController.dispose();
    super.dispose();
  }

  void _showBookSearchDialog(bool isSeries) {
    if (selectedSampleType == null) {
      AppUtils.showToast('Please select Sample Type');
      return;
    }

    if (selectedSampleGiven == null) {
      AppUtils.showToast('Please select Sample Given');
      return;
    }

    if (isSeries && selectSeries == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a series')),
        );
      });
      return;
    }

    setState(() {
      isLoadingSearch = true;
    });

    if (isSeries) {
      var cId = int.tryParse(selectedClassLevel?.label ?? '0');
      final request = dsrsampling.FetchTitlesRequest(
          executiveId: widget.executiveId,
          seriesId: selectSeries?.label,
          classLevel: cId,
          sampleGiven: selectedSampleGiven?.label);

      ref
          .read(dsrEntryProvider.notifier)
          .fetchTitles(
            request: request,
            token: widget.token,
          )
          .then((response) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            isLoadingSearch = false;
          });
          if (response.status == 'Success' && response.titleList.isNotEmpty) {
            _showTitlesDialog(response.titleList, isSeries);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No titles found for this series')),
            );
          }
        });
      });
    } else {
      final searchText = isbnSearchController.text.trim();
      if (searchText.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            isLoadingSearch = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a search term')),
          );
        });
        return;
      }

      final request = sampling.TitleNotInSeriesRequest(
          executiveId: widget.executiveId,
          titleOrISBN: searchText,
          sampleGiven: selectedSampleGiven?.label);

      ref
          .read(dsrEntryProvider.notifier)
          .fetchTitlesNotInSeries(
            request: request,
            token: widget.token,
          )
          .then((response) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            isLoadingSearch = false;
          });
          if (response.status == 'Success' && response.titleList.isNotEmpty) {
            _showTitlesDialog(response.titleList, isSeries);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No titles found for this ISBN/Title')),
            );
          }
        });
      });
    }
  }

  void _showTitlesDialog(List<dsrsampling.TitleData> titles, bool isSeries) {
    print('widget.selectedSamplingType $selectedClassLevel');
    print('widget.selectedSampleGiven ${selectedSampleGiven?.text}');
    print('widget.selectedSeriesId $selectSeries');
    print('widget.selectedClassLevel ${selectedClassLevel}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => BookSearchDialog(
          contextType: widget.contextType,
          titles: titles,
          sampleGiven: selectedSampleGiven?.label, // Pass sampleGiven to dialog
          onConfirmSelection: (selected) {
            int? titleId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                if (isSeries) {
                  dsrsampling.SamplingModel s = dsrsampling.SamplingModel();
                  bool isMatchSeries = false;
                  var seriesId = selectSeries?.label;
                  for (var action in sampleInSeries) {
                    if (seriesId == action.seriesId) {
                      isMatchSeries = true;
                      s = action;
                    }
                  }

                  print('isMatchSeries ${isMatchSeries}');

                  for (var action in seriesData) {
                    if (action.label.toString() == selectSeries?.label) {
                      s.seriesName = action.text;
                    }
                  }

                  if (!AppUtils.isBlank(selectedSampleType?.label)) {
                    s.samplingType = selectedSampleType?.label;
                  }
                  if (!AppUtils.isBlank(selectedSampleGiven?.label)) {
                    s.sampleGiven = selectedSampleGiven?.label;
                  }
                  if (!AppUtils.isBlank(selectedClassLevel?.label)) {
                    s.classLevelName = selectedClassLevel?.label;
                  }

                  if (isMatchSeries) {
                    s.titles?.addAll(selected);
                    s.titles = mergeTitleDataList(s.titles);
                  } else {
                    print('s.seriesName ${s.seriesName}');

                    s.seriesId = isSeries ? selectSeries?.label : '0';
                    s.sampleTo = 'Select';
                    s.shipTo = 'Select';
                    s.titles = selected;
                    sampleInSeries.add(s);
                  }
                } else {
                  if (selected.isNotEmpty) {
                    titleId = selected[0].bookId;
                  }

                  dsrsampling.SamplingModel s = dsrsampling.SamplingModel();
                  bool isMatchSeries = false;
                  var seriesName = isbnSearchController.text.trim();
                  for (var action in sampleNotInSeries) {
                    if (seriesName == action.seriesName) {
                      isMatchSeries = true;
                      s = action;
                    }
                  }

                  s.seriesName = seriesName;

                  if (!AppUtils.isBlank(selectedSampleType?.label)) {
                    s.samplingType = selectedSampleType?.label;
                  }
                  if (!AppUtils.isBlank(selectedSampleGiven?.label)) {
                    s.sampleGiven = selectedSampleGiven?.label;
                  }
                  if (!AppUtils.isBlank(selectedClassLevel?.label)) {
                    s.classLevelName = selectedClassLevel?.label;
                  }

                  if (isMatchSeries) {
                    s.titles?.addAll(selected);
                    s.titles = mergeTitleDataList(s.titles);
                  } else {
                    s.seriesId = isSeries ? selectSeries?.label : '0';
                    s.sampleTo = 'Select';
                    s.shipTo = 'Select';
                    s.titles = selected;
                    sampleNotInSeries.add(s);
                  }
                }
                _fetchSamplingDetails(isSeries, selectSeries?.label, titleId);
                selectedSampleType = null;
                selectedSampleGiven = null;
                selectSeries = null;
                selectedClassLevel = null;
                isbnSearchController.text = '';
                isbnSearchController.clear();
              });
            });
          },
        ),
      );
    });
  }

  Widget _widgetForSeries() {
    if (sampleInSeries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 15,
          ),
          Text(
            'In Series',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 6,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sampleInSeries.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final sample = sampleInSeries[index];
                var titleList = sample.titles;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sample.seriesName ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 28,
                          ),
                          onPressed: () => {
                            sampleInSeries.remove(sample),
                            setState(() {}),
                          },
                          tooltip: 'Delete Sample',
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.black,
                      height: 1,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    AppUtils.isBlank(sample.samplingType)
                        ? SizedBox()
                        : Text(
                            'Sample Type',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    AppUtils.isBlank(sample.samplingType)
                        ? SizedBox()
                        : Text(
                            sample.samplingType ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    AppUtils.isBlank(sample.sampleGiven)
                        ? SizedBox()
                        : Text(
                            'Sample Given',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    AppUtils.isBlank(sample.sampleGiven)
                        ? SizedBox()
                        : Text(
                            sample.sampleGiven ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                    SizedBox(
                      height: 5,
                    ),
                    ClickButtonWidget(
                      field: 'Sample To',
                      required: '*',
                      value: sample.sampleTo,
                      resourceList: sampleToNewList,
                      onSelected: (data) {
                        sample.shipTo = 'Select';
                        sample.sampleTo = data?.text;
                        sample.sampleToId = data?.value;
                        shipToNewList.clear();
                        setState(() {});
                        _fetchShipToList(
                            data?.value.toString(), sample.sampleGiven);
                      },
                    ),
                    ClickButtonWidget(
                      field: 'Ship To',
                      required: '*',
                      value: sample.shipTo,
                      resourceList: shipToNewList,
                      onSelected: (data) {
                        sample.shipTo = data?.label;
                        sample.shipToLabel = data?.section;
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: titleList?.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final title = titleList?[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 6, top: 6, bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: title?.imageUrl != null &&
                                              title?.imageUrl.isNotEmpty == true
                                          ? NetworkImage(title!.imageUrl)
                                          : const AssetImage(
                                              'assets/books/book.avif'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title?.title ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        "ISBN: ${title?.isbn}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      AppUtils.isBlank(title?.bookType)
                                          ? SizedBox()
                                          : Text(
                                              "Book Type: ${title?.bookType}",
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10, right: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      titleList!.length != 1
                                          ? IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => {
                                                titleList.remove(title),
                                                setState(() {}),
                                              },
                                            )
                                          : SizedBox(
                                              width: 10,
                                            ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                if (title?.quantity != 1) {
                                                  title?.quantity--;
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 34,
                                                height: 34,
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "${title?.quantity}",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Material(
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                var given = sample.sampleGiven;

                                                var maxLimit =
                                                    title!.maxSamplingQty ??
                                                        maxQuantityAllowed;

                                                var physicalStock =
                                                    title!.physicalStock;

                                                var nValue = AppUtils.filterSetup(
                                                        'ExecutiveNegativeStockAllowed')
                                                    ?.keyValue;

                                                bool isSampleAndN = given ==
                                                        'Sample Given' &&
                                                    (nValue?.toLowerCase() ==
                                                        'n');

                                                if (isSampleAndN &&
                                                    title!.quantity >=
                                                        physicalStock) {
                                                  AppUtils.showTop(
                                                      'Cannot increase beyond available stock');
                                                  return;
                                                }

                                                void showLimitExceeded() {
                                                  AppUtils.showTop(
                                                    'Cannot exceed limit of $maxLimit '
                                                    'or max sampling qty of ${title.maxSamplingQty ?? 'unlimited'} '
                                                    'for "${title.title}"',
                                                  );
                                                }

                                                if (title.quantity >=
                                                    maxLimit) {
                                                  showLimitExceeded();
                                                  return;
                                                }
                                                title?.quantity++;
                                                setState(() {});
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 34,
                                                height: 34,
                                                child: Text(
                                                  '+',
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          )
        ],
      );
    }

    return SizedBox();
  }

  Widget _widgetForNotSeries() {
    if (sampleNotInSeries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 15,
          ),
          Text(
            'Not In Series',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 6,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sampleNotInSeries.length,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final sample = sampleNotInSeries[index];
                var titleList = sample.titles;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sample.seriesName ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 28,
                          ),
                          onPressed: () => {
                            sampleNotInSeries.remove(sample),
                            setState(() {}),
                          },
                          tooltip: 'Delete Sample',
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.black,
                      height: 1,
                    ),
                    AppUtils.isBlank(sample.samplingType)
                        ? SizedBox()
                        : Text(
                            'Sample Type',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    AppUtils.isBlank(sample.samplingType)
                        ? SizedBox()
                        : Text(
                            sample.samplingType ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    AppUtils.isBlank(sample.sampleGiven)
                        ? SizedBox()
                        : Text(
                            'Sample Given',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    AppUtils.isBlank(sample.sampleGiven)
                        ? SizedBox()
                        : Text(
                            sample.sampleGiven ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                    SizedBox(
                      height: 5,
                    ),
                    AppUtils.isBlank(sample.classLevelName)
                        ? SizedBox()
                        : Text(
                            'Class Level',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                    AppUtils.isBlank(sample.classLevelName)
                        ? SizedBox()
                        : Text(
                            sample.classLevelName ?? '',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                    ClickButtonWidget(
                      field: 'Sample To',
                      required: '*',
                      value: sample.sampleTo,
                      resourceList: sampleToNewList,
                      onSelected: (data) {
                        sample.sampleTo = data?.text;
                        sample.sampleToId = data?.value;
                        sample.shipTo = 'Select';
                        shipToNewList.clear();
                        setState(() {});
                        _fetchShipToList(
                            data?.value.toString(), sample.sampleGiven);
                      },
                    ),
                    ClickButtonWidget(
                      field: 'Ship To',
                      required: '*',
                      value: sample.shipTo,
                      resourceList: shipToNewList,
                      onSelected: (data) {
                        sample.shipTo = data?.label;
                        sample.shipToLabel = data?.section;
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: titleList?.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final title = titleList?[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 6, top: 6, bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: title?.imageUrl != null &&
                                              title?.imageUrl.isNotEmpty == true
                                          ? NetworkImage(title!.imageUrl)
                                          : const AssetImage(
                                              'assets/books/book.avif'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title?.title ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        "ISBN: ${title?.isbn}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      AppUtils.isBlank(title?.bookType)
                                          ? SizedBox()
                                          : Text(
                                              "Book Type: ${title?.bookType}",
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10, right: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      titleList!.length != 1
                                          ? IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () => {
                                                titleList.remove(title),
                                                setState(() {}),
                                              },
                                            )
                                          : SizedBox(
                                              width: 10,
                                            ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                if (title?.quantity != 1) {
                                                  title?.quantity--;
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 34,
                                                height: 34,
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "${title?.quantity}",
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Material(
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                title?.quantity++;
                                                setState(() {});
                                              },
                                              child: Container(
                                                alignment: Alignment.center,
                                                width: 34,
                                                height: 34,
                                                child: Text(
                                                  '+',
                                                  style: TextStyle(
                                                      fontSize: 26,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          )
        ],
      );
    }

    return SizedBox();
  }

  List<dsrsampling.TitleData> mergeTitleDataList(
      List<dsrsampling.TitleData>? inputList) {
    final Map<int, dsrsampling.TitleData> mergedMap = {};

    for (var item in inputList!) {
      if (mergedMap.containsKey(item.bookId)) {
        final existing = mergedMap[item.bookId]!;
        mergedMap[item.bookId] = existing.copyWith(
          quantity: existing.quantity + item.quantity,
        );
      } else {
        mergedMap[item.bookId] = item;
      }
    }

    return mergedMap.values.toList();
  }

  Future<void> _fetchSamplingDetails(
      bool isSeries, String? seriesID, int? titleId) async {
    final authState = ref.read(authProvider);
    String? series;

    final token = authState.token ?? '';

    if (isSeries) {
      series = seriesID;
    } else {}
    final request = dsrsampling.dsrSamplingDetailsRequest(
      titleId: titleId,
      classLevelId: null,
      seriesId: series,
      customerId: widget.customerId,
      requestType: 'visit',
      profileId: AppUtils.getProfileIdStr(),
      customerType: widget.customerType,
      executiveId: AppUtils.getExecutiveStr(),
    );

    final response =
        await ref.read(dsrEntryProvider.notifier).dsrfetchSamplingDetails(
              request: request,
              token: token,
            );
    if (response.status == "Success") {
      sampleToNewList.clear();
      response.sampleTo.forEach((action) {
        StateResponse s = StateResponse();
        s.value = action.customerContactId;
        s.label = action.customerContactId.toString();
        s.text = action.customerName;
        sampleToNewList.add(s);
      });

      setState(() {});
    }
  }
}
