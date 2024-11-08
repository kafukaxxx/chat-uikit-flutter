// ignore_for_file: must_be_immutable

import 'dart:ui';

import 'package:azlistview_all_platforms/azlistview_all_platforms.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/az_list_view.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/radio_button.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:wb_flutter_tool/popup/jw_popup.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart';

import '../../business_logic/separate_models/tui_group_profile_model.dart';
import '../../business_logic/view_models/tui_self_info_view_model.dart';
import '../../data_services/services_locatar.dart';

class GroupProfileMemberList extends StatefulWidget {
  final List<V2TimGroupMemberFullInfo?> memberList;
  final Function(String userID)? removeMember;
  final bool canSlideDelete;
  final bool canSelectMember;
  final bool canAtAll;
  String? groupId;

  // when the @ need filter some group types
  final String? groupType;
  final Function(List<V2TimGroupMemberFullInfo> selectedMember)? onSelectedMemberChange;
  // notice: onTapMemberItem and onSelectedMemberChange use together will triger together
  final Function(V2TimGroupMemberFullInfo memberInfo, TapDownDetails? tapDetails)? onTapMemberItem;
  // When sliding to the bottom bar callBack
  final Function()? touchBottomCallBack;

  final int? maxSelectNum;

  Widget? customTopArea;

  GroupProfileMemberList({
    Key? key,
    required this.memberList,
    this.groupType,
    this.removeMember,
    this.groupId,
    this.canSlideDelete = true,
    this.canSelectMember = false,
    this.canAtAll = false,
    this.onSelectedMemberChange,
    this.onTapMemberItem,
    this.customTopArea,
    this.touchBottomCallBack,
    this.maxSelectNum,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileMemberListState();
}

class _GroupProfileMemberListState extends TIMUIKitState<GroupProfileMemberList> {
  List<V2TimGroupMemberFullInfo> selectedMember = [];
  //显示内容
  bool _shouldReact = false;
  //坐标位置
  Offset? _position;
  final TUISelfInfoViewModel selfModel = serviceLocator<TUISelfInfoViewModel>();

  _getShowName(V2TimGroupMemberFullInfo? item) {
    final friendRemark = item?.friendRemark ?? "";
    final nameCard = item?.nameCard ?? "";
    final nickName = item?.nickName ?? "";
    final userID = item?.userID ?? "";
    return friendRemark.isNotEmpty
        ? friendRemark
        : nameCard.isNotEmpty
            ? nameCard
            : nickName.isNotEmpty
                ? nickName
                : userID;
  }

  List<ISuspensionBeanImpl> _getShowList(List<V2TimGroupMemberFullInfo?> memberList) {
    final List<ISuspensionBeanImpl> showList = List.empty(growable: true);
    for (var i = 0; i < memberList.length; i++) {
      final item = memberList[i];
      final showName = _getShowName(item);
      if (item?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER || item?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN) {
        showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "@"));
      } else {
        String pinyin = PinyinHelper.getPinyinE(showName);
        String tag = pinyin.substring(0, 1).toUpperCase();
        if (RegExp("[A-Z]").hasMatch(tag)) {
          showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
        } else {
          showList.add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
        }
      }
    }

    SuspensionUtil.sortListBySuspensionTag(showList);

    // add @everyone item
    if (widget.canAtAll) {
      final canAtGroupType = ["Work", "Public", "Meeting"];
      if (canAtGroupType.contains(widget.groupType)) {
        showList.insert(0, ISuspensionBeanImpl(memberInfo: V2TimGroupMemberFullInfo(userID: "__kImSDK_MesssageAtALL__", nickName: TIM_t("所有人")), tagIndex: ""));
      }
    }

    return showList;
  }

  Widget _buildListItem(BuildContext context, V2TimGroupMemberFullInfo memberInfo) {
    final theme = Provider.of<TUIThemeViewModel>(context).theme;
    final isDesktopScreen = TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;
    final isGroupMember = memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER;
    return Container(
        color: Colors.white,
        child: Slidable(
            endActionPane: widget.canSlideDelete && isGroupMember
                ? ActionPane(motion: const DrawerMotion(), children: [
                    SlidableAction(
                      onPressed: (_) {
                        if (widget.removeMember != null) {
                          widget.removeMember!(memberInfo.userID);
                        }
                      },
                      flex: 1,
                      backgroundColor: theme.cautionColor ?? CommonColor.cautionColor,
                      autoClose: true,
                      label: TIM_t("删除"),
                    )
                  ])
                : null,
            child: Column(children: [
              ListTile(
                tileColor: Colors.black,
                title: Row(
                  children: [
                    if (widget.canSelectMember)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: CheckBoxButton(
                            onChanged: (isChecked) {
                              if (isChecked) {
                                if (widget.maxSelectNum != null && selectedMember.length >= widget.maxSelectNum!) {
                                  return;
                                }
                                selectedMember.add(memberInfo);
                              } else {
                                selectedMember.remove(memberInfo);
                              }
                              if (widget.onSelectedMemberChange != null) {
                                widget.onSelectedMemberChange!(selectedMember);
                              }
                              setState(() {});
                            },
                            isChecked: selectedMember.contains(memberInfo)),
                      ),
                    Container(
                      width: isDesktopScreen ? 30 : 36,
                      height: isDesktopScreen ? 30 : 36,
                      margin: const EdgeInsets.only(right: 10),
                      child:Listener(
                        child: Avatar(
                          faceUrl: memberInfo.faceUrl ?? "",
                          showName: _getShowName(memberInfo),
                          type: 1,
                        ),
                        onPointerDown: (event) {
                          _shouldReact = event.kind ==
                              PointerDeviceKind.mouse &&
                              event.buttons ==
                                  kSecondaryMouseButton;
                        },
                        onPointerUp: (event) {
                          if (!_shouldReact) return;
                          _position = Offset(
                            event.position.dx,
                            event.position.dy,
                          );
                          var tapp = TapDownDetails(localPosition: _position);
                          onRightClickUser(memberInfo, tapp, context);
                        },
                      )
                    ),
                    Text(_getShowName(memberInfo), style: TextStyle(fontSize: isDesktopScreen ? 14 : 16)),
                    memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER
                        ? Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: Text(TIM_t("群主"),
                                style: TextStyle(
                                  color: theme.ownerColor,
                                  fontSize: isDesktopScreen ? 10 : 12,
                                )),
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.ownerColor ?? CommonColor.ownerColor, width: 1),
                              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                            ),
                          )
                        : memberInfo.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN
                            ? Container(
                                margin: const EdgeInsets.only(left: 5),
                                child: Text(TIM_t("管理员"),
                                    style: TextStyle(
                                      color: theme.adminColor,
                                      fontSize: 12,
                                    )),
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.adminColor ?? CommonColor.adminColor, width: 1),
                                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                ),
                              )
                            : Container(),
                    Spacer(),
                    if ((memberInfo.muteUntil ?? 0) * 1000 > DateTime.now().millisecondsSinceEpoch) Text("已禁言")
                  ],
                ),
                onTap: () {
                  if (widget.onTapMemberItem != null) {
                    widget.onTapMemberItem!(memberInfo, null);
                  }
                  if (widget.canSelectMember) {
                    final isChecked = selectedMember.contains(memberInfo);
                    if (isChecked) {
                      selectedMember.remove(memberInfo);
                    } else {
                      if (widget.maxSelectNum != null && selectedMember.length >= widget.maxSelectNum!) {
                        return;
                      }
                      selectedMember.add(memberInfo);
                    }
                    if (widget.onSelectedMemberChange != null) {
                      widget.onSelectedMemberChange!(selectedMember);
                    }
                    setState(() {});
                  }
                },
              ),
              Divider(thickness: 1, indent: 74, endIndent: 0, color: theme.weakBackgroundColor, height: 0)
            ])));
  }
  onRightClickUser(V2TimGroupMemberFullInfo memberInfo, TapDownDetails tapDetails,BuildContext context) {

    var isMute = (memberInfo.muteUntil ?? 0) * 1000 > DateTime.now().millisecondsSinceEpoch;
   var selfMemberInfo = widget.memberList.firstWhereOrNull(
            (e) => e?.userID == selfModel.loginInfo?.userID);
    if (selfMemberInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_ADMIN || selfMemberInfo?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_OWNER) {
      showPopupWindow(context: context,emptyDismissable: true, offset: Offset(tapDetails.localPosition.dx + 20, tapDetails.localPosition.dy-20), windowBuilder: (context,from,to){
        return Container(
          width: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextButton(child: Text(isMute ?"解除禁言":"禁言",style: TextStyle(color: text3Color)),onPressed: ()async{
                V2TimCallback result = await TencentImSDKPlugin.v2TIMManager
                    .getGroupManager().muteGroupMember(groupID: widget.groupId ?? "", userID: memberInfo.userID, seconds: isMute ? 0: 365*24*3600);
                if (result.code == 0) {
                  final targetIndex =
                  widget.memberList.indexWhere((e) => e!.userID == memberInfo.userID);


                  EasyLoading.showInfo(isMute ? "解除成功":"禁言成功");
                  if (targetIndex != -1) {
                    isMute = !isMute;
                    final targetElem = widget.memberList[targetIndex];
                    targetElem?.muteUntil = isMute ? (DateTime.now().millisecondsSinceEpoch) + 365*24*10 : 0;
                    setState(() {
                      widget.memberList[targetIndex] = targetElem;
                    });
                    final TUIGroupProfileModel groupProfileModel =
                    Provider.of<TUIGroupProfileModel>(context,listen: false);
                   var index = groupProfileModel.groupMemberList.indexWhere((info){
                      return info?.userID == targetElem?.userID;
                    });

                    List<V2TimGroupMemberFullInfo?> lists = groupProfileModel.groupMemberList;
                    lists[index] = targetElem;
                    groupProfileModel.groupMemberList = lists;
                    setState(() {

                    });
                  }
                  // notifyListeners();
                  Navigator.pop(context);
                }else {
                  EasyLoading.showError(result.desc);
                }
              },),

            ],
          ),
        );
      });
    }
  }

  static Widget getSusItem(BuildContext context, TUITheme theme, String tag, {double susHeight = 40}) {
    if (tag == '@') {
      tag = TIM_t("群主、管理员");
    }
    return Container(
      height: susHeight,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 16.0),
      color: theme.weakBackgroundColor,
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        softWrap: true,
        style: TextStyle(
          fontSize: 14.0,
          color: theme.darkTextColor,
        ),
      ),
    );
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    final isDesktopScreen = TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;

    final throteFunction = OptimizeUtils.throttle((ScrollNotification notification) {
      final pixels = notification.metrics.pixels;
      // 总像素高度
      final maxScrollExtent = notification.metrics.maxScrollExtent;
      // 滑动百分比
      final progress = pixels / maxScrollExtent;
      if (progress >= 0.9 && widget.touchBottomCallBack != null) {
        widget.touchBottomCallBack!();
      }
    }, 300);
    final showList = _getShowList(widget.memberList);
    return Container(
      color: isDesktopScreen ? null : theme.weakBackgroundColor,
      child: SafeArea(
          child: Column(
        children: [
          widget.customTopArea != null ? widget.customTopArea! : Container(),
          Expanded(
              child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              throteFunction(notification);
              return true;
            },
            child: (showList.isEmpty)
                ? Center(
                    child: Text(TIM_t("暂无群成员")),
                  )
                : Container(
                    padding: isDesktopScreen ? const EdgeInsets.symmetric(horizontal: 16) : null,
                    child: AZListViewContainer(
                        memberList: showList,
                        susItemBuilder: (context, index) {
                          final model = showList[index];
                          return getSusItem(context, theme, model.getSuspensionTag());
                        },
                        itemBuilder: (context, index) {
                          final memberInfo = showList[index].memberInfo as V2TimGroupMemberFullInfo;

                          return _buildListItem(context, memberInfo);
                        }),
                  ),
          ))
        ],
      )),
    );
  }
}
