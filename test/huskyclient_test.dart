import 'package:huskyclient/huskyclient.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    Native awesome;

    setUp(() {
      awesome = Native();
    });

    test('First Test', () {
      //expect(awesome.isAwesome, isTrue);
    });
  });
}
