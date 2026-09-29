// import 'package:dart_crm/edit/library/library_edit_page.dart';
// import 'package:dart_crm/models/customer/customer_master_list_model.dart';
// import 'package:dart_crm/providers/customerProvider/customer_master_list_provider.dart';
// import 'package:dart_crm/screens/customer/customerCreationScreen/customer_creation_screen.dart';
// import 'package:dart_crm/screens/customer/details/library_details_screen.dart';
// import 'package:dart_crm/screens/customer/details/school_details_screen.dart';
// import 'package:dart_crm/screens/customer/edit/customerEditScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class LibraryMasterListScreen extends ConsumerStatefulWidget {
//   const LibraryMasterListScreen({super.key});

//   @override
//   ConsumerState<LibraryMasterListScreen> createState() => _LibraryMasterListScreenState();
// }

// class _LibraryMasterListScreenState extends ConsumerState<LibraryMasterListScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   List<CustomerMasterListItem> _allCustomers = []; // Cache for filtering

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_filterCustomers);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _filterCustomers() {
//     final query = _searchController.text.toLowerCase();
//     final notifier = ref.read(customerMasterListProvider('School').notifier);
//     if (query.isEmpty) {
//       notifier.state = notifier.state.copyWith(customers: _allCustomers);
//     } else {
//       final filtered = _allCustomers.where((customer) {
//         final name = customer.customerName.toLowerCase();
//         final code = customer.customerCode.toLowerCase();
//         return name.contains(query) || code.contains(query);
//       }).toList();
//       notifier.state = notifier.state.copyWith(customers: filtered);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final customerType = 'Library'; // Replace with 'Trade' or 'Library' for other screens
//     final state = ref.watch(customerMasterListProvider(customerType));
//     final notifier = ref.read(customerMasterListProvider(customerType).notifier);

//     // Cache the full list for filtering when not loading or errored
//     if (!state.isLoading && state.error == null && _allCustomers.isEmpty) {
//       _allCustomers = List.from(state.customers);
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "$customerType Master List",
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
//         elevation: 2,
//         centerTitle: true,
//         shadowColor: Colors.black.withOpacity(0.1),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => CustomerCreation(initialCustomerType: customerType),
//             ),
//           );
//         },
//         backgroundColor: Colors.blueAccent,
//         elevation: 6,
//         tooltip: 'Add New $customerType',
//         child: const Icon(Icons.add, color: Colors.white, size: 28),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.grey[100]!, Colors.grey[50]!],
//           ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search $customerType by name or code...',
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 child: state.isLoading && state.customers.isEmpty
//                     ? const Center(
//                         child: CircularProgressIndicator(
//                           color: Colors.blueAccent,
//                           strokeWidth: 5,
//                         ),
//                       )
//                     : state.error != null
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   state.error!,
//                                   style: const TextStyle(
//                                     color: Colors.redAccent,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 10),
//                                 /* ElevatedButton(
//                                   onPressed: () => notifier.fetchCustomers(),
//                                   child: const Text('Retry'),
//                                 ),*/
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             itemCount: state.customers.length + (state.isLoading ? 1 : 0),
//                             itemBuilder: (context, index) {
//                               if (index == state.customers.length) {
//                                 return const Padding(
//                                   padding: EdgeInsets.all(16.0),
//                                   child: Center(
//                                     child: CircularProgressIndicator(
//                                       color: Colors.blueAccent,
//                                     ),
//                                   ),
//                                 );
//                               }
//                               final customer = state.customers[index];
//                               return _buildCustomerCard(
//                                   customer, context, customerType, notifier);
//                             },
//                             controller: ScrollController()
//                               ..addListener(() {
//                                 if (!state.isLoading &&
//                                     state.customers.isNotEmpty &&
//                                     context.size!.height + context.scrollOffset >=
//                                         context.scrollMax) {
//                                   //  notifier.fetchCustomers();
//                                 }
//                               }),
//                           ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerCard(CustomerMasterListItem customer, BuildContext context,
//       String customerType, dynamic notifier) {
//     final validationStatus = customer.validationStatus;
//     // return Card(
//     //   elevation: 5,
//     //   margin: const EdgeInsets.symmetric(vertical: 10.0),
//     //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//     //   color: Colors.white,
//     //   child: ListTile(
//     //     contentPadding: const EdgeInsets.all(16.0),
//     //     leading: CircleAvatar(
//     //       radius: 25,
//     //       backgroundColor: Colors.blueAccent.withOpacity(0.1),
//     //       child: Text(
//     //         customer.customerName.isNotEmpty
//     //             ? customer.customerName[0].toUpperCase()
//     //             : '?',
//     //         style: const TextStyle(
//     //           fontSize: 20,
//     //           fontWeight: FontWeight.bold,
//     //           color: Colors.blueAccent,
//     //         ),
//     //       ),
//     //     ),
//     //     title: Text(
//     //       customer.customerName,
//     //       style: const TextStyle(
//     //         fontSize: 18,
//     //         fontWeight: FontWeight.bold,
//     //         color: Colors.black87,
//     //       ),
//     //     ),
//     //     subtitle: Padding(
//     //       padding: const EdgeInsets.only(top: 8.0),
//     //       child: Column(
//     //         crossAxisAlignment: CrossAxisAlignment.start,
//     //         children: [
//     //           _buildSubtitleText('Code', customer.customerCode.split(',')[0]),
//     //           _buildSubtitleText('Address', customer.address),
//     //           _buildSubtitleText('City', customer.city),
//     //           _buildSubtitleText('State', customer.state),
//     //           _buildSubtitleText('Validation', validationStatus),
//     //         ],
//     //       ),
//     //     ),
//     //     trailing: const Icon(
//     //       Icons.arrow_forward_ios,
//     //       color: Colors.blueGrey,
//     //       size: 18,
//     //     ),
//     // onTap: () {
//     //   final actionParts = customer.action.split(',');
//     //   final customerId = actionParts[0];
//     //   Navigator.push(
//     //     context,
//     //     MaterialPageRoute(
//     //       builder: (context) => CustomerCreation(
//     //         customerId: int.parse(customerId),
//     //         initialCustomerType: customerType,
//     //       ),
//     //     ),
//     //   );
//     // },
//     //   ),
//     // );
//     return GestureDetector(
//       onTap: () {
//         final actionParts = customer.action.split(',');
//         final customerId = actionParts[0];
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => LibraryDetailsScreen(
//               customer: customer,
//               customerType: customerType,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.all(10.0),
//         margin: EdgeInsets.all(5),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: Colors.grey.shade600,
//             width: 1,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(
//                   width: MediaQuery.sizeOf(context).width * 0.8,
//                   child: Text(
//                     customer.customerName +
//                         ' (' +
//                         customer.customerCode.split(',')[0] +
//                         ')',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),

//                 SizedBox(height: 5),
//                 _buildSubtitleText('', customer.address),
//                 // _buildSubtitleText('City', customer.city),
//                 // _buildSubtitleText('State', customer.state),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _buildSubtitleText('Validation: ', validationStatus),
//                     Row(
//                       children: [
//                         GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => LibraryEditPage(
//                                     customer: customer,
//                                     customerType: customerType,
//                                   ),
//                                 ),
//                               ).then((_) {
//                                 notifier.fetchCustomers();
//                               });
//                             },
//                             child: Icon(Icons.edit, color: Colors.black, size: 25)),
//                         // IconButton(
//                         //   icon: const Icon(Icons.edit,
//                         //       color: Colors.blue, size: 25),
//                         // onPressed: () {
//                         //   Navigator.push(
//                         //     context,
//                         //     MaterialPageRoute(
//                         //       builder: (context) => CustomerEditScreen(
//                         //         customer: customer,
//                         //         customerType: customerType,
//                         //       ),
//                         //     ),
//                         //   ).then((_) {
//                         //     notifier.fetchCustomers();
//                         //   });
//                         // },
//                         // ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red, size: 25),
//                           onPressed: () {
//                             showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text('Delete Customer'),
//                                 content: Text(
//                                     'Are you sure you want to delete ${customer.customerName}?'),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () => Navigator.pop(context),
//                                     child: const Text('Cancel'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       notifier.deleteCustomer(customer.customerId);
//                                       Navigator.pop(context);
//                                     },
//                                     child: const Text('Delete',
//                                         style: TextStyle(color: Colors.red)),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             // Divider(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSubtitleText(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 3.0),
//       child: RichText(
//         text: TextSpan(
//           children: [
//             TextSpan(
//               text: '$label',
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.black54,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             TextSpan(
//               text: value.isEmpty ? 'N/A' : value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// extension ScrollContext on BuildContext {
//   double get scrollOffset =>
//       (findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero).dy ?? 0;
//   double get scrollMax => (findRenderObject() as RenderBox?)?.size.height ?? 0;
// }
