import 'dart:ui';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
    as dsrsampling;
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/dsr_entry_provider.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/widgets/add_more_book_popup.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/widgets/book_search_popup.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/widgets/sampling_detail_container.dart';
import 'package:dart_crm/screens/samplingScreen/request_screen/customer_sampling_screen/widgets/save_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SamplingDoneWidget extends ConsumerStatefulWidget {
  final bool samplingDone;
  final dsrsampling.dsrSamplingDetailsResponse? samplingResponse;
  final dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;
  final List<dsrsampling.TitleData> selectedTitles;
  final String? selectedSamplingType;
  final int? selectedClassLevel;
  final String? selectedSeriesId;
  final List<dsrsampling.Series> seriesList;
  final bool isLoadingSeries;
  final int customerId;
  final String customerType;
  final int customerContactId;
  final int executiveId;
  final String token;
  final VoidCallback onFetchSamplingDetails;
  final Function(String?) onSamplingTypeChanged;
  final Function(int?) onClassLevelChanged;
  final Function(String?) onSeriesChanged;
  final Function(List<dsrsampling.TitleData>) onTitlesSelected;
  final List<String> samplingTypeOptions;
  final String contextType;
  final Function(int) onRemoveGroup;
  final Function(int, String?, String?, String?, List<dsrsampling.TitleData>,
      List<ShipTo>) onContainerDetailsChanged;

  const SamplingDoneWidget({
    super.key,
    required this.samplingDone,
    required this.samplingResponse,
    required this.classLevelResponse,
    required this.selectedTitles,
    required this.selectedSamplingType,
    required this.selectedClassLevel,
    required this.selectedSeriesId,
    required this.seriesList,
    required this.isLoadingSeries,
    required this.customerId,
    required this.customerType,
    required this.customerContactId,
    required this.executiveId,
    required this.token,
    required this.onFetchSamplingDetails,
    required this.onSamplingTypeChanged,
    required this.onClassLevelChanged,
    required this.onSeriesChanged,
    required this.onTitlesSelected,
    required this.samplingTypeOptions,
    required this.contextType,
    required this.onContainerDetailsChanged,
    required this.onRemoveGroup,
  });

  @override
  ConsumerState<SamplingDoneWidget> createState() => _SamplingDoneWidgetState();
}

class _SamplingDoneWidgetState extends ConsumerState<SamplingDoneWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final TextEditingController isbnSearchController = TextEditingController();
  List<List<dsrsampling.TitleData>> selectedTitleGroups = [];
  List<Map<String, dynamic>> containerDetails = [];
  List<sampling.SamplingContact> sampleToList = [];
  bool isLoadingSampleTo = false;
  bool isLoadingSearch = false;
  String? sampleToError;
  int? seriesClassLevel;
  List<dsrsampling.TitleData> _activeTitles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    seriesClassLevel = widget.selectedClassLevel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSampleToList();
    });
  }

  Future<void> _fetchSampleToList() async {
    setState(() {
      isLoadingSampleTo = true;
      sampleToError = null;
    });

    try {
      if (widget.token.isEmpty) {
        throw Exception('Token is null or empty');
      }
      if (widget.customerId == 0) {
        throw Exception('CustomerId is invalid: ${widget.customerId}');
      }
      if (widget.customerType.isEmpty) {
        throw Exception('CustomerType is null or empty');
      }
      if (widget.executiveId == 0) {
        throw Exception('ExecutiveId is invalid: ${widget.executiveId}');
      }
      final authState = ref.read(authProvider);
      final response =
          await ref.read(dsrEntryProvider.notifier).fetchSamplingDetails(
                request: sampling.SamplingDetailsRequest(
                  customerId: widget.customerId,
                  requestType: 'SampleTo',
                  profileId: authState
                          .loginResponse!.executiveBasicData?[0].profileId ??
                      5,
                  customerType: widget.customerType,
                  executiveId: widget.executiveId,
                  titleId: null,
                  seriesId: widget.selectedSeriesId,
                  classLevelId: widget.selectedClassLevel,
                ),
                token: widget.token,
              );

      setState(() {
        isLoadingSampleTo = false;
        if (response.status == 'Success' &&
            response.sampleTo?.isNotEmpty == true) {
          final uniqueContacts = <String, sampling.SamplingContact>{};
          for (var contact in response.sampleTo!) {
            uniqueContacts[contact.customerContactId.toString()] = contact;
          }
          sampleToList = uniqueContacts.values.toList();
        } else {
          sampleToList = const [];
          sampleToError = 'No Sample To option is available for this customer';
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchSampleToList: $e\nStackTrace: $stackTrace');
      setState(() {
        isLoadingSampleTo = false;
        sampleToError = 'Error fetching sample to options: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sampleToError!)),
      );
    }
  }

  @override
  void didUpdateWidget(covariant SamplingDoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId ||
        oldWidget.customerType != widget.customerType ||
        oldWidget.executiveId != widget.executiveId ||
        oldWidget.selectedSeriesId != widget.selectedSeriesId ||
        oldWidget.selectedClassLevel != widget.selectedClassLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSampleToList();
        setState(() {
          _activeTitles.clear();
        });
        final allTitles = selectedTitleGroups.expand((group) => group).toList();
        widget.onTitlesSelected(allTitles);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    isbnSearchController.dispose();
    super.dispose();
  }

  void _handleSearchPressed(bool isSeries) {
    if (isSeries) {
      _showBookSearchDialog(null, widget.selectedSeriesId, seriesClassLevel);
    } else {
      _showBookSearchDialog(null, null, null);
    }
  }

  void _showBookSearchDialog(
      int? groupIndex, String? seriesId, int? classLevelId) {
    if (isLoadingSampleTo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, loading sample to options')),
      );
      return;
    }

    if (sampleToList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sample to options available')),
      );
      return;
    }

    if (widget.selectedSamplingType == null) {
      AppUtils.showToast('Please select Sampling Type');
      return;
    }

    bool isSeriesSearch = seriesId != null && seriesId != '0';

    setState(() {
      isLoadingSearch = true;
    });

    if (isSeriesSearch) {
      final request = dsrsampling.FetchTitlesRequest(
        executiveId: widget.executiveId,
        seriesId: seriesId,
        classLevel: classLevelId ?? seriesClassLevel,
      );

      ref
          .read(dsrEntryProvider.notifier)
          .fetchTitles(request: request, token: widget.token)
          .then((response) {
        setState(() {
          isLoadingSearch = false;
        });
        if (response.status == 'Success' && response.titleList.isNotEmpty) {
          if (groupIndex == null) {
            // Main search - use SearchBookDialog
            showDialog(
              context: context,
              builder: (context) => SearchBookDialog(
                contextType: widget.contextType,
                titles: response.titleList,
                onConfirmSelection: (selected) {
                  setState(() {
                    _activeTitles = List.from(selected);
                    if (_activeTitles.isNotEmpty) {
                      final newGroupIndex = selectedTitleGroups.length;
                      final uniqueTitles = <String, dsrsampling.TitleData>{};
                      for (var title in _activeTitles) {
                        final bookId = title.bookId.toString();
                        if (uniqueTitles.containsKey(bookId)) {
                          uniqueTitles[bookId] = dsrsampling.TitleData(
                            bookId: title.bookId,
                            title: title.title,
                            quantity:
                                uniqueTitles[bookId]!.quantity + title.quantity,
                            isbn: title.isbn,
                            price: title.price,
                            listPrice: title.listPrice,
                            bookNum: title.bookNum,
                            image: title.image,
                            physicalStock: title.physicalStock,
                            author: title.author,
                            imageUrl: title.imageUrl,
                            bookType: title.bookType,
                            seriesId: title.seriesId,
                            subjectId: title.subjectId,
                            seriesName: title.seriesName,
                          );
                        } else {
                          uniqueTitles[bookId] = title;
                        }
                      }
                      selectedTitleGroups.add(uniqueTitles.values.toList());
                      containerDetails.add({
                        'sampleTo': null,
                        'shipTo': null,
                        'shipToList': <ShipTo>[],
                        'isLoadingShipTo': false,
                        'seriesId': _activeTitles.isNotEmpty &&
                                _activeTitles[0].seriesId != null
                            ? _activeTitles[0].seriesId.toString()
                            : '0',
                        'classLevelId': seriesClassLevel,
                        'samplingType': widget.selectedSamplingType,
                      });
                      widget.onContainerDetailsChanged(
                        newGroupIndex,
                        null,
                        null,
                        widget.selectedSamplingType,
                        selectedTitleGroups[newGroupIndex],
                        <ShipTo>[],
                      );
                    }
                    _activeTitles = [];
                  });
                  final allTitles =
                      selectedTitleGroups.expand((group) => group).toList();
                  widget.onTitlesSelected(allTitles);
                },
              ),
            );
          } else {
            // Add More - use AddMoreBookDialog
            showDialog(
              context: context,
              builder: (context) => AddMoreBookDialog(
                contextType: widget.contextType,
                titles: response.titleList,
                selectedTitles: selectedTitleGroups[groupIndex],
                groupIndex: groupIndex,
                onConfirmSelection: (selected, removedBookIds) {
                  setState(() {
                    final currentTitles = selectedTitleGroups[groupIndex];
                    var updatedTitles =
                        List<dsrsampling.TitleData>.from(currentTitles);

                    // Remove titles set to 0 in dialog
                    for (var bookId in removedBookIds) {
                      final existingIndex =
                          updatedTitles.indexWhere((t) => t.bookId == bookId);
                      if (existingIndex != -1) {
                        updatedTitles.removeAt(existingIndex);
                      }
                    }

                    // Update or add titles with >0 quantity
                    for (var newTitle in selected) {
                      final existingIndex = updatedTitles
                          .indexWhere((t) => t.bookId == newTitle.bookId);
                      if (existingIndex != -1) {
                        updatedTitles[existingIndex] = dsrsampling.TitleData(
                          bookId: updatedTitles[existingIndex].bookId,
                          title: updatedTitles[existingIndex].title,
                          quantity: newTitle
                              .quantity, // Set to the absolute quantity from dialog
                          isbn: updatedTitles[existingIndex].isbn,
                          price: updatedTitles[existingIndex].price,
                          listPrice: updatedTitles[existingIndex].listPrice,
                          bookNum: updatedTitles[existingIndex].bookNum,
                          image: updatedTitles[existingIndex].image,
                          physicalStock:
                              updatedTitles[existingIndex].physicalStock,
                          author: updatedTitles[existingIndex].author,
                          imageUrl: updatedTitles[existingIndex].imageUrl,
                          bookType: updatedTitles[existingIndex].bookType,
                          seriesId: updatedTitles[existingIndex].seriesId,
                          subjectId: updatedTitles[existingIndex].subjectId,
                          seriesName: updatedTitles[existingIndex].seriesName,
                        );
                      } else {
                        updatedTitles.add(newTitle);
                      }
                    }

                    selectedTitleGroups[groupIndex] = updatedTitles;

                    // If the group is now empty, remove the container
                    if (updatedTitles.isEmpty) {
                      _onRemoveContainer(groupIndex);
                    } else {
                      widget.onContainerDetailsChanged(
                        groupIndex,
                        containerDetails[groupIndex]['sampleTo'],
                        containerDetails[groupIndex]['shipTo'],
                        containerDetails[groupIndex]['samplingType'],
                        selectedTitleGroups[groupIndex],
                        List<ShipTo>.from(
                            containerDetails[groupIndex]['shipToList']),
                      );
                    }

                    final allTitles =
                        selectedTitleGroups.expand((group) => group).toList();
                    widget.onTitlesSelected(allTitles);
                  });
                },
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No titles found for this series')),
          );
        }
      });
    } else {
      final searchText = isbnSearchController.text.trim();
      if (searchText.isEmpty) {
        setState(() {
          isLoadingSearch = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a search term')),
        );
        return;
      }

      final request = sampling.TitleNotInSeriesRequest(
        executiveId: widget.executiveId,
        titleOrISBN: searchText,
      );

      ref
          .read(dsrEntryProvider.notifier)
          .fetchTitlesNotInSeries(request: request, token: widget.token)
          .then((response) {
        setState(() {
          isLoadingSearch = false;
        });
        if (response.status == 'Success' && response.titleList.isNotEmpty) {
          if (groupIndex == null) {
            // Main search for non-series
            showDialog(
              context: context,
              builder: (context) => SearchBookDialog(
                contextType: widget.contextType,
                titles: response.titleList,
                onConfirmSelection: (selected) {
                  setState(() {
                    _activeTitles = List.from(selected);
                    if (_activeTitles.isNotEmpty) {
                      final newGroupIndex = selectedTitleGroups.length;
                      final uniqueTitles = <String, dsrsampling.TitleData>{};
                      for (var title in _activeTitles) {
                        final bookId = title.bookId.toString();
                        if (uniqueTitles.containsKey(bookId)) {
                          uniqueTitles[bookId] = dsrsampling.TitleData(
                            bookId: title.bookId,
                            title: title.title,
                            quantity:
                                uniqueTitles[bookId]!.quantity + title.quantity,
                            isbn: title.isbn,
                            price: title.price,
                            listPrice: title.listPrice,
                            bookNum: title.bookNum,
                            image: title.image,
                            physicalStock: title.physicalStock,
                            author: title.author,
                            imageUrl: title.imageUrl,
                            bookType: title.bookType,
                            seriesId: title.seriesId,
                            subjectId: title.subjectId,
                            seriesName: title.seriesName,
                          );
                        } else {
                          uniqueTitles[bookId] = title;
                        }
                      }
                      selectedTitleGroups.add(uniqueTitles.values.toList());
                      containerDetails.add({
                        'sampleTo': null,
                        'shipTo': null,
                        'shipToList': <ShipTo>[],
                        'isLoadingShipTo': false,
                        'seriesId': _activeTitles.isNotEmpty &&
                                _activeTitles[0].seriesId != null
                            ? _activeTitles[0].seriesId.toString()
                            : '0',
                        'classLevelId': seriesClassLevel,
                        'samplingType': widget.selectedSamplingType,
                      });
                      widget.onContainerDetailsChanged(
                        newGroupIndex,
                        null,
                        null,
                        widget.selectedSamplingType,
                        selectedTitleGroups[newGroupIndex],
                        <ShipTo>[],
                      );
                    }
                    _activeTitles = [];
                  });
                  final allTitles =
                      selectedTitleGroups.expand((group) => group).toList();
                  widget.onTitlesSelected(allTitles);
                },
              ),
            );
          } else {
            // Add More for non-series
            showDialog(
              context: context,
              builder: (context) => AddMoreBookDialog(
                contextType: widget.contextType,
                titles: response.titleList,
                selectedTitles: selectedTitleGroups[groupIndex],
                groupIndex: groupIndex,
                onConfirmSelection: (selected, removedBookIds) {
                  setState(() {
                    final currentTitles = selectedTitleGroups[groupIndex];
                    var updatedTitles =
                        List<dsrsampling.TitleData>.from(currentTitles);

                    // Remove titles set to 0 in dialog
                    for (var bookId in removedBookIds) {
                      final existingIndex =
                          updatedTitles.indexWhere((t) => t.bookId == bookId);
                      if (existingIndex != -1) {
                        updatedTitles.removeAt(existingIndex);
                      }
                    }

                    // Update or add titles with >0 quantity
                    for (var newTitle in selected) {
                      final existingIndex = updatedTitles
                          .indexWhere((t) => t.bookId == newTitle.bookId);
                      if (existingIndex != -1) {
                        updatedTitles[existingIndex] = dsrsampling.TitleData(
                          bookId: updatedTitles[existingIndex].bookId,
                          title: updatedTitles[existingIndex].title,
                          quantity: newTitle
                              .quantity, // Set to the absolute quantity from dialog
                          isbn: updatedTitles[existingIndex].isbn,
                          price: updatedTitles[existingIndex].price,
                          listPrice: updatedTitles[existingIndex].listPrice,
                          bookNum: updatedTitles[existingIndex].bookNum,
                          image: updatedTitles[existingIndex].image,
                          physicalStock:
                              updatedTitles[existingIndex].physicalStock,
                          author: updatedTitles[existingIndex].author,
                          imageUrl: updatedTitles[existingIndex].imageUrl,
                          bookType: updatedTitles[existingIndex].bookType,
                          seriesId: updatedTitles[existingIndex].seriesId,
                          subjectId: updatedTitles[existingIndex].subjectId,
                          seriesName: updatedTitles[existingIndex].seriesName,
                        );
                      } else {
                        updatedTitles.add(newTitle);
                      }
                    }

                    selectedTitleGroups[groupIndex] = updatedTitles;

                    // If the group is now empty, remove the container
                    if (updatedTitles.isEmpty) {
                      _onRemoveContainer(groupIndex);
                    } else {
                      widget.onContainerDetailsChanged(
                        groupIndex,
                        containerDetails[groupIndex]['sampleTo'],
                        containerDetails[groupIndex]['shipTo'],
                        containerDetails[groupIndex]['samplingType'],
                        selectedTitleGroups[groupIndex],
                        List<ShipTo>.from(
                            containerDetails[groupIndex]['shipToList']),
                      );
                    }

                    final allTitles =
                        selectedTitleGroups.expand((group) => group).toList();
                    widget.onTitlesSelected(allTitles);
                  });
                },
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No titles found for this ISBN/Title')),
          );
        }
      });
    }
  }

  void _onSeriesChanged(String? seriesId) {
    setState(() {
      seriesClassLevel = null;
      _activeTitles.clear();
    });
    widget.onSeriesChanged(seriesId);
    widget.onClassLevelChanged(null);
  }

  void _onClassLevelChanged(int? classLevel) {
    setState(() {
      seriesClassLevel = classLevel;
    });
    widget.onClassLevelChanged(classLevel);
  }

  void _onRemoveContainer(int groupIndex) {
    setState(() {
      if (groupIndex < selectedTitleGroups.length &&
          groupIndex < containerDetails.length) {
        selectedTitleGroups.removeAt(groupIndex);
        containerDetails.removeAt(groupIndex);
        final allTitles = selectedTitleGroups.expand((group) => group).toList();
        widget.onTitlesSelected(allTitles);
        widget.onRemoveGroup(groupIndex);
        for (var i = 0; i < selectedTitleGroups.length; i++) {
          widget.onContainerDetailsChanged(
            i,
            containerDetails[i]['sampleTo'],
            containerDetails[i]['shipTo'],
            containerDetails[i]['samplingType'],
            selectedTitleGroups[i],
            List<ShipTo>.from(containerDetails[i]['shipToList']),
          );
        }
        print(
            'Child after removal: containerDetails length=${containerDetails.length}, selectedTitleGroups length=${selectedTitleGroups.length}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.samplingDone || widget.samplingResponse == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SamplingDetailsContainer(
          samplingResponse: widget.samplingResponse!,
          localSelectedSamplingType: widget.selectedSamplingType,
          onSamplingTypeChanged: widget.onSamplingTypeChanged,
          tabController: _tabController,
          seriesList: widget.seriesList,
          isLoadingSeries: widget.isLoadingSeries,
          selectedSeriesId: widget.selectedSeriesId,
          onSeriesChanged: _onSeriesChanged,
          classLevelResponse: widget.classLevelResponse,
          seriesClassLevel: seriesClassLevel,
          onClassLevelChanged: _onClassLevelChanged,
          isLoadingSampleTo: isLoadingSampleTo,
          isLoadingSearch: isLoadingSearch,
          onSearchPressed: _handleSearchPressed,
          isbnSearchController: isbnSearchController,
        ),
        SavedContainersWidget(
          selectedTitleGroups: selectedTitleGroups,
          containerDetails: containerDetails,
          sampleToList: sampleToList,
          seriesList: widget.seriesList,
          samplingTypeOptions: widget.samplingTypeOptions,
          onRemoveContainer: _onRemoveContainer,
          onContainerDetailsChanged: widget.onContainerDetailsChanged,
          onTitlesSelected: widget.onTitlesSelected,
          token: widget.token,
          customerId: widget.customerId,
          customerType: widget.customerType,
          executiveId: widget.executiveId,
          customerContactId: widget.customerContactId,
          formKey: _formKey,
          onSearchPressed: _showBookSearchDialog,
        ),
      ],
    );
  }
}
