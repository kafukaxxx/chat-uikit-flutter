

import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_im_base/theme/tui_theme.dart';
import '../../../../base_widgets/tim_ui_kit_base.dart';
import '../../../customMessages/DggRedpacketTipsModel.dart';
import '../../../utils/message.dart';

class DGGRedTipsElem extends StatefulWidget {
  final DggRedpacketTipsModel redModel;

   DGGRedTipsElem({Key? key,required this.redModel}) : super(key: key);

  @override
  State<DGGRedTipsElem> createState() => _DGGRedTipsElemState();
}

class _DGGRedTipsElemState extends TIMUIKitState<DGGRedTipsElem> {
  String tipsText = "";
  @override
  void initState() async{
    // TODO: implement initState
    super.initState();
    tipsText = await getStringByRedTipsModel(widget.redModel);
  }
  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    // TODO: implement tuiBuild
    final TUITheme theme = value.theme;

    return LayoutBuilder(builder: (context,constrian) {
      return Center(
        child: Container(padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
          constraints: BoxConstraints(
            maxWidth: 200,
          ),
          decoration: BoxDecoration(color: Color.fromRGBO(0, 0, 0, 0.2),
              borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          margin: EdgeInsets.only(bottom: 10),
          child: RichText(text: TextSpan(children: [
            WidgetSpan(child: Image.asset("assets/redPacket/icon_redpacket_tip@3x.png",height: 11,)),
            WidgetSpan(child: SizedBox(width: 5,),),
            TextSpan(text:tipsText,style: TextStyle(color: Colors.white,fontSize: 11),),
          ])),
        ),
      );
    });

  }
}
