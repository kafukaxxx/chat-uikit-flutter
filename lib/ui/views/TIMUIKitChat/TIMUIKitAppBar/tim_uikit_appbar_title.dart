import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

class TIMUIKitAppBarTitle extends StatelessWidget {
  final Widget? title;
  final String conversationShowName;
  final bool showC2cMessageEditStatus;
  final String fromUser;
  final GestureTapDownCallback? onClick;
  final String? timeIp;
  final String? address;
  final TextStyle? textStyle;

  const TIMUIKitAppBarTitle(
      {Key? key,
      this.title,
      this.textStyle,
        this.timeIp,
        this.address,
      required this.conversationShowName,
      required this.showC2cMessageEditStatus,
      required this.fromUser, this.onClick})
      : super(key: key);

  Widget titleText(String text){
    return InkWell(
      onTapDown: onClick,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(  
            text,
            style: textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
          ),
          Offstage(
            offstage: (timeIp == null && address == null) || (timeIp == "" && address == ""),
            child: Text("${timeIp}  (${address})",style: TextStyle(fontSize: 10,color: Colors.grey),),
          )
        ],
      ),
    );
  }

  // String conversationShowName;
  @override
  Widget build(BuildContext context) {
    int status = Provider.of<TUIChatGlobalModel>(context, listen: true)
        .getC2cMessageEditStatus(fromUser);
    if (status == 0) {
      if (title != null) {
        return title!;
      }
      return titleText(conversationShowName,);
    } else {
      if (showC2cMessageEditStatus) {
        return titleText(
          TIM_t("对方正在输入中..."),);

      } else {
        if (title != null) {
          return title!;
        }
        return titleText(
          conversationShowName,);

      }
    }
  }
}
