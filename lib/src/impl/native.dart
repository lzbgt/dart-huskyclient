// Copyright (c) 2021, ETSME.
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

// Bruce.Lu <lzbgt@icloud.com> 2021.01.04

part of 'package:huskyclient/src/huskyclient_base.dart';

class Native extends Client {
  Native({
    String hostAddr,
    String token,
    Int64 uid,
  }) : super(
          hostAddr: hostAddr,
          token: token,
          uid: uid,
        );

  Socket _socket;
  final List<int> _cache = <int>[];
  //int _writePos = 0;
  final _connCompl = Completer<Socket>();
  final _authCompl = Completer<Socket>();
  int _streamId = 0;
  final _cplMap = <int, Completer<ApiResponse>>{};
  var _remains = 0;
  StreamSubscription<Uint8List> _sub;

  Future<ApiResponse> _send(ApiOperation code, $pb.GeneratedMessage m) {
    var _cpl = Completer<ApiResponse>();
    _connCompl.future.then((value) {
      var req = ApiRequest();
      req.content = m.writeToBuffer();
      req.operation = code;
      req.serverVersion = serverVersion;
      _streamId++;
      var frame = encodeFrame(_streamId, req.writeToBuffer());
      _socket.add(frame);
      _cplMap[_streamId] = _cpl;
    }, onError: (err) {
      //
      _cpl.complete(err);
    }).timeout(timeoutSend + timeoutRecv);
    return _cpl.future;
  }

  Future<ApiResponse> _sendAuth() async {
    var req = AuthenticationRequest();
    req.uid = uid;
    req.boxToken = token;
    return _send(ApiOperation.AuthenticationOp, req);
  }

  @override
  Future<Client> connect() {
    final sp = hostAddr.split(':');
    final host = sp[0];
    var port = 7777;
    try {
      if (sp.length == 2) {
        port = int.parse(sp[1]);
      }
    } catch (e) {
      // ignore
    }

    var s = Socket.connect(host, port, timeout: timeoutConn).then((value) {
      _connCompl.complete(value);
      _socket = value;
      // send auth req
      _sendAuth().then((value) {
        if (value.code == 0) {
          _authCompl.complete(_socket);
        } else {
          _authCompl.completeError(value.message);
        }
      }, onError: (err) {
        _authCompl.completeError(err);
        throw err;
      });

      _sub = value.listen((event) {
        // print(event);
        int id;
        try {
          var _conv = List<int>.from(event);
          _cache.addAll(_conv);

          if (_remains == 0) {
            var header = decodeHeader(Uint8List.fromList(_cache));
            if (header == null) {
              // wait more
              return;
            }
            _remains = header.remains;
            id = header.id;
          }
          _cache.removeRange(0, 10);

          if (_cache.length < _remains) {
            // wait more
            return;
          }

          var res = ApiResponse.fromBuffer(_cache.sublist(0, _remains));
          if (id == 1) {
            //print('auth: $res');
          }
          _cplMap[id].complete(res);
          _cplMap.remove(id);
          _cache.removeRange(0, _remains);
          _remains = 0;
        } catch (e) {
          if (id != null) {
            _cplMap[id].completeError(e);
          } else {
            // let any future completes with error
            if (_cplMap.isNotEmpty) {
              _cplMap.values.first.completeError(e);
            } else {
              rethrow;
            }
          }
          close();
        }
      });
    }, onError: (err) {
      // _authCompl.completeError(err);
      // _connCompl.completeError(err);
      // print('err1: $err');
      throw err;
    });

    return s;
  }

  @override
  Future<ApiResponse> send(ApiOperation code, $pb.GeneratedMessage m) {
    return _authCompl.future.then((value) => _send(code, m));
  }

  @override
  void close() {
    if (_sub != null) {
      _sub.cancel();
      _sub = null;
    }
    if (_socket != null) {
      _socket.close();
      _socket = null;
    }
    _cplMap.clear();
  }
}
