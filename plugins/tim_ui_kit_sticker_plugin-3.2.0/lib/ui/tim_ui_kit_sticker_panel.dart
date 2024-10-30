import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tim_ui_kit_sticker_plugin/utils/tim_ui_kit_sticker_data.dart';

class StickerPanel extends StatefulWidget {
  final void Function()? sendTextMsg;
  final void Function(int index, String data) sendFaceMsg;
  final void Function(int unicode) addText;
  final void Function(String emojiName)? addCustomEmojiText;
  final void Function() deleteText;
  final List<CustomStickerPackage> customStickerPackageList;
  final Widget? emptyPlaceHolder;
  final void Function(BuildContext context, LayerLink layerLink,
      int selectedPackageIdx, CustomSticker selectedSticker)? onLongTap;
  final bool showBottomContainer;
  final int crossAxisCount;
  final bool showDeleteButton;
  final Color? backgroundColor;
  final Color? bottomColor;
  final Color? lightPrimaryColor;
  final EdgeInsetsGeometry? panelPadding;
  final double? height;
  final double? width;
  final bool isWideScreen;

  const StickerPanel({Key? key,
    this.sendTextMsg,
    required this.sendFaceMsg,
    required this.deleteText,
    required this.addText,
    this.addCustomEmojiText,
    this.bottomColor,
    required this.customStickerPackageList,
    this.emptyPlaceHolder,
    this.onLongTap,
    this.backgroundColor = const Color(0xFFEDEDED),
    this.lightPrimaryColor = const Color(0xFF3371CD),
    this.showBottomContainer = true,
    this.showDeleteButton = true,
    this.crossAxisCount = 8,
    this.height,
    this.width,
    this.isWideScreen = false,
    this.panelPadding})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<StickerPanel> {
  int selectedIdx = 0;
  late List<int> textEmojiIndexList;
  late List<int> customEmojiStickerIndexList;

  void filterTextEmojiIndexList() {
    List<int> textEmojiList = [];
    widget.customStickerPackageList
        .asMap()
        .keys
        .forEach((customStickerPackageIndex) {
      if (!widget.customStickerPackageList[customStickerPackageIndex]
          .isCustomSticker) {
        textEmojiList.add(customStickerPackageIndex);
      }
    });
    setState(() {
      textEmojiIndexList = textEmojiList;
    });
  }

  void filterCustomEmojiStickerIndexList() {
    List<int> customEmojiList = [];
    widget.customStickerPackageList
        .asMap()
        .keys
        .forEach((customStickerPackageIndex) {
      if (widget.customStickerPackageList[customStickerPackageIndex]
          .isCustomEmojiSticker) {
        customEmojiList.add(customStickerPackageIndex);
      }
    });
    setState(() {
      customEmojiStickerIndexList = customEmojiList;
    });
  }

  List<Widget> _buildEmojiListWidget(
      List<CustomStickerPackage> customStickerList) {
    List<Widget> list = [];
    for (var index = 0; index < (customStickerList.length); index++) {
      final customEmojiFace = customStickerList[index];

      list.add(InkWell(
        onTap: () {
          setState(() {
            selectedIdx = index;
          });
        },
        child: Container(
            width: 40,
            height: 40,
            // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: selectedIdx == index
                    ? widget.lightPrimaryColor
                    : widget.backgroundColor,
                borderRadius: widget.isWideScreen
                    ? null
                    : const BorderRadius.all(Radius.circular(4))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: customEmojiFace.isCustomSticker
                            ? (customEmojiFace.isCustomEmojiSticker
                            ? (customEmojiFace.isDefaultEmojiSticker
                            ? CustomEmojiItem(
                            size: 22,
                            sticker: customEmojiFace.menuItem,
                            isCustomEmoji: true,
                            isDeafultEmoji: true,
                            baseUrl: customEmojiFace.baseUrl)
                            : CustomEmojiItem(
                            size: 22,
                            sticker: customEmojiFace.menuItem,
                            isCustomEmoji: true,
                            baseUrl: customEmojiFace.baseUrl))
                            : CustomEmojiItem(
                            size: 22,
                            sticker: customEmojiFace.menuItem,
                            baseUrl: customEmojiFace.baseUrl))
                            : Container(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: EmojiItem(
                            size: 19,
                            name: customEmojiFace.menuItem.name,
                            unicode: customEmojiFace.menuItem.unicode!,
                          ),
                        ),
                      ),
                    ))
              ],
            )),
      ));
    }
    return list;
  }

  Widget _buildEmojiPanel(List<int> textEmojiIndexList,
      List<int> customEmojiStickerIndexList,
      List<CustomStickerPackage> customStickerList) {
    if (customStickerList.isEmpty) return Container();
    if (customStickerList[selectedIdx].stickerList.isEmpty) {
      return widget.emptyPlaceHolder ??
          Center(
            child: Text(TIM_t("暂无表情"),
                style: const TextStyle(color: Colors.black12, fontSize: 24)),
          );
    }
    if (textEmojiIndexList.contains(selectedIdx)) {
      return Stack(
        children: [
          GridView(
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: 1,
            ),
            children: [
              ...customStickerList[selectedIdx].stickerList.map(
                    (item) {
                  LayerLink layerLink = LayerLink();
                  return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        widget.addText(item.unicode!);
                      },
                      onLongPressStart: (LongPressStartDetails details) {
                        if (widget.onLongTap != null) {
                          widget.onLongTap!(
                              context, layerLink, selectedIdx, item);
                        }
                      },
                      child: CompositedTransformTarget(
                          link: layerLink,
                          child: EmojiItem(
                            name: item.name,
                            unicode: item.unicode!,
                          )));
                },
              ).toList()
            ],
          ),
          if (widget.showDeleteButton && !widget.isWideScreen)
            Align(
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                child: GestureDetector(
                  onTap: () {
                    widget.deleteText();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0x66bebebe),
                                offset: Offset(0.0, 0.0),
                                blurRadius: 10,
                                spreadRadius: 2),
                          ],
                          borderRadius: const BorderRadius.all(Radius.circular(4))),
                      margin: const EdgeInsets.only(right: 10),
                      width: 44,
                      height: 35,
                      child: Center(
                        child: Image.asset(
                          'images/delete_emoji.png',
                          package: 'tim_ui_kit_sticker_plugin',
                          width: 28,
                        ),
                      )),
                ),
              ),
            ),
        ],
      );
    }
    if (customEmojiStickerIndexList.contains(selectedIdx)) {
      return Stack(
        children: [
          GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isWideScreen ? 7 : 8,
              childAspectRatio: 1,
            ),
            children: customStickerList[selectedIdx].stickerList.map(
                  (item) {
                LayerLink layerLink = LayerLink();
                return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (widget.addCustomEmojiText != null) {
                        widget.addCustomEmojiText!(item.name);
                      }
                    },
                    onLongPressStart: (LongPressStartDetails details) {
                      if (widget.onLongTap != null) {
                        widget.onLongTap!(
                            context, layerLink, selectedIdx, item);
                      }
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CompositedTransformTarget(
                            link: layerLink,
                            child: CustomEmojiItem(
                                isBigImage: false,
                                isCustomEmoji: true,
                                isDeafultEmoji: customStickerList[selectedIdx]
                                    .isDefaultEmoji,
                                baseUrl: customStickerList[selectedIdx].baseUrl,
                                sticker: item))));
              },
            ).toList(),
          ),
          if (widget.showDeleteButton && !widget.isWideScreen)
            Align(
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                child: GestureDetector(
                  onTap: () {
                    widget.deleteText();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0x66bebebe),
                                offset: Offset(0.0, 0.0),
                                blurRadius: 10,
                                spreadRadius: 2),
                          ],
                          borderRadius: const BorderRadius.all(Radius.circular(4))),
                      margin: const EdgeInsets.only(right: 10),
                      width: 44,
                      height: 35,
                      child: Center(
                        child: Image.asset(
                          'images/delete_emoji.png',
                          package: 'tim_ui_kit_sticker_plugin',
                          width: 28,
                        ),
                      )),
                ),
              ),
            ),
        ],
      );
    }
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      children: customStickerList[selectedIdx].stickerList.map(
            (item) {
          LayerLink layerLink = LayerLink();
          return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                final path = customStickerList[selectedIdx].baseUrl == null
                    ? item.url!
                    : customStickerList[selectedIdx].baseUrl! +
                    '/' +
                    item.name;
                widget.sendFaceMsg(
                    item.index,
                    path);
              },
              onLongPressStart: (LongPressStartDetails details) {
                if (widget.onLongTap != null) {
                  widget.onLongTap!(context, layerLink, selectedIdx, item);
                }
              },
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CompositedTransformTarget(
                      link: layerLink,
                      child: CustomEmojiItem(
                          isBigImage: true,
                          baseUrl: customStickerList[selectedIdx].baseUrl,
                          sticker: item))));
        },
      ).toList(),
    );
  }

  Widget _buildBottomPanel(List<int> textEmojiIndexList,
      List<int> customEmojiStickerIndexList,
      List<CustomStickerPackage> customStickerList) {
    return SizedBox(
        height: 40,
        child: Row(children: [
          Expanded(
              child: Container(
                  margin: const EdgeInsets.only(right: 25),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child:
                    Row(children: _buildEmojiListWidget(customStickerList)),
                  ))),
          if ((textEmojiIndexList.contains(selectedIdx) ||
              customEmojiStickerIndexList.contains(selectedIdx)) &&
              widget.sendTextMsg != null)
            ElevatedButton(
                child: Text(TIM_t("发送")),
                style: ElevatedButton.styleFrom(),
                onPressed: () {
                  widget.sendTextMsg!();
                })
        ]));
  }

  @override
  Widget build(BuildContext context) {
    filterTextEmojiIndexList();
    filterCustomEmojiStickerIndexList();
    return SizedBox(
      width: widget.width ?? 350,
      child: Column(
        children: [
          Container(
            // TODO
            height:
            (widget.height ?? 248) - (widget.showBottomContainer ? 48 : 0),
            color: widget.backgroundColor,
            padding: widget.panelPadding ??
                (widget.isWideScreen
                    ? const EdgeInsets.all(16)
                    : const EdgeInsets.fromLTRB(24, 16, 24, 16)),
            child: Scrollbar(
              child: _buildEmojiPanel(textEmojiIndexList,
                  customEmojiStickerIndexList, widget.customStickerPackageList),
            ),
          ),
          // Expanded(child: Container(
          //   height: (widget.height ?? 248) -
          //       (widget.showBottomContainer ? 58 : 0),
          //   color: widget.backgroundColor,
          //   padding: widget.panelPadding ??
          //       (widget.isWideScreen
          //           ? const EdgeInsets.all(16)
          //           : const EdgeInsets.fromLTRB(24, 16, 24, 16)),
          //   child: _buildEmojiPanel(
          //       textEmojiIndexList,
          //       customEmojiStickerIndexList,
          //       widget.customStickerPackageList),
          // )),
          widget.showBottomContainer
              ? Container(
              padding: EdgeInsets.fromLTRB(
                  widget.isWideScreen ? 0 : 16, 0, 16, 0),
              color: widget.bottomColor,
              child: _buildBottomPanel(
                  textEmojiIndexList,
                  customEmojiStickerIndexList,
                  widget.customStickerPackageList))
              : Container(),
        ],
      ),
    );
  }
}

class EmojiItem extends StatelessWidget {
  const EmojiItem(
      {Key? key, required this.name, required this.unicode, this.size})
      : super(key: key);
  final String name;
  final int unicode;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: size ?? 26,
      ),
      child: Text(
        String.fromCharCode(unicode),
        style: const TextStyle(fontFamily: 'MaterialIcons'),
      ),
    );
  }
}

class CustomEmojiItem extends StatefulWidget {
  const CustomEmojiItem({Key? key,
    required this.sticker,
    this.baseUrl,
    this.size,
    this.isBigImage = false,
    this.isCustomEmoji = false,
    this.isDeafultEmoji = false})
      : super(key: key);

  final CustomSticker sticker;
  final String? baseUrl;
  final bool? isBigImage;
  final double? size;
  final bool isDeafultEmoji;
  final bool isCustomEmoji;

  @override
  State<StatefulWidget> createState() => _CustomEmojiItemState();
}

class _CustomEmojiItemState extends State<CustomEmojiItem> {
// gif图片首帧
  ImageInfo? _imageInfo;

  @override
  initState() {
    super.initState();
  }

  bool isFromNetwork() {
    if (widget.baseUrl == null) {
      return widget.sticker.url!.startsWith('http');
    }
    return widget.baseUrl!.startsWith('http');
  }

  String getUrl() {
    return widget.baseUrl == null
        ? widget.sticker.url!
        : widget.baseUrl! + '/' + widget.sticker.name;
  }

  bool isAnimated() {
    String url = getUrl();
    return url.endsWith("gif") || url.endsWith("webp") || url.endsWith("apng");
  }

  double get size => widget.isBigImage! ? 60 : 30;

  void _buildFristFrameFromNetworkImg(String url) async {
    final cache = await DefaultCacheManager().getSingleFile(url);
    final data = await cache.readAsBytes();
    _getFirstFrame(data);
  }

  void _buildFristFrameFromLocalImg(ImageProvider image) async {
    dynamic data;
    if (image is AssetImage) {
      AssetBundleImageKey key =
      await image.obtainKey(const ImageConfiguration());
      data = await key.bundle.load(key.name);
    } else if (image is FileImage) {
      data = await image.file.readAsBytes();
    } else if (image is MemoryImage) {
      data = image.bytes;
    }
    _getFirstFrame(data);
  }

  void _getFirstFrame(dynamic data) async {
    var codec = await PaintingBinding.instance
        .instantiateImageCodecWithSize(data.buffer.asUint8List());
    FrameInfo? frameInfo = await codec?.getNextFrame();
    if (frameInfo != null && mounted) {
      setState(() {
        _imageInfo = ImageInfo(image: frameInfo.image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String url = getUrl();
    bool isImgFromNetwork = isFromNetwork();
    bool isImgAnimated = isAnimated();
    Widget? img;
    if (isImgAnimated && isImgFromNetwork) {
      _buildFristFrameFromNetworkImg(url);
    }
    if (isImgAnimated && !isImgFromNetwork) {
      _buildFristFrameFromLocalImg(Image
          .asset(
        url,
        height: size,
        width: size,
      )
          .image);
    }
    if (!isImgAnimated && isImgFromNetwork) {
      img = CachedNetworkImage(
        imageUrl: url,
        height: size,
        width: size,
      );
    }
    if (!isImgAnimated && !isImgFromNetwork && widget.isCustomEmoji) {
      if (widget.isDeafultEmoji) {
        img = Image.asset(
          url,
          height: size,
          width: size,
          package: 'tim_ui_kit_sticker_plugin',
        );
      } else {
        img = Image.asset(
          url,
          height: size,
          width: size,
        );
      }
    }
    if (!isImgAnimated && !isImgFromNetwork && !widget.isCustomEmoji) {
      img = Image.asset(
        url,
        height: size,
        width: size,
      );
    }
    return SizedBox(
        width: widget.size,
        height: widget.size,
        child: isImgAnimated
            ? RawImage(
          image: _imageInfo?.image,
          width: size,
          height: size,
        )
            : img);
  }
}
