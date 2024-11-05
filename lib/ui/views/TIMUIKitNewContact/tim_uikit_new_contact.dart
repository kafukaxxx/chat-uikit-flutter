import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/new_contact_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_friendship_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart';

typedef NewContactItemBuilder = Widget Function(
    BuildContext context, V2TimFriendApplication applicationInfo);

class TIMUIKitNewContact extends StatefulWidget {
  /// the callback when accept friend request
  final void Function(V2TimFriendApplication applicationInfo)? onAccept;

  /// the callback when reject friend request
  final void Function(V2TimFriendApplication applicationInfo)? onRefuse;

  /// the widget builder when no friend request exists
  final Widget Function(BuildContext context)? emptyBuilder;

  /// the builder for the request item
  final NewContactItemBuilder? itemBuilder;

  /// the life cycle hooks for new contact business logic
  final NewContactLifeCycle? lifeCycle;

  const TIMUIKitNewContact(
      {Key? key,
      this.lifeCycle,
      this.onAccept,
      this.onRefuse,
      this.emptyBuilder,
      this.itemBuilder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitNewContactState();
}

class _TIMUIKitNewContactState extends TIMUIKitState<TIMUIKitNewContact> {
  late TUIFriendShipViewModel model = serviceLocator<TUIFriendShipViewModel>();

  _getShowName(V2TimFriendApplication item) {
    return TencentUtils.checkString(item.nickname) ??
        TencentUtils.checkString(item.userID);
  }

  Widget _itemBuilder(
      BuildContext context, V2TimFriendApplication applicationInfo) {
    final theme = Provider.of<TUIThemeViewModel>(context).theme;
    final showName = _getShowName(applicationInfo);
    final faceUrl = applicationInfo.faceUrl ?? "";
    final applicationText = applicationInfo.addWording ?? "";
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    return Material(
      color: theme.wideBackgroundColor,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.only(
              top: isDesktopScreen ? 6 : 10,
              left: 16,
              right: isDesktopScreen ? 16 : 0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: isDesktopScreen ? 10 : 12),
                margin: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  height: isDesktopScreen ? 30 : 40,
                  width: isDesktopScreen ? 30 : 40,
                  child: Avatar(faceUrl: faceUrl, showName: showName),
                ),
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: theme.weakDividerColor ??
                                CommonColor.weakDividerColor))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: (applicationText.isNotEmpty && isDesktopScreen)
                              ? 10
                              : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showName,
                            style: TextStyle(
                                color: theme.darkTextColor,
                                fontSize: isDesktopScreen ? 14 : 18),
                          ),
                          if (applicationText.isNotEmpty && isDesktopScreen)
                            const SizedBox(
                              height: 4,
                            ),
                          if (applicationText.isNotEmpty && isDesktopScreen)
                            Text(
                              applicationText,
                              style: TextStyle(
                                  color: theme.weakTextColor, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: theme.primaryColor,
                              border: Border.all(
                                  width: 1,
                                  color: theme.weakTextColor ??
                                      CommonColor.weakTextColor)),
                          child: Text(
                            TIM_t("同意"),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktopScreen ? 12 : null,
                            ),
                          ),
                        ),
                        onTap: () async {
                          V2TimFriendOperationResult? resu = await model.acceptFriendApplication(
                            applicationInfo.userID,
                            applicationInfo.type,
                          );
                          if (resu?.resultCode == 0) {
                            _sendHelloToFriend(applicationInfo.userID);
                          }
                          model.loadData();
                          if (widget.onAccept != null) {
                            widget.onAccept!(applicationInfo);
                          }
                          // widget?.onAccept();
                        },
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                border: Border.all(
                                    width: 1,
                                    color: theme.weakTextColor ??
                                        CommonColor.weakTextColor)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Text(
                              TIM_t("拒绝"),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: isDesktopScreen ? 12 : null,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await model.refuseFriendApplication(
                              applicationInfo.userID,
                              applicationInfo.type,
                            );
                            model.loadData();
                            if (widget.onRefuse != null) {
                              widget.onRefuse!(applicationInfo);
                            }
                            // refuse(context);
                          },
                        ))
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  NewContactItemBuilder _getItemBuilder() {
    return widget.itemBuilder ?? _itemBuilder;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
        ],
        builder: (BuildContext context, Widget? w) {
          final model = Provider.of<TUIFriendShipViewModel>(context);
          model.newContactLifeCycle = widget.lifeCycle;
          final newContactList = model.friendApplicationList;
          if (newContactList != null && newContactList.isNotEmpty) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: newContactList.length,
              itemBuilder: (context, index) {
                final friendInfo = newContactList[index]!;
                final itemBuilder = _getItemBuilder();
                return itemBuilder(context, friendInfo);
              },
            );
          }

          if (widget.emptyBuilder != null) {
            return widget.emptyBuilder!(context);
          }

          return Container();
        });
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
