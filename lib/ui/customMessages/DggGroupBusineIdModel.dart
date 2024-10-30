import 'package:tencent_cloud_chat_uikit/ui/customMessages/DGGCustomMsgBaseModel.dart';

class DggGroupBusineIdModel extends DGGCustomMsgBaseModel {

  String? groupID;
  String? groupName;

  DggGroupBusineIdModel({super.businessID, this.groupID, this.groupName});

  DggGroupBusineIdModel.fromJson(Map<String, dynamic> json) {
    businessID = json['businessID'];
    groupID = json['groupID'];
    groupName = json['groupName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessID'] = this.businessID;
    data['groupID'] = this.groupID;
    data['groupName'] = this.groupName;
    return data;
  }
}
