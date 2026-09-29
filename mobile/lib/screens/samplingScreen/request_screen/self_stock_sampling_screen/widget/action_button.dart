import 'package:dart_crm/util/constants/colors.dart';
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final bool Function() validateFields;

  const ActionButtons({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    required this.validateFields,
  });

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Confirm Submission',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
              'Are you sure you want to submit the self stock request?',
              style: TextStyle(color: Colors.grey[800])),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.buttonPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send, size: 20, color: Colors.white),
          label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TColors.buttonPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: isSubmitting
              ? null
              : () {
                  if (validateFields()) {
                    _showConfirmationDialog(context);
                  }
                },
        ),
      ],
    );
  }
}
