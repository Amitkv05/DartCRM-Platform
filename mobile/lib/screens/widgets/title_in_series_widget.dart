// import 'package:dart_crm/edit/utils/AppUtils.dart';
// import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
// import 'package:dart_crm/models/planList/dsr_sampling_details.dart' as dsrsampling;
// import 'package:dart_crm/providers/auth_provider.dart';
// import 'package:dart_crm/providers/dsr_entry_provider.dart';
// import 'package:dart_crm/screens/Visit_DSR/DSR_entry/widget/book_search_popup.dart';
// import 'package:dart_crm/util/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class TitleInSeriesPage extends ConsumerStatefulWidget {
//   final String contextType; // 'dsr', 'selfStock', or 'customer'
//   final dsrsampling.dsrSeriesAndClassLevelResponse? classLevelResponse;

//   const TitleInSeriesPage(
//       {super.key, this.classLevelResponse, required this.contextType});

//   @override
//   _TitleInSeriesPageState createState() => _TitleInSeriesPageState();
// }

// class _TitleInSeriesPageState extends ConsumerState<TitleInSeriesPage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   List<dsrsampling.TitleData> selectedTitles = [];
//   int? selectedClassLevel;
//   String? selectedSeriesId;
//   List<dsrsampling.Series> seriesList = [];
//   bool isLoadingSeries = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnimation =
//         CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
//     _animationController.forward();

//     if (widget.classLevelResponse != null &&
//         widget.classLevelResponse!.classLevelList.isNotEmpty) {
//       selectedClassLevel = -1;
//       _fetchSeriesList();
//     }
//   }

//   void _fetchSeriesList() {
//     setState(() => isLoadingSeries = true);
//     final authState = ref.read(authProvider);
//     final executiveId = authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
//     final token = authState.token ?? '';

//     ref
//         .read(dsrEntryProvider.notifier)
//         .dsrfetchSeriesAndClassLevel(
//           request: dsrsampling.dsrSeriesAndClassLevelRequest(
//             profileId: AppUtils.getProfileIdStr(),
//             executiveId: AppUtils.getExecutiveStr(),
//             classLevelId: selectedClassLevel == -1 ? null : selectedClassLevel,
//           ),
//           token: token,
//         )
//         .then((response) {
//       setState(() {
//         isLoadingSeries = false;
//         if (response.status == 'Success') {
//           seriesList = response.seriesList;
//           selectedSeriesId =
//               seriesList.isNotEmpty ? seriesList.first.seriesId.toString() : null;
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to load series: ${response.status}')),
//           );
//         }
//       });
//     });
//   }

//   void _showBookSearchDialog() {
//     if (selectedClassLevel == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a class level first')),
//       );
//       return;
//     }
//     if (selectedSeriesId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a series')),
//       );
//       return;
//     }

//     final authState = ref.read(authProvider);
//     final executiveId = authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
//     final token = authState.token ?? '';

//     final request = dsrsampling.FetchTitlesRequest(
//       executiveId: executiveId,
//       seriesId: selectedSeriesId,
//       classLevel: selectedClassLevel == -1 ? null : selectedClassLevel,
//     );

//     ref
//         .read(dsrEntryProvider.notifier)
//         .fetchTitles(request: request, token: token)
//         .then((response) {
//       if (response.status == 'Success' && response.titleList.isNotEmpty) {
//         _showTitlesDialog(response.titleList);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No titles found for this series')),
//         );
//       }
//     });
//   }

//   void _showTitlesDialog(List<dsrsampling.TitleData> titles) {
//     showDialog(
//       context: context,
//       builder: (context) => BookSearchDialog(
//         contextType: widget.contextType,
//         titles: titles,
//         onConfirmSelection: (selected) {
//           setState(() {
//             selectedTitles.addAll(selected);
//           });
//         },
//       ),
//     ).then((_) {
//       if (Navigator.canPop(context)) Navigator.pop(context, _prepareResult());
//     });
//   }

//   List<Map<String, dynamic>> _prepareResult() {
//     return selectedTitles.map((t) {
//       final index = selectedTitles.indexOf(t) + 1;
//       return {
//         'sno': index.toString(),
//         'series': t.seriesId?.toString() ?? '',
//         'subject': '',
//         'title': t.title,
//         'bookType': t.bookType,
//         'bookId': t.bookId is int ? t.bookId : int.parse(t.bookId.toString()),
//         'seriesId': t.seriesId is int
//             ? t.seriesId ?? 0
//             : int.tryParse(t.seriesId?.toString() ?? '0') ?? 0,
//         'qty': t.quantity.toString(),
//         'price': t.price.toString(),
//         'imageUrl': t.imageUrl,
//       };
//     }).toList();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Title in Series',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 22,
//             color: Colors.black87,
//           ),
//         ),
//         backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         centerTitle: true,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color.fromRGBO(252, 242, 219, 1),
//                 Color.fromRGBO(252, 242, 219, 0.85),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.grey[50]!, Colors.white],
//           ),
//         ),
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Select Series',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           value: selectedSeriesId,
//                           decoration: InputDecoration(
//                             labelText: 'Series',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: TColors.icon),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: TColors.icon),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: TColors.icon),
//                             ),
//                           ),
//                           isExpanded: true,
//                           icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
//                           dropdownColor: Colors.white,
//                           style: const TextStyle(fontSize: 14, color: Colors.black87),
//                           items: seriesList.map((series) {
//                             return DropdownMenuItem<String>(
//                               value: series.seriesId.toString(),
//                               child: Text(
//                                 "${series.seriesName}",
//                                 // "${series.seriesName} (ID: ${series.seriesId})",
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             );
//                           }).toList(),
//                           onChanged: (value) {
//                             setState(() => selectedSeriesId = value);
//                           },
//                           hint: isLoadingSeries
//                               ? const Text("Loading series...")
//                               : seriesList.isEmpty
//                                   ? const Text("No series available")
//                                   : const Text("Select a series"),
//                           validator: (value) =>
//                               value == null ? 'Please select a series' : null,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: _showBookSearchDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: TColors.buttonPrimary,
//                           foregroundColor: Colors.white,
//                           padding:
//                               const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                           elevation: 4,
//                         ),
//                         child: const Text(
//                           'Search',
//                           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//                   DropdownButtonFormField<int>(
//                     value: selectedClassLevel,
//                     decoration: InputDecoration(
//                       labelText: 'Class Level',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: TColors.icon),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: TColors.icon),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: TColors.icon),
//                       ),
//                     ),
//                     isExpanded: true,
//                     icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
//                     dropdownColor: Colors.white,
//                     style: const TextStyle(fontSize: 14, color: Colors.black87),
//                     items: [
//                       const DropdownMenuItem<int>(
//                         value: -1,
//                         child: Text('All Class Levels'),
//                       ),
//                       ...(widget.classLevelResponse?.classLevelList.map((level) {
//                             return DropdownMenuItem<int>(
//                               value: level.classLevelId is int
//                                   ? level.classLevelId
//                                   : int.tryParse(level.classLevelId.toString()) ?? 0,
//                               child: Text(level.classLevelName),
//                             );
//                           }).toList() ??
//                           []),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         selectedClassLevel = value;
//                         selectedSeriesId = null;
//                         seriesList = [];
//                         _fetchSeriesList();
//                       });
//                     },
//                     validator: (value) =>
//                         value == null ? 'Please select a class level' : null,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
