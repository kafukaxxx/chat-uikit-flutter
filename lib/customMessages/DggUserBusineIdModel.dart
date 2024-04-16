import 'DGGCustomMsgBaseModel.dart';

class DggUserBusineIdModel extends DGGCustomMsgBaseModel {

  String? faceURL;
  String? nickName;
  String? userID;

  DggUserBusineIdModel(
      {super.businessID, this.faceURL, this.nickName, this.userID});

  DggUserBusineIdModel.fromJson(Map<String, dynamic> json) {
    businessID = json['businessID'].toString();
    faceURL = json['faceURL'].toString();
    nickName = json['nickName'].toString();
    userID = json['userID'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessID'] = this.businessID;
    data['faceURL'] = this.faceURL;
    data['nickName'] = this.nickName;
    data['userID'] = this.userID;
    return data;
  }
}
