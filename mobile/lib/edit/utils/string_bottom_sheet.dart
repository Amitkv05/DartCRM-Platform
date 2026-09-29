import 'package:dart_crm/edit/model/schoolUpdate/StateResponse.dart';
import 'package:flutter/material.dart';

import 'color_constants.dart';

class StringBottomSheet extends StatefulWidget {
  final List<StateResponse> list;
  final Function(StateResponse value) onItemClick;

  StringBottomSheet({required this.onItemClick, required this.list});

  @override
  _StringBottomSheetState createState() => _StringBottomSheetState();
}

class _StringBottomSheetState extends State<StringBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _widgetSheet();
  }

  Widget _widgetSheet() {
    double w = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Wrap(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  width: w,
                  color: AppColor.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 35,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColor.color_E8E8E8,
                              border: Border.all(color: AppColor.color_D6D6D6, width: .6),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25),
                        child: Text(
                          'Select Value',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 21,
                            color: AppColor.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Divider(
                        height: 0.5,
                        color: AppColor.black,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _widgetStatusList(),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _widgetStatusList() {
    return SizedBox(
      height: 460,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.list.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                print('ididid widget.listAPI ${widget.list[index].value}');
                widget.onItemClick(widget.list[index]);
              },
              child: SizedBox(
                height: 40,
                child: Text(
                  textAlign: TextAlign.center,
                  widget.list[index].text ?? '',
                  style: TextStyle(
                    color: AppColor.black,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          }),
    );
  }
}
