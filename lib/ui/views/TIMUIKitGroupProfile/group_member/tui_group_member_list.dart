// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';

import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_ui_group_member_search.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/group_member_list.dart';

class GroupProfileMemberListPage extends StatefulWidget {
  List<V2TimGroupMemberFullInfo?> memberList;
  TUIGroupProfileModel model;

  GroupProfileMemberListPage({
    Key? key,
    required this.memberList,
    required this.model,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupProfileMemberListPageState();
}

class GroupProfileMemberListPageState
    extends TIMUIKitState<GroupProfileMemberListPage> {
  List<V2TimGroupMemberFullInfo?>? searchMemberList;
  String? searchText;

  _kickedOffMember(String userID) async {
    widget.model.kickOffMember([userID]);
  }

  bool isSearchTextExist(String? searchText) {
    return searchText != null && searchText != "";
  }
  _getShowName(V2TimGroupMemberFullInfo? item) {
    final friendRemark = item?.friendRemark ?? "";
    final nameCard = item?.nameCard ?? "";
    final nickName = item?.nickName ?? "";
    final userID = item?.userID;
    final showName = (nameCard == "") ? (nickName != "" ? nickName : userID) : nameCard;
    return friendRemark != "" ? friendRemark : showName;
  }
  handleSearchGroupMembers(String searchText, context) async {
    searchText = searchText;
    List<V2TimGroupMemberFullInfo?> currentGroupMember =
        Provider.of<TUIGroupProfileModel>(context, listen: false)
            .groupMemberList;

    if (!isSearchTextExist(searchText)) {
      setState(() {
        searchMemberList = null;
      });
      return;
    }
    List<V2TimGroupMemberFullInfo?> localSearch = [];
    for (V2TimGroupMemberFullInfo? info in currentGroupMember) {
      if (_getShowName(info).contains(searchText) == true || info?.userID.contains(searchText) == true) {
        localSearch.add(info);
      }
    }
    // final res =
    //     await widget.model.searchGroupMember(V2TimGroupMemberSearchParam(
    //   keywordList: [searchText],
    //   groupIDList: [widget.model.groupInfo!.groupID],
    // ));

    // if (res.code == 0) {
    List<V2TimGroupMemberFullInfo?> list = [];
    List<V2TimFriendInfo> friends = widget.model.contactList;
    // final searchResult = res.data!.groupMemberSearchResultItems!;
    // searchResult.forEach((key, value) {
    //   if (value is List) {
    for (V2TimGroupMemberFullInfo? item in localSearch) {
      List<V2TimFriendInfo> temps =  friends.where((element) => element.userID == (item?.userID ?? "")).toList();
      if (temps.length > 0) {
        V2TimFriendInfo friend = temps.first;
        item?.friendRemark = friend.friendRemark;
      }
      list.add(item);
    }
    //   }
    // });

    currentGroupMember = list;
    // } else {
    //   currentGroupMember = [];
    // }
    setState(() {
      searchMemberList = currentGroupMember;
    });
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor() == DeviceType.Desktop;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.model),
      ],
      builder: (BuildContext context, Widget? w) {
        final TUIGroupProfileModel groupProfileModel =
        Provider.of<TUIGroupProfileModel>(context);
        String option1 = groupProfileModel.groupInfo?.memberCount.toString() ??
            widget.memberList.length.toString();
        if(isDesktopScreen){
          return  GroupProfileMemberList(
            customTopArea: PlatformUtils().isWeb
                ? null
                : GroupMemberSearchTextField(
              onTextChange: (text) =>
                  handleSearchGroupMembers(text, context),
            ),
            memberList: searchMemberList ?? groupProfileModel.groupMemberList,
            removeMember: _kickedOffMember,
            touchBottomCallBack: () {},
            onTapMemberItem: (friendInfo, details) {
              if (widget.model.onClickUser != null) {
                widget.model.onClickUser!(friendInfo.userID, details);
              }
            },
          );
        }
        return Scaffold(
            appBar: AppBar(
                title: Text(
                  TIM_t_para("群成员({{option1}}人)", "群成员($option1人)")(
                      option1: option1),
                  style: TextStyle(color: theme.appbarTextColor, fontSize: 17),
                ),
                shadowColor: theme.weakBackgroundColor,
                backgroundColor: theme.appbarBgColor ??
                    theme.primaryColor,
                iconTheme: IconThemeData(
                  color: theme.appbarTextColor,
                )),
            body: GroupProfileMemberList(
              customTopArea: PlatformUtils().isWeb
                  ? null
                  : GroupMemberSearchTextField(
                onTextChange: (text) =>
                    handleSearchGroupMembers(text, context),
              ),
              memberList: searchMemberList ?? groupProfileModel.groupMemberList,
              removeMember: _kickedOffMember,
              touchBottomCallBack: () {},
              onTapMemberItem: (friendInfo, details) {
                if (widget.model.onClickUser != null) {
                  widget.model.onClickUser!(friendInfo.userID, details);
                }
              },
            )
        );
      },
    );
  }
}
