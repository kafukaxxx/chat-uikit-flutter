// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_file_icon.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/textSize.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wb_flutter_tool/im_tool/wb_ext_file_path.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart' hide PlatformUtils;

class TIMUIKitFileElem extends StatefulWidget {
  final String? messageID;
  final V2TimFileElem? fileElem;
  final bool isSelf;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final V2TimMessage message;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel chatModel;

  const TIMUIKitFileElem(
      {Key? key,
      required this.chatModel,
      required this.messageID,
      required this.fileElem,
      required this.isSelf,
      required this.isShowJump,
      this.clearJump,
      required this.message,
      this.isShowMessageReaction})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitFileElemState();
}

class _TIMUIKitFileElemState extends TIMUIKitState<TIMUIKitFileElem> {
  String filePath = "";
  bool isWebDownloading = false;
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();
  int downloadProgress = 0;
  V2TimAdvancedMsgListener? advancedMsgListener;
  final GlobalKey containerKey = GlobalKey();
  double? containerHeight;
  bool? _downloadFailed = false;
  String decryptLocalPath = "";
  @override
  void dispose() {
    if (advancedMsgListener != null) {
      TencentImSDKPlugin.v2TIMManager
          .getMessageManager()
          .removeAdvancedMsgListener(listener: advancedMsgListener);
      advancedMsgListener = null;
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!PlatformUtils().isWeb) {
      Future.delayed(const Duration(microseconds: 10), () {
        hasFile();
        dggAsyncDownloadFile();
        addAdvancedMsgListenerForDownload();
      });
    }
  }
  dggAsyncDownloadFile() async {
    if (await hasFile()) {
      if (downloadProgress == 100) {
       print("该文件已下完:${filePath}");
      } else {
        print("该文件正在下载:${widget.messageID}");
      }
      return;
    }
    if (checkIsWaiting()) {
      print("current file is waiting:${widget.messageID}");
    } else {

      await addUrlToWaitingPath(CommonColor.defaultTheme);
      print("current file add waiting:${widget.messageID}");
    }
  }

  Future<bool> addAdvancedMsgListenerForDownload() async {
    if(advancedMsgListener != null){
      return false;
    }
    advancedMsgListener = V2TimAdvancedMsgListener(
      onMessageDownloadProgressCallback:
          (V2TimMessageDownloadProgress messageProgress) async {
        if (messageProgress.msgID == widget.message.msgID) {
          if (messageProgress.isError || messageProgress.errorCode != 0) {
            setState(() {
              _downloadFailed = true;
            });
            return;
          }

          if (messageProgress.isFinish) {
            if (mounted) {
              setState(() {
                downloadProgress = 100;
              });

              if (advancedMsgListener != null) {
                TencentImSDKPlugin.v2TIMManager
                    .getMessageManager()
                    .removeAdvancedMsgListener(listener: advancedMsgListener);
                advancedMsgListener = null;
              }
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
    await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .addAdvancedMsgListener(listener: advancedMsgListener!);
    return true;
  }

  Future<String> getSavePath() async {
    String savePathWithAppPath =
        '/storage/emulated/0/Android/data/com.tencent.flutter.tuikit/cache/' +
            (widget.message.msgID ?? "") +
            widget.fileElem!.fileName!;
    return savePathWithAppPath;
  }

  Future<bool> hasFile() async {
    if (PlatformUtils().isWeb) {
      return true;
    }
    String savePath = TencentUtils.checkString(
            model.getFileMessageLocation(widget.messageID)) ??
        TencentUtils.checkString(widget.message.fileElem!.localUrl) ??
        widget.message.fileElem?.path ??
        '';
    File f = File(savePath);
    if (f.existsSync() && widget.messageID != null) {
      filePath = savePath;
      var tmpstr = await filePath.decryptPath();
      if (mounted) {
        setState(() {
          decryptLocalPath = tmpstr;
        });
      }
      if (downloadProgress != 100) {
        setState(() {
          downloadProgress = 100;
        });
      }
      if (model.getMessageProgress(widget.messageID) != 100) {
        model.setMessageProgress(widget.messageID!, 100);
      }
      if (advancedMsgListener != null) {
        TencentImSDKPlugin.v2TIMManager
            .getMessageManager()
            .removeAdvancedMsgListener(listener: advancedMsgListener);
        advancedMsgListener = null;
      }
      return true;
    }
    return false;
  }

  String showFileSize(int fileSize) {
    if (fileSize < 1024) {
      return fileSize.toString() + "B";
    } else if (fileSize < 1024 * 1024) {
      return (fileSize / 1024).toStringAsFixed(2) + "KB";
    } else if (fileSize < 1024 * 1024 * 1024) {
      return (fileSize / 1024 / 1024).toStringAsFixed(2) + "MB";
    } else {
      return (fileSize / 1024 / 1024 / 1024).toStringAsFixed(2) + "GB";
    }
  }

  addUrlToWaitingPath(TUITheme theme) async {
    if (widget.messageID != null) {
      model.addWaitingList(widget.messageID!);
    }
    if (model.getWaitingListLength() == 1) {
      await downloadFile(theme);
    }
  }

  checkIsWaiting() {
    bool res = false;
    try {
      if (widget.messageID!.isNotEmpty) {
        res = model.isWaiting(widget.messageID!);
      }
    } catch (err) {
      // err
    }
    return res;
  }

  downloadFile(TUITheme theme) async {
    if (PlatformUtils().isMobile) {
      if (PlatformUtils().isIOS) {
        if (!await Permissions.checkPermission(
            context, Permission.photosAddOnly.value, theme, false)) {
          return;
        }
      } else {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if ((androidInfo.version.sdkInt) >= 33) {
        } else {
          var storage = await Permissions.checkPermission(
            context,
            Permission.storage.value,
          );
          if (!storage) {
            return;
          }
        }
      }
    }
    await model.downloadFile();
  }

  Future<bool> hasZeroSize(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      return fileSize == 0;
    } catch (e) {
      return false;
    }
  }

  tryOpenFile(context, theme) async {
    if (!PlatformUtils().isWeb &&
        (await hasZeroSize(filePath) || widget.message.status == 3)) {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: "不支持 0KB 文件的传输",
          infoCode: 6660417));
      return;
    }
    if (PlatformUtils().isMobile) {
      if (PlatformUtils().isIOS) {
        if (!await Permissions.checkPermission(
            context, Permission.photosAddOnly.value, theme!, false)) {
          return;
        }
      } else {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if ((androidInfo.version.sdkInt) >= 33) {
        } else {
          var storage = await Permissions.checkPermission(
            context,
            Permission.storage.value,
          );
          if (!storage) {
            return;
          }
        }
      }
    }

    try {
      String decryptFile = await filePath.decryptPath();
      if (PlatformUtils().isDesktop && !PlatformUtils().isWindows) {
        launchUrl(Uri.file(decryptFile));
      } else {
        OpenFile.open(decryptFile);
      }
      // ignore: empty_catches
    } catch (e) {
      OpenFile.open(filePath);
    }
  }

  void downloadWebFile(String fileUrl) async {
    if (mounted) {
      setState(() {
        isWebDownloading = true;
      });
    }
    String fileName = Uri.parse(fileUrl).pathSegments.last;
    try {
      http.Response response = await http.get(
        Uri.parse(fileUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      final html.AnchorElement downloadAnchor =
          html.document.createElement('a') as html.AnchorElement;

      final html.Blob blob = html.Blob([response.bodyBytes]);

      downloadAnchor.href = html.Url.createObjectUrlFromBlob(blob);
      downloadAnchor.download = widget.message.fileElem?.fileName ?? fileName;

      downloadAnchor.click();
    } catch (e) {
      html.AnchorElement(
        href: widget.fileElem?.path ?? "",
      )
        ..setAttribute(
            "download", widget.message.fileElem?.fileName ?? fileName)
        ..setAttribute("target", '_blank')
        ..style.display = "none"
        ..click();
    }
    if (mounted) {
      setState(() {
        isWebDownloading = false;
      });
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final received = downloadProgress;
    final fileName = widget.fileElem!.fileName ?? "";
    final fileSize = widget.fileElem!.fileSize;
    final borderRadius = widget.isSelf
        ? const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(2),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10))
        : const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10));
    String? fileFormat;
    if (widget.fileElem?.fileName != null &&
        widget.fileElem!.fileName!.isNotEmpty) {
      final String fileName = widget.fileElem!.fileName!;
      fileFormat = fileName.split(".")[max(fileName.split(".").length - 1, 0)];
    }
    final RenderBox? containerRenderBox =
        containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerRenderBox != null) {
      containerHeight = containerRenderBox.size.height;
    }

    return Row(
      key: containerKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        // if (widget.isSelf && isWebDownloading)
        //   Container(
        //     margin: const EdgeInsets.only(top: 2),
        //     child: LoadingAnimationWidget.threeArchedCircle(
        //       color: theme.weakTextColor ?? Colors.grey,
        //       size: 20,
        //     ),
        //   ),
        TIMUIKitMessageReactionWrapper(
            chatModel: widget.chatModel,
            isShowJump: widget.isShowJump,
            clearJump: widget.clearJump,
            isFromSelf: widget.message.isSelf ?? true,
            isShowMessageReaction: widget.isShowMessageReaction ?? true,
            message: widget.message,
            child: GestureDetector(
              onTap: () async {
                try {
                  if (PlatformUtils().isWeb) {
                    if (!isWebDownloading) {
                      downloadWebFile(widget.fileElem?.path ?? "");
                    }
                    return;
                  }


                  if (await hasFile()) {
                    if (received == 100) {
                      tryOpenFile(context, theme);
                    } else {
                      onTIMCallback(
                        TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("正在下载中"),
                          infoCode: 6660411,
                        ),
                      );
                    }
                    return;
                  }
                  if (checkIsWaiting()) {
                    onTIMCallback(
                      TIMCallback(
                          type: TIMCallbackType.INFO,
                          infoRecommendText: TIM_t("已加入待下载队列，其他文件下载中"),
                          infoCode: 6660413),
                    );
                    return;
                  } else {
                    await addUrlToWaitingPath(theme);
                  }
                } catch (e) {
                  onTIMCallback(TIMCallback(
                      type: TIMCallbackType.INFO,
                      infoRecommendText: "文件处理异常",
                      infoCode: 6660416));
                }
              },
              child: decryptLocalPath.isEmpty ?  _renderImage(heroTag: 1) : Container(
                          child: Image.file(File(decryptLocalPath),width: 200,)),
            )),
        if (!widget.isSelf && isWebDownloading)
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: LoadingAnimationWidget.threeArchedCircle(
              color: theme.weakTextColor ?? Colors.grey,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _renderImage({dynamic heroTag,int downLoaded = 0
  }) {

    return Hero(tag: heroTag, child: downloadProgress >= 100 ?
    ( _getLocalImgData().length > 0 ? Image(image: MemoryImage(_getLocalImgData() as Uint8List),width: 200,fit: BoxFit.cover,gaplessPlayback: true,):
    Container(
      width: 200,height: 200,decoration: BoxDecoration(
        color: Colors.grey
    ),
      alignment: Alignment.center,
      child: Text("加载中。。。点击重试",style: TextStyle(color: Colors.white),),
    )):
    Container(width: 200,height: 200,decoration: BoxDecoration(
      color: Colors.grey,
    ),child: Stack(
      children: [

        Center(child: CircularProgressIndicator(semanticsLabel: "下载中",value: downloadProgress/100,
          color: themeColor,
          backgroundColor: Colors.blue,
        ),)
      ],
    ),));
  }
  Uint8List _getLocalImgData() {
    if (filePath == '') {
      String savePath = TencentUtils.checkString(
          model.getFileMessageLocation(widget.messageID)) ??
          TencentUtils.checkString(widget.message.fileElem!.localUrl) ??
          widget.message.fileElem?.path ??
          '';
      filePath = savePath;
    }

    try {
      var aescode = Uint8List.fromList(aesKey.codeUnits);
      var file = File(filePath).readAsBytesSync();
      var imgfile = file.sublist(aescode.length, file.length);
      return imgfile;
    } catch (e) {
      // print("get localImgData error：${e}");


      return Uint8List(0);
    }
  }
}
