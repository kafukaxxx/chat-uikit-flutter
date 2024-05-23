import 'dart:io';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:cross_file/cross_file.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart' as platform;
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:wb_flutter_tool/im_tool/wb_ext_file_path.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart';
import 'TIMUIKitMessageItem/tim_uikit_chat_file_icon.dart';
import 'package:audioplayers/audioplayers.dart';

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

  if (!platform.PlatformUtils().isWeb) {
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
        text: TIM_t("无法发送，包含文件夹"),
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
                          child: Text(TIM_t("发送"),style:TextStyle(color: theme.weakBackgroundColor),))
                    ],
                  ),
                )
              ],
            ),
          ));
}
Future<void> sendAudio(
    XFile file,
    TUIChatSeparateViewModel model,
    V2TimConversation conversation,
    ConvType conversationType,
    BuildContext context) async{
  AudioPlayer audioPlayer = AudioPlayer();
  var duration = await audioPlayer.setSourceDeviceFile(file.path)
      .then((_) => audioPlayer.getDuration());
  int durationInSeconds = (duration?.inSeconds ?? 0).toInt();
  //发送
  await MessageUtils.handleMessageError(
    model.sendSoundMessage(
        soundPath: file.path,
        duration: durationInSeconds,
        convID: _getConvID(conversation),
        convType: conversationType
    ),context);
}
// _sendVideoMessage(AssetEntity asset, TUIChatSeparateViewModel model) async {
//   try {
//     final plugin = FcNativeVideoThumbnail();
//     final originFile = await asset.originFile;
//     final size = await originFile!.length();
//     if (size >= 104857600) {
//       onTIMCallback(TIMCallback(
//           type: TIMCallbackType.INFO,
//           infoRecommendText: TIM_t("发送失败,视频不能大于100MB"),
//           infoCode: 6660405));
//       return;
//     }
//
//     final duration = asset.videoDuration.inSeconds;
//     final filePath = originFile.path;
//     final convID = widget.conversationID;
//     final convType = widget.conversationType;
//
//     String tempPath = (await getTemporaryDirectory()).path +
//         p.extension(originFile.path, 3) +
//         ".jpeg";
//
//     await plugin.getVideoThumbnail(
//       srcFile: originFile.path,
//       keepAspectRatio: true,
//       destFile: tempPath,
//       format: 'jpeg',
//       width: 128,
//       quality: 100,
//       height: 128,
//     );
//     MessageUtils.handleMessageError(
//         model.sendVideoMessage(
//             videoPath: filePath,
//             duration: duration,
//             snapshotPath: tempPath,
//             convID: convID,
//             convType: convType),
//         context);
//   } catch (e) {
//     onTIMCallback(TIMCallback(
//         type: TIMCallbackType.INFO,
//         infoRecommendText: TIM_t("视频文件异常"),
//         infoCode: 6660415));
//   }
// }

_sendMediaMessage(
    TUIChatSeparateViewModel model,
    XFile file,
    V2TimConversation conversation,
    ConvType conversationType,
    BuildContext context
    ) async {
  try {
    final convID = _getConvID(conversation);
    final convType = conversationType;

    // FilePickerResult? result =
    // await FilePicker.platform.pickFiles(type: fileType);
    if (file.path != null && file.path.isNotEmpty) {
      // File f = File(file.path!);
      final String savePath = file.path;
      // final String type = TencentUtils.getFileType(
      //     (savePath.split(".")[savePath.split(".").length - 1])
      //         .toLowerCase())
      //     .split("/")[0];

      var fileFormat = savePath.split(".")[max(savePath.split(".").length - 1, 0)];
      var encryptPath = await savePath.encryptVideo(fileFormat);
      var coverPath = (await getTemporaryDirectory()).path + "videoCover.jpeg";

      ByteData bytes = await rootBundle.load("assets/video.jpeg");
      final coverdata = bytes.buffer.asUint8List();
      File(coverPath)..createSync(recursive: true)..writeAsBytesSync(coverdata);
      MessageUtils.handleMessageError(
          model.sendVideoMessage(
              videoPath: encryptPath,
              convID: convID,
              convType: convType,
              snapshotPath: coverPath),
          context);
    } else {
      throw TypeError();
    }
  } catch (err) {
    // ignore: avoid_print
    outputLogger.i("send media err: $err");
    WBToastUtil.showToastCenter("视频文件异常");
  }
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
    var fileformat = fileName.split(".")[max(filePath.split(".").length - 1, 0)];
    var encryPath = "";

    //视频处理
    if(fileformat == 'mp4' || fileformat == 'm4v' || fileformat == 'avi') {
      _sendMediaMessage(model,file,conversation,conversationType,context);
      return;
    }
    if(fileformat == 'm4a' || fileformat == 'mp3') { //发送音频
      await sendAudio(file,model,conversation,conversationType,context);
      await Future.delayed(const Duration(microseconds: 300));
      return;
    }else {
      encryPath = await filePath.encrypyPath(fileformat);
    }
    if (encryPath.isNotEmpty) {
      await MessageUtils.handleMessageError(
          model.sendFileMessage(
              fileName: fileName,
              filePath: encryPath,
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
