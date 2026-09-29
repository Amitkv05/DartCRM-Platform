// import 'package:dart_crm/models/customer/school_detail_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class CustomerDetailsScreen extends ConsumerWidget {
//   final int customerId;
//   final String customerType;

//   const CustomerDetailsScreen(
//       {required this.customerId, required this.customerType, super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final state = ref.watch(customerDetailsProvider(
//         {'customerId': customerId, 'customerType': customerType}));

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('$customerType Details'),
//         backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
//       ),
//       body: state.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : state.error != null
//               ? Center(child: Text(state.error!))
//               : state.details?.status == 'Success' &&
//                       state.details!.schoolDetails != null
//                   ? ListView(
//                       padding: const EdgeInsets.all(16.0),
//                       children: [
//                         Text(
//                             'Name: ${state.details!.schoolDetails!.first.schoolName}',
//                             style: const TextStyle(fontSize: 18)),
//                         Text(
//                             'Code: ${state.details!.schoolDetails!.first.schoolCode}'),
//                         Text(
//                             'Address: ${state.details!.schoolDetails!.first.address}'),
//                         Text(
//                             'Validation: ${state.details!.schoolDetails!.first.validationStatus == 'Y' ? 'Validated' : 'Pending'}'),
//                         if (state.details!.bookSellerList != null) ...[
//                           const SizedBox(height: 16),
//                           const Text('Booksellers:',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.bold)),
//                           ...state.details!.bookSellerList!
//                               .map((bs) => ListTile(
//                                     title: Text(bs.bookSellerName),
//                                     subtitle: Text(
//                                         '${bs.address}, ${bs.city}, ${bs.state}, ${bs.country}'),
//                                   )),
//                         ],
//                       ],
//                     )
//                   : const Center(child: Text('No details available')),
//     );
//   }
// }
