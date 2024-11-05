import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/add_friend_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart';

class SendApplication extends StatefulWidget {
  final V2TimUserFullInfo friendInfo;
  final TUISelfInfoViewModel model;
  final bool? isShowDefaultGroup;
  final AddFriendLifeCycle? lifeCycle;

  const SendApplication(
      {Key? key,
      this.lifeCycle,
      required this.friendInfo,
      required this.model,
      this.isShowDefaultGroup = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SendApplicationState();
}

class _SendApplicationState extends TIMUIKitState<SendApplication> {
  final TextEditingController _verficationController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final showName =
        widget.model.loginInfo?.nickName ?? widget.model.loginInfo?.userID;
    _verficationController.text = "我是: $showName";
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final FriendshipServices _friendshipServices =
        serviceLocator<FriendshipServices>();

    final faceUrl = widget.friendInfo.faceUrl ?? "";
    final userID = widget.friendInfo.userID ?? "";
    final String showName = ((widget.friendInfo.nickName != null &&
                widget.friendInfo.nickName!.isNotEmpty)
            ? widget.friendInfo.nickName
            : userID) ??
        "";
    final option2 = widget.friendInfo.selfSignature ?? "";

    Widget sendApplicationBody() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: theme.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    child: Avatar(faceUrl: faceUrl, showName: showName),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showName,
                        style:
                            TextStyle(color: theme.darkTextColor, fontSize: 18),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "ID: $userID",
                        style:
                            TextStyle(fontSize: 13, color: theme.weakTextColor),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      if (TencentUtils.checkString(option2) != null)
                        Text(
                          TIM_t_para("个性签名: {{option2}}", "个性签名: $option2")(
                              option2: option2),
                          style: TextStyle(
                              fontSize: 13, color: theme.weakTextColor),
                        ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                TIM_t("填写验证信息"),
                style: TextStyle(fontSize: 16, color: theme.weakTextColor),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.white,
              child: TextField(
                // minLines: 1,
                maxLines: 4,
                controller: _verficationController,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: theme.textgrey),
                  hintText: '',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                TIM_t("请填写备注"),
                style: TextStyle(fontSize: 16, color: theme.weakTextColor),
              ),
            ),
            Container(
              color: theme.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TIM_t("备注"),
                    style: TextStyle(color: theme.darkTextColor, fontSize: 16),
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _nickNameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: theme.textgrey,
                        ),
                        hintText: '',
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Divider(
              height: 1,
            ),
            if (widget.isShowDefaultGroup == true)
              Container(
                color: theme.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TIM_t("分组"),
                      style:
                          TextStyle(color: theme.darkTextColor, fontSize: 16),
                    ),
                    Text(
                      TIM_t("我的好友"),
                      style:
                          TextStyle(color: theme.darkTextColor, fontSize: 16),
                    )
                  ],
                ),
              ),
            Container(
              color: theme.white,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              child: TextButton(
                  onPressed: () async {
                    final remark = _nickNameController.text;
                    final addWording = _verficationController.text;
                    final friendGroup = TIM_t("我的好友");

                    if (widget.lifeCycle?.shouldAddFriend != null &&
                        await widget.lifeCycle!.shouldAddFriend(userID, remark,
                                friendGroup, addWording, context) ==
                            false) {
                      return;
                    }

                    final res = await _friendshipServices.addFriend(
                        userID: userID,
                        addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH,
                        remark: remark,
                        addWording: addWording,
                        friendGroup: friendGroup);

                    if (res.code == 0 && res.data?.resultCode == 0) {
                      _sendHelloToFriend(userID);
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("好友添加成功"),
                          infoCode: 6661202));
                    } else if (res.code == 0 && res.data?.resultCode == 30539) {
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("好友申请已发出"),
                          infoCode: 6661203));
                    } else if (res.code == 0 && res.data?.resultCode == 30515) {
                      onTIMCallback(TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("当前用户在黑名单"),
                          infoCode: 6661204));
                    }
                  },
                  child: Text(TIM_t("发送"))),
            )
          ],
        ),
      );
    }

    return TUIKitScreenUtils.getDeviceWidget(
        context: context,
        desktopWidget: Container(
          padding: const EdgeInsets.only(top: 10),
          color: theme.weakBackgroundColor,
          child: sendApplicationBody(),
        ),
        defaultWidget: Scaffold(
          appBar: AppBar(
            title: Text(
              TIM_t("添加好友"),
              style: TextStyle(color: theme.appbarTextColor, fontSize: 17),
            ),
            shadowColor: theme.white,
            backgroundColor: theme.appbarBgColor ?? theme.primaryColor,
            iconTheme: IconThemeData(
              color: theme.appbarTextColor,
            ),
          ),
          body: sendApplicationBody(),
        ));
  }
  _sendHelloToFriend(String userId) async{
    // 创建文本消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createTextMessageRes =
    await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createTextMessage(
      text: AESTools.encryptString("{\"original\":\"你好\"}"), // 文本信息
    );
    if (createTextMessageRes.code == 0) {
      // 文本信息创建成功
      String? id = createTextMessageRes.data?.id;
      // 发送文本消息
      // 在sendMessage时，若只填写receiver则发个人用户单聊消息
      //                 若只填写groupID则发群组消息
      //                 若填写了receiver与groupID则发群内的个人用户，消息在群聊中显示，只有指定receiver能看见
      V2TimValueCallback<V2TimMessage> sendMessageRes =
      await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
          id: id!, // 创建的messageid
          receiver: userId, // 接收人id
          groupID: "", // 接收群组id
          priority: MessagePriorityEnum.V2TIM_PRIORITY_DEFAULT, // 消息优先级
          onlineUserOnly:
          false, // 是否只有在线用户才能收到，如果设置为 true ，接收方历史消息拉取不到，常被用于实现“对方正在输入”或群组里的非重要提示等弱提示功能，该字段不支持 AVChatRoom。
          isExcludedFromUnreadCount: false, // 发送消息是否计入会话未读数
          isExcludedFromLastMessage: false, // 发送消息是否计入会话 lastMessage
          needReadReceipt:
          false, // 消息是否需要已读回执（只有 Group 消息有效，6.1 及以上版本支持，需要您购买旗舰版套餐）
          offlinePushInfo: OfflinePushInfo(title: "您有一条新消息"), // 离线推送时携带的标题和内容
          cloudCustomData: "", // 消息云端数据，消息附带的额外的数据，存云端，消息的接收者可以访问到
          localCustomData:
          "" // 消息本地数据，消息附带的额外的数据，存本地，消息的接收者不可以访问到，App 卸载后数据丢失
      );
      if (sendMessageRes.code == 0) {
        // 发送成功
      }
    }
  }
}
