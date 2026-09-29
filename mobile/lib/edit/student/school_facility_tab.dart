import 'dart:async';

import 'package:dart_crm/edit/utils/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../model/school/SchoolFacilityModel.dart';
import '../model/school/SchoolListResponse.dart';
import '../utils/AppUtils.dart';
import '../utils/check_tab.dart';

class SchoolFacilityTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const SchoolFacilityTab({super.key, required this.apiData, required this.type});

  @override
  State<SchoolFacilityTab> createState() => _SchoolFacilityTabState();
}

class _SchoolFacilityTabState extends State<SchoolFacilityTab>
    with AutomaticKeepAliveClientMixin {
  List<SchoolFacilityModel>? schoolFacility;
  Set<SchoolFacilityModel> _selectedOptions = {};

  @override
  void initState() {
    schoolFacility = widget.apiData?.schoolFacility;

    if (schoolFacility == null || schoolFacility?.isEmpty == true) {
      final List<Map<String, dynamic>> rawJson = [
        {
          "CustomerFacilityId": 1,
          "CustomerFacilityName": "Wifi",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 2,
          "CustomerFacilityName": "Lab",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 3,
          "CustomerFacilityName": "Kit Storage Space - Cabinet - Locker",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 4,
          "CustomerFacilityName": "Working Computers",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 5,
          "CustomerFacilityName": "Smart TV",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 6,
          "CustomerFacilityName": "Bluetooth Connectivity",
          "FacilityAvailable": "N"
        },
        {
          "CustomerFacilityId": 7,
          "CustomerFacilityName": "Projector",
          "FacilityAvailable": "N"
        }
      ];

      schoolFacility = rawJson.map((item) => SchoolFacilityModel.fromJson(item)).toList();
    }
    schoolFacility?.forEach((d) {
      if (d.facilityAvailable?.toLowerCase() == 'y' ||
          d.facilityAvailable?.toLowerCase() == 'yes') {
        _selectedOptions.add(d);
      }
    });
    super.initState();
  }

  void getAllId() {
    String? fId;
    final List<int> fIdList = [];
    if (_selectedOptions.isNotEmpty == true) {
      for (var action in _selectedOptions) {
        var d = action.customerFacilityId ?? 0;
        fIdList.add(d);
      }

      if (fIdList.isNotEmpty) {
        fId = fIdList.join(',');
      }
    }
    UPDATED_REQ.schoolFacility = fId;
    print("SSSS UPDATED_REQ.schoolFacility ${UPDATED_REQ.schoolFacility}");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return schoolFacility == null || schoolFacility?.length == 0
        ? SizedBox(
            height: 40,
          )
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              height: 440,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 4,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: schoolFacility!.map((option) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedOptions.contains(option)) {
                          _selectedOptions.remove(option);
                        } else {
                          _selectedOptions.add(option);
                          getAllId();
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
                              getAllId();
                            });
                          },
                          visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        Expanded(
                            child: Text(
                          option.customerFacilityName ?? '',
                          style: TextStyle(fontSize: 14, color: AppColor.black),
                        )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
