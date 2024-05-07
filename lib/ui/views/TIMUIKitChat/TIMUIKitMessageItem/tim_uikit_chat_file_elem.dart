// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_file_icon.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/avatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/image_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/textSize.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wb_flutter_tool/im_tool/wb_ext_file_path.dart';
import 'package:wb_flutter_tool/wb_flutter_tool.dart' hide PlatformUtils;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class TIMUIKitFileElem extends StatefulWidget {
  final String? messageID;
  final V2TimFileElem? fileElem;
  final bool isSelf;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final V2TimMessage message;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel chatModel;

  const TIMUIKitFileElem({Key? key, required this.chatModel, required this.messageID, required this.fileElem, required this.isSelf, required this.isShowJump, this.clearJump, required this.message, this.isShowMessageReaction})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitFileElemState();
}

class _TIMUIKitFileElemState extends TIMUIKitState<TIMUIKitFileElem> {
  String filePath = "";
  bool isWebDownloading = false;
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();
  int downloadProgress = 0;
  late V2TimAdvancedMsgListener advancedMsgListener;
  final GlobalKey containerKey = GlobalKey();
  double? containerHeight;
  bool? _downloadFailed = false;
  String imgUrl = "";
  String decryptLocalPath = "";
  String decodeUrl = "";
  final TUISelfInfoViewModel selfInfoViewModel = serviceLocator<TUISelfInfoViewModel>();

  @override
  void dispose() {
    TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener(listener: advancedMsgListener);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (!PlatformUtils().isWeb) {
      Future.delayed(const Duration(microseconds: 10), () {
        hasFile();
      });
    }

    advancedMsgListener = V2TimAdvancedMsgListener(
      onMessageDownloadProgressCallback: (V2TimMessageDownloadProgress messageProgress) async {
        if (messageProgress.msgID == widget.message.msgID) {
          if (messageProgress.isError || messageProgress.errorCode != 0) {
            // if (mounted) {
            //   setState(() {
            //     _downloadFailed = true;
            //   });
            // }

            return;
          }

          if (messageProgress.isFinish) {
            if (mounted) {
              // setState(() {
                downloadProgress = 100;
              // });

              TencentImSDKPlugin.v2TIMManager.getMessageManager().removeAdvancedMsgListener(
                    listener: advancedMsgListener,
                  );
            }
          } else {
            final currentProgress = (messageProgress.currentSize / messageProgress.totalSize * 100).floor();
            if (mounted && currentProgress > downloadProgress) {
              // setState(() {
                downloadProgress = currentProgress;
              // });
            }
          }
        }
      },
    );
    TencentImSDKPlugin.v2TIMManager.getMessageManager().addAdvancedMsgListener(listener: advancedMsgListener);
    dggAsyncDownloadFile();
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

  Future<String> getSavePath() async {
    String savePathWithAppPath = '/storage/emulated/0/Android/data/com.tencent.flutter.tuikit/cache/' + (widget.message.msgID ?? "") + widget.fileElem!.fileName!;
    return savePathWithAppPath;
  }

  Future<bool> hasFile() async {
    if (PlatformUtils().isWeb) {
      return true;
    }
    V2TimValueCallback<V2TimMessageOnlineUrl> imgdata = await TencentImSDKPlugin.v2TIMManager.getMessageManager().getMessageOnlineUrl(msgID: widget.messageID!);
      if (mounted) {
        setState(() {
          imgUrl = imgdata.data?.fileElem?.url ?? "";
        });
      }

    String savePath = TencentUtils.checkString(model.getFileMessageLocation(widget.messageID)) ?? TencentUtils.checkString(widget.message.fileElem!.localUrl) ?? widget.message.fileElem?.path ?? '';
    print("local file url:${widget.message.fileElem!.localUrl}, path:${widget.message.fileElem?.path}, savedPath:${savePath}");
    if (savePath.contains("tencent/uploads/")) {
      savePath = savePath.replaceAll("tencent/uploads/", "temp_tencent\\uploads\\").replaceAll("/", "\\");
      print("changed path:${savePath}");
    }
    if (WBManager().downloadPath == "") {
      if (savePath.contains("TencentCloudChat")) {
        var downloadPath = savePath.split("\\").first;
        if (downloadPath.isNotEmpty) {
          WBManager().downloadPath = downloadPath + "\\";
          GetStorage().write("wbdownloadPath", WBManager().downloadPath);
        }
      }


    }

    print("GetStorage():${GetStorage().read<String>("wbdownloadPath")} --savePath:$savePath");
    if (savePath == "") {
      if (WBManager().downloadPath.isNotEmpty) {
        print("空的id :${widget.message.fileElem?.UUID}");
        savePath = WBManager().downloadPath + (widget.message.fileElem?.UUID ?? "");
      }
    }
    File f = File(savePath);

    if (f.existsSync() && widget.messageID != null) {
      filePath = savePath;
      var tmpstr = await filePath.decryptPath();
      print("tmpstr:$tmpstr");
      // if (mounted) {
        // setState(() {
          decryptLocalPath = tmpstr;
        // });
      // }

      if (downloadProgress != 100) {
        if (mounted) {
          // setState(() {
            downloadProgress = 100;
          // });
        }
      }
      if (model.getMessageProgress(widget.messageID) != 100) {
        model.setMessageProgress(widget.messageID!, 100);
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
        if (!await Permissions.checkPermission(context, Permission.photosAddOnly.value, theme, false)) {
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
    if (!PlatformUtils().isWeb && (await hasZeroSize(filePath) || widget.message.status == 3)) {
      onTIMCallback(TIMCallback(type: TIMCallbackType.INFO, infoRecommendText: "不支持 0KB 文件的传输", infoCode: 6660417));
      return;
    }
    if (PlatformUtils().isMobile) {
      if (PlatformUtils().isIOS) {
        if (!await Permissions.checkPermission(context, Permission.photosAddOnly.value, theme!, false)) {
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
      var savedPath = await filePath.decryptPath();
      if (PlatformUtils().isDesktop && !PlatformUtils().isWindows) {
        launchUrl(Uri.file(savedPath));
      } else {
        OpenFile.open(savedPath);
      }
      // ignore: empty_catches
    } catch (e) {
      OpenFile.open(filePath);
    }
  }

  void downloadWebFile(String fileUrl) async {
    if (mounted) {
      // setState(() {
      //   isWebDownloading = true;
      // });
    }
    String fileName = Uri.parse(fileUrl).pathSegments.last;
    try {
      http.Response response = await http.get(
        Uri.parse(fileUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      final html.AnchorElement downloadAnchor = html.document.createElement('a') as html.AnchorElement;

      final html.Blob blob = html.Blob([response.bodyBytes]);

      downloadAnchor.href = html.Url.createObjectUrlFromBlob(blob);
      downloadAnchor.download = widget.message.fileElem?.fileName ?? fileName;

      downloadAnchor.click();
    } catch (e) {
      html.AnchorElement(
        href: widget.fileElem?.path ?? "",
      )
        ..setAttribute("download", widget.message.fileElem?.fileName ?? fileName)
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

  Widget getImageWidget(BuildContext context, TUITheme theme) {
    Widget defaultAvatar() {
      return Image.asset(
          TencentUtils.checkString(
              selfInfoViewModel.globalConfig?.defaultAvatarAssetPath) ??
              'images/default_c2c_head.png',
          fit: BoxFit.cover,
          package:
          selfInfoViewModel.globalConfig?.defaultAvatarAssetPath != null
              ? null
              : 'tencent_cloud_chat_uikit');
    }
    return defaultAvatar();
  }

  ImageProvider getImageProvider(String? url) {
    ImageProvider defaultAvatar() {
      return Image.asset(
          TencentUtils.checkString(selfInfoViewModel
              .globalConfig?.defaultAvatarAssetPath) ??
              'images/default_c2c_head.png',
          fit: BoxFit.cover,
          package: selfInfoViewModel.globalConfig?.defaultAvatarAssetPath != null ? null
              : 'tencent_cloud_chat_uikit').image;
    }
    if (imgUrl.isNotEmpty) {
      if(url?.isNotEmpty ?? false) {
        return Image.file(File(url ?? ""),width: 200,).image;
      } else if (decryptLocalPath.isNotEmpty) {
        return Image.file(File(decryptLocalPath),width: 200,).image;
      }
      return defaultAvatar();
    } else {
      WBToastUtil.showToastCenter("图片解析失败");
      return defaultAvatar();
    }
  }


  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final received = downloadProgress;
    final fileName = widget.fileElem!.fileName ?? "";
    final fileSize = widget.fileElem!.fileSize;
    final borderRadius = widget.isSelf
        ? const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(2), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))
        : const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
    String? fileFormat;
    if (widget.fileElem?.fileName != null && widget.fileElem!.fileName!.isNotEmpty) {
      final String fileName = widget.fileElem!.fileName!;
      fileFormat = fileName.split(".")[max(fileName.split(".").length - 1, 0)];
    }
    final RenderBox? containerRenderBox = containerKey.currentContext?.findRenderObject() as RenderBox?;
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
        GestureDetector(
          onTap: () async {

            try {
              if (PlatformUtils().isWeb) {
                if (!isWebDownloading) {
                  downloadWebFile(widget.fileElem?.path ?? "");
                }
                return;
              }
              if (imgUrl.isNotEmpty) {
                var opfile = await DefaultCacheManager().getSingleFile(
                    imgUrl);
                decodeUrl = await opfile.path.decryptPath();
                //用电脑自带插件打开，客户觉得卡 、改成有弹窗打开
                // print("decodeUrl:$decodeUrl");
                // outputLogger.i("decodeUrl:$decodeUrl");
                // OpenFile.open(decodeUrl);
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false, // set to false
                    pageBuilder: (_, __, ___) => ImageScreen(
                        imageProvider: getImageProvider(decodeUrl), heroTag: decodeUrl),
                  ),
                );
              }
              if (await hasFile()) {
                if (received == 100) {
                  // tryOpenFile(context, theme);
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
                  TIMCallback(type: TIMCallbackType.INFO, infoRecommendText: TIM_t("已加入待下载队列，其他文件下载中"), infoCode: 6660413),
                );
                return;
              } else {
                await addUrlToWaitingPath(theme);
              }
            } catch (e) {
              onTIMCallback(TIMCallback(type: TIMCallbackType.INFO, infoRecommendText: "文件处理异常", infoCode: 6660416));
            }
          },
          child:Hero(
            tag: decodeUrl,
            child: (decryptLocalPath.isEmpty ? //本地有没有缓存文件
            (imgUrl.isEmpty ? _emptyImage() :  _renderCacheImage(url: imgUrl)) :
            Container( //读取本地缓存文件
              child: Image.file(File(decryptLocalPath),width: 200,),
            )),
          ),
        ),
        // TIMUIKitMessageReactionWrapper(
        //     chatModel: widget.chatModel,
        //     isShowJump: widget.isShowJump,
        //     clearJump: widget.clearJump,
        //     isFromSelf: widget.message.isSelf ?? true,
        //     isShowMessageReaction: widget.isShowMessageReaction ?? true,
        //     message: widget.message,
        //     child: GestureDetector(
        //       onTap: () async {
        //         try {
        //           if (PlatformUtils().isWeb) {
        //             if (!isWebDownloading) {
        //               downloadWebFile(widget.fileElem?.path ?? "");
        //             }
        //             return;
        //           }
        //           if (imgUrl.isNotEmpty) {
        //             var opfile = await DefaultCacheManager().getSingleFile(
        //                 imgUrl);
        //             var pp = await opfile.path.decryptPath();
        //             OpenFile.open(pp);
        //           }
        //           if (await hasFile()) {
        //             if (received == 100) {
        //               // tryOpenFile(context, theme);
        //             } else {
        //               onTIMCallback(
        //                 TIMCallback(
        //                   type: TIMCallbackType.INFO,
        //                   infoRecommendText: TIM_t("正在下载中"),
        //                   infoCode: 6660411,
        //                 ),
        //               );
        //             }
        //             return;
        //           }
        //           if (checkIsWaiting()) {
        //             onTIMCallback(
        //               TIMCallback(type: TIMCallbackType.INFO, infoRecommendText: TIM_t("已加入待下载队列，其他文件下载中"), infoCode: 6660413),
        //             );
        //             return;
        //           } else {
        //             await addUrlToWaitingPath(theme);
        //           }
        //         } catch (e) {
        //           onTIMCallback(TIMCallback(type: TIMCallbackType.INFO, infoRecommendText: "文件处理异常", infoCode: 6660416));
        //         }
        //       },
        //       child:imgUrl.isEmpty ? Text("处理中.....") : (decryptLocalPath.isEmpty ?  _renderCacheImage(url: imgUrl) : Container(
        //         child: Image.file(File(decryptLocalPath),width: 200,),
        //       )),
        //     )),
        // if (!widget.isSelf && isWebDownloading)
        //   Container(
        //     margin: const EdgeInsets.only(top: 2),
        //     child: LoadingAnimationWidget.threeArchedCircle(
        //       color: theme.weakTextColor ?? Colors.grey,
        //       size: 20,
        //     ),
        //   ),
      ],
    );
  }

  Widget _emptyImage() {
    return Container(
        width: 200,
        height: 200,
        padding:const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.grey,
        alignment: Alignment.center,
        child:const Text("图片地址获取失败，请切换窗口重新加载...",style: TextStyle(color: Colors.white),),
    );
  }
  Widget _renderCacheImage({dynamic heroTag,required String url}) {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey,
      alignment: Alignment.center,
      child: FutureBuilder(
        future: DefaultCacheManager().getSingleFile(url),
        builder: (context,snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(_getFlutterCachedImg(snapshot.data!));
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Container(width: 30,height: 30,child: CircularProgressIndicator(),);
          }
        },

      ),
    );
  }
  Uint8List _getFlutterCachedImg(File filex) {
    try {
      var aescode = Uint8List.fromList( aesKey.codeUnits);
      var file = filex.readAsBytesSync();
      var imgfile = file.sublist(aescode.length,file.length);
      // print("imgfile:$imgfile");
      return imgfile;
    } catch(e) {
      print("get localImgData error：${e}");


      return Uint8List(0);
    }
  }
}
