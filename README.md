A library for ebox husky protocol client.

## pubspec.yaml

```yaml
dependencies:
  huskyclient:
    git:
      url: your_git_url
      ref: master
```

or simply use pub.dev

```yaml
dependencies:
  huskyclient:
```

## Usage

A simple usage example:

```dart
import 'package:huskyclient/huskyclient.dart';
import 'package:huskyclient/proto/dart/box/conversation.pb.dart';

void main() async {
    // create a native socket client. libzt client is under working
  var client = Native(
      hostAddr: '68.0.0.7:7777',
      token:
          'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEdmYqKy6699SFbaLD4fNBHlT2pBc/cYC7MdoYPlldh+XGiu0yfdJTZ5GpSf+d6HT5nuuM4EwIoM/fjhkZiHUcBA==',
      uid: Int64(292));

  try {
    await client.connect();
  } catch (e) {
    print('exception in connect: $e');
  }

  var req = ListConversationRequest();

  var res = await client.send(ApiOperation.ListConversationOp, req);

  var rep = ListConversationResponse.fromBuffer(res.content);

  print('code: ${res.code}\nres: $res\nrep: $rep');

  await Future.delayed(Duration(seconds: 2)).then((value) => client.close());
  print('done');
}
```
