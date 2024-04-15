class DGGCustomMsgBaseModel {
  String? businessID;
  DGGCustomMsgBaseModel({this.businessID});
  DGGCustomMsgBaseModel.fromJson(Map<String, dynamic> json) {
    businessID = json['businessID'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessID'] = this.businessID;
    return data;
  }
}