
import 'package:azlistview_all_platforms/azlistview_all_platforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_friendship_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/az_list_view.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/radio_button.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';

import '../views/TIMUIKitGroupProfile/widgets/tim_ui_group_member_search.dart';

class ContactList extends StatefulWidget {
  final List<V2TimFriendInfo> contactList;
  final bool isCanSelectMemberItem;
  final bool isCanSlidableDelete;
  final Function(List<V2TimFriendInfo> selectedMember)?
      onSelectedMemberItemChange;
  final Function()? handleSlidableDelte;
  final Color? bgColor;

  /// tap联系人列表项回调
  final void Function(V2TimFriendInfo item)? onTapItem;

  /// 顶部列表
  final List<TopListItem>? topList;

  /// 顶部列表项构造器
  final Widget? Function(TopListItem item)? topListItemBuilder;

  /// Control if shows the online status for each user on its avatar.
  final bool isShowOnlineStatus;

  final int? maxSelectNum;

  final List<V2TimGroupMemberFullInfo?>? groupMemberList;

  /// the builder for the empty item, especially when there is no contact
  final Widget Function(BuildContext context)? emptyBuilder;

  final String? currentItem;
  final bool? canSelectAll;
  final bool? showNotInGroup;

  const ContactList({
    Key? key,
    required this.contactList,
    this.isCanSelectMemberItem = false,
    this.onSelectedMemberItemChange,
    this.isCanSlidableDelete = false,
    this.handleSlidableDelte,
    this.onTapItem,
    this.showNotInGroup,
    this.bgColor,
    this.topList,
    this.topListItemBuilder,
    this.isShowOnlineStatus = false,
    this.maxSelectNum,
    this.groupMemberList,
    this.emptyBuilder,
    this.currentItem,
    this.canSelectAll = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactListState();
}

class _ContactListState extends TIMUIKitState<ContactList> {
  List<V2TimFriendInfo> selectedMember = [];
  List<ISuspensionBeanImpl> searchResults = [];
  String? searchKey;
  final TUIFriendShipViewModel friendShipViewModel =
      serviceLocator<TUIFriendShipViewModel>();

  _getShowName(V2TimFriendInfo item) {
    final friendRemark = item.friendRemark ?? "";
    final nickName = item.userProfile?.nickName ?? "";
    final userID = item.userID;
    final showName = nickName != "" ? nickName : userID;
    return friendRemark != "" ? friendRemark : showName;
  }

  List<ISuspensionBeanImpl> _getShowList(List<V2TimFriendInfo> memberList) {
    final List<ISuspensionBeanImpl> showList = List.empty(growable: true);
    for (var i = 0; i < memberList.length; i++) {
      final item = memberList[i];
      String showName = _getShowName(item);
      if (searchKey?.isNotEmpty == true) {
        if (showName.contains(searchKey!)) {
          if (widget.showNotInGroup == true) {
            if (widget.groupMemberList != null &&
                widget.groupMemberList!.isNotEmpty) {
              var isExist = ((widget.groupMemberList?.indexWhere(
                      (element) => element?.userID == item.userID)) ??
                  -1) >
                  -1;
              if (isExist == false) {
                String pinyin = PinyinHelper.getPinyinE(showName);
                String tag = pinyin.substring(0, 1).toUpperCase();
                if (RegExp("[A-Z]").hasMatch(tag)) {
                  showList.add(
                      ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
                } else {
                  showList.add(
                      ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
                }
              }
            }
          } else {
            String pinyin = PinyinHelper.getPinyinE(showName);
            String tag = pinyin.substring(0, 1).toUpperCase();
            if (RegExp("[A-Z]").hasMatch(tag)) {
              showList
                  .add(ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
            } else {
              showList
                  .add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
            }
          }
        }
      } else {
        if (widget.showNotInGroup == true) {
          if (widget.groupMemberList != null &&
              widget.groupMemberList!.isNotEmpty) {
            var isExist = ((widget.groupMemberList?.indexWhere(
                    (element) => element?.userID == item.userID)) ??
                -1) >
                -1;
            if (isExist == false) {
              String pinyin = PinyinHelper.getPinyinE(showName);
              String tag = pinyin.substring(0, 1).toUpperCase();
              if (RegExp("[A-Z]").hasMatch(tag)) {
                showList.add(
                    ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
              } else {
                showList.add(
                    ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
              }
            }
          }
        } else {
          String pinyin = PinyinHelper.getPinyinE(showName);
          String tag = pinyin.substring(0, 1).toUpperCase();
          if (RegExp("[A-Z]").hasMatch(tag)) {
            showList
                .add(ISuspensionBeanImpl(memberInfo: item, tagIndex: tag));
          } else {
            showList
                .add(ISuspensionBeanImpl(memberInfo: item, tagIndex: "#"));
          }
        }
      }
    }

    SuspensionUtil.sortListBySuspensionTag(showList);

    return showList;
  }

  bool selectedMemberIsOverFlow() {
    if (widget.maxSelectNum == null) {
      return false;
    }

    return selectedMember.length >= widget.maxSelectNum!;
  }

  Widget _buildItem(TUITheme theme, V2TimFriendInfo item) {
    final showName = _getShowName(item);
    final faceUrl = item.userProfile?.faceUrl ?? "";

    final V2TimUserStatus? onlineStatus = widget.isShowOnlineStatus
        ? friendShipViewModel.userStatusList.firstWhere(
            (element) => element.userID == item.userID,
            orElse: () => V2TimUserStatus(statusType: 0))
        : null;

    bool disabled = false;
    if (widget.groupMemberList != null && widget.groupMemberList!.isNotEmpty) {
      disabled = ((widget.groupMemberList
                  ?.indexWhere((element) => element?.userID == item.userID)) ??
              -1) >
          -1;
    }

    final isDesktopScreen = TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color:
                      theme.weakDividerColor ?? CommonColor.weakDividerColor))),
      child: Row(
        children: [
          if (widget.isCanSelectMemberItem)
            Container(
              margin: const EdgeInsets.only(right: 12, bottom: 8),
              child: CheckBoxButton(
                disabled: disabled,
                isChecked: selectedMember.contains(item),
                onChanged: (isChecked) {
                  if (isChecked) {
                    if (selectedMemberIsOverFlow()) {
                      // selectedMember = [item];
                      EasyLoading.showInfo('最多只能选择${widget.maxSelectNum}');
                      setState(() {});
                      return;
                    }
                    selectedMember.add(item);
                  } else {
                    selectedMember.remove(item);
                  }
                  if (widget.onSelectedMemberItemChange != null) {
                    widget.onSelectedMemberItemChange!(selectedMember);
                  }
                  setState(() {});
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            margin: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: isDesktopScreen ? 30 : 40,
              width: isDesktopScreen ? 30 : 40,
              child: Avatar(
                  onlineStatus: onlineStatus,
                  faceUrl: faceUrl,
                  showName: showName),
            ),
          ),
          Expanded(
              child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 10, bottom: 20, right: 28),
            child: Text(
              showName,
              style: TextStyle(
                  color: Colors.black, fontSize: isDesktopScreen ? 14 : 18),
            ),
          )),
        ],
      ),
    );
  }

  Widget generateTopItem(memberInfo) {
    final isDesktopScreen = TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    if (widget.topListItemBuilder != null) {
      final customWidget = widget.topListItemBuilder!(memberInfo);
      if (customWidget != null) {
        return customWidget;
      }
    }
    return InkWell(
        onTap: () {
          if (memberInfo.onTap != null) {
            memberInfo.onTap!();
          }
        },
        child: Container(
          padding: const EdgeInsets.only(top: 8, left: 16),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: hexToColor("DBDBDB")))),
          child: Row(
            children: [
              Container(
                height: isDesktopScreen ? 30 : 40,
                width: isDesktopScreen ? 30 : 40,
                margin: const EdgeInsets.only(right: 12, bottom: 12),
                child: memberInfo.icon,
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      memberInfo.name,
                      style: TextStyle(
                          color: hexToColor("111111"),
                          fontSize: isDesktopScreen ? 14 : 18),
                    ),
                    Expanded(child: Container()),
                    // if (item.id == "newContact")
                    //   const TIMUIKitUnreadCount(),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        color: hexToColor('BBBBBB'),
                      ),
                    )
                  ],
                ),
              ))
            ],
          ),
        ));
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    searchResults = _getShowList(widget.contactList);
    final isDesktopScreen = TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

    if (widget.topList != null && widget.topList!.isNotEmpty) {
      final topList = widget.topList!
          .map((e) => ISuspensionBeanImpl(memberInfo: e, tagIndex: '@'))
          .toList();
      searchResults.insertAll(0, topList);
    }

    if (widget.contactList.isEmpty) {
      return Column(
        children: [
          ...searchResults.map((e) => generateTopItem(e.memberInfo)).toList(),
          Expanded(
              child: widget.emptyBuilder != null
                  ? widget.emptyBuilder!(context)
                  : Container())
        ],
      );
    }

    return Stack(
      children: [
        Positioned(left: 0,height: 65,right: 0,child: GroupMemberSearchTextField(isSearchAddUser: true,onTextChange: (str){
          searchKey = str;
          setState(() {
            searchResults = _getShowList(widget.contactList);
          });
        },)),
        if (widget.canSelectAll == true) Positioned(left: 0,height:50,top: 65,child: Row(
          children: [
            Text("全选"),
            SizedBox(width: 4,),
            CheckBoxButton(isChecked: selectedMember.length == widget.contactList.length,onChanged: (check){
              if (check) {
                for (var item in searchResults) {
                  V2TimFriendInfo items = item.memberInfo;
                  selectedMember.add(items);
                }


              }else {

                selectedMember.clear();

              }
              if (widget.onSelectedMemberItemChange != null) {
                widget.onSelectedMemberItemChange!(selectedMember);
              }
              setState(() {});

            },)
          ],
        )
        ),
        Positioned(top: (widget.canSelectAll == true) ?115:65,left: 0,right: 0,bottom: 0,child: AZListViewContainer(
          memberList: searchResults,
          itemBuilder: (context, index) {
            final memberInfo = searchResults[index].memberInfo;
            if (memberInfo is TopListItem) {
              return generateTopItem(memberInfo);
            } else {
              return Material(
                color: (isDesktopScreen)
                    ? (widget.currentItem == memberInfo.userProfile.userID
                    ? theme.conversationItemChooseBgColor
                    : widget.bgColor)
                    : null,
                child: InkWell(
                  onTap: () {
                    if (widget.isCanSelectMemberItem) {
                      if (selectedMember.contains(memberInfo)) {
                        selectedMember.remove(memberInfo);
                      } else {
                        if (selectedMemberIsOverFlow()) {
                          // selectedMember = [memberInfo];
                          EasyLoading.showInfo('最多只能选择${widget.maxSelectNum}');
                          setState(() {});
                          return;
                        }
                        selectedMember.add(memberInfo);
                      }
                      if (widget.onSelectedMemberItemChange != null) {
                        widget.onSelectedMemberItemChange!(selectedMember);
                      }
                      setState(() {});
                      return;
                    }
                    if (widget.onTapItem != null) {
                      widget.onTapItem!(memberInfo);
                    }
                  },
                  child: _buildItem(theme, memberInfo),
                ),
              );
            }
          },
        )),
      ],
    );
  }
}

class TopListItem {
  final String name;
  final String id;
  final Widget? icon;
  final Function()? onTap;

  TopListItem({required this.name, required this.id, this.icon, this.onTap});
}
