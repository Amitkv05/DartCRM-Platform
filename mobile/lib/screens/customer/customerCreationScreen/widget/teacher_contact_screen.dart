import 'package:dart_crm/providers/auth_provider.dart'; // Assuming this exists
import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming the new provider code is in a separate file and imported here
// import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';

class TeacherContactScreen extends ConsumerStatefulWidget {
  const TeacherContactScreen({super.key});

  @override
  ConsumerState<TeacherContactScreen> createState() =>
      _TeacherContactScreenState();
}

class _TeacherContactScreenState extends ConsumerState<TeacherContactScreen> {
  final _formKey = GlobalKey<FormState>();
  String primaryContact = 'Y';
  String contactStatus = 'Active';
  String salutation = '';
  String firstName = '';
  String lastName = '';
  String designation = '';
  String emailId = '';
  String mobileNumber = '';
  String address = '';
  String pincode = '';
  String country = '';
  String state = '';
  String district = '';
  String city = '';
  String dataSource = '';
  String birthDay = '';
  String anniversary = '';
  List<Map<String, String>> subjectClassData = [
    {'subject': '', 'class': '', 'decisionMaker': ''}
  ];

  final List<String> countryOptions = ['India', 'USA', 'UK']; // Static for now
  final List<String> stateOptions = ['Maharashtra', 'Karnataka', 'Tamil Nadu'];
  final List<String> districtOptions = ['Mumbai', 'Bangalore', 'Chennai'];
  final List<String> cityOptions = ['Mumbai', 'Bangalore', 'Chennai'];

  void _addSubjectClassRow() {
    setState(() {
      subjectClassData.add({'subject': '', 'class': '', 'decisionMaker': ''});
    });
  }

  @override
  Widget build(BuildContext context) {
    final masterDataState = ref.watch(customerEntryMasterProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Text("Teacher Contact Details",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05)),
        backgroundColor: const Color.fromRGBO(252, 242, 219, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: masterDataState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : masterDataState.error != null
                    ? Center(child: Text('Error: ${masterDataState.error}'))
                    : Container(
                        color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenWidth * 0.05),
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                      title: "Contact Details",
                                      icon: Icons.person,
                                      screenWidth: screenWidth),
                                  Text("Primary Contact *",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.black87)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text("Yes",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                          value: 'Y',
                                          groupValue: primaryContact,
                                          onChanged: (value) => setState(
                                              () => primaryContact = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text("No",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                          value: 'N',
                                          groupValue: primaryContact,
                                          onChanged: (value) => setState(
                                              () => primaryContact = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text("Contact Status *",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.black87)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text("Active",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                          value: 'Active',
                                          groupValue: contactStatus,
                                          onChanged: (value) => setState(
                                              () => contactStatus = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text("Inactive",
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.04)),
                                          value: 'Inactive',
                                          groupValue: contactStatus,
                                          onChanged: (value) => setState(
                                              () => contactStatus = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildDropdownField(
                                    label: "Salutation",
                                    value: salutation.isNotEmpty
                                        ? salutation
                                        : null,
                                    items: masterDataState.salutations
                                        .map((item) => item.salutationName)
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => salutation = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                    label: "First Name *",
                                    onChanged: (value) => firstName = value,
                                    validator: (value) =>
                                        value!.isEmpty ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                      label: "Last Name",
                                      onChanged: (value) => lastName = value,
                                      screenWidth: screenWidth),
                                  _buildDropdownField(
                                    label: "Designation *",
                                    value: designation.isNotEmpty
                                        ? designation
                                        : null,
                                    items: masterDataState.contactDesignations
                                        .map((item) =>
                                            item.contactDesignationName)
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => designation = value!),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                    label: "Email Id *",
                                    onChanged: (value) => emailId = value,
                                    validator: (value) =>
                                        value!.isEmpty ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                    label: "Mobile Number",
                                    onChanged: (value) => mobileNumber = value,
                                    keyboardType: TextInputType.phone,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildSectionHeader(
                                      title: "Address Details",
                                      icon: Icons.location_on,
                                      screenWidth: screenWidth),
                                  _buildTextField(
                                      label: "Address",
                                      onChanged: (value) => address = value,
                                      screenWidth: screenWidth),
                                  _buildTextField(
                                    label: "Pincode",
                                    onChanged: (value) => pincode = value,
                                    keyboardType: TextInputType.number,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Country",
                                    value: country.isNotEmpty ? country : null,
                                    items: countryOptions,
                                    onChanged: (value) =>
                                        setState(() => country = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "State",
                                    value: state.isNotEmpty ? state : null,
                                    items: stateOptions,
                                    onChanged: (value) =>
                                        setState(() => state = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "District",
                                    value:
                                        district.isNotEmpty ? district : null,
                                    items: districtOptions,
                                    onChanged: (value) =>
                                        setState(() => district = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "City",
                                    value: city.isNotEmpty ? city : null,
                                    items: cityOptions,
                                    onChanged: (value) =>
                                        setState(() => city = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Data Source",
                                    value: dataSource.isNotEmpty
                                        ? dataSource
                                        : null,
                                    items: masterDataState.dataSources
                                        .map((item) => item.dataSourceName)
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => dataSource = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                      label: "Birth Day",
                                      onChanged: (value) => birthDay = value,
                                      screenWidth: screenWidth),
                                  _buildTextField(
                                      label: "Anniversary",
                                      onChanged: (value) => anniversary = value,
                                      screenWidth: screenWidth),
                                  _buildSectionHeader(
                                      title: "Subject and Class Details",
                                      icon: Icons.book,
                                      screenWidth: screenWidth),
                                  Table(
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300),
                                    columnWidths: const {
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(3),
                                      2: FlexColumnWidth(3),
                                      3: FlexColumnWidth(2),
                                      4: FlexColumnWidth(1)
                                    },
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                            color: Colors.yellow.shade100),
                                        children: [
                                          _buildTableHeader(
                                              "S.No", screenWidth),
                                          _buildTableHeader(
                                              "Subject Name", screenWidth),
                                          _buildTableHeader(
                                              "Class Name", screenWidth),
                                          _buildTableHeader(
                                              "Decision Maker", screenWidth),
                                          _buildTableHeader(
                                              "Action", screenWidth),
                                        ],
                                      ),
                                      ...subjectClassData
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        Map<String, String> row = entry.value;
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(
                                                  screenWidth * 0.02),
                                              child: Text(
                                                  (index + 1).toString(),
                                                  style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.030),
                                                  textAlign: TextAlign.center),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(
                                                  screenWidth * 0.01),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value:
                                                    row['subject']!.isNotEmpty
                                                        ? row['subject']
                                                        : null,
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                items: masterDataState.subjects
                                                    .map((subject) =>
                                                        DropdownMenuItem<
                                                                String>(
                                                            value: subject
                                                                .subjectName,
                                                            child: Text(subject
                                                                .subjectName)))
                                                    .toList(),
                                                onChanged: (value) => setState(
                                                    () =>
                                                        subjectClassData[index]
                                                                ['subject'] =
                                                            value!),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(
                                                  screenWidth * 0.02),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value: row['class']!.isNotEmpty
                                                    ? row['class']
                                                    : null,
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                items: masterDataState.classes
                                                    .map((classItem) =>
                                                        DropdownMenuItem<
                                                                String>(
                                                            value: classItem
                                                                .className,
                                                            child: Text(classItem
                                                                .className)))
                                                    .toList(),
                                                onChanged: (value) => setState(
                                                    () =>
                                                        subjectClassData[index]
                                                            ['class'] = value!),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(
                                                  screenWidth * 0.02),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value: row['decisionMaker']!
                                                        .isNotEmpty
                                                    ? row['decisionMaker']
                                                    : null,
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                items: ['Yes', 'No']
                                                    .map((decision) =>
                                                        DropdownMenuItem<
                                                                String>(
                                                            value: decision,
                                                            child:
                                                                Text(decision)))
                                                    .toList(),
                                                onChanged: (value) => setState(
                                                    () => subjectClassData[
                                                                index]
                                                            ['decisionMaker'] =
                                                        value!),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(
                                                  screenWidth * 0.02),
                                              child: IconButton(
                                                icon: Icon(Icons.add_circle,
                                                    color: Colors.blue,
                                                    size: screenWidth * 0.06),
                                                onPressed: _addSubjectClassRow,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                  SizedBox(height: screenWidth * 0.08),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          final teacherContact = {
                                            'primaryContact': primaryContact,
                                            'contactStatus': contactStatus,
                                            'salutation': salutation,
                                            'firstName': firstName,
                                            'lastName': lastName,
                                            'designation': designation,
                                            'emailId': emailId,
                                            'mobileNumber': mobileNumber,
                                            'address': address,
                                            'pincode': pincode,
                                            'country': country,
                                            'state': state,
                                            'district': district,
                                            'city': city,
                                            'dataSource': dataSource,
                                            'birthDay': birthDay,
                                            'anniversary': anniversary,
                                            'subjectClassData':
                                                subjectClassData,
                                          };
                                          // Since there's no direct update/submit method in the new provider,
                                          // you might need to implement a custom submission logic here.
                                          // For now, we'll just simulate a success message.
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Teacher contact data prepared for submission'),
                                                backgroundColor: Colors.blue),
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenWidth * 0.04),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                      ),
                                      child: Text(
                                        "Submit",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          if (masterDataState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(masterDataState.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title,
      required IconData icon,
      required double screenWidth}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.03, horizontal: screenWidth * 0.04),
      margin: EdgeInsets.only(bottom: screenWidth * 0.025),
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: screenWidth * 0.06),
          SizedBox(width: screenWidth * 0.025),
          Text(title,
              style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2)),
          contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, vertical: screenWidth * 0.035),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2)),
          contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04, vertical: screenWidth * 0.035),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item,
                    style: TextStyle(
                        fontSize: screenWidth * 0.04, color: Colors.black87))))
            .toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down,
            color: Colors.blue, size: screenWidth * 0.07),
      ),
    );
  }

  Widget _buildTableHeader(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: Text(title,
          style: TextStyle(
              fontSize: screenWidth * 0.030,
              fontWeight: FontWeight.bold,
              color: Colors.black),
          textAlign: TextAlign.center),
    );
  }
}
