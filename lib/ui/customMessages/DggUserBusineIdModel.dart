import 'package:tencent_cloud_chat_uikit/ui/customMessages/DGGCustomMsgBaseModel.dart';

class DggUserBusineIdModel extends DGGCustomMsgBaseModel {

  String? faceURL;
  String? nickName;
  String? userID;

  DggUserBusineIdModel(
      {super.businessID, this.faceURL, this.nickName, this.userID});

  DggUserBusineIdModel.fromJson(Map<String, dynamic> json) {
    businessID = json['businessID'];
    faceURL = json['faceURL'];
    nickName = json['nickName'];
    userID = json['userID'];
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
