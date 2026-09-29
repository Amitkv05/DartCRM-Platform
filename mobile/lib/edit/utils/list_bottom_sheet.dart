import 'package:flutter/material.dart';

import '../model/schoolUpdate/StateResponse.dart';
import 'ValueModel.dart';
import 'color_constants.dart';

class ListBottomSheet extends StatefulWidget {
  final String? title;
  final List<StateResponse>? resourceList;
  final Function(StateResponse? model, bool isClear) onTypeClick;

  ListBottomSheet({
    required this.title,
    required this.resourceList,
    required this.onTypeClick,
  });

  @override
  _ListBottomSheetState createState() => _ListBottomSheetState();
}

class _ListBottomSheetState extends State<ListBottomSheet> {
  @override
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: Container(
            color: AppColor.white,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColor.color_E8E8E8,
                          border: Border.all(color: AppColor.color_D6D6D6, width: .6),
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: AppColor.black,
                          ),
                        ),
                      ),
                    ),
                    /*Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColor.color_1A1A1A,
                            ),
                          ),
                        ),
                      ),
                    ),*/
                  ],
                ),
                SizedBox(height: 10),
                Container(height: 1, color: AppColor.color_DADADA),
                SizedBox(height: 10),
                Text(
                  widget.title ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColor.black,
                  ),
                ),
                SizedBox(height: 10),
                _widgetList(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _widgetList() {
    var dataList = widget.resourceList;
    return SizedBox(
      height: MediaQuery.of(context).size.height / 1.8,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: dataList?.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          var d = dataList?[index];
          return Material(
            color: AppColor.white,
            child: InkWell(
              onTap: () {
                dataList?.forEach((element) {
                  element.isSelected = false;
                });
                d?.isSelected = true;
                widget.onTypeClick(d, false);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 16),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            d?.text ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
