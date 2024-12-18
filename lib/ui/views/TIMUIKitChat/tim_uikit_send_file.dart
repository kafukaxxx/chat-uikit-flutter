import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:cross_file/cross_file.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:wb_flutter_tool/im_tool/wb_ext_file_path.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart' hide PlatformUtils;
import 'TIMUIKitMessageItem/tim_uikit_chat_file_icon.dart';
import 'package:just_audio/just_audio.dart';


String _getConvID(V2TimConversation conversation) {
  return (conversation.type == 1
          ? conversation.userID
          : conversation.groupID) ??
      "";
}

sendFileWithConfirmation(
    {required List<XFile> files,
    required V2TimConversation conversation,
    required ConvType conversationType,
    required TUIChatSeparateViewModel model,
    required TUITheme theme,
    required BuildContext context}) async {
  bool isCanSend = true;

  if (!PlatformUtils().isWeb) {
    files.forEach((e) {
      String fileExtension = path.extension(e.path);
      List<String> imgExArr = [".jpg",".jpeg",".png",".gif",".wav",".mp3"];
      if (!imgExArr.contains(fileExtension.toLowerCase())) {
        isCanSend = false;
      }
    });
    files.map((e) => e.path).any((filePath) {
      final directory = Directory(filePath);
      final isDirectoryExists = directory.existsSync();
      if (isDirectoryExists) {
        isCanSend = false;
        return false;
      }
      return true;
    });
  } else {
    files.map((e) => e.name).any((fileName) {
      String fileExtension = path.extension(fileName);
      bool hasNoExtension = fileExtension.isEmpty;
      if (hasNoExtension) {
        isCanSend = false;
        return false;
      }
      return true;
    });
  }

  if (!isCanSend) {
    TUIKitWidePopup.showSecondaryConfirmDialog(
        text: "只能发送图片或音频",
        onConfirm: () {},
        operationKey: TUIKitWideModalOperationKey.unableToSendDueToFolders,
        context: context,
        theme: theme);
    return;
  }

  final option1 = conversation.showName ??
      (conversationType == ConvType.group ? TIM_t("群聊") : TIM_t("对方"));
  TUIKitWidePopup.showPopupWindow(
      operationKey: TUIKitWideModalOperationKey.beforeSendScreenShot,
      context: context,
      isDarkBackground: false,
      width: 600,
      height: files.length < 4 ? 300 : 500,
      title: TIM_t_para("发送给{{option1}}", "发送给$option1")(option1: option1),
      child: (closeFunc) => Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Scrollbar(
                    child: ListView.separated(
                      itemBuilder: (BuildContext context, int index) {
                        final file = files[index];
                        final fileName = PlatformUtils().isWeb
                            ? file.name
                            : path.basename(file.path);
                        return Material(
                          color: theme.wideBackgroundColor,
                          child: InkWell(
                            onTap: () {
                              launchUrl(Uri.file(file.path));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 20),
                              child: Row(
                                children: [
                                  TIMUIKitFileIcon(
                                    size: 44,
                                    fileFormat: fileName.split(
                                        ".")[fileName.split(".").length - 1],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: theme.darkTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          color: theme.weakDividerColor,
                        );
                      },
                      itemCount: files.length,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      OutlinedButton(
                          onPressed: () {
                            closeFunc();
                          },
                          child: Text(TIM_t("取消"))),
                      const SizedBox(
                        width: 20,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            sendFiles(files, model, conversation,
                                conversationType, context);
                            closeFunc();
                          },
                          child: Text(TIM_t("发送")))
                    ],
                  ),
                )
              ],
            ),
          ));
}

Future<void> sendFiles(
    List<XFile> files,
    TUIChatSeparateViewModel model,
    V2TimConversation conversation,
    ConvType conversationType,
    BuildContext context) async {
  for (final file in files) {
    final fileName = file.name;
    final filePath = file.path;
    if (fileName.contains(".wav") || fileName.contains(".mp3")) {
      final player = AudioPlayer();
      var duration = await player.setAudioSource(AudioSource.file(filePath),
          initialPosition: Duration.zero, preload: true);

      await MessageUtils.handleMessageError(
          model.sendSoundMessage(
              soundPath: filePath,
          duration: duration?.inSeconds ?? 0,
              convID: _getConvID(conversation),
              convType: conversationType),
          context);
    }else {
      var encryptPath = await filePath.encrypyPath("");
      await MessageUtils.handleMessageError(
          model.sendFileMessage(
              fileName: fileName,
              filePath: encryptPath,
              convID: _getConvID(conversation),
              convType: conversationType),
          context);
    }
   
    await Future.delayed(const Duration(microseconds: 300));
  }
}

class TIMUIKitSendFile extends TIMUIKitStatelessWidget {
  final V2TimConversation conversation;

  TIMUIKitSendFile({required this.conversation, Key? key}) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final conversationType = conversation.type;
    final option1 = conversation.showName ??
        (conversationType == 2 ? TIM_t("群聊") : TIM_t("会话"));

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
            child: Opacity(
          opacity: 0.85,
          child: Container(
            color: theme.wideBackgroundColor,
            padding: const EdgeInsets.all(40),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(20),
              color: theme.primaryColor ?? theme.weakTextColor!,
              dashPattern: const [6, 3],
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_copy_outlined,
                        size: 60,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Text(
                        TIM_t_para("发送给{{option1}}", "发送给$option1")(
                            option1: option1),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.darkTextColor),
                      )
                    ],
                  ))
                ],
              ),
            ),
          ),
        ))
      ],
    );
  }
}
