import 'package:flutter/material.dart';

import 'color_constants.dart';

class FillButtonWidget extends StatefulWidget {
  final Color bgColor;
  final String title;
  final double? fontSize;
  final double? height;
  final double? radius;
  final double? width;
  final VoidCallback onPressed;

  FillButtonWidget(
      {super.key,
      this.height = 50,
      this.width,
      this.radius = 10,
      this.fontSize = 15,
      this.bgColor = Colors.orange,
      required this.title,
      required this.onPressed});

  @override
  _FillButtonWidgetState createState() => _FillButtonWidgetState();
}

class _FillButtonWidgetState extends State<FillButtonWidget> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: widget.width ?? null,
      height: widget.height ?? 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.color_206bc4,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(widget.radius ?? 10)),
          ),
        ),
        onPressed: widget.onPressed,
        child: Text(
          widget.title,
          style: TextStyle(fontSize: widget.fontSize, color: AppColor.white),
        ),
      ),
    );
  }
}
