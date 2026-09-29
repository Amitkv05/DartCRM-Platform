import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/richText_widget.dart';
import 'package:flutter/material.dart';

class DropdownRow extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final List<String>? displayItems;
  final bool isRequired;

  const DropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.displayItems,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure "Select" is included in the items list if not already present
    final modifiedItems =
        items.contains('Select') ? items : ['Select', ...items];
    // Determine the default value: use "Select" if value is null or not in items
    final selectedValue =
        value != null && items.contains(value) ? value : 'Select';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value:
              modifiedItems.contains(selectedValue) ? selectedValue : 'Select',
          decoration: RichtextWidget.getInputDecoration(
            label: label,
            isMandatory: isRequired,
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          items: modifiedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final itemValue = entry.value;
            final displayValue =
                displayItems != null && index < displayItems!.length
                    ? displayItems![index]
                    : itemValue;
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
