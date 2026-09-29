import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/schoolUpdate/StateResponse.dart';
import 'ValueModel.dart';
import 'color_constants.dart';
import 'list_bottom_sheet.dart';

class FORMAT {
  static const int ALL = 1;
  static const int PHONE = 2;
  static const int EMAIL = 3;
  static const int DIGIT = 4;
  static const int CAP = 5;
}

class WidgetUtils {
  static Widget widgetGetErrorUI(StreamController<String> stream) {
    return StreamBuilder<String>(
      stream: stream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.isNotEmpty == true) {
          String error = snapshot.data ?? '';
          return Container(child: WidgetUtils.getError(error));
        } else {
          return SizedBox(height: 7);
        }
      },
    );
  }

  static Widget getError(String str) {
    return Text(
      str,
      style: const TextStyle(
          fontSize: 11, color: AppColor.color_01162B, fontWeight: FontWeight.normal),
    );
  }

  static void hideKeyboard(context) {
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  static launchScreenRemoveAll(context, screen) {
    Future.delayed(Duration.zero, () {
      Navigator.pushAndRemoveUntil<dynamic>(
        context,
        MaterialPageRoute<dynamic>(builder: (BuildContext context) => screen),
        (route) => false, //if you want to disable back feature set to false
      );
    });
  }

  static launchScreen(context, screen) {
    hideKeyboard(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static formatPhone() {
    return [
      FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
    ];
  }

  void identificationDialog(
      BuildContext context, String title, List<StateResponse>? resourceList,
      {required Function(StateResponse? data) onSelected}) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ListBottomSheet(
          title: title,
          resourceList: resourceList,
          onTypeClick: (data, isClear) async {
            Navigator.pop(context);
            onSelected(data);
          },
        );
      },
    );
  }
}
