import 'dart:io';
import 'dart:math';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/video_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wb_flutter_tool/im_tool/wb_ext_file_path.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart' hide PlatformUtils;

class TIMUIKitVideoElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;

  const TIMUIKitVideoElem(this.message,
      {Key? key,
      this.isShowJump = false,
      this.clearJump,
      this.isFrom,
      this.isShowMessageReaction,
      required this.chatModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitVideoElemState();
}

class _TIMUIKitVideoElemState extends TIMUIKitState<TIMUIKitVideoElem> {
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimVideoElem stateElement = widget.message.videoElem!;
  int downloadProgress = 0;
  late V2TimAdvancedMsgListener advancedMsgListener;
  String? dggLocalCover;
  Widget errorDisplay(TUITheme? theme) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        width: 1,
        color: Colors.black12,
      )),
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            Text(
              TIM_t("视频加载失败"),
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget generateSnapshot(TUITheme theme, int height) {
    print(
        "snapshot url:${stateElement.snapshotUrl},${stateElement.snapshotPath}");
    if (widget.message.videoElem?.localVideoUrl != null) {
      String videoStr = widget.message.videoElem?.localVideoUrl ?? "";
      String fileFormat =
      videoStr.split(".")[max(videoStr.split(".").length - 1, 0)];
      String tempPath =
          videoStr.replaceAll(".${fileFormat}", "_dggtemp") + ".jpeg";
      if (File(tempPath).existsSync()) {
        dggLocalCover = tempPath;
      }
    }

    if (dggLocalCover != null) {
      return Image.file(
        File(dggLocalCover!),
        fit: BoxFit.fitWidth,
      );
    }
    if (!PlatformUtils().isWeb) {
      final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
      final timeStamp = widget.message.timestamp ?? current;
      if (current - timeStamp < 300) {
        if (stateElement.snapshotPath != null &&
            stateElement.snapshotPath != '') {
          File imgF = File(stateElement.snapshotPath!);
          bool isExist = imgF.existsSync();
          if (isExist) {
            return Image.file(File(stateElement.snapshotPath!),
                fit: BoxFit.fitWidth);
          }
        }
      }
    }

    if ((stateElement.snapshotUrl == null || stateElement.snapshotUrl == '') &&
        (stateElement.snapshotPath == null ||
            stateElement.snapshotPath == '')) {
      return Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(
              width: 1,
              color: Colors.black12,
            )),
        height: double.parse(height.toString()),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: theme.weakTextColor ?? Colors.grey,
                size: 28,
              )
            ],
          ),
        ),
      );
    }
    return (!PlatformUtils().isWeb && stateElement.snapshotUrl == null ||
            widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING)
        ? (stateElement.snapshotPath!.isNotEmpty
            ? Image.file(File(stateElement.snapshotPath!), fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth))
        : (PlatformUtils().isWeb ||
                stateElement.localSnapshotUrl == null ||
                stateElement.localSnapshotUrl == "")
            ? Image.network(stateElement.snapshotUrl!, fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth);
  }
  Future<bool> hasFile() async {
    if (PlatformUtils().isWeb) {
      return true;
    }
    String? savePath = TencentUtils.checkString(
        widget.message.videoElem?.localVideoUrl ?? "");
    if (savePath != null) {
      File f = File(savePath);
      if (f.existsSync()) {

        if (downloadProgress != 100) {
          setState(() {
            downloadProgress = 100;
          });
        }
        return true;
      }
    }

    return false;
  }
  generateLocalImage() async {
    print("获取视频本地地址：${widget.message.videoElem?.localVideoUrl}");
    String videoStr = (widget.message.videoElem?.localVideoUrl ?? "");
    String? fileFormat;

    String? videoName;
    if (widget.message.videoElem?.localVideoUrl != null && widget.message.videoElem?.localVideoUrl != "") {

      videoName = widget.message.videoElem?.UUID ?? "";
      fileFormat = videoName!.split(".")[max(videoName!.split(".").length - 1, 0)];
      String myLocalVideo = await videoStr.decryptPath(isImg: false);
      String tempPath =
          videoStr.replaceAll(".${fileFormat}", "_dggtemp") + ".jpeg";
      final plugin = FcNativeVideoThumbnail();

      await plugin.getVideoThumbnail(
        srcFile: myLocalVideo,

        destFile: tempPath,
        format: 'jpeg',
        width: 128,
        quality: 100,
        height: 128,
      );
      setState(() {
        dggLocalCover = tempPath;
      });
    }

  }

  downloadMessageDetailAndSave() async {
    if (TencentUtils.checkString(widget.message.msgID) != null) {
      if (TencentUtils.checkString(widget.message.videoElem!.videoUrl) ==
          null) {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        if (response.data != null) {
          widget.message.videoElem = response.data!.videoElem;
          Future.delayed(const Duration(microseconds: 10), () {
            setState(() => stateElement = response.data!.videoElem!);
          });
        }
      }
      if (!PlatformUtils().isWeb) {
        if (TencentUtils.checkString(widget.message.videoElem!.localVideoUrl) ==
                null ||
            !File(widget.message.videoElem!.localVideoUrl!).existsSync()) {
          print(
              "msg local videourl:${widget.message.videoElem?.localVideoUrl}");
          V2TimCallback result = await _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: false);
          if (result.code == 0) {
            print(
                "视频下载成功了,${widget.message.videoElem?.localVideoUrl},描述：${result.desc}");
          }
        }
        // if (TencentUtils.checkString(
        //             widget.message.videoElem!.localSnapshotUrl) ==
        //         null ||
        //     !File(widget.message.videoElem!.localSnapshotUrl!).existsSync()) {
        //   _messageService.downloadMessage(
        //       msgID: widget.message.msgID!,
        //       messageType: 5,
        //       imageType: 0,
        //       isSnapshot: true);
        // }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!PlatformUtils().isWeb) {
      Future.delayed(const Duration(microseconds: 10), () {
        hasFile();
      });
    }
    if (widget.message.videoElem?.localVideoUrl != null) {
      generateLocalImage();
    }
    advancedMsgListener = V2TimAdvancedMsgListener(
      onMessageDownloadProgressCallback:
          (V2TimMessageDownloadProgress messageProgress) async {
        if (messageProgress.msgID == widget.message.msgID) {
          if (messageProgress.isFinish) {
            if (mounted) {
              setState(() {
                downloadProgress = 100;
                generateLocalImage();
              });
            }
          } else {
            final currentProgress =
            (messageProgress.currentSize / messageProgress.totalSize * 100)
                .floor();
            if (mounted && currentProgress > downloadProgress) {
              setState(() {
                downloadProgress = currentProgress;
              });
            }
          }
        }
      },
    );
    TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: advancedMsgListener);
  }

  void launchDesktopFile(String path) async{
    String decryptFile = await path.decryptPath(isImg: false);
    if (PlatformUtils().isWindows) {
      OpenFile.open(decryptFile);
    } else {
      launchUrl(Uri.file(decryptFile));
    }
  }


  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final heroTag =
        "${widget.message.msgID ?? widget.message.id ?? widget.message.timestamp ?? DateTime.now().millisecondsSinceEpoch}${widget.isFrom}";

    return GestureDetector(
      onTap: () async{
        if (PlatformUtils().isWeb) {
          final url = widget.message.videoElem?.videoUrl ?? widget.message.videoElem?.videoPath ?? "";
          TUIKitWidePopup.showMedia(
              context: context,
              mediaURL: url,
              onClickOrigin: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ));
          return;
        }
        if (PlatformUtils().isDesktop) {
          print("点击下载新视频：${widget.message.videoElem?.videoUrl}");
          if (widget.message.videoElem?.localVideoUrl == null || widget.message.videoElem?.localVideoUrl?.isEmpty == true) {
            downloadMessageDetailAndSave();
          } else {
            generateLocalImage();
          }
          final videoElem = widget.message.videoElem;
          if (videoElem != null) {
            final localVideoUrl =
                TencentUtils.checkString(videoElem.localVideoUrl);
            final videoPath = TencentUtils.checkString(videoElem.videoPath);
            final videoUrl = videoElem.videoUrl;
            if (localVideoUrl != null) {
              launchDesktopFile(localVideoUrl);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaPath: localVideoUrl,
              //     onClickOrigin: () => launchDesktopFile(localVideoUrl));
            } else if (videoPath != null && File(videoPath).existsSync()) {
              launchDesktopFile(videoPath);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaPath: videoPath,
              //     onClickOrigin: () => launchDesktopFile(videoPath));
            } else if (TencentUtils.isTextNotEmpty(videoUrl)) {
              onTIMCallback(TIMCallback(
                  infoCode: 6660414,
                  infoRecommendText: TIM_t("正在下载中"),
                  type: TIMCallbackType.INFO));
            }
          }
        } else {
          print("点击下载新视频：${widget.message.videoElem?.videoUrl}");
          if (widget.message.videoElem?.localVideoUrl == null || widget.message.videoElem?.localVideoUrl?.isEmpty == true) {
            downloadMessageDetailAndSave();
          } else {
            generateLocalImage();
            final localVideoUrl =
            TencentUtils.checkString(widget.message.videoElem?.localVideoUrl);
            var path = localVideoUrl ?? "";
            await path.decryptPath(isImg: false);
          }
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false, // set to false
              pageBuilder: (_, __, ___) => VideoScreen(
                message: widget.message,
                heroTag: heroTag,
                videoElement: stateElement,
              ),
            ),
          );
        }
      },
      child: Hero(
          tag: heroTag,
          child: TIMUIKitMessageReactionWrapper(
              chatModel: widget.chatModel,
              message: widget.message,
              isShowJump: widget.isShowJump,
              isShowMessageReaction: widget.isShowMessageReaction ?? true,
              clearJump: widget.clearJump,
              isFromSelf: widget.message.isSelf ?? true,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  double? positionRadio;
                  if ((stateElement.snapshotWidth) != null &&
                      stateElement.snapshotHeight != null &&
                      stateElement.snapshotWidth != 0 &&
                      stateElement.snapshotHeight != 0) {
                    positionRadio = (stateElement.snapshotWidth! /
                        stateElement.snapshotHeight!);
                  }
                  return ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: PlatformUtils().isWeb
                              ? 300
                              : constraints.maxWidth * 0.5,
                          maxHeight: min(constraints.maxHeight * 0.8, 300),
                          minHeight: 20,
                          minWidth: 20),
                      child: Stack(
                        children: <Widget>[
                          if (positionRadio != null &&
                              (stateElement.snapshotUrl != null ||
                                  stateElement.snapshotUrl != null))
                            AspectRatio(
                              aspectRatio: positionRadio,
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: Colors.transparent),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                  child: generateSnapshot(theme,
                                      stateElement.snapshotHeight ?? 100))
                            ],
                          ),
                          if (widget.message.status !=
                                      MessageStatus.V2TIM_MSG_STATUS_SENDING &&
                                  (stateElement.snapshotUrl != null ||
                                      stateElement.snapshotPath != null) &&
                                  stateElement.videoPath != null ||
                              stateElement.videoUrl != null)
                            Positioned.fill(
                              // alignment: Alignment.center,
                              child: Center(
                                  child: Image.asset('images/play.png',
                                      package: 'tencent_cloud_chat_uikit',
                                      height: 64)),
                            ),
                          if (widget.message.videoElem?.duration != null &&
                              widget.message.videoElem!.duration! > 0)
                            Positioned(
                                right: 10,
                                bottom: 10,
                                child: Text(
                                    MessageUtils.formatVideoTime(widget
                                                .message.videoElem!.duration!)
                                        .toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12))),
                          Positioned.fill(child: Offstage(offstage: downloadProgress == 100,child:
                          Container(color: Color.fromRGBO(0, 0, 0, 0.5),child:
                          Center(child: CircularProgressIndicator(value: downloadProgress/100.0,color: themeColor,backgroundColor: Colors.grey,)))))
                        ],
                      ));
                }),
              ))),
    );
  }
}
