import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/radio_button.dart';




class DggTransferConversationList extends StatefulWidget {
  final Function(List<V2TimConversation?> conversationList)? onChanged;
  DggTransferConversationList({Key? key,this.onChanged}) : super(key: key);

  @override
  State<DggTransferConversationList> createState() => _DggTransferConversationListState();
}

class _DggTransferConversationListState extends State<DggTransferConversationList> {
  List<V2TimConversation?> convs = [];
  List<V2TimConversation?> _selectedConversation = [];
  EasyRefreshController _refreshController = EasyRefreshController();
  String? pageStr = "0";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getConversationList("0");
  }
  Future<List<V2TimConversation?>?> getConversationList(String page) async{
//获取会话列表
    V2TimValueCallback<V2TimConversationResult> getConversationListRes =
        await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getConversationList(
        count: 100, //分页拉取的个数，一次分页拉取不宜太多，会影响拉取的速度，建议每次拉取 100 个会话
        nextSeq:page,//分页拉取的游标，第一次默认取传 0，后续分页拉传上一次分页拉取成功回调里的 nextSeq
    );
    if (getConversationListRes.code == 0) {
      //拉取成功
      bool? isFinished = getConversationListRes.data?.isFinished; //是否拉取完
      pageStr = getConversationListRes.data?.nextSeq; //后续分页拉取的游标
      List<V2TimConversation?>? conversationList =
           getConversationListRes.data?.conversationList; //此次拉取到的消息列表
      //如果没有拉取完，使用返回的nextSeq继续拉取直到isFinished为true
      if (isFinished == true) {
        _refreshController.finishLoad(noMore: true);
      }else {
        _refreshController.finishLoad();
      }
      setState(() {
        convs.addAll(conversationList ?? []);
      });
      return conversationList;
    }
    return null;

  }
  @override
  Widget build(BuildContext context) {
    return EasyRefresh.builder(controller: _refreshController,builder: (context,physics,header,footer){


      return ListView.builder(itemCount: convs.length,physics: physics,itemBuilder: (context,index) {
        var conversation = convs[index];
        final faceUrl = conversation?.faceUrl ?? "";
        final showName = conversation?.showName ?? "";
        return Container(
          margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

                Container(
                  padding: EdgeInsets.only(left: 8, top: 10 ),
                  child: CheckBoxButton(
                    isChecked: _selectedConversation.contains(conversation),
                    onChanged: (value) {
                      if (value) {
                        _selectedConversation.add(conversation);
                      } else {
                        _selectedConversation.remove(conversation);
                      }
                      setState(() {});
                      widget.onChanged?.call(_selectedConversation);
                    },
                  ),
                ),
              Expanded(
                  child: InkWell(
                    onTap: () {

                        final isSelected = _selectedConversation.contains(conversation);
                        if (isSelected) {
                          _selectedConversation.remove(conversation);
                        } else {
                          _selectedConversation.add(conversation);
                        }

                        setState(() {});
                        widget.onChanged?.call(_selectedConversation);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(top: 10, left: 16),
                      child: Row(
                        children: [
                          Container(
                            height:  30 ,
                            width:   30 ,
                            margin: const EdgeInsets.only(right: 12),
                            child: Avatar(
                              faceUrl: faceUrl,
                              showName: showName,
                              type: conversation?.type,
                            ),
                          ),
                          Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(top: 10, bottom:  12 ),
                                child: Text(
                                  showName,
                                  // textAlign: TextAlign.center,
                                  style:
                                  TextStyle(color: const Color(0xFF111111), fontSize:  16 ),
                                ),
                              ))
                        ],
                      ),
                    ),
                  ))
            ],
          ),
        );
      });
    },onLoad: () async{
      getConversationList(pageStr ?? "0");
    },);
  }
}
