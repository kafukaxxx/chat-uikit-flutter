import 'package:wb_flutter_tool/wb_flutter_tool.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/customMessages/DGGCustomMsgBaseModel.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
class DggRedpacketTipsModel extends DGGCustomMsgBaseModel {
  /**
      是否为最后一个红包
   */
  String? isGetDone;
  /**
      拆红包者昵称
   */
  String? openName;
  /**
      拆红包的人的ID
   */
  String? openPacketId;
  /**
   *  红包ID
   */
  String? packetId;
  /**
      红包发送者昵称
   */
  String? sendName;
  /**
      红包发送者ID
   */
  String? sendPacketId;

  DggRedpacketTipsModel(
      {super.businessID,
        this.isGetDone,
        this.openName,
        this.openPacketId,
        this.packetId,
        this.sendName,
        this.sendPacketId});

  DggRedpacketTipsModel.fromJson(Map<String, dynamic> json) {
    businessID = json['businessID'].toString();
    isGetDone = json['isGetDone'].toString();
    openName = json['openName'].toString();
    openPacketId = json['openPacketId'].toString();
    packetId = json['packetId'].toString();
    sendName = json['sendName'].toString();
    sendPacketId = json['sendPacketId'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessID'] = this.businessID;
    data['isGetDone'] = this.isGetDone;
    data['openName'] = this.openName;
    data['openPacketId'] = this.openPacketId;
    data['packetId'] = this.packetId;
    data['sendName'] = this.sendName;
    data['sendPacketId'] = this.sendPacketId;
    return data;
  }
}
Future<String> getStringByRedTipsModel(DggRedpacketTipsModel model) async{
  var res = await TencentImSDKPlugin.v2TIMManager.getLoginUser();
  String userId = res.data ?? "";
  String showContent = "";
  if (userId == model.sendPacketId && userId == model.openPacketId) {
    if (bool.parse(model.isGetDone ?? "false")) {
      showContent = "你领取了自己的红包，你的红包已被领完";
    }else {
      showContent = "你领取了自己的红包";
    }
  }else if (userId == model.openPacketId) {
    showContent = "你领取了${model.sendName ?? ""}的红包";
  }else if (userId == model.sendPacketId) {
    if (bool.parse(model.isGetDone ?? "false")) {
      showContent = "${model.openName}领取了你的红包，你的红包已被领完";
    }else {
      showContent = "${model.openName}领取了你的红包";
    }
  }else {
    if (bool.parse(model.isGetDone ?? "false")) {
      showContent = "${model.openName}领取了${model.sendName}的红包,${model.sendName}的红包已被领完";
    }else {
      showContent = "${model.openName}领取了${model.sendName}的红包";
    }
  }
  return showContent;
}
