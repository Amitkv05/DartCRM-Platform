// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class HelperFunctions {
//   static void showSnackBor(String message, BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }

//   static void showAlert(BuildContext context, String title, String message) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: Text(title),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Ok'),
//               ),
//             ],
//           );
//         });
//   }

//   static bool isDarkMode(BuildContext context) {
//     return Theme.of(context).brightness == Brightness.dark;
//   }

//   static double screenHeight(BuildContext context) {
//     return MediaQuery.of(context).size.height;
//   }

//   static double screenWidth(BuildContext context) {
//     return MediaQuery.of(context).size.width;
//   }

//   static String GetFormattedDate(DateTime date,
//       {String format = 'dd MMM yyyy'}) {
//     return DateFormat(format).format(date);
//   }
// }
