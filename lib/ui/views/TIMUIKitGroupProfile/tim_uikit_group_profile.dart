import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/group_profile_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/listener_model/tui_group_listener_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/group_profile_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_ui_group_profile_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_uikit_group_button_area.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_uikit_group_manage.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_uikit_group_notification.dart';
import 'package:wb_flutter_tool/popup/jw_popup.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart' hide PlatformUtils;

import '../../../data_services/core/tim_uikit_wide_modal_operation_key.dart';
import '../../controller/tim_uikit_chat_controller.dart';
import '../../widgets/wide_popup.dart';
import '../TIMUIKitConversation/dgg_transfer_conversation_list.dart';
export 'package:tencent_cloud_chat_uikit/ui/widgets/transimit_group_owner_select.dart';

typedef GroupProfileBuilder = Widget Function(BuildContext context,
    V2TimGroupInfo groupInfo, List<V2TimGroupMemberFullInfo?> groupMemberList);

class TIMUIKitGroupProfile extends StatefulWidget {
  /// Group ID
  final String groupID;
  final Color? backGroundColor;

  /// [Deprecated:] The builder for custom bottom operation area.
  /// [operationListBuilder] and [bottomOperationBuilder] merged into [builder], please use it instead.
  final Widget Function(BuildContext context, V2TimGroupInfo groupInfo,
      List<V2TimGroupMemberFullInfo?> groupMemberList)? bottomOperationBuilder;

  /// [Deprecated:] The builder for custom bottom operation area.
  /// [operationListBuilder] and [bottomOperationBuilder] merged into [builder], please use it instead.
  final Widget Function(BuildContext context, V2TimGroupInfo groupInfo,
      List<V2TimGroupMemberFullInfo?> groupMemberList)? operationListBuilder;

  /// [If you tend to customize the profile page, use [profileWidgetBuilder] with [profileWidgetsOrder] as priority.]
  /// The builder for each widgets in profile page,
  /// you can customize some of it by pass your own widget into here.
  /// Or, you can add your custom widget to the three custom widgets.
  final GroupProfileWidgetBuilder? profileWidgetBuilder;

  /// [If you tend to customize the profile page, use [profileWidgetBuilder] with [profileWidgetsOrder] as priority.]
  /// If the default widget order can not meet you needs,
  /// you may change the order by this array with widget enum.
  final List<GroupProfileWidgetEnum>? profileWidgetsOrder;

  /// The builder for the whole group profile page, you can use this to customize all the element here.
  /// Mentioned: If you use this builder, [profileWidgetBuilder] and [profileWidgetsOrder] will no longer works.
  final GroupProfileBuilder? builder;

  /// The life cycle hooks for group profile business logic.
  /// You have better to implement the `didLeaveGroup` in it.
  final GroupProfileLifeCycle? lifeCycle;

  /// The callback after user clicking a user,
  /// you may navigating to the specific profile page, or anywhere you want.
  final Function(String userID, TapDownDetails? tapDetails)? onClickUser;

  const TIMUIKitGroupProfile(
      {Key? key,
      required this.groupID,
      this.backGroundColor,
      @Deprecated("[operationListBuilder] and [bottomOperationBuilder] merged into [builder], please use it instead")
          this.bottomOperationBuilder,
      @Deprecated("[operationListBuilder] and [bottomOperationBuilder] merged into [builder], please use it instead")
          this.operationListBuilder,
      this.builder,
      this.profileWidgetBuilder,
      this.onClickUser,
      this.profileWidgetsOrder,
      this.lifeCycle})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitGroupProfileState();
}

class _TIMUIKitGroupProfileState extends TIMUIKitState<TIMUIKitGroupProfile> {
  bool isSingleUse = false;
  final model = TUIGroupProfileModel();
  List<V2TimConversation?> _selConvs = [];
  final TUIGroupListenerModel groupListenerModel =
      serviceLocator<TUIGroupListenerModel>();

  @override
  void initState() {
    super.initState();
    model.loadData(widget.groupID);
    model.onClickUser = widget.onClickUser;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TIMUIKitGroupProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupID != widget.groupID) {
      model.loadData(widget.groupID);
    }
  }

  final List<GroupProfileWidgetEnum> _defaultWidgetOrder = [
    GroupProfileWidgetEnum.detailCard,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.memberListTile,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.searchMessage,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.groupNotice,
    GroupProfileWidgetEnum.customBuilderOne,
    GroupProfileWidgetEnum.groupManage,
    GroupProfileWidgetEnum.groupJoiningModeBar,
    GroupProfileWidgetEnum.groupTypeBar,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.pinedConversationBar,
    GroupProfileWidgetEnum.muteGroupMessageBar,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.nameCardBar,
    GroupProfileWidgetEnum.operationDivider,
    GroupProfileWidgetEnum.buttonArea
  ];

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue buildValue) {
    final TUITheme theme = buildValue.theme;

    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider.value(value: groupListenerModel),
        ],
        builder: (context, w) {
          final model = Provider.of<TUIGroupProfileModel>(context);
          model.lifeCycle = widget.lifeCycle;
          final V2TimGroupInfo? groupInfo = model.groupInfo;
          final memberList = model.groupMemberList;
          final isDesktopScreen =
              TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
          if (groupInfo == null) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: theme.weakTextColor ?? Colors.grey,
                size: 48,
              ),
            );
          }

          final TUIGroupListenerModel groupListenerModel =
              Provider.of<TUIGroupListenerModel>(context);
          final NeedUpdate? needUpdate = groupListenerModel.needUpdate;
          if (needUpdate != null && needUpdate.groupID == widget.groupID) {
            groupListenerModel.needUpdate = null;
            switch (needUpdate.updateType) {
              case UpdateType.groupInfo:
                model.loadGroupInfo(widget.groupID);
                break;
              case UpdateType.memberList:
                model.loadGroupMemberList(groupID: widget.groupID);
                model.loadGroupInfo(widget.groupID);
                break;
              default:
                break;
            }
          }

          final isGroupOwner = groupInfo.role ==
              GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER;
          final isAdmin = groupInfo.role ==
              GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN;

          Widget groupProfilePage({required Widget child}) {
            return SingleChildScrollView(
              child: Container(
                color: widget.backGroundColor ??
                    (isDesktopScreen
                        ? theme.wideBackgroundColor
                        : theme.weakBackgroundColor),
                child: child,
              ),
            );
          }

          void toDefaultNoticePage() {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GroupProfileNotificationPage(
                        model: model,
                        notification: groupInfo.notification ?? "")));
          }

          void toDefaultManagePage() {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GroupProfileGroupManagePage(
                          model: model,
                        )));
          }

          List<Widget> _renderWidgetsWithOrder(
              List<GroupProfileWidgetEnum> order) {
            final GroupProfileWidgetBuilder? customBuilder =
                widget.profileWidgetBuilder;
            return order.map((element) {
              switch (element) {
                case GroupProfileWidgetEnum.detailCard:
                  return (customBuilder?.detailCard != null
                      ? customBuilder?.detailCard!(
                          groupInfo, model.setGroupName)
                      : TIMUIKitGroupProfileWidget.detailCard(
                          isHavePermission: isAdmin || isGroupOwner,
                          groupInfo: groupInfo))!;
                case GroupProfileWidgetEnum.memberListTile:
                  return (customBuilder?.memberListTile != null
                      ? customBuilder?.memberListTile!(memberList)
                      : TIMUIKitGroupProfileWidget.memberTile())!;
                case GroupProfileWidgetEnum.groupNotice:
                  return (customBuilder?.groupNotice != null
                      ? customBuilder?.groupNotice!(
                          groupInfo.notification ?? "",
                          toDefaultNoticePage,
                          model.setGroupNotification)
                      : TIMUIKitGroupProfileWidget.groupNotification(
                          isHavePermission: isAdmin || isGroupOwner))!;
                case GroupProfileWidgetEnum.groupManage:
                  if (isAdmin || isGroupOwner) {
                    return (customBuilder?.groupManage != null
                        ? customBuilder?.groupManage!(toDefaultManagePage)
                        : TIMUIKitGroupProfileWidget.groupManage())!;
                  } else {
                    return Container();
                  }
                case GroupProfileWidgetEnum.searchMessage:
                  return (customBuilder?.searchMessage != null
                      ? customBuilder?.searchMessage!()
                      : Text(TIM_t("你必须自定义search bar，并处理点击跳转")))!;
                case GroupProfileWidgetEnum.operationDivider:
                  return (customBuilder?.operationDivider != null
                      ? customBuilder?.operationDivider!()
                      : TIMUIKitGroupProfileWidget.operationDivider(theme))!;
                case GroupProfileWidgetEnum.groupTypeBar:
                  return (customBuilder?.groupTypeBar != null
                      ? customBuilder?.groupTypeBar!(groupInfo.groupType)
                      : TIMUIKitGroupProfileWidget.groupType())!;
                case GroupProfileWidgetEnum.groupJoiningModeBar:
                  final String groupType = groupInfo.groupType;
                  if (!(isGroupOwner || isAdmin) ||
                      groupType == "Work" ||
                      groupType == "Meeting" ||
                      groupType == "AVChatRoom") {
                    return Container();
                  }
                  return (customBuilder?.groupJoiningModeBar != null
                      ? customBuilder?.groupJoiningModeBar!(
                          groupInfo.groupAddOpt ?? 1, model.setGroupAddOpt)
                      : TIMUIKitGroupProfileWidget.groupAddOpt())!;
                case GroupProfileWidgetEnum.nameCardBar:
                  return (customBuilder?.nameCardBar != null
                      ? customBuilder?.nameCardBar!(
                          model.getSelfNameCard(), model.setNameCard)
                      : TIMUIKitGroupProfileWidget.nameCard())!;
                case GroupProfileWidgetEnum.muteGroupMessageBar:
                  return (customBuilder?.muteGroupMessageBar != null
                      ? customBuilder?.muteGroupMessageBar!(
                          model.conversation?.recvOpt != 0,
                          model.setMessageDisturb)
                      : TIMUIKitGroupProfileWidget.messageDisturb())!;
                case GroupProfileWidgetEnum.pinedConversationBar:
                  return (customBuilder?.pinedConversationBar != null
                      ? customBuilder?.pinedConversationBar!(
                          model.conversation?.isPinned ?? false,
                          model.pinedConversation)
                      : TIMUIKitGroupProfileWidget.pinedConversation())!;
                case GroupProfileWidgetEnum.buttonArea:
                  return (customBuilder?.buttonArea != null
                      ? customBuilder?.buttonArea!(groupInfo, memberList)
                      : GroupProfileButtonArea(groupInfo.groupID, model))!;
                case GroupProfileWidgetEnum.customBuilderOne:
                  return (customBuilder?.customBuilderOne != null
                      ? customBuilder?.customBuilderOne!(groupInfo, memberList)
                  // Please define the corresponding custom widget in `profileWidgetBuilder` before using it here.
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: isDesktopScreen
                            ? null
                            : Border(
                            bottom: BorderSide(
                                color: theme.weakDividerColor ??
                                    CommonColor.weakDividerColor))),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async{
                            showPopupWindow(context: context, offset: Offset(0, 0),emptyDismissable: true, windowBuilder: (context,from,to){
                              return Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width*0.5,
                                    height: MediaQuery.of(context).size.height*0.6,
                                    color: Colors.white,
                                    child: Stack(
                                      children: [
                                        Positioned(right: 0,child: TextButton(child: Text("转发"),onPressed: ()async{
                                          if (_selConvs.length > 0) {
                                            EasyLoading.show();
                                            for (var conv in _selConvs) {
                                              await sendGroupCardToConversation(conv!);
                                            }
                                            EasyLoading.dismiss();
                                            Navigator.pop(context);
                                          }
                                        },)),
                                        Positioned(left: 0,right: 0,bottom: 0,top: 50,child: DggTransferConversationList(onChanged: (convs) {
                                          _selConvs = convs;
                                        },))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });


                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TIM_t("分享群名片"),
                                style: TextStyle(
                                    fontSize: isDesktopScreen ? 14 : 16,
                                    color: theme.darkTextColor),
                              ),
                              Icon(Icons.keyboard_arrow_right,
                                  color: theme.weakTextColor)
                            ],
                          ),
                        ),

                      ],
                    ),
                  )
                  )!;
                case GroupProfileWidgetEnum.customBuilderTwo:
                  if (!isGroupOwner) {
                    return Container();
                  }
                  return (customBuilder?.customBuilderTwo != null
                      ? customBuilder?.customBuilderTwo!(groupInfo, memberList)
                  // Please define the corresponding custom widget in `profileWidgetBuilder` before using it here.
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: isDesktopScreen
                            ? null
                            : Border(
                            bottom: BorderSide(
                                color: theme.weakDividerColor ??
                                    CommonColor.weakDividerColor))),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async{
                            showCustomAlert(context: context,title: "提示",content: "清屏后消息不可恢复",enterStr: "清屏",cancelStr: "取消",enterCall: ()async{
                              var dic = '{"businessID":"dgg_clearGroupMsg","group_id":"${model.groupID}"}';
                              V2TimValueCallback<V2TimMsgCreateInfoResult> createCustomMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createCustomMessage(
                                data: dic,

                              );
                              if(createCustomMessageRes.code == 0){
                                String? id =  createCustomMessageRes.data?.id;
                                // 发送自定义消息
                                V2TimValueCallback<V2TimMessage> sendMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(id: id!, receiver: "", groupID: model.groupID);
                                if(sendMessageRes.code == 0){
                                  // 发送成功,清理自己本地
                                  TencentImSDKPlugin.v2TIMManager.getMessageManager().clearGroupHistoryMessage(groupID: model.groupID ?? "");
                                  TIMUIKitChatController().clearHistory(model.groupID ?? "");
                                  Navigator.of(context).pop();
                                }
                              }
                            });

                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TIM_t("清屏"),
                                style: TextStyle(
                                    fontSize: isDesktopScreen ? 14 : 16,
                                    color: theme.darkTextColor),
                              ),
                              Icon(Icons.keyboard_arrow_right,
                                  color: theme.weakTextColor)
                            ],
                          ),
                        ),

                      ],
                    ),
                  ))!;
                case GroupProfileWidgetEnum.customBuilderThree:
                  if (!isGroupOwner && !isAdmin) {
                    return Container();
                  }
                  return (customBuilder?.customBuilderThree != null
                      ? customBuilder?.customBuilderThree!(
                      groupInfo, memberList)
                  // Please define the corresponding custom widget in `profileWidgetBuilder` before using it here.
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: isDesktopScreen
                            ? null
                            : Border(
                            bottom: BorderSide(
                                color: theme.weakDividerColor ??
                                    CommonColor.weakDividerColor))),
                    child: Column(
                      children: [
                        InkWell(
                          onTapDown: (details) async{
                            if(isDesktopScreen){
                              TUIKitWidePopup.showPopupWindow(
                                  operationKey: TUIKitWideModalOperationKey.groupAddOpt,
                                  isDarkBackground: false,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                  context: context,
                                  offset: Offset(min(details.globalPosition.dx,
                                      MediaQuery.of(context).size.width - 186), details.globalPosition.dy),
                                  child: (onClose) => TUIKitColumnMenu(
                                    data: [
                                      ...[
                                        {"label": TIM_t("管理员审批"), "id": "0"},
                                        {"label": TIM_t("自动审批"), "id": "1"},
                                        {"label": TIM_t("禁止邀请"), "id": "2"}]
                                          .map((e){
                                        return ColumnMenuItem(label: e["label"] as String, onClick: ()async{
                                          var resp = await WBsyncHttpRequest().post(WBApi.setGroupInfo,data: {"team_id":model.groupID,"beinvitemode":e["id"]});
                                          if (resp.code == 200) {
                                            setState(() {
                                              model.beinvitemode = e["id"];
                                            });
                                          }
                                          onClose();
                                        });
                                      }),
                                    ],
                                  )
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                TIM_t("邀请入群方式"),
                                style: TextStyle(
                                    fontSize: isDesktopScreen ? 14 : 16,
                                    color: theme.darkTextColor),
                              ),
                              Spacer(),
                              Text(["管理员审批","自动审批","禁止邀请"][int.parse(model.beinvitemode ?? "2")] ),
                              Icon(Icons.keyboard_arrow_right,
                                  color: theme.weakTextColor)
                            ],
                          ),
                        ),

                      ],
                    ),
                  )
                  )!;
                case GroupProfileWidgetEnum.customBuilderFour:
                  return (customBuilder?.customBuilderFour != null
                      ? customBuilder?.customBuilderFour!(groupInfo, memberList)
                      // Please define the corresponding custom widget in `profileWidgetBuilder` before using it here.
                      : Text(TIM_t("如使用自定义区域，请在profileWidgetBuilder传入对应组件")))!;
                case GroupProfileWidgetEnum.customBuilderFive:
                  return (customBuilder?.customBuilderFive != null
                      ? customBuilder?.customBuilderFive!(groupInfo, memberList)
                      // Please define the corresponding custom widget in `profileWidgetBuilder` before using it here.
                      : Text(TIM_t("如使用自定义区域，请在profileWidgetBuilder传入对应组件")))!;
                default:
                  return Container();
              }
            }).toList();
          }

          if (widget.builder != null) {
            return groupProfilePage(
              child: widget.builder!(context, groupInfo, memberList),
            );
          } else if (widget.profileWidgetsOrder != null) {
            return groupProfilePage(
              child: Column(
                children: [
                  ..._renderWidgetsWithOrder(widget.profileWidgetsOrder!)
                ],
              ),
            );
          } else {
            return groupProfilePage(
                child: Column(
              children: [..._renderWidgetsWithOrder(_defaultWidgetOrder)],
            ));
          }
        });
  }
  Future<bool> sendGroupCardToConversation(V2TimConversation conv) async{
    var dic = '{"businessID":"dgg_group_businessId","groupID":"${model.groupID}","groupName":"${model.groupInfo?.groupName}"}';
    V2TimValueCallback<V2TimMsgCreateInfoResult> createCustomMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().createCustomMessage(
      data: dic,

    );
    if(createCustomMessageRes.code == 0){
      String? id =  createCustomMessageRes.data?.id;
      // 发送自定义消息

      V2TimValueCallback<V2TimMessage> sendMessageRes = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(id: id!, receiver: conv.userID ?? "", groupID: conv.groupID ?? "");
      if(sendMessageRes.code == 0){
        // 发送成功
        return true;
      }
    }
    return false;
  }
}
