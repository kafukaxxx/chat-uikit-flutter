
import 'package:tencent_cloud_chat_uikit/ui/customMessages/DGGCustomMsgBaseModel.dart';

class DggTransferModel extends DGGCustomMsgBaseModel {
  String? content;

  DggTransferModel({this.content, super.businessID});

  DggTransferModel.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    businessID = json['businessID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['content'] = this.content;
    data['businessID'] = this.businessID;
    return data;
  }
}
