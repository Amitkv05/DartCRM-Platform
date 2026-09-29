import 'dart:collection';

import 'package:flutter/material.dart';

import '../../util/constants/colors.dart';
import '../model/school/AddSubject.dart';
import '../model/school/SchoolListResponse.dart';
import '../model/schoolUpdate/StateResponse.dart';
import '../model/teacher/ContactModel.dart';
import '../utils/AppUtils.dart';
import '../utils/add_more_drop_widget.dart';
import '../utils/all_field_widget.dart';
import '../utils/click_button_widget.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/message_field_widget.dart';
import '../utils/radio_tab.dart';
import '../utils/widgetUtils.dart';

class AddSubjectPage extends StatefulWidget {
  final Function callback;
  final SchoolListResponse? apiData;
  final List<AddSubject>? subjectListAdded;

  const AddSubjectPage(
      {super.key,
      required this.subjectListAdded,
      required this.callback,
      required this.apiData});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage>
    with SingleTickerProviderStateMixin {
  List<StateResponse> subjects = [];
  List<StateResponse>? classes = [];
  List<StateResponse> decisionMaker = [];
  String? selectedSubject;

  int? selectedSubjectId;
  int? selectedClassId;

  String? selectedMaker;

  Set<StateResponse> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onPostFrameCallback(context));
  }

  Set<StateResponse> sortByValue(Set<StateResponse> options) {
    try {
      final sortedList = options.toList()
        ..sort((a, b) => a.value!.compareTo(b.value!));
      return LinkedHashSet<StateResponse>.from(sortedList);
    } catch (e) {}
    return options;
  }

  onPostFrameCallback(BuildContext context) {
    BOARD_DATA?.subject?.forEach((e) {
      var s = StateResponse();
      s.text = e.subjectName;
      s.value = e.subjectId;
      subjects.add(s);
    });

    BOARD_DATA?.classes?.forEach((e) {
      var s = StateResponse();
      s.text = e.className;
      s.value = e.classNumId;
      classes?.add(s);
    });

    var p1 = StateResponse();
    p1.text = 'Y';
    p1.label = 'Yes';
    p1.value = 1;
    decisionMaker.add(p1);

    var p2 = StateResponse();
    p2.text = 'N';
    p2.label = 'No';
    p2.value = 2;
    decisionMaker.add(p2);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
            leading: BackButton(
              color: Colors.white, // Customize the back icon color
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FillButtonWidget(
                  height: 40,
                  width: 140,
                  title: 'Add Subject',
                  bgColor: AppColor.color_4285F4,
                  onPressed: () async {
                    if (selectedSubjectId == null ||
                        _selectedOptions.isEmpty ||
                        selectedMaker == null) {
                      print('selectedSubjectId $selectedSubjectId');
                      print('selectedSubjectId ${_selectedOptions.isEmpty}');
                      print('selectedMaker $selectedMaker');

                      AppUtils.showToast('* field is required');
                    } else {
                      AddSubject s = AddSubject();
                      s.name = selectedSubject;
                      s.nameId = selectedSubjectId;
                      List<StateResponse>? classes = [];

                      final sortedByValue = sortByValue(_selectedOptions);
                      for (var action in sortedByValue) {
                        classes.add(action);
                      }
                      s.classes = classes;
                      s.maker = selectedMaker;
                      widget.callback(s);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
            title: Text(
              'Add Subject',
              style: TextStyle(fontSize: 19, color: Colors.white),
            ),
            centerTitle: false,
            // Centers the title
            backgroundColor: TColors.warning),
        backgroundColor: AppColor.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[100]!, Colors.grey[50]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 15,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClickButtonWidget(
                    field: 'Subject Name',
                    required: '*',
                    value: selectedSubject,
                    resourceList: subjects,
                    onSelected: (data) {
                      selectedSubject = data?.text;
                      selectedSubjectId = data?.value;
                      bool isMatch = false;
                      if (widget.subjectListAdded != null &&
                          widget.subjectListAdded?.isNotEmpty == true) {
                        var d = widget.subjectListAdded;
                        for (var action in d!) {
                          if (selectedSubject == action.name) {
                            isMatch = true;
                          }
                        }
                      }
                      if (isMatch) {
                        AppUtils.showToast('Subject name is already added');
                      } else {
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Text(
                        'Classes',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '*',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.red),
                      ),
                    ],
                  ),
                  _widgetAddClasses(),
                  RadioTab(
                    size: 27,
                    field: 'Decision Maker',
                    selectedOption: null,
                    required: '*',
                    resource: decisionMaker,
                    callback: (value) {
                      selectedMaker = value?.label;
                      print('selectedMaker $selectedMaker');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _widgetAddClasses() {
    return classes == null || classes?.isEmpty == true
        ? SizedBox(
            height: 40,
          )
        : SizedBox(
            height: 170,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 4,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: classes!.map((option) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedOptions.contains(option)) {
                        _selectedOptions.remove(option);
                      } else {
                        _selectedOptions.add(option);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedOptions.contains(option),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedOptions.add(option);
                            } else {
                              _selectedOptions.remove(option);
                            }
                          });
                        },
                        visualDensity:
                            VisualDensity(horizontal: -4.0, vertical: -4.0),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      Expanded(
                          child: Text(
                        option.text ?? '',
                        style: TextStyle(fontSize: 14, color: AppColor.black),
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
  }
}
