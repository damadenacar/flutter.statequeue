import 'dart:io';
import 'package:timestampedqueue/timestampedqueue.dart';
import 'package:test/test.dart';

void main() {
  group('Basic testing of the class', () {
    TimestampedQueue<int> queue = TimestampedQueue();

    setUp(() {
      for (var element in [1,3,5,1,3,5,1,5,8,5]) {
        queue.add(element);
        sleep(Duration(milliseconds: 5));
      }
    });

    test('Testing the basics', () {
      final first = queue.sequenceFind([1,3]);
      expect(first, 0);
      final second = queue.sequenceFind([1,3], offset: first! + 1);
      expect(second, 3);
      expect(queue.sequenceFind([1,5], timeDone: 10), 6);
      final reverseFirst = queue.sequenceReverseFind([1,3]);
      expect(reverseFirst, 3);
      final reverseSecond = queue.sequenceReverseFind([1,3], offset: -(queue.length - reverseFirst! + 1));
      expect(reverseSecond, 0);
      expect(queue.lastSequenceDone([1,5,8,5]), isTrue);
      final subqueue = queue.slice(1,4);
      expect(subqueue.length, 4);
      expect(subqueue.lastEntry, 3);
    });
  });
}
