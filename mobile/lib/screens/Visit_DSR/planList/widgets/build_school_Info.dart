// import 'package:dart_crm/models/visit_details.dart';
// import 'package:flutter/material.dart';

// class buildSchoolInfo extends StatefulWidget {
//   final CustomerDetail customerDetail;
//   final double screenWidth;
//   const buildSchoolInfo(
//       {super.key, required this.customerDetail, required this.screenWidth});

//   @override
//   State<buildSchoolInfo> createState() => _buildSchoolInfoState();
// }

// class _buildSchoolInfoState extends State<buildSchoolInfo> {
//   @override
//   Widget build(BuildContext context) {
//     final addressLines = widget.customerDetail.address
//         .replaceAll(RegExp(r'<[^>]+>'), '')
//         .split('\r\n')
//         .where((line) => line.isNotEmpty)
//         .toList();
//     return Card(
//       color: Colors.blue[50],
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(widget.screenWidth * 0.04),
//       ),
//       shadowColor: Colors.blue.withOpacity(0.3),
//       child: Padding(
//         padding: EdgeInsets.all(widget.screenWidth * 0.05),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '${widget.customerDetail.customerName})',
//                     // '${customerDetail.customerName} (ID: ${customerDetail.customerId})',
//                     style: TextStyle(
//                       fontSize: widget.screenWidth * 0.05,
//                       fontWeight: FontWeight.bold,
//                       color: TColors.headerText,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   ...addressLines.map((line) => Text(
//                         line,
//                         style: TextStyle(
//                           color: Colors.grey[700],
//                           fontSize: widget.screenWidth * 0.035,
//                         ),
//                       )),
//                   Text(
//                     'Contact: ${widget.customerDetail.name}',
//                     style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: widget.screenWidth * 0.035,
//                     ),
//                   ),
//                   if (widget.customerDetail.emailId.isNotEmpty)
//                     Text(
//                       'Email: ${widget.customerDetail.emailId}',
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontSize: widget.screenWidth * 0.035,
//                       ),
//                     ),
//                   if (widget.customerDetail.mobile.isNotEmpty)
//                     Text(
//                       'Mobile: ${widget.customerDetail.mobile}',
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontSize: widget.screenWidth * 0.035,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//     ;
//   }
// }
