class UploadDocumentRequest {
  UploadDocumentRequest({
    this.fileName,
    this.fileExtension,
    this.module,
    this.base64String,
  });

  UploadDocumentRequest.fromJson(dynamic json) {
    fileName = json['FileName'];
    fileExtension = json['FileExtension'];
    module = json['Module'];
    base64String = json['Base64String'];
  }

  String? fileName;
  String? fileExtension;
  String? module;
  String? base64String;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['FileName'] = fileName;
    map['FileExtension'] = fileExtension;
    map['Module'] = module;
    map['Base64String'] = base64String;
    return map;
  }
}
