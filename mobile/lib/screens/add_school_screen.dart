// import 'package:flutter/material.dart';

// class AddSchoolScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.orange,
//         title: Text(
//           'Add School',
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: ElevatedButton(
//               onPressed: () {},
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 'ADD NEW SCHOOL',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'School already sent for update approval',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 20),
//             _buildTextField('School Name *', 'ABC Public School'),
//             _buildTextField('Reference Code', 'ERP2454'),
//             _buildTextField('Email Id', 'abcd@dps.com'),
//             _buildTextField('Mobile Number', '8765434'),
//             SizedBox(height: 20),
//             // Tabs section as buttons to open popups
//             Wrap(
//               spacing: 8.0,
//               runSpacing: 8.0,
//               children: [
//                 _buildTabButton(context, 'Address', AddressPopup()),
//                 _buildTabButton(
//                     context, 'School Details', SchoolDetailsPopup()),
//                 _buildTabButton(context, 'Enrollment', EnrollmentPopup()),
//                 _buildTabButton(context, 'Teacher', TeachersPopup()),
//                 _buildTabButton(
//                     context, 'School Facility', SchoolFacilityPopup()),
//                 _buildTabButton(context, 'Notes/Comment', NotesCommentsPopup()),
//               ],
//             ),
//             SizedBox(height: 20),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[100],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 child: Text(
//                   'Update',
//                   style: TextStyle(color: Colors.blue),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, String initialValue) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           ),
//           SizedBox(height: 8),
//           TextFormField(
//             initialValue: initialValue,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabButton(BuildContext context, String title, Widget popup) {
//     return ElevatedButton(
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: popup,
//           ),
//         );
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white,
//         side: BorderSide(color: Colors.blue),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       child: Text(
//         title,
//         style: TextStyle(color: Colors.blue),
//       ),
//     );
//   }
// }

// // Address Popup
// class AddressPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Address',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           _buildTextField('Address *', 'Main Road\nGandhi Nagar'),
//           _buildTextField('Pincode *', '110091'),
//           _buildDropdownField('Country Name *', 'India'),
//           _buildDropdownField('State Name *', 'Delhi'),
//           _buildDropdownField('District Name *', 'Delhi'),
//           _buildDropdownField('City Name *', 'Select'),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // School Details Popup
// class SchoolDetailsPopup extends StatefulWidget {
//   @override
//   _SchoolDetailsPopupState createState() => _SchoolDetailsPopupState();
// }

// class _SchoolDetailsPopupState extends State<SchoolDetailsPopup> {
//   String _purchaseMode = 'Book Seller'; // Default value
//   String _keyCustomer = 'Yes'; // Default value
//   String _customerStatus = 'Active'; // Default value

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'School Details',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           _buildDropdownField('Board *', 'CBSE'),
//           _buildDropdownField('Chain School', 'Select'),
//           _buildDropdownField('Start Class *', 'Nry'),
//           _buildDropdownField('End Class *', '12'),
//           _buildDropdownField('Medium *', 'English'),
//           _buildDropdownField('Ranking *', 'A'),
//           _buildDropdownField('Sampling Month *', 'December'),
//           _buildDropdownField('Decision Month *', 'February'),
//           _buildRadioGroup(
//             'Purchase Mode *',
//             ['Open', 'Direct', 'Book Seller'],
//             _purchaseMode,
//             (value) {
//               setState(() {
//                 _purchaseMode = value!;
//               });
//             },
//           ),
//           // Conditionally show Book Seller section only if "Book Seller" is selected
//           if (_purchaseMode == 'Book Seller') ...[
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: _buildDropdownField('Book Seller *', 'Rohit Joshi'),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => Dialog(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: SearchBookSellerPopup(),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: Text(
//                     'Add Book Seller',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//             _buildBookSellerTable(),
//           ],
//           _buildRadioGroup(
//             'Key Customer *',
//             ['Yes', 'No'],
//             _keyCustomer,
//             (value) {
//               setState(() {
//                 _keyCustomer = value!;
//               });
//             },
//           ),
//           _buildTextField('PAN Number', 'PAN NUMBER'),
//           _buildTextField('GST Number', 'GST NUMBER'),
//           _buildRadioGroup(
//             'Customer Status *',
//             ['Active', 'Inactive'],
//             _customerStatus,
//             (value) {
//               setState(() {
//                 _customerStatus = value!;
//               });
//             },
//           ),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBookSellerTable() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Book Seller Details',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 8),
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: DataTable(
//             columns: [
//               DataColumn(label: Text('S.No')),
//               DataColumn(label: Text('Book Seller Name')),
//               DataColumn(label: Text('Address')),
//               DataColumn(label: Text('City')),
//               DataColumn(label: Text('State')),
//               DataColumn(label: Text('Country')),
//               DataColumn(label: Text('Action')),
//             ],
//             rows: [
//               DataRow(cells: [
//                 DataCell(Text('1')),
//                 DataCell(Text('Ane Books Depot(TR101)')),
//                 DataCell(Text('Ansari Road, Daryaganj')),
//                 DataCell(Text('Delhi (Delhi)')),
//                 DataCell(Text('Delhi')),
//                 DataCell(Text('India')),
//                 DataCell(Icon(Icons.delete, color: Colors.red)),
//               ]),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// // Search Book Seller Popup
// class SearchBookSellerPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Search Book Seller',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               IconButton(
//                 icon: Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           _buildTextField('Book Seller Name', ''),
//           _buildTextField('Book Seller Code/RefCode', ''),
//           SizedBox(height: 16),
//           Text(
//             'Geographical Structure',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           _buildDropdownField('Country Name', 'India'),
//           _buildDropdownField('State Name', 'Select'),
//           _buildDropdownField('District Name', 'Select'),
//           _buildDropdownField('City Name', 'Select'),
//           SizedBox(height: 16),
//           Text(
//             'Organizational Structure',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           _buildDropdownField('Region Name', 'Select'),
//           _buildDropdownField('Area Name', 'Select'),
//           _buildDropdownField('Territory Name', 'Select'),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 'Submit',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Enrollment Popup
// class EnrollmentPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Enrollment',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           _buildTextField('Total Enrollment', '0'),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Teachers Popup (Updated to Open Add New Teacher Popup)
// class TeachersPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'List of Contacts',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) => Dialog(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: AddNewTeacherPopup(),
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 child: Text(
//                   'Add New Teacher',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columns: [
//                 DataColumn(label: Text('S.No')),
//                 DataColumn(label: Text('Name')),
//                 DataColumn(label: Text('Designation')),
//                 DataColumn(label: Text('Mobile')),
//                 DataColumn(label: Text('Email')),
//                 DataColumn(label: Text('Primary Contact')),
//                 DataColumn(label: Text('Validation')),
//                 DataColumn(label: Text('Action')),
//               ],
//               rows: [
//                 DataRow(cells: [
//                   DataCell(Text('1')),
//                   DataCell(Text('Dr. ABC School')),
//                   DataCell(Text('Coordinator')),
//                   DataCell(Text('1234567890')),
//                   DataCell(Text('example@email.com')),
//                   DataCell(Text('Yes')),
//                   DataCell(Text('Yes')),
//                   DataCell(Row(
//                     children: [
//                       Icon(Icons.edit, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Icon(Icons.delete, color: Colors.red),
//                     ],
//                   )),
//                 ]),
//                 DataRow(cells: [
//                   DataCell(Text('2')),
//                   DataCell(Text('Miss suraj sing')),
//                   DataCell(Text('Chairman')),
//                   DataCell(Text('4545464646')),
//                   DataCell(Text('deep124@gmail.com')),
//                   DataCell(Text('No')),
//                   DataCell(Text('Yes')),
//                   DataCell(Row(
//                     children: [
//                       Icon(Icons.edit, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Icon(Icons.delete, color: Colors.red),
//                     ],
//                   )),
//                 ]),
//                 DataRow(cells: [
//                   DataCell(Text('3')),
//                   DataCell(Text('Miss suraj sing')),
//                   DataCell(Text('Chairman')),
//                   DataCell(Text('4545464646')),
//                   DataCell(Text('deep124@gmail.com')),
//                   DataCell(Text('Yes')),
//                   DataCell(Text('No')),
//                   DataCell(Row(
//                     children: [
//                       Icon(Icons.edit, color: Colors.blue),
//                       SizedBox(width: 8),
//                       Icon(Icons.delete, color: Colors.red),
//                     ],
//                   )),
//                 ]),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Add New Teacher Popup (New)
// class AddNewTeacherPopup extends StatefulWidget {
//   @override
//   _AddNewTeacherPopupState createState() => _AddNewTeacherPopupState();
// }

// class _AddNewTeacherPopupState extends State<AddNewTeacherPopup> {
//   String _primaryContact = 'No'; // Default value
//   String _contactStatus = 'Active'; // Default value

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Add New Teacher',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               IconButton(
//                 icon: Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           _buildRadioGroup(
//             'Primary Contact *',
//             ['Yes', 'No'],
//             _primaryContact,
//             (value) {
//               setState(() {
//                 _primaryContact = value!;
//               });
//             },
//           ),
//           _buildRadioGroup(
//             'Contact Status *',
//             ['Active', 'Inactive'],
//             _contactStatus,
//             (value) {
//               setState(() {
//                 _contactStatus = value!;
//               });
//             },
//           ),
//           _buildDropdownField('Salutation', 'Select'),
//           _buildTextField('First Name *', ''),
//           _buildTextField('Last Name', ''),
//           _buildDropdownField('Designation *', 'Select'),
//           _buildTextField('Email Id *', ''),
//           _buildTextField('Mobile Number', ''),
//           _buildTextField('Address', ''),
//           _buildTextField('Pincode', ''),
//           _buildDropdownField('Country', 'Select'),
//           _buildDropdownField('State', 'Select'),
//           _buildDropdownField('District', 'Select'),
//           _buildDropdownField('City', 'Select'),
//           _buildDropdownField('Data Source', 'Select'),
//           _buildTextField('Birth Day', ''),
//           _buildTextField('Anniversary', ''),
//           SizedBox(height: 16),
//           Text(
//             'Subject and Class',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columns: [
//                 DataColumn(label: Text('S.No')),
//                 DataColumn(label: Text('Subject Name')),
//                 DataColumn(label: Text('Class Name')),
//                 DataColumn(label: Text('Decision Maker')),
//                 DataColumn(label: Text('Action')),
//               ],
//               rows: [
//                 DataRow(cells: [
//                   DataCell(Text('1')),
//                   DataCell(DropdownButton<String>(
//                     value: 'Select',
//                     items: ['Select', 'Other'].map((String value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       );
//                     }).toList(),
//                     onChanged: (newValue) {},
//                   )),
//                   DataCell(DropdownButton<String>(
//                     value: 'Teacher Class Name',
//                     items: ['Teacher Class Name', 'Other'].map((String value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       );
//                     }).toList(),
//                     onChanged: (newValue) {},
//                   )),
//                   DataCell(DropdownButton<String>(
//                     value: 'Select',
//                     items: ['Select', 'Other'].map((String value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       );
//                     }).toList(),
//                     onChanged: (newValue) {},
//                   )),
//                   DataCell(Icon(Icons.add_circle, color: Colors.blue)),
//                 ]),
//               ],
//             ),
//           ),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 'Submit',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // School Facility Popup
// class SchoolFacilityPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'School Facility',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           _buildCheckbox('WiFi', true),
//           _buildCheckbox('Working Computers', true),
//           _buildCheckbox('Projector', true),
//           _buildCheckbox('Lab', false),
//           _buildCheckbox('Smart TV', false),
//           _buildCheckbox('Kit Storage - Cabinet - Locker', false),
//           _buildCheckbox('Bluetooth Connectivity', false),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCheckbox(String title, bool value) {
//     return Row(
//       children: [
//         Checkbox(
//           value: value,
//           onChanged: (newValue) {},
//         ),
//         Text(title),
//       ],
//     );
//   }
// }

// // Notes/Comments Popup
// class NotesCommentsPopup extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Notes/Comments',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           _buildTextField('Comments', ''),
//           SizedBox(height: 16),
//           Center(
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Close'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Reusable Widgets
// Widget _buildTextField(String label, String initialValue) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         SizedBox(height: 8),
//         TextFormField(
//           initialValue: initialValue,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             hintText: label,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildDropdownField(String label, String initialValue) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: initialValue,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           ),
//           items: [initialValue, 'Other'].map((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value),
//             );
//           }).toList(),
//           onChanged: (newValue) {},
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildRadioGroup(String label, List<String> options,
//     String selectedValue, ValueChanged<String?> onChanged) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 16.0),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//         SizedBox(height: 8),
//         Row(
//           children: options.map((option) {
//             return Row(
//               children: [
//                 Radio<String>(
//                   value: option,
//                   groupValue: selectedValue,
//                   onChanged: onChanged,
//                 ),
//                 Text(option),
//                 SizedBox(width: 16),
//               ],
//             );
//           }).toList(),
//         ),
//       ],
//     ),
//   );
// }
