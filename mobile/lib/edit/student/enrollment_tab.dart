import 'package:dart_crm/edit/model/board/Classes.dart';
import 'package:dart_crm/edit/model/school/EnrolmentList.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:dart_crm/edit/utils/color_constants.dart';
import 'package:flutter/material.dart';

import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/StateResponse.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/widgetUtils.dart';

class EnrollmentTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const EnrollmentTab({super.key, required this.apiData, required this.type});

  @override
  State<EnrollmentTab> createState() => _EnrollmentTabState();
}

class _EnrollmentTabState extends State<EnrollmentTab>
    with AutomaticKeepAliveClientMixin {
  int totalEnrolment = 0;

  String? selectedStartClass, selectedEndClass;
  List<StateResponse>? modelStartClass = [];
  List<StateResponse>? modelEndClass = [];

  @override
  void initState() {
    super.initState();

    // Always build one canonical class list from the class master. The legacy
    // code reused a global list and could show duplicate rows (for example
    // Class 9-12 twice). Existing enrollment values are merged by ClassNumId.
    final existingByClass = <int, EnrolmentList>{};
    for (final item in widget.apiData?.enrolmentList ?? <EnrolmentList>[]) {
      final id = item.classNumId;
      if (id != null) existingByClass[id] = item;
    }

    final merged = <EnrolmentList>[];
    final seen = <int>{};
    for (final item in BOARD_DATA?.classes ?? <Classes>[]) {
      final id = item.classNumId;
      if (id == null || !seen.add(id)) continue;
      final existing = existingByClass[id];
      merged.add(
        EnrolmentList(
          classNumId: id,
          className: item.className,
          enrolValue: existing?.enrolValue ?? 0,
          totalEnrolment: existing?.totalEnrolment ?? 0,
        ),
      );
    }

    // Safe fallback for local/offline master-data failures.
    classes = merged.isNotEmpty
        ? merged
        : [
            EnrolmentList(classNumId: -3, className: 'Nry', enrolValue: 0, totalEnrolment: 0),
            EnrolmentList(classNumId: -2, className: 'LKG', enrolValue: 0, totalEnrolment: 0),
            EnrolmentList(classNumId: -1, className: 'UKG', enrolValue: 0, totalEnrolment: 0),
            for (var i = 1; i <= 12; i++)
              EnrolmentList(classNumId: i, className: '$i', enrolValue: 0, totalEnrolment: 0),
          ];

    modelStartClass = [];
    modelEndClass = [];
    for (final item in classes ?? <EnrolmentList>[]) {
      final id = item.classNumId;
      if (id == null) continue;
      final option = StateResponse()
        ..text = item.className
        ..value = id;
      modelStartClass!.add(option);
      modelEndClass!.add(StateResponse()
        ..text = item.className
        ..value = id);
    }

    final startId = UPDATED_REQ.startClassId;
    final endId = UPDATED_REQ.endClassId;
    for (final item in classes ?? <EnrolmentList>[]) {
      if (item.classNumId == startId) selectedStartClass = item.className;
      if (item.classNumId == endId) selectedEndClass = item.className;
    }

    updateValue();
  }

  void updateValue() {
    var startClassId = UPDATED_REQ.startClassId;
    var endClassId = UPDATED_REQ.endClassId;

    totalEnrolment = 0;

    if (classes != null && classes?.isNotEmpty == true) {
      classes?.forEach((c) {
        var start = startClassId ?? 0;
        var end = endClassId ?? 0;
        var classNumId = c.classNumId ?? 0;
        c.readOnly = !(classNumId >= start && classNumId <= end);
        if (c.readOnly == false) {
          var e = c.enrolValue ?? 0;
          totalEnrolment = totalEnrolment + e;
        }
      });
      setClassData();
      setState(() {});
    }
  }

  void total() {
    if (classes != null && classes?.isNotEmpty == true) {
      totalEnrolment = 0;
      classes?.forEach((c) {
        if (c.readOnly == false) {
          var e = c.enrolValue ?? 0;
          totalEnrolment = totalEnrolment + e;
        }
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        ClickButtonWidget(
          field: 'Start Class',
          required: '*',
          value: selectedStartClass,
          resourceList: modelStartClass,
          onSelected: (data) {
            selectedStartClass = data?.text;
            UPDATED_REQ.startClassId = data?.value;
            selectedEndClass = null;
            UPDATED_REQ.endClassId = -10;
            updateValue();
          },
        ),
        ClickButtonWidget(
          field: 'End Class',
          required: '*',
          value: selectedEndClass,
          resourceList: modelEndClass,
          onSelected: (data) {
            var s = UPDATED_REQ.startClassId ?? 0;
            var e = data?.value ?? 0;
            if (s > e) {
              AppUtils.showToast('Start Class must be before End Class');
            } else {
              UPDATED_REQ.endClassId = data?.value;
              selectedEndClass = data?.text;
              updateValue();
            }
          },
        ),
        SizedBox(
          height: 25,
        ),
        Container(
          height: 1,
          color: AppColor.black,
        ),
        SizedBox(
          height: 5,
        ),
        Builder(
          builder: (context) {
            final selectedClasses = (classes ?? <EnrolmentList>[])
                .where((item) => item.readOnly == false)
                .toList();
            if (selectedClasses.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Select Start Class and End Class to enter enrollment.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 0),
              scrollDirection: Axis.vertical,
              itemCount: selectedClasses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final c = selectedClasses[index];
                final value = c.enrolValue;
                final expectedText = value == null || value == 0 ? '' : '$value';
                if (c.editingController.text != expectedText) {
                  c.editingController.text = expectedText;
                }
                return AllFieldWidget(
                  controller: c.editingController,
                  preNode: null,
                  nextNode: null,
                  max: 5,
                  readOnly: false,
                  required: '*',
                  format: FORMAT.DIGIT,
                  field: 'Class ${c.className}',
                  onTypeChange: (value) {
                    c.enrolValue = int.tryParse(value);
                    total();
                    setClassData();
                  },
                );
              },
            );
          },
        ),
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Total Enrollment:  ',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.black),
            ),
            Text(
              '$totalEnrolment',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.black),
            ),
          ],
        ),
        SizedBox(
          height: 50,
        ),
      ],
    );
  }

  int getValue(String? s) {
    try {
      var d = int.parse(s?.trim() ?? '0');
      return d;
    } catch (e) {}

    return 0;
  }

  void setClassData() {
    if (classes != null && classes?.isNotEmpty == true) {
      String d = '';
      classes?.forEach((e) {
        if (e.readOnly == false) {
          var c1 = e.classNumId;
          var e1 = e.enrolValue;
          d = '$d<ClassName><ClassId>$c1</ClassId><Enrolment>$e1</Enrolment></ClassName>';
        }
      });
      UPDATED_REQ.xmlClassName = '<row_ClassName>$d</row_ClassName>';
    }
  }

  @override
  bool get wantKeepAlive => true;
}
