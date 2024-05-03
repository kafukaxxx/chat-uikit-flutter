import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_class.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitConversation/dgg_transfer_conversation_list.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:wb_flutter_tool/popup/jw_popup.dart';

class DggProfileWidget extends TIMUIKitClass {
  static final bool isDesktopScreen =
      TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;

  static Widget operationDivider(
      {Color? color, double? height, EdgeInsetsGeometry? margin}) {
    return Container(
      color: color,
      margin: margin,
      height: height ?? 10,
    );
  }
  /// default button area
  static Widget shareUserCard(
      V2TimFriendInfo friendInfo,
      V2TimConversation conversation,
      int friendType,
      bool isDisturb,
      bool isBlocked,
      TUITheme theme,
      VoidCallback handleAddFriend,
      VoidCallback handleDeleteFriend,
      bool smallCardMode,
      BuildContext context
      ) {

    List<V2TimConversation?> _selConvs = [];

    Future<bool> sendGroupCardToConversation(V2TimConversation conv) async{
      var dic = '{"businessID":"dgg_businessId","userID":"${friendInfo.userID}","nickName":"${friendInfo.userProfile?.nickName}","faceURL":"${friendInfo.userProfile?.faceUrl ?? ""}"}';
      V2TimValueCallback<V2TimMsgCreateInfoResult> createCustomMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createCustomMessage(
        data: dic,

      );
      if(createCustomMessageRes.code == 0){
        String? id =  createCustomMessageRes.data?.id;
        // 发送自定义消息

        V2TimValueCallback<V2TimMessage> sendMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
            id: id!,
            receiver: conv.userID ?? "",
            groupID: conv.groupID ?? "");
        if(sendMessageRes.code == 0){
          // 发送成功
          return true;
        }
      }
      return false;
    }

    return InkWell(
      onTap: () async{
        showPopupWindow(context: context, offset: Offset(0, 0),emptyDismissable: true, windowBuilder: (context,from,to){
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: MediaQuery.of(context).size.width*0.3,
                height: MediaQuery.of(context).size.height*0.6,
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned(right: 0,child: TextButton(child: Text("转发",style: TextStyle(fontSize: 14,color: theme.primaryColor),),onPressed: ()async{
                      if (_selConvs.length > 0) {
                        EasyLoading.show();
                        for (var conv in _selConvs) {
                          await sendGroupCardToConversation(conv!);
                        }
                        EasyLoading.dismiss();
                        Navigator.pop(context);
                      }
                    },)),
                    Positioned(left: 0,right: 0,bottom: 0,top: 40,child: DggTransferConversationList(onChanged: (convs) {
                      _selConvs = convs;
                    },))
                  ],
                ),
              ),
            ),
          );
        });
      },
      child: Container(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: Text(TIM_t("分享名片"))),
              Icon(Icons.keyboard_arrow_right,
                  color: theme.weakTextColor)
            ],
          )),
    );
  }
}
