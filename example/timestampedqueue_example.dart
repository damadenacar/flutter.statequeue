import 'dart:io';
import 'package:timestampedqueue/timestampedqueue.dart';

void main() {
  TimestampedQueue<int> queue = TimestampedQueue()..add(0);

  for (var element in [1,3,5,1,3,5,1,5,8,5]) {
    queue.add(element);
    sleep(Duration(milliseconds: 5));
  }

  print(queue.sequenceFind([1,5], timeDone: 10));
  print(queue.lastSequenceDone([1,5,8,5]));
  print(queue);
  print(queue.slice(1, 4));
}
