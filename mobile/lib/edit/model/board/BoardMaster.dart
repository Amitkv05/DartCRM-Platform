class BoardMaster {
  BoardMaster({
    this.boardId,
    this.boardName,
  });

  BoardMaster.fromJson(dynamic json) {
    boardId = json['BoardId'];
    boardName = json['BoardName'];
  }
  int? boardId;
  String? boardName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['BoardId'] = boardId;
    map['BoardName'] = boardName;
    return map;
  }
}
