import 'package:dart_crm/providers/auth_provider.dart'; // Assuming this exists
import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';
import 'package:dart_crm/screens/customer/customerCreationScreen/widget/class_enrollment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming the new provider code is in a separate file and imported here
// import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';

class SchoolDetailsScreen extends ConsumerStatefulWidget {
  const SchoolDetailsScreen({super.key});

  @override
  ConsumerState<SchoolDetailsScreen> createState() =>
      _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends ConsumerState<SchoolDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String board = '';
  String chainSchool = '';
  int startClassId = 0;
  int endClassId = 0;
  String mediumInstruction = '';
  String ranking = '';
  int samplingMonth = 0;
  int decisionMonth = 0;
  String purchaseMode = '';
  String keyCustomer = 'N';
  String customerStatus = 'Active';
  String panNumber = '';
  String gstNumber = '';
  String accountableExecutive = '';

  final List<String> rankingOptions = ['High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    final masterDataState = ref.watch(customerEntryMasterProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Text("School Details",
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
                                      title: "School Details",
                                      icon: Icons.school,
                                      screenWidth: screenWidth),
                                  _buildDropdownField(
                                    label: "Board *",
                                    value: board.isNotEmpty ? board : null,
                                    items: masterDataState.boards
                                        .map((item) => item.boardName)
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => board = value!),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Chain School",
                                    value: chainSchool.isNotEmpty
                                        ? chainSchool
                                        : null,
                                    items: masterDataState.chainSchools
                                        .map((item) => item.chainSchoolName)
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => chainSchool = value!),
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Start Class *",
                                    value: startClassId != 0
                                        ? masterDataState
                                            .classes[startClassId].className
                                        : null,
                                    items: masterDataState.classes
                                        .map((item) => item.className)
                                        .toList(),
                                    onChanged: (value) => setState(() =>
                                        startClassId = masterDataState.classes
                                            .indexWhere((item) =>
                                                item.className == value)),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "End Class *",
                                    value: endClassId != 0
                                        ? masterDataState
                                            .classes[endClassId].className
                                        : null,
                                    items: masterDataState.classes
                                        .map((item) => item.className)
                                        .toList(),
                                    onChanged: (value) => setState(() =>
                                        endClassId = masterDataState.classes
                                            .indexWhere((item) =>
                                                item.className == value)),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildTextField(
                                    label: "Medium *",
                                    onChanged: (value) =>
                                        mediumInstruction = value,
                                    validator: (value) =>
                                        value!.isEmpty ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Ranking *",
                                    value: ranking.isNotEmpty ? ranking : null,
                                    items: rankingOptions,
                                    onChanged: (value) =>
                                        setState(() => ranking = value!),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Sampling Month *",
                                    value: samplingMonth != 0
                                        ? masterDataState
                                            .months[samplingMonth - 1].name
                                        : null,
                                    items: masterDataState.months
                                        .map((item) => item.name)
                                        .toList(),
                                    onChanged: (value) => setState(() =>
                                        samplingMonth = masterDataState.months
                                                .indexWhere((item) =>
                                                    item.name == value) +
                                            1),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  _buildDropdownField(
                                    label: "Decision Month *",
                                    value: decisionMonth != 0
                                        ? masterDataState
                                            .months[decisionMonth - 1].name
                                        : null,
                                    items: masterDataState.months
                                        .map((item) => item.name)
                                        .toList(),
                                    onChanged: (value) => setState(() =>
                                        decisionMonth = masterDataState.months
                                                .indexWhere((item) =>
                                                    item.name == value) +
                                            1),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  Text("Purchase Mode *",
                                      style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          color: Colors.black87)),
                                  Row(
                                    children: masterDataState.purchaseModes
                                        .map((mode) => Expanded(
                                              child: RadioListTile<String>(
                                                title: Text(mode.modeName,
                                                    style: TextStyle(
                                                        fontSize: screenWidth *
                                                            0.04)),
                                                value: mode.modeName,
                                                groupValue: purchaseMode,
                                                onChanged: (value) => setState(
                                                    () =>
                                                        purchaseMode = value!),
                                                activeColor: Colors.green,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  _buildSectionHeader(
                                      title: "Additional Details",
                                      icon: Icons.info,
                                      screenWidth: screenWidth),
                                  _buildTextField(
                                      label: "PAN Number",
                                      onChanged: (value) => panNumber = value,
                                      screenWidth: screenWidth),
                                  _buildTextField(
                                      label: "GST Number",
                                      onChanged: (value) => gstNumber = value,
                                      screenWidth: screenWidth),
                                  _buildSectionHeader(
                                      title: "Customer Status",
                                      icon: Icons.info,
                                      screenWidth: screenWidth),
                                  const SizedBox(height: 10),
                                  Text("Key Customer *",
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
                                          groupValue: keyCustomer,
                                          onChanged: (value) => setState(
                                              () => keyCustomer = value!),
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
                                          groupValue: keyCustomer,
                                          onChanged: (value) => setState(
                                              () => keyCustomer = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text("Customer Status *",
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
                                          groupValue: customerStatus,
                                          onChanged: (value) => setState(
                                              () => customerStatus = value!),
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
                                          groupValue: customerStatus,
                                          onChanged: (value) => setState(
                                              () => customerStatus = value!),
                                          activeColor: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDropdownField(
                                    label: "Accountable Executive *",
                                    value: accountableExecutive.isNotEmpty
                                        ? accountableExecutive
                                        : null,
                                    items: masterDataState.accountableExecutives
                                        .map((item) => item.executiveName)
                                        .toList(),
                                    onChanged: (value) => setState(
                                        () => accountableExecutive = value!),
                                    validator: (value) =>
                                        value == null ? 'Required' : null,
                                    screenWidth: screenWidth,
                                  ),
                                  SizedBox(height: screenWidth * 0.08),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          final schoolDetails = {
                                            'board': board,
                                            'chainSchool': chainSchool,
                                            'startClassId': startClassId,
                                            'endClassId': endClassId,
                                            'mediumInstruction':
                                                mediumInstruction,
                                            'ranking': ranking,
                                            'samplingMonth': samplingMonth,
                                            'decisionMonth': decisionMonth,
                                            'purchaseMode': purchaseMode,
                                            'keyCustomer': keyCustomer,
                                            'customerStatus': customerStatus,
                                            'panNumber': panNumber,
                                            'gstNumber': gstNumber,
                                            'accountableExecutive':
                                                accountableExecutive,
                                          };
                                          // Placeholder for submission logic
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'School details prepared for submission'),
                                                backgroundColor: Colors.blue),
                                          );
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ClassEnrollmentScreen()));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenWidth * 0.04),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        "Next",
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
              borderSide: const BorderSide(color: Colors.grey, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1)),
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
              borderSide: const BorderSide(color: Colors.grey, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1)),
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
            color: Colors.grey, size: screenWidth * 0.07),
      ),
    );
  }
}
