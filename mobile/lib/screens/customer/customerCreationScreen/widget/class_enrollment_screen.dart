import 'package:dart_crm/providers/auth_provider.dart'; // Assuming this exists
import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';
import 'package:dart_crm/screens/customer/customerCreationScreen/widget/teacher_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming the new provider code is in a separate file and imported here
// import 'package:dart_crm/providers/customerProvider/customer_entry_master_provider.dart';

class ClassEnrollmentScreen extends ConsumerStatefulWidget {
  const ClassEnrollmentScreen({super.key});

  @override
  ConsumerState<ClassEnrollmentScreen> createState() =>
      _ClassEnrollmentScreenState();
}

class _ClassEnrollmentScreenState extends ConsumerState<ClassEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, int> enrollments = {};

  @override
  void initState() {
    super.initState();
    // Initialize enrollments using the provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masterData = ref.read(customerEntryMasterProvider);
      setState(() {
        enrollments = Map.fromIterable(masterData.classes,
            key: (e) => e.className as String, value: (e) => 0);
      });
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
        title: Text("Class Enrollment",
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
                                      title: "Class Enrollment",
                                      icon: Icons.class_,
                                      screenWidth: screenWidth),
                                  ...masterDataState.classes.map((classItem) {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            label:
                                                "Class ${classItem.className} *",
                                            onChanged: (value) => enrollments[
                                                    classItem.className] =
                                                int.tryParse(value) ?? 0,
                                            validator: (value) => value!.isEmpty
                                                ? 'Required'
                                                : null,
                                            keyboardType: TextInputType.number,
                                            screenWidth: screenWidth,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.04),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    );
                                  }).toList(),
                                  SizedBox(height: screenWidth * 0.08),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          // Placeholder for submission logic
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Class enrollments prepared for submission'),
                                                backgroundColor: Colors.blue),
                                          );
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const TeacherContactScreen()));
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
        initialValue: '0',
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
}
