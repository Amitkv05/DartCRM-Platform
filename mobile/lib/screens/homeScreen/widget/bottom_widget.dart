import 'package:flutter/material.dart';

class bottomWidget extends StatelessWidget {
  const bottomWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        '© 2024 Avant WebTech Pvt. Ltd.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}
