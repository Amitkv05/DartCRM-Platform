// import 'package:dart_crm/models/planList/sampling_details.dart' as sampling;
// import 'package:dart_crm/models/planList/dsr_sampling_details.dart'
//     as dsrsampling;
// import 'package:dart_crm/providers/auth_provider.dart';
// import 'package:dart_crm/providers/dsr_entry_provider.dart';
// import 'package:dart_crm/screens/Visit_DSR/DSR_entry/widget/book_search_popup.dart';
// import 'package:dart_crm/util/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class TitleNotInSeriesPage extends ConsumerStatefulWidget {
//   final String contextType; // 'dsr', 'selfStock', or 'customer'
//   const TitleNotInSeriesPage({super.key, required this.contextType});

//   @override
//   _TitleNotInSeriesPageState createState() => _TitleNotInSeriesPageState();
// }

// class _TitleNotInSeriesPageState extends ConsumerState<TitleNotInSeriesPage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _searchController = TextEditingController();
//   List<dsrsampling.TitleData> selectedTitles = [];
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

//     _searchController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {}

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _showBookSearchDialog() {
//     final authState = ref.read(authProvider);
//     final executiveId =
//         authState.loginResponse?.executiveBasicData?[0].executiveId ?? 0;
//     final token = authState.token ?? '';
//     final searchText = _searchController.text.trim();

//     if (searchText.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a search term')),
//       );
//       return;
//     }

//     final request = sampling.TitleNotInSeriesRequest(
//       executiveId: executiveId,
//       titleOrISBN: searchText,
//     );

//     ref
//         .read(dsrEntryProvider.notifier)
//         .fetchTitlesNotInSeries(request: request, token: token)
//         .then((response) {
//       if (response.status == 'Success' && response.titleList.isNotEmpty) {
//         _showTitlesDialog(response.titleList);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No titles found for this ISBN/Title')),
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
//         'title': t.title,
//         'bookId': t.bookId,
//         'qty': t.quantity.toString(),
//         'price': t.price.toString(),
//         'imageUrl': t.imageUrl,
//       };
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Title not in Series',
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
//                     'Search ISBN/Title',
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
//                         child: TextFormField(
//                           controller: _searchController,
//                           decoration: InputDecoration(
//                             labelText: 'ISBN or Title',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide:
//                                   BorderSide(color: Colors.blue.shade200),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide:
//                                   BorderSide(color: Colors.blue.shade200),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: TColors.icon),
//                             ),
//                           ),
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton(
//                         onPressed: _showBookSearchDialog,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: TColors.buttonPrimary,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 14),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12)),
//                           elevation: 4,
//                         ),
//                         child: const Text(
//                           'Search',
//                           style: TextStyle(
//                               fontSize: 14, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ],
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
