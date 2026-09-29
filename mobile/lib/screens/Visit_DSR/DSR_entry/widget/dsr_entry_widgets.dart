import 'package:dart_crm/models/planList/dsr_entry_model.dart';
import 'package:dart_crm/models/planList/eProduct_details.dart';
import 'package:dart_crm/models/planList/eproduct_list.dart';
import 'package:dart_crm/models/planList/plan.dart';
import 'package:dart_crm/models/shipment_model.dart';
import 'package:dart_crm/models/ship_to.dart';
import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../edit/utils/color_constants.dart';

class DSREntryWidgets {
  // Common InputDecoration for consistent styling
  static InputDecoration getInputDecoration({
    required String label,
    bool isMandatory = false,
    Color borderColor = Colors.blue,
    EdgeInsets contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  }) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
          children: [
            if (isMandatory)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      contentPadding: contentPadding,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static String formatAddress2(String input) {
    var d = input
        .replaceAll('\\r\\n', '\n') // Handle Windows line endings
        .split('\\n') // Split into lines
        .map((line) =>
            line.trim().replaceAll(RegExp(r',$'), '')) // Trim and remove trailing commas
        .where((line) => line.isNotEmpty) // Remove empty lines
        .join('\n');
    return d;
  }

  static Widget buildCustomerCard(Plan plan) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: TColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.customerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: TColors.textPrimary,
                ),
              ),
              Text(
                formatAddress2(plan.address),
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 2),
              if (plan.contact.isNotEmpty)
                Text(
                  'Contact: ${plan.contact}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
              if (plan.emailId.isNotEmpty)
                Text(
                  'Email: ${plan.emailId}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
              if (plan.phone.isNotEmpty)
                Text(
                  'Mobile: ${plan.phone}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDateField(
    TextEditingController controller,
    BuildContext context, {
    required List<AllowedDateRange> allowedDateRanges,
    required Function(DateTime) onDateSelected,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final validRanges = allowedDateRanges
        .where((range) => range.from != null && range.to != null)
        .toList();

    final fallbackFrom = today.subtract(const Duration(days: 3));
    final firstDate = validRanges.isEmpty
        ? fallbackFrom
        : validRanges
            .map((range) => range.from!)
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final rangeLastDate = validRanges.isEmpty
        ? today
        : validRanges
            .map((range) => range.to!)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final lastDate = rangeLastDate.isAfter(today) ? today : rangeLastDate;

    bool isAllowed(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      if (d.isAfter(today)) return false;
      if (validRanges.isEmpty) {
        return !d.isBefore(fallbackFrom) && !d.isAfter(today);
      }
      return validRanges.any((range) => range.contains(d));
    }

    DateTime initialDate = today;
    if (!isAllowed(initialDate)) {
      final candidates = validRanges
          .map((range) => range.to!)
          .where((date) => !date.isAfter(today))
          .toList()
        ..sort();
      initialDate = candidates.isNotEmpty ? candidates.last : firstDate;
    }

    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          selectableDayPredicate: isAllowed,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                datePickerTheme: DatePickerThemeData(
                  headerBackgroundColor: TColors.icon,
                  headerForegroundColor: Colors.white,
                  dayStyle: TextStyle(fontSize: 16),
                  yearStyle: TextStyle(fontSize: 16),
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) onDateSelected(pickedDate);
      },
      decoration: getInputDecoration(label: 'Visit Date', isMandatory: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please select a visit date';
        final selectedDate = DateTime.tryParse(value);
        if (selectedDate == null || !isAllowed(selectedDate)) {
          return 'Visit date is outside the allowed date range';
        }
        return null;
      },
    );
  }

  static Widget buildDropdownField({
    required String label,
    required List<String> options,
    required Function(String?) onChanged,
    bool isMandatory = false,
  }) {
    return DropdownButtonFormField<String>(
      decoration: getInputDecoration(
        label: label,
        isMandatory: isMandatory,
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select'),
        ),
        ...options.map((option) => DropdownMenuItem(value: option, child: Text(option))),
      ],
      onChanged: onChanged,
      validator: isMandatory
          ? (value) => value == null || value == 'Select' ? 'Please select $label' : null
          : null,
    );
  }

  static Widget buildPersonMetField(
    List<PersonMet> personMet,
    int? selectedCustomerContactId,
    bool personMetMandatory,
    Function(int?, String?) onChanged,
  ) {
    if (personMet.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: getInputDecoration(
              label: 'Person Met',
              isMandatory: personMetMandatory,
            ),
            child: const Text(
              'No customer contacts available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Optional. You can submit the visit without selecting a Person Met.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    return DropdownButtonFormField<int>(
      value: selectedCustomerContactId,
      decoration: getInputDecoration(
        label: 'Person Met',
        isMandatory: personMetMandatory,
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Select'),
        ),
        ...personMet.map((person) {
          return DropdownMenuItem<int>(
            value: person.customerContactId,
            child: Text(person.customerContactName),
            onTap: () => onChanged(person.customerContactId, person.customerContactName),
          );
        }).toList(),
      ],
      onChanged: (value) {
        if (value != null) {
          final selectedPerson =
              personMet.firstWhere((person) => person.customerContactId == value);
          onChanged(value, selectedPerson.customerContactName);
        } else {
          onChanged(null, null);
        }
      },
      validator: personMetMandatory
          ? (value) => value == null ? 'Please select a Person Met' : null
          : null,
    );
  }

  static Widget buildAcademicSessionField(
    List<AcademicData>? academicList,
    int? selectedAcademicSessionId,
    bool personMetMandatory,
    Function(int?, String?) onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: selectedAcademicSessionId,
      decoration: getInputDecoration(
        label: 'Academic Session',
        isMandatory: personMetMandatory,
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Select'),
        ),
        ...academicList!.map((person) {
          return DropdownMenuItem<int>(
            value: person.AcademicSessionId,
            child: Text(person.AcademicSession),
            onTap: () => onChanged(person.AcademicSessionId, person.AcademicSession),
          );
        }).toList(),
      ],
      onChanged: (value) {
        if (value != null) {
          final selectedPerson =
              academicList!.firstWhere((person) => person.AcademicSessionId == value);
          onChanged(value, selectedPerson.AcademicSession);
        } else {
          onChanged(null, null);
        }
      },
      validator: personMetMandatory
          ? (value) => value == null ? 'Please select an academic session' : null
          : null,
    );
  }

  static Widget buildAddressField(
    TextEditingController controller,
    bool addressEntryMandatory,
  ) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      decoration: getInputDecoration(
        label: 'Visit Address',
        isMandatory: addressEntryMandatory,
      ),
      validator: addressEntryMandatory
          ? (value) =>
              value == null || value.isEmpty ? 'Please enter the visit address' : null
          : null,
    );
  }

  static Widget buildRadioButtons({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 20, color: Colors.black),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                activeColor: TColors.icon,
                title: const Text(
                  "Yes",
                  style: TextStyle(
                      fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600),
                ),
                value: true,
                groupValue: value,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => onChanged(val!),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                activeColor: TColors.icon,
                title: const Text(
                  "No",
                  style: TextStyle(
                      fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600),
                ),
                value: false,
                groupValue: value,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => onChanged(val!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildFollowUpActionCard(int index, FollowUpAction followUp,
      {required Function(FollowUpAction d) onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 10, right: 5, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColors.icon),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'S.No ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Spacer(
                flex: 1,
              ),
              IconButton(
                onPressed: () {
                  onDelete(followUp);
                },
                icon: Icon(Icons.delete),
              )
            ],
          ),
          Row(
            children: [
              Text(
                "Department Name:",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                " ${followUp.executive}",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "Executive:",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                " ${followUp.executive}",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "Action Date:",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
              ),
              Text(
                " ${followUp.actionDate}",
                style: TextStyle(
                    fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildForDocument(int index, DocumentSaveData document,
      {required Function(DocumentSaveData dr) onDelete}) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
      child: Container(
        padding: EdgeInsets.only(
          left: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black,
            width: 0.4,
          ),
          // boxShadow: [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Document: ',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          maxLines: 1,
                          document.documentName,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'File: ',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          maxLines: 1,
                          document.fileName,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
                icon: Icon(Icons.clear, color: Colors.red),
                onPressed: () {
                  onDelete(document);
                }),
          ],
        ),
      ),
    );
  }

  static Widget buildProductAddCard(int index, EProductData followUp,
      {required Function(EProductData d) onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColors.icon),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "S.No ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Spacer(
                flex: 1,
              ),
              IconButton(
                onPressed: () {
                  onDelete(followUp);
                },
                icon: Icon(Icons.delete),
              )
            ],
          ),
          Text(
            "Brand Name:",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          Text(
            "${followUp.brandName}",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "Product Name:",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          Text(
            "${followUp.productName}",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "Class Name:",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          Text(
            " ${followUp.className}",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "Current Sales Stage:",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          Text(
            "${followUp.currentSalesStageName}",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            "Prospect:",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
          ),
          Text(
            "${followUp.prospectName}",
            style:
                TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  static Widget buildAddFollowUpAction(
    BuildContext context,
    List<Department> departments,
    String? selectedDepartmentId,
    List<Executive> executives,
    String? selectedExecutive,
    bool isLoadingExecutives,
    TextEditingController actionDateController,
    TextEditingController actionTextController,
    TextEditingController visitDateController,
    int? academicSessionId, {
    required Function(String?) onDepartmentChanged,
    required Function(String?) onExecutiveChanged,
    required Function(DateTime) onActionDateSelected,
    required VoidCallback onAddAction,
  }) {
    DateTime firstDate;
    try {
      firstDate = visitDateController.text.isNotEmpty
          ? DateTime.parse(visitDateController.text)
          : DateTime.now();
    } catch (e) {
      firstDate = DateTime.now();
    }

    DateTime sessionEndDate = academicSessionId == null
        ? DateTime(2026, 3, 31)
        : academicSessionId == 1
            ? DateTime(2025, 3, 31)
            : DateTime(2026, 3, 31);

    DateTime lastDate = sessionEndDate.isBefore(firstDate)
        ? firstDate.add(Duration(days: 365))
        : sessionEndDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: TColors.icon),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Follow Up Action",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          const Divider(
            color: Colors.grey,
          ),
          SizedBox(
            height: 10,
          ),
          DropdownButtonFormField<String>(
            value: selectedDepartmentId,
            decoration: getInputDecoration(
              label: 'Department',
              isMandatory: true,
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("Select"),
              ),
              ...departments.map((dept) {
                return DropdownMenuItem<String>(
                  value: dept.id.toString(),
                  child: Text(
                    "${dept.executiveDepartmentName}",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ],
            onChanged: onDepartmentChanged,
            hint: departments.isEmpty
                ? const Text("No departments available")
                : const Text("Select a department"),
            validator: (value) => value == null ? 'Please select a department' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedExecutive,
            decoration: getInputDecoration(
              label: 'Executive',
              isMandatory: true,
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("Select"),
              ),
              ...executives.map((exec) => DropdownMenuItem<String>(
                    value: exec.name,
                    child: Text(
                      exec.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: selectedDepartmentId == null ? null : onExecutiveChanged,
            hint: isLoadingExecutives
                ? const Text("Loading executives...")
                : selectedDepartmentId == null
                    ? const Text("Select a department first")
                    : executives.isEmpty
                        ? const Text("No executives available")
                        : const Text("Select an executive"),
            validator: (value) => value == null ? 'Please select an executive' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: actionDateController,
            readOnly: true,
            decoration: getInputDecoration(
              label: 'Action Date',
              isMandatory: true,
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: firstDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      datePickerTheme: DatePickerThemeData(
                        headerBackgroundColor: TColors.icon,
                        headerForegroundColor: Colors.white,
                        dayStyle: TextStyle(fontSize: 16),
                        yearStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                actionDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                onActionDateSelected(pickedDate);
              }
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'Please select an action date' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: actionTextController,
            maxLines: 2,
            decoration: getInputDecoration(
              label: 'Action Text',
              isMandatory: true,
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter action text' : null,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onAddAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.buttonPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Add Action",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDocumentUpload({
    required VoidCallback? onUpload,
    bool isUploading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Document Upload",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: isUploading ? null : onUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.buttonPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  "Upload",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  static Future<void> showDocumentUploadDialog(
    BuildContext context, {
    required Future<void> Function() onCaptureImage,
    required Future<void> Function() onPickFile,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Document Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Capture Image"),
                onTap: () async {
                  Navigator.of(context).pop();
                  await onCaptureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text("Pick File"),
                onTap: () async {
                  Navigator.of(context).pop();
                  await onPickFile();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  static Widget buildFeedbackField(
    TextEditingController controller,
    bool feedbackMandatory,
    int feedbackMaxLength,
  ) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      maxLength: feedbackMaxLength,
      decoration: getInputDecoration(
        label: 'Visit Feedback',
        isMandatory: feedbackMandatory,
      ),
      validator: feedbackMandatory
          ? (value) => value == null || value.isEmpty ? 'Please enter feedback' : null
          : null,
    );
  }

  static Widget buildShipmentFields(
    bool isLoadingShipmentData,
    int? selectedCustomerContactId,
    ShipmentModeResponse? shipmentModeResponse,
    String? selectedShipmentMode,
    ShipToResponse? shipToResponse,
    String? selectedShipTo, {
    required Function(String?) onShipmentModeChanged,
    required Function(String?) onShipToChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Shipment Details",
          style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 10),
        if (isLoadingShipmentData)
          const Center(child: CircularProgressIndicator())
        else if (selectedCustomerContactId == null)
          const Text(
            "Please select a Person Met to load shipment details",
            style: TextStyle(color: Colors.red),
          )
        else ...[
          DropdownButtonFormField<String>(
            value: selectedShipmentMode,
            decoration: getInputDecoration(
              label: 'Shipment Mode',
              isMandatory: true,
            ),
            isExpanded: true,
            items: shipmentModeResponse?.shipmentModes
                .map((mode) => DropdownMenuItem<String>(
                      value: mode.shipmentModeName,
                      child: Text(mode.shipmentModeName),
                    ))
                .toList(),
            onChanged: onShipmentModeChanged,
            validator: (value) => value == null ? 'Please select a Shipment Mode' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedShipTo,
            decoration: getInputDecoration(
              label: 'Ship To',
              isMandatory: true,
            ),
            isExpanded: true,
            items: shipToResponse?.shipTo
                .map((shipTo) => DropdownMenuItem<String>(
                      value: shipTo.shipToName,
                      child: Text(shipTo.shipToName),
                    ))
                .toList(),
            onChanged: onShipToChanged,
            validator: (value) => value == null ? 'Please select a Ship To' : null,
          ),
        ],
      ],
    );
  }

  static Widget buildSubmitButton({
    required VoidCallback onSubmit,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.buttonPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          "Submit DSR Entry",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  static Widget buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
