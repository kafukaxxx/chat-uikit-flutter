
import 'package:tencent_cloud_chat_uikit/ui/customMessages/DGGCustomMsgBaseModel.dart';

class DggRedPacketModel extends DGGCustomMsgBaseModel {
  String? chatType;
  String? redid;
  String? content;
  String? sendPacketId;
  String? title;
  String? sendName;


  DggRedPacketModel(
      {this.chatType,
        this.redid,
        this.content,
        this.sendPacketId,
        this.title,
        this.sendName,
        super.businessID});

  DggRedPacketModel.fromJson(Map<String, dynamic> json) {
    chatType = json['chatType'].toString();
    redid = json['redid'].toString();
    content = json['content'].toString();
    sendPacketId = json['sendPacketId'].toString();
    title = json['title'].toString();
    sendName = json['sendName'].toString();
    businessID = json['businessID'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chatType'] = this.chatType;
    data['redid'] = this.redid;
    data['content'] = this.content;
    data['sendPacketId'] = this.sendPacketId;
    data['title'] = this.title;
    data['sendName'] = this.sendName;
    data['businessID'] = this.businessID;
    return data;
  }
}
