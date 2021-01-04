// Copyright (c) 2021, ETSME.
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

// Bruce.Lu <lzbgt@icloud.com> 2021.01.04

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import '../proto/dart/box/api.pb.dart';
import '../proto/dart/box/account.pb.dart';

export 'package:fixnum/fixnum.dart';
export '../proto/dart/box/api.pb.dart';

part 'impl/native.dart';

class Header {
  Header({this.id, this.remains, this.version, this.frameFlag, this.frameType});
  final int id;
  final int frameType;
  final int frameFlag;
  final int version;
  final int remains;
}

abstract class Client {
  Client({
    @required this.hostAddr,
    @required this.token,
    @required this.uid,
    this.serverVersion = 0x12,
    this.frameFlag = 0,
    this.frameType = 1,
    this.source = 0,
    this.apiVersion = 1,
    this.timeoutConn = const Duration(seconds: 5),
    this.timeoutSend = const Duration(seconds: 5),
    this.timeoutRecv = const Duration(seconds: 5),
  });

  @nonVirtual
  final String hostAddr;
  @nonVirtual
  final String token;
  @nonVirtual
  final Int64 uid;
  @nonVirtual
  final int serverVersion;
  @nonVirtual
  final int frameType;
  @nonVirtual
  final int apiVersion;
  @nonVirtual
  final int frameFlag;
  @nonVirtual
  final int source;
  @nonVirtual
  final Duration timeoutConn;
  @nonVirtual
  final Duration timeoutSend;
  @nonVirtual
  final Duration timeoutRecv;

  // hexString .
  static String hexString(List<int> data) {
    var sb = StringBuffer();
    data.forEach((f) {
      sb.write(f.toRadixString(16).padLeft(2, '0'));
      sb.write(' ');
    });
    return sb.toString();
  }

  Uint8List encodeFrame(int id, Uint8List b) {
    var buf = Uint8List(10);
    var bd = ByteData.view(buf.buffer);
    bd.setUint8(0, apiVersion); // 1
    bd.setUint32(1, (id & 0x7FFFFFFF) | (source << 31), Endian.big); // 4 + 1
    bd.setUint8(5, frameType); // 1 + 4 + 1
    bd.setUint8(6, frameFlag); // 1 + 1 + 4 + 1
    // length
    bd.setUint8(7, (b.length & 0x00FF0000) >> 16); // 8
    bd.setUint8(8, (b.length & 0x00FF00) >> 8); // 9
    bd.setUint8(9, (b.length & 0x00FF)); //10
    return Uint8List.fromList(buf.toList() + b.toList());
  }

  Header decodeHeader(Uint8List b) {
    if (b.length < 10) {
      return null;
    }

    var bd = ByteData.view(b.buffer);
    var version = bd.getInt8(0);
    var hex = bd.getUint32(1, Endian.big);
    var id = hex & 0x7FFFFFFF;
    var ftype = bd.getInt8(5);
    var flag = bd.getInt8(6);
    var remain = bd.getInt32(6, Endian.big) & 0x00FFFFFF;
    print(
        'version: $version, ftype: $ftype, id: $id, flag: $flag, remain: $remain \n');

    return Header(
        id: id,
        version: version,
        remains: remain,
        frameFlag: flag,
        frameType: ftype);
  }

  Future<Client> connect();
  Future<ApiResponse> send(ApiOperation code, $pb.GeneratedMessage m);
  void close();
}
