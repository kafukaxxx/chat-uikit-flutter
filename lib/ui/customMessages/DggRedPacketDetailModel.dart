class DggRedPacketParentModel {
  DggRedPacketDetailModel? red;
  List<Rows>? rows;
  int? leftCount;

  DggRedPacketParentModel({this.red, this.rows, this.leftCount});

  DggRedPacketParentModel.fromJson(Map<String, dynamic> json) {
    red = json['red'] != null ? new DggRedPacketDetailModel.fromJson(json['red']) : null;
    if (json['rows'] != null) {
      rows = <Rows>[];
      json['rows'].forEach((v) {
        rows!.add(new Rows.fromJson(v));
      });
    }
    leftCount = json['left_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.red != null) {
      data['red'] = this.red!.toJson();
    }
    if (this.rows != null) {
      data['rows'] = this.rows!.map((v) => v.toJson()).toList();
    }
    data['left_count'] = this.leftCount;
    return data;
  }
}
class DggRedPacketDetailModel {
  String? id;
  String? userId;
  String? type;
  String? recvId;
  String? count;
  String? amount;
  String? rand;
  String? words;
  String? leftCount;
  String? createTime;
  String? refundTime;
  String? maxamount;
  String? lasttm;
  String? myamount;
  String? userNickname;
  String? userAvatar;

  DggRedPacketDetailModel(
      {this.id,
        this.userId,
        this.type,
        this.recvId,
        this.count,
        this.amount,
        this.rand,
        this.words,
        this.leftCount,
        this.createTime,
        this.refundTime,
        this.maxamount,
        this.lasttm,
        this.myamount,
        this.userNickname,
        this.userAvatar});

  DggRedPacketDetailModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    userId = json['user_id'].toString();
    type = json['type'].toString();
    recvId = json['recv_id'].toString();
    count = json['count'].toString();
    amount = json['amount'].toString();
    rand = json['rand'].toString();
    words = json['words'].toString();
    leftCount = json['left_count'].toString();
    createTime = json['create_time'].toString();
    refundTime = json['refund_time'].toString();
    maxamount = json['maxamount'].toString();
    lasttm = json['lasttm'].toString();
    myamount = json['myamount'].toString();
    userNickname = json['user_nickname'].toString();
    userAvatar = json['user_avatar'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['type'] = this.type;
    data['recv_id'] = this.recvId;
    data['count'] = this.count;
    data['amount'] = this.amount;
    data['rand'] = this.rand;
    data['words'] = this.words;
    data['left_count'] = this.leftCount;
    data['create_time'] = this.createTime;
    data['refund_time'] = this.refundTime;
    data['maxamount'] = this.maxamount;
    data['lasttm'] = this.lasttm;
    data['myamount'] = this.myamount;
    data['user_nickname'] = this.userNickname;
    data['user_avatar'] = this.userAvatar;
    return data;
  }
}

class Rows {
  String? userId;
  String? amount;
  String? receiveAt;
  Member? member;

  Rows({this.userId, this.amount, this.receiveAt, this.member});

  Rows.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    amount = json['amount'].toString();
    receiveAt = json['receive_at'];
    member =
    json['member'] != null ? new Member.fromJson(json['member']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['amount'] = this.amount;
    data['receive_at'] = this.receiveAt;
    if (this.member != null) {
      data['member'] = this.member!.toJson();
    }
    return data;
  }
}

class Member {
  int? id;
  String? nickname;

  Member({this.id, this.nickname});

  Member.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nickname = json['nickname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['nickname'] = this.nickname;
    return data;
  }
}
