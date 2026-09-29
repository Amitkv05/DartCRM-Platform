import 'package:dart_crm/screens/samplingScreen/request_screen/self_stock_sampling_screen/widget/richText_widget.dart';
import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final int wordLimit;
  final String? errorText;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.isRequired,
    required this.wordLimit,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLines: label == 'Transport Official Address' ? 3 : 2,
          maxLength: wordLimit > 0 ? wordLimit * 5 : null,
          decoration: RichtextWidget.getInputDecoration(
            label: label,
            isMandatory: isRequired,
          ),
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
