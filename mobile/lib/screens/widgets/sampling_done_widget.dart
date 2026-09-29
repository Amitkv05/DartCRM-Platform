// import 'package:dart_crm/edit/utils/AppUtils.dart';
// import 'package:dart_crm/models/planList/dsr_sampling_details.dart' as dsrsampling;
// import 'package:dart_crm/models/ship_to.dart';
// import 'package:dart_crm/providers/dsr_entry_provider.dart';
// import 'package:dart_crm/screens/Visit_DSR/DSR_entry/widget/book_search_popup.dart';
// import 'package:dart_crm/util/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../edit/model/schoolUpdate/StateResponse.dart';
// import '../../edit/utils/click_button_widget.dart';
// class SamplingDoneWidget extends ConsumerStatefulWidget {
//   final bool samplingDone;
//   final dsrsampling.dsrSamplingDetailsResponse? samplingResponse;
//   final dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;
//   final List<dsrsampling.TitleData> selectedTitles;
//   final String? selectedSamplingType;
//   final String? selectedSampleGiven;
//   final int? selectedClassLevel;
//   final String? selectedSeriesId;
//   final List<dsrsampling.Series> seriesList;
//   final bool isLoadingSeries;
//   final int customerId;
//   final String customerType;
//   final int customerContactId;
//   final int executiveId;
//   final String token;
//   final Function(String?) onSamplingTypeChanged;
//   final Function(String?) onSampleGivenChanged;
//   final Function(int?) onClassLevelChanged;
//   final Function(String?) onSeriesChanged;
//   final Function() onTitlesSelected;
//   final List<String> samplingTypeOptions;
//   final List<String> sampleGivenOptions;
//   final String contextType;
//   final Function(int, String?, String?, List<dsrsampling.TitleData>)
//       onContainerDetailsChanged;

//   const SamplingDoneWidget({
//     super.key,
//     required this.samplingDone,
//     required this.samplingResponse,
//     required this.classLevelResponse,
//     required this.selectedTitles,
//     required this.selectedSamplingType,
//     required this.selectedSampleGiven,
//     // required this.selectedSampleGiven,
//     required this.selectedClassLevel,
//     required this.selectedSeriesId,
//     required this.seriesList,
//     required this.isLoadingSeries,
//     required this.customerId,
//     required this.customerType,
//     required this.customerContactId,
//     required this.executiveId,
//     required this.token,
//     required this.onSamplingTypeChanged,
//     required this.onSampleGivenChanged,
//     required this.onClassLevelChanged,
//     required this.onSeriesChanged,
//     required this.onTitlesSelected,
//     required this.samplingTypeOptions,
//     required this.sampleGivenOptions,
//     required this.contextType,
//     required this.onContainerDetailsChanged,
//   });

//   @override
//   ConsumerState<SamplingDoneWidget> createState() => _SamplingDoneWidgetState();
// }

// class _SamplingDoneWidgetState extends ConsumerState<SamplingDoneWidget>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController isbnSearchController = TextEditingController();

//   bool isLoadingSampleTo = false;
//   bool isLoadingSearch = false;
//   String? sampleToError;
//   int? seriesClassLevel;

//   String? _localSelectedSamplingType;
//   List<StateResponse> sampleToNewList = [];
//   List<StateResponse> shipToNewList = [];

//   @override
//   void initState() {
//     widget.samplingResponse?.sampleTo.forEach((action) {
//       StateResponse s = StateResponse();
//       s.value = action.customerContactId;
//       s.text = action.customerName;
//       sampleToNewList.add(s);
//     });

//     super.initState();
//     _localSelectedSamplingType = null;
//     _tabController = TabController(length: 2, vsync: this);
//     seriesClassLevel = widget.selectedClassLevel;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.samplingDone || widget.samplingResponse == null) {
//       return const SizedBox.shrink();
//     }

//     final uniqueSampleGiven = <String, dsrsampling.SampleGiven>{};
//     for (var sample in widget.samplingResponse!.sampleGiven) {
//       uniqueSampleGiven[sample.sampleGiven] = sample;
//     }
//     final sampleGivenList = uniqueSampleGiven.values.toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 10),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: Container(
//             padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               border: Border.all(color: TColors.icon),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Sampling Details",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const Divider(color: Colors.black),
//                 const SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   value: _localSelectedSamplingType,
//                   decoration: InputDecoration(
//                     labelText: "Sampling Type",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                   ),
//                   isExpanded: true,
//                   items: [
//                     const DropdownMenuItem<String>(
//                       value: null,
//                       child: Text('Select'),
//                     ),
//                     ...widget.samplingResponse!.samplingType.map((type) {
//                       return DropdownMenuItem<String>(
//                         value: type.samplingType,
//                         child: Text(type.samplingType),
//                       );
//                     }),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       _localSelectedSamplingType = value;
//                     });
//                     widget.onSamplingTypeChanged(value);
//                   },
//                   validator: (value) =>
//                       value == null ? 'Please select a sampling type' : null,
//                 ),
//                 const SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   value: sampleGivenList.any(
//                           (sample) => sample.sampleGiven == widget.selectedSampleGiven)
//                       ? widget.selectedSampleGiven
//                       : null,
//                   decoration: InputDecoration(
//                     labelText: "Sample Given",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide(color: TColors.icon),
//                     ),
//                     errorText: sampleGivenList.isEmpty
//                         ? 'No sample given options available'
//                         : null,
//                   ),
//                   isExpanded: true,
//                   items: [
//                     const DropdownMenuItem<String>(
//                       value: null,
//                       child: Text('Select'),
//                     ),
//                     ...sampleGivenList.map((sample) {
//                       return DropdownMenuItem<String>(
//                         value: sample.sampleGiven,
//                         child: Text(sample.sampleGiven),
//                       );
//                     }),
//                   ],
//                   onChanged: (value) {
//                     setState(() {});
//                     widget.onSampleGivenChanged(value);
//                   },
//                   validator: (value) =>
//                       value == null ? 'Please select a sample given option' : null,
//                 ),
//                 const SizedBox(height: 10),
//                 TabBar(
//                   controller: _tabController,
//                   tabs: const [
//                     Tab(
//                       text: "Titles in Series",
//                     ),
//                     Tab(text: "Titles not in Series"),
//                   ],
//                   labelColor: TColors.icon,
//                   unselectedLabelColor: Colors.grey,
//                 ),
//                 SizedBox(
//                   height: 150,
//                   child: TabBarView(
//                     controller: _tabController,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(top: 15),
//                         child: Column(
//                           children: [
//                             DropdownButtonFormField<String>(
//                               value: widget.selectedSeriesId,
//                               decoration: InputDecoration(
//                                 labelText: "Select Series",
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide(color: Colors.blue.shade200),
//                                 ),
//                                 enabledBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide(color: Colors.blue.shade200),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                   borderSide: BorderSide(color: TColors.icon),
//                                 ),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 16, vertical: 14),
//                               ),
//                               isExpanded: true,
//                               items: [
//                                 const DropdownMenuItem<String>(
//                                   value: null,
//                                   child: Text("Select"),
//                                 ),
//                                 ...widget.seriesList.map((series) {
//                                   return DropdownMenuItem<String>(
//                                     value: series.seriesId.toString(),
//                                     child: Text(
//                                       "${series.seriesName}",
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   );
//                                 }).toList(),
//                               ],
//                               onChanged: widget.onSeriesChanged,
//                               hint: widget.isLoadingSeries
//                                   ? const Text("Loading series...")
//                                   : widget.seriesList.isEmpty
//                                       ? const Text("No series available")
//                                       : const Text("Select a series"),
//                             ),
//                             const SizedBox(height: 10),
//                             if (widget.classLevelResponse != null)
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: DropdownButtonFormField<int>(
//                                       value: seriesClassLevel,
//                                       decoration: InputDecoration(
//                                         labelText: "Class Level",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: BorderSide(color: TColors.icon),
//                                         ),
//                                         enabledBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: BorderSide(color: TColors.icon),
//                                         ),
//                                         focusedBorder: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(12),
//                                           borderSide: BorderSide(color: TColors.icon),
//                                         ),
//                                       ),
//                                       items: [
//                                         const DropdownMenuItem<int>(
//                                           value: null,
//                                           child: Text("Select"),
//                                         ),
//                                         ...widget.classLevelResponse!.classLevelList
//                                             .map((level) {
//                                           return DropdownMenuItem<int>(
//                                             value: level.classLevelId,
//                                             child: Text(level.classLevelName),
//                                           );
//                                         }).toList(),
//                                       ],
//                                       onChanged: (value) {
//                                         setState(() {
//                                           seriesClassLevel = value;
//                                         });
//                                         widget.onClassLevelChanged(value);
//                                       },
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   ElevatedButton(
//                                     onPressed: isLoadingSampleTo || isLoadingSearch
//                                         ? null
//                                         : () => _showBookSearchDialog(true),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: TColors.buttonPrimary,
//                                       shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(12)),
//                                     ),
//                                     child: isLoadingSearch
//                                         ? const SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               color: Colors.white,
//                                               strokeWidth: 2,
//                                             ),
//                                           )
//                                         : const Text("Search",
//                                             style: TextStyle(color: Colors.white)),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: isbnSearchController,
//                                 decoration: InputDecoration(
//                                   labelText: "Search ISBN/Title",
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(color: Colors.blue.shade200),
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(color: Colors.blue.shade200),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                     borderSide: BorderSide(color: TColors.icon),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             ElevatedButton(
//                               onPressed: isLoadingSampleTo || isLoadingSearch
//                                   ? null
//                                   : () => _showBookSearchDialog(false),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: TColors.icon,
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12)),
//                               ),
//                               child: isLoadingSearch
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     )
//                                   : const Text("Search",
//                                       style: TextStyle(color: Colors.white)),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         _widgetForSeries(),
//         _widgetForNotSeries(),
//       ],
//     );
//   }

//   Future<List<ShipTo>> _fetchShipToList(String? sampleTo) async {
//     if (sampleTo == null) {
//       return [];
//     }

//     final sampleGiven = widget.selectedSampleGiven ??
//         (widget.samplingResponse?.sampleGiven.isNotEmpty == true
//             ? widget.samplingResponse!.sampleGiven.first.sampleGiven
//             : null);

//     final request = ShipToRequest(
//       executiveId: widget.executiveId,
//       customerId: widget.customerId,
//       customerType: widget.customerType,
//       customerContactId: int.tryParse(sampleTo) ?? widget.customerContactId,
//       sampleGiven: sampleGiven,
//     );

//     final response = await ref.read(dsrEntryProvider.notifier).fetchShipTo(
//           request: request,
//           token: widget.token,
//         );

//     print('response ${response.shipTo?.length}');

//     List<ShipTo> shipToList = [];
//     if (response.status == 'Success' && response.shipTo?.isNotEmpty == true) {
//       shipToNewList.clear();
//       response.shipTo?.forEach((action) {
//         var office = action.officeAddress;

//         if (!AppUtils.isBlank(office)) {
//           StateResponse s = StateResponse();
//           s.text = 'Official Address:\n\n$office';
//           s.label = office;
//           s.section = 'Official Address';
//           shipToNewList.add(s);
//         }

//         var res = action.resAddress;

//         if (!AppUtils.isBlank(res)) {
//           StateResponse s = StateResponse();
//           s.text = 'Residence Address:\n\n: $res';
//           s.label = res;
//           s.section = 'Residence Address';
//           shipToNewList.add(s);
//         }
//       });
//     } else {
//       StateResponse s = StateResponse();
//       s.text = 'Official Address';
//       s.label = 'Official Address';
//       shipToNewList.add(s);
//     }

//     setState(() {});
//     return shipToList;
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     isbnSearchController.dispose();
//     super.dispose();
//   }

//   void _showBookSearchDialog(bool isSeries) {
//     if (isSeries && widget.selectedSeriesId == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select a series')),
//         );
//       });
//       return;
//     }

//     setState(() {
//       isLoadingSearch = true;
//     });

//     if (isSeries) {
//       final request = dsrsampling.FetchTitlesRequest(
//         executiveId: widget.executiveId,
//         seriesId: widget.selectedSeriesId,
//         classLevel: seriesClassLevel,
//         // Pass sampleGiven to filter titles based on stock for "To Be Dispatched"
//         sampleGiven: widget.selectedSampleGiven,
//       );

//       ref
//           .read(dsrEntryProvider.notifier)
//           .fetchTitles(
//             request: request,
//             token: widget.token,
//           )
//           .then((response) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           setState(() {
//             isLoadingSearch = false;
//           });
//           if (response.status == 'Success' && response.titleList.isNotEmpty) {
//             _showTitlesDialog(response.titleList, isSeries);
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('No titles found for this series')),
//             );
//           }
//         });
//       });
//     } else {
//       final searchText = isbnSearchController.text.trim();
//       if (searchText.isEmpty) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           setState(() {
//             isLoadingSearch = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Please enter a search term')),
//           );
//         });
//         return;
//       }

//       final request = dsrsampling.TitleNotInSeriesRequest(
//         executiveId: widget.executiveId,
//         titleOrISBN: searchText,
//         // Pass sampleGiven to filter titles based on stock for "To Be Dispatched"
//         sampleGiven: widget.selectedSampleGiven,
//       );

//       ref
//           .read(dsrEntryProvider.notifier)
//           .dsrfetchTitlesNotInSeries(
//             request: request,
//             token: widget.token,
//           )
//           .then((response) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           setState(() {
//             isLoadingSearch = false;
//           });
//           if (response.status == 'Success' && response.titleList.isNotEmpty) {
//             _showTitlesDialog(response.titleList, isSeries);
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('No titles found for this ISBN/Title')),
//             );
//           }
//         });
//       });
//     }
//   }

//   void _showTitlesDialog(List<dsrsampling.TitleData> titles, bool isSeries) {
//     print('widget.selectedSamplingType ${widget.selectedSamplingType}');
//     print('widget.selectedSampleGiven ${widget.selectedSampleGiven}');
//     print('widget.selectedSeriesId ${widget.selectedSeriesId}');
//     print('widget.selectedClassLevel ${widget.selectedClassLevel}');

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       showDialog(
//         context: context,
//         builder: (context) => BookSearchDialog(
//           contextType: widget.contextType,
//           titles: titles,
//           sampleGiven: widget.selectedSampleGiven, // Pass sampleGiven to dialog
//           onConfirmSelection: (selected) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               setState(() {
//                 if (isSeries) {
//                   dsrsampling.SamplingModel s = dsrsampling.SamplingModel();
//                   bool isMatchSeries = false;
//                   var seriesId = widget.selectedSeriesId;
//                   for (var action in sampleInSeries) {
//                     if (seriesId == action.seriesId) {
//                       isMatchSeries = true;
//                       s = action;
//                     }
//                   }

//                   print('isMatchSeries ${isMatchSeries}');

//                   for (var action in widget.seriesList) {
//                     if (action.seriesId.toString() == widget.selectedSeriesId) {
//                       s.seriesName = action.seriesName;
//                     }
//                   }

//                   if (isMatchSeries) {
//                     s.titles?.addAll(selected);
//                     s.titles = mergeTitleDataList(s.titles);
//                   } else {
//                     print('s.seriesName ${s.seriesName}');

//                     s.seriesId = isSeries ? widget.selectedSeriesId : '0';
//                     s.samplingType = widget.selectedSamplingType;
//                     s.sampleGiven = widget.selectedSampleGiven;
//                     s.classLevelName = '${widget.selectedClassLevel}';
//                     s.sampleTo = 'Select';
//                     s.shipTo = 'Select';
//                     s.titles = selected;
//                     sampleInSeries.add(s);
//                   }
//                 } else {
//                   dsrsampling.SamplingModel s = dsrsampling.SamplingModel();
//                   bool isMatchSeries = false;
//                   var seriesName = isbnSearchController.text.trim();
//                   for (var action in sampleNotInSeries) {
//                     if (seriesName == action.seriesName) {
//                       isMatchSeries = true;
//                       s = action;
//                     }
//                   }

//                   s.seriesName = seriesName;

//                   if (isMatchSeries) {
//                     s.titles?.addAll(selected);
//                     s.titles = mergeTitleDataList(s.titles);
//                   } else {
//                     s.seriesId = isSeries ? widget.selectedSeriesId : '0';
//                     s.samplingType = widget.selectedSamplingType;
//                     s.sampleGiven = widget.selectedSampleGiven;
//                     s.classLevelName = '${widget.selectedClassLevel}';
//                     s.sampleTo = 'Select';
//                     s.shipTo = 'Select';
//                     s.titles = selected;
//                     sampleNotInSeries.add(s);
//                   }
//                 }

//                 widget.onTitlesSelected();
//               });
//             });
//           },
//         ),
//       );
//     });
//   }

//   Widget _widgetForSeries() {
//     if (sampleInSeries.isNotEmpty) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           SizedBox(
//             height: 15,
//           ),
//           Text(
//             'In Series',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           SizedBox(
//             height: 6,
//           ),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: TColors.primary,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.white.withOpacity(0.5)),
//             ),
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: sampleInSeries.length,
//               physics: NeverScrollableScrollPhysics(),
//               itemBuilder: (context, index) {
//                 final sample = sampleInSeries[index];
//                 var titleList = sample.titles;
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           sample.seriesName ?? '',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[900],
//                           ),
//                         ),
//                         IconButton(
//                           icon: Icon(
//                             Icons.delete_outline,
//                             color: Colors.red[400],
//                             size: 28,
//                           ),
//                           onPressed: () => {
//                             sampleInSeries.remove(sample),
//                             setState(() {}),
//                           },
//                           tooltip: 'Delete Sample',
//                         ),
//                       ],
//                     ),
//                     Divider(
//                       color: Colors.black,
//                       height: 1,
//                     ),
//                     ClickButtonWidget(
//                       field: 'Sample To',
//                       required: '*',
//                       value: sample.sampleTo,
//                       resourceList: sampleToNewList,
//                       onSelected: (data) {
//                         sample.shipTo = 'Select';
//                         sample.sampleTo = data?.text;
//                         sample.sampleToId = data?.value;
//                         shipToNewList.clear();
//                         setState(() {});
//                         _fetchShipToList(data?.value.toString());
//                       },
//                     ),
//                     ClickButtonWidget(
//                       field: 'Ship To',
//                       required: '*',
//                       value: sample.shipTo,
//                       resourceList: shipToNewList,
//                       onSelected: (data) {
//                         sample.shipTo = data?.label;
//                         print('Section ${data?.section}');

//                         setState(() {});
//                       },
//                     ),
//                     SizedBox(height: 10),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: titleList?.length,
//                       physics: NeverScrollableScrollPhysics(),
//                       itemBuilder: (context, index) {
//                         final title = titleList?[index];
//                         return Card(
//                           child: Padding(
//                             padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Container(
//                                   width: 55,
//                                   height: 55,
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     image: DecorationImage(
//                                       image: title?.imageUrl != null &&
//                                               title?.imageUrl.isNotEmpty == true
//                                           ? NetworkImage(title!.imageUrl)
//                                           : const AssetImage('assets/books/book.avif'),
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         title?.title ?? '',
//                                         style: const TextStyle(fontSize: 16),
//                                       ),
//                                       Text(
//                                         "ISBN: ${title?.isbn}",
//                                         style: const TextStyle(fontSize: 14),
//                                       ),
//                                       AppUtils.isBlank(title?.bookType)
//                                           ? SizedBox()
//                                           : Text(
//                                               "Book Type: ${title?.bookType}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                     ],
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 10, right: 10),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       titleList!.length != 1
//                                           ? IconButton(
//                                               icon: const Icon(Icons.delete,
//                                                   color: Colors.red),
//                                               onPressed: () => {
//                                                 titleList.remove(title),
//                                                 setState(() {}),
//                                               },
//                                             )
//                                           : SizedBox(
//                                               width: 10,
//                                             ),
//                                       SizedBox(
//                                         height: 10,
//                                       ),
//                                       Row(
//                                         children: [
//                                           Material(
//                                             color: Colors.white,
//                                             child: InkWell(
//                                               onTap: () {
//                                                 if (title?.quantity != 1) {
//                                                   title?.quantity--;
//                                                 }
//                                                 setState(() {});
//                                               },
//                                               child: Container(
//                                                 alignment: Alignment.center,
//                                                 width: 34,
//                                                 height: 34,
//                                                 child: Text(
//                                                   '-',
//                                                   style: TextStyle(
//                                                       fontSize: 26, color: Colors.black),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             width: 10,
//                                           ),
//                                           Text(
//                                             "${title?.quantity}",
//                                             style: const TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.w600),
//                                           ),
//                                           SizedBox(
//                                             width: 10,
//                                           ),
//                                           Material(
//                                             color: Colors.white,
//                                             child: InkWell(
//                                               onTap: () {
//                                                 title?.quantity++;
//                                                 setState(() {});
//                                               },
//                                               child: Container(
//                                                 alignment: Alignment.center,
//                                                 width: 34,
//                                                 height: 34,
//                                                 child: Text(
//                                                   '+',
//                                                   style: TextStyle(
//                                                       fontSize: 26, color: Colors.black),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 );
//               },
//             ),
//           )
//         ],
//       );
//     }

//     return SizedBox();
//   }

//   Widget _widgetForNotSeries() {
//     if (sampleNotInSeries.isNotEmpty) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           SizedBox(
//             height: 15,
//           ),
//           Text(
//             'Not In Series',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//           ),
//           SizedBox(
//             height: 6,
//           ),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: TColors.primary,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.white.withOpacity(0.5)),
//             ),
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: sampleNotInSeries.length,
//               physics: NeverScrollableScrollPhysics(),
//               itemBuilder: (context, index) {
//                 final sample = sampleNotInSeries[index];
//                 var titleList = sample.titles;
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           sample.seriesName ?? '',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[900],
//                           ),
//                         ),
//                         IconButton(
//                           icon: Icon(
//                             Icons.delete_outline,
//                             color: Colors.red[400],
//                             size: 28,
//                           ),
//                           onPressed: () => {
//                             sampleNotInSeries.remove(sample),
//                             setState(() {}),
//                           },
//                           tooltip: 'Delete Sample',
//                         ),
//                       ],
//                     ),
//                     Divider(
//                       color: Colors.black,
//                       height: 1,
//                     ),
//                     ClickButtonWidget(
//                       field: 'Sample To',
//                       required: '*',
//                       value: sample.sampleTo,
//                       resourceList: sampleToNewList,
//                       onSelected: (data) {
//                         sample.sampleTo = data?.text;
//                         sample.sampleToId = data?.value;
//                         sample.shipTo = 'Select';
//                         shipToNewList.clear();
//                         setState(() {});
//                         _fetchShipToList(data?.value.toString());
//                       },
//                     ),
//                     ClickButtonWidget(
//                       field: 'Ship To',
//                       required: '*',
//                       value: sample.shipTo,
//                       resourceList: shipToNewList,
//                       onSelected: (data) {
//                         sample.shipTo = data?.label;
//                         print('Section ${data?.section}');

//                         setState(() {});
//                       },
//                     ),
//                     SizedBox(height: 10),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: titleList?.length,
//                       physics: NeverScrollableScrollPhysics(),
//                       itemBuilder: (context, index) {
//                         final title = titleList?[index];
//                         return Card(
//                           child: Padding(
//                             padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Container(
//                                   width: 55,
//                                   height: 55,
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     image: DecorationImage(
//                                       image: title?.imageUrl != null &&
//                                               title?.imageUrl.isNotEmpty == true
//                                           ? NetworkImage(title!.imageUrl)
//                                           : const AssetImage('assets/books/book.avif'),
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         title?.title ?? '',
//                                         style: const TextStyle(fontSize: 16),
//                                       ),
//                                       Text(
//                                         "ISBN: ${title?.isbn}",
//                                         style: const TextStyle(fontSize: 14),
//                                       ),
//                                       AppUtils.isBlank(title?.bookType)
//                                           ? SizedBox()
//                                           : Text(
//                                               "Book Type: ${title?.bookType}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                     ],
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 10, right: 10),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     mainAxisAlignment: MainAxisAlignment.end,
//                                     children: [
//                                       titleList!.length != 1
//                                           ? IconButton(
//                                               icon: const Icon(Icons.delete,
//                                                   color: Colors.red),
//                                               onPressed: () => {
//                                                 titleList.remove(title),
//                                                 setState(() {}),
//                                               },
//                                             )
//                                           : SizedBox(
//                                               width: 10,
//                                             ),
//                                       SizedBox(
//                                         height: 10,
//                                       ),
//                                       Row(
//                                         children: [
//                                           Material(
//                                             color: Colors.white,
//                                             child: InkWell(
//                                               onTap: () {
//                                                 if (title?.quantity != 1) {
//                                                   title?.quantity--;
//                                                 }
//                                                 setState(() {});
//                                               },
//                                               child: Container(
//                                                 alignment: Alignment.center,
//                                                 width: 34,
//                                                 height: 34,
//                                                 child: Text(
//                                                   '-',
//                                                   style: TextStyle(
//                                                       fontSize: 26, color: Colors.black),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(
//                                             width: 10,
//                                           ),
//                                           Text(
//                                             "${title?.quantity}",
//                                             style: const TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.w600),
//                                           ),
//                                           SizedBox(
//                                             width: 10,
//                                           ),
//                                           Material(
//                                             color: Colors.white,
//                                             child: InkWell(
//                                               onTap: () {
//                                                 title?.quantity++;
//                                                 setState(() {});
//                                               },
//                                               child: Container(
//                                                 alignment: Alignment.center,
//                                                 width: 34,
//                                                 height: 34,
//                                                 child: Text(
//                                                   '+',
//                                                   style: TextStyle(
//                                                       fontSize: 26, color: Colors.black),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 );
//               },
//             ),
//           )
//         ],
//       );
//     }

//     return SizedBox();
//   }

//   List<dsrsampling.TitleData> mergeTitleDataList(List<dsrsampling.TitleData>? inputList) {
//     final Map<int, dsrsampling.TitleData> mergedMap = {};

//     for (var item in inputList!) {
//       if (mergedMap.containsKey(item.bookId)) {
//         final existing = mergedMap[item.bookId]!;
//         mergedMap[item.bookId] = existing.copyWith(
//           quantity: existing.quantity + item.quantity,
//         );
//       } else {
//         mergedMap[item.bookId] = item;
//       }
//     }

//     return mergedMap.values.toList();
//   }
// }
