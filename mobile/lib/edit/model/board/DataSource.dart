class DataSource {
  DataSource({
    this.dataSourceId,
    this.dataSourceName,
  });

  DataSource.fromJson(dynamic json) {
    dataSourceId = json['DataSourceId'];
    dataSourceName = json['DataSourceName'];
  }
  int? dataSourceId;
  String? dataSourceName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['DataSourceId'] = dataSourceId;
    map['DataSourceName'] = dataSourceName;
    return map;
  }
}
