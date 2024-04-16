import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_group_profile_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitGroupProfile/widgets/tim_ui_group_member_search.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/group_member_list.dart';
import 'package:tencent_im_base/tencent_im_base.dart';

GlobalKey<_DeleteGroupMemberPageState> deleteGroupMemberKey = GlobalKey();

class DeleteGroupMemberPage extends StatefulWidget {
  final TUIGroupProfileModel model;
  final VoidCallback? onClose;

  const DeleteGroupMemberPage({Key? key, required this.model, this.onClose}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeleteGroupMemberPageState();
}

class _DeleteGroupMemberPageState extends TIMUIKitState<DeleteGroupMemberPage> {
  List<V2TimGroupMemberFullInfo> selectedGroupMember = [];
  List<V2TimGroupMemberFullInfo?>? searchMemberList;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    List<V2TimGroupMemberFullInfo?>? tempArr = handleRole(widget.model.groupMemberList);
    List<V2TimGroupMemberFullInfo?> list = [];
    List<V2TimFriendInfo> friends = widget.model.contactList;
    tempArr?.forEach((item) {
      List<V2TimFriendInfo> temps =  friends.where((element) => element.userID == (item?.userID ?? "")).toList();
      if (temps.length > 0) {
        V2TimFriendInfo friend = temps.first;
        item?.friendRemark = friend.friendRemark;
      }
      list.add(item);

    });
    searchMemberList = list;

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
    List<V2TimGroupMemberFullInfo?> currentGroupMember = Provider.of<TUIGroupProfileModel>(context, listen: false).groupMemberList;
    print("currentGroupMembers : ${currentGroupMember}");
    if (!isSearchTextExist(searchText)) {
      setState(() {
        searchMemberList = null;
      });
      return;
    }
    List<V2TimGroupMemberFullInfo?> localSearch = [];
    for (V2TimGroupMemberFullInfo? info in currentGroupMember) {

      if (_getShowName(info).contains(searchText) == true) {
        localSearch.add(info);
      }
    }
    // final res = await widget.model.searchGroupMember(V2TimGroupMemberSearchParam(
    //   keywordList: [searchText],
    //   groupIDList: [widget.model.groupInfo!.groupID],
    // ));

    // if (res.code == 0) {
    List<V2TimGroupMemberFullInfo?> list = [];
    List<V2TimFriendInfo> friends = widget.model.contactList;
    // final searchResult = res.data!.groupMemberSearchResultItems!;
    // searchResult.forEach((key, value) {
    //   if (value is List) {
    for (V2TimGroupMemberFullInfo? item in handleRole(localSearch)) {
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

  handleRole(groupMemberList) {
    return groupMemberList?.where((value) => value?.role == GroupMemberRoleType.V2TIM_GROUP_MEMBER_ROLE_MEMBER).toList() ?? [];
  }

  void submitDelete() async {
    if (selectedGroupMember.isNotEmpty) {
      final userIDs = selectedGroupMember.map((e) => e.userID).toList();
      widget.model.kickOffMember(userIDs);
      widget.onClose ?? Navigator.pop(context);
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;

    return MultiProvider(providers: [
      ChangeNotifierProvider.value(value: widget.model)
    ],
      builder: (context,w) {
        return TUIKitScreenUtils.getDeviceWidget(
            context: context,
            desktopWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GroupProfileMemberList(
                customTopArea: PlatformUtils().isWeb
                    ? null
                    : GroupMemberSearchTextField(
                  onTextChange: (text) =>
                      handleSearchGroupMembers(text, context),
                ),
                memberList: searchMemberList ?? handleRole(widget.model.groupMemberList),
                canSelectMember: true,
                canSlideDelete: false,
                onSelectedMemberChange: (selectedMember) {
                  selectedGroupMember = selectedMember;
                },
                touchBottomCallBack: () {},
              ),
            ),
            defaultWidget: Scaffold(
                appBar: AppBar(
                    title: Text(
                      TIM_t("删除群成员"),
                      style: TextStyle(color: theme.appbarTextColor, fontSize: 17),
                    ),
                    actions: [
                      TextButton(
                        onPressed: submitDelete,
                        child: Text(
                          TIM_t("确定"),
                          style: TextStyle(
                            color: theme.appbarTextColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                    shadowColor: theme.weakBackgroundColor,
                    backgroundColor: theme.appbarBgColor ?? theme.primaryColor,
                    iconTheme: IconThemeData(
                      color: theme.appbarTextColor,
                    )),
                body: GroupProfileMemberList(
                  memberList: handleRole(searchMemberList ?? widget.model.groupMemberList),
                  canSelectMember: true,
                  canSlideDelete: false,
                  onSelectedMemberChange: (selectedMember) {
                    selectedGroupMember = selectedMember;
                  },
                  touchBottomCallBack: () {},
                )));
      },);
  }
}
