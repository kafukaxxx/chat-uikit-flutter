import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/change_notifier.dart';

class CustomTextSelectionControls extends TextSelectionControls {
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    // 返回自定义的文本选择句柄小部件
    return SizedBox.shrink();
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // 返回句柄小部件的锚点偏移量
    return Offset(0, 0);
  }
  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // TODO: implement canSelectAll
    return false;
  }

  @override
  Widget buildToolbar(
      BuildContext context,
      Rect globalEditableRegion,
      double textLineHeight,
      Offset selectionMidpoint,
      List<TextSelectionPoint> endpoints,
      TextSelectionDelegate delegate,
      ValueListenable<ClipboardStatus>? clipboardStatus,
      Offset? lastSecondaryTapDownPosition,
      ) {
    // TODO: implement buildToolbar
    return SizedBox.shrink();
  }

  @override
  Size getHandleSize(double textLineHeight) {
    // TODO: implement getHandleSize
    return Size(0, 0);
  }

// 重写其他方法，如 buildToolbar、handleCut、handleCopy、handlePaste 等

// ...
}

class MyTextSelectionHandleWidget extends StatelessWidget {
  final TextSelectionHandleType type;
  final double textLineHeight;

  const MyTextSelectionHandleWidget({required this.type, required this.textLineHeight});

  @override
  Widget build(BuildContext context) {
    // 返回自定义的文本选择句柄小部件
    // 根据句柄类型和文本行高来绘制不同样式的句柄
    return SizedBox.shrink();
  }
}
