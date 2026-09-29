class CommentsModel {
  CommentsModel({
    this.sNo,
    this.commentDate,
    this.enteredBy,
    this.comment,
    this.existence,
  });

  CommentsModel.fromJson(dynamic json) {
    sNo = json['SNo'];
    commentDate = json['CommentDate'];
    enteredBy = json['EnteredBy'];
    comment = json['Comment'];
    existence = json['Existence'];
  }
  int? sNo;
  String? commentDate;
  String? enteredBy;
  String? comment;
  int? existence;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SNo'] = sNo;
    map['CommentDate'] = commentDate;
    map['EnteredBy'] = enteredBy;
    map['Comment'] = comment;
    map['Existence'] = existence;
    return map;
  }
}
