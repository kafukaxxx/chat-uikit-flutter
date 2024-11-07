import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wb_flutter_tool/popup/jw_popup.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_class.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitConversation/dgg_transfer_conversation_list.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';


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
      TUITheme theme,
      VoidCallback clickShare,
      BuildContext context
      ) {



    return InkWell(
      onTap: clickShare,
      child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(left: 15),
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
