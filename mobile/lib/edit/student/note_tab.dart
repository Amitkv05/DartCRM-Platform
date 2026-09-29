import 'dart:async';

import 'package:dart_crm/edit/model/school/CommentsModel.dart';
import 'package:dart_crm/edit/utils/AppUtils.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/constants/colors.dart';
import '../model/school/SchoolListResponse.dart';
import '../utils/color_constants.dart';
import '../utils/fill_button_widget.dart';
import '../utils/message_field_widget.dart';

class NoteTab extends StatefulWidget {
  final SchoolListResponse? apiData;
  final int? type;

  const NoteTab({super.key, required this.apiData, required this.type});

  @override
  State<NoteTab> createState() => _NoteTabState();
}

class _NoteTabState extends State<NoteTab> with AutomaticKeepAliveClientMixin {
  FocusNode nameNode = FocusNode();

  TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteController.text = UPDATED_REQ.comment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // important!
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
        ),
        MessageFieldWidget(
          maxLength: 1000,
          preNode: null,
          nextNode: null,
          textInputAction: TextInputAction.done,
          controller: noteController,
          error: '',
          maxLines: 3,
          field: 'Comment',
          hint: 'Write the comment',
          onTypeChange: (value) {
            UPDATED_REQ.comment = value;
          },
        ),
        SizedBox(
          height: 5,
        ),
        _widgetList(widget.apiData?.comments)
      ],
    );
  }

  Widget _widgetList(List<CommentsModel>? contactList) {
    if (contactList == null || contactList.isEmpty == true) {
      return SizedBox();
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 0),
      scrollDirection: Axis.vertical,
      itemCount: contactList.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        var comment = contactList[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment?.enteredBy ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
                  ),
                ),
                Text(
                  comment?.commentDate ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black),
                ),
              ],
            ),
            Text(
              comment?.comment ?? '',
              style: TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
            ),
            SizedBox(
              height: 4,
            ),
            Divider(
              height: 1,
              color: AppColor.color_B0B0B0,
            ),
            SizedBox(
              height: 4,
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
