# Timestamped Queue

This package implements a class to manage a queue that associates a timestamp to the entries in the queue so that it is possible to calculate the elapsed time between two entries in the queue.

It is possible to use it in a list-like fashion: getting the last element, slicing it, etc. And it is also possible to search sequences of entries to check if they have been done in a period.

## Features

- Class `TimestampedQueue` is abstract so it is possible to use any type for the elements in the queue.
- The timestamp is an _integer value_. While it is conceived to be a timestamp (e.g. `DateTime.now().millisecondsSinceEpoch`), it is possible to use any user-defined integer value. The package is shipped with two basic time functions: `LegacyTimeFunction.microsecondsNow` and `LegacyTimeFunction.millisecondsNow`. The default one is `LegacyTimeFunction.microsecondsNow`.
- If it is possible that the queue grows too much, it is possible to keep only a defined amount of values.

## Getting started

To start using this package, add it to your _pubspec.yaml_ file:

```yaml
dependencies:
    timestampedqueue:
```

Then get the dependencies (e.g. `dart pub get` or `flutter pub get`) and import in your application:

```dart
import 'package:timestampedqueue/timestampedqueue.dart';
```

## Usage

The basic usage is:

```dart
const TimestampedQueue<int> queue = TimestampedQueue();

[1,3,5,1,3,5,1,5,8,5].forEach((element) {
    queue.add(element);
    sleep(Duration(milliseconds: 5));
});
```

Then it is possible to search for sequences or (e.g.) check if the last sequence done was one specific one:

```dart
print(queue.sequenceFind([1,5], timeDone: 10));
print(queue.lastSequenceDone([1,5,8,5]));
print(queue);
print(queue.slice(1, 4));
```

## Additional information

The code is documented, so if wanted to get the full documentation, it is possible to run generate it by executing `dart doc .` in the source folder.

The main methods for class `TimestampedQueue` are the next:

- `void add(dynamic entry, [int? time])`

    Adds the new value entry to the queue, and sets its timestamp to time. If time is set to null, the value will be set to the current time in milliseconds.

- `int? find(T? item, {int offset = 0, bool matchNull = false})`
 
    Finds the position of the first occurrence of item \[`item`\] in the queue.

- `bool isSequenceAt(List<T?> sequence, int position, {int? timeDone, bool matchNull = false})`

    Returns true if the sequence exists at position \[`position`\] and the time elapsed between the first entry and the last entry in the queue is less than \[`timeDone`\] milliseconds.

- `bool lastSequenceDone(List<T?> sequence, {int? timeDone, bool matchNull = false})`
    Returns true if the last sequence done is \[`sequence`\], and it the elapsed time between the first and the last entry of the sequence is less or equal than \[`timeDone`\].

- `int? reverseFind(T? item, {int offset = 0, bool matchNull = false})`

    Finds the position of the last occurrence of \[`item`\] in the queue.

- `int? sequenceFind(List<T?> sequence, {int? timeDone, int offset = 0, bool matchNull = false})`

    Returns the first position in which the \[`sequence`\] has appeared, and the elapsed time between the beginning of the sequence and the end is less or equal than \[`timeDone`\]. 

    If the sequence does not appear or the time of appearance is greater than the requested one, the funcion will return null.

    \[`sequence`\] is a list of T or null values; the null value matches with any entry unless \[`matchNull`\] is set to true; in that case, null values need to match with the entries in the queue.

    Searching the sequence starts at the beginning of the queue, but it is possible to skip \[`offset`\] entries. This is specially useful to search multiple.

- `int? sequenceReverseFind(List<T?> sequence, {int? timeDone, int? offset, bool matchNull = false})`

    Returns the last position in which the sequence has appeared, and the elapsed time between the beginning of the sequence and the end is less or equal than \[`timeDone`\]. If the sequence does not appear or the time of appearance is greater than the requested one, the funcion will return null.

    \[`sequence`\] is a list of T or null values; the null value matches with any entry unless \[`matchNull`\] is set to true; in that case, null values need to match with the entries in the queue.

    If \[`offset`\] is specified, the search will begin at this entry position; if \[`offset`\] is negative, the search will begin from this position, starting from the end. e.g. having a queue of 1000, and a search sequence of 5 values; offset = 30 means to search from 30 to 1000, while offset = -30 means to search from 0 to 970 (so the first posible position will be 965, as the sequence is of 5 entries).

- `TimestampedQueue<T> slice(int start, [int? end])`
    
    Returns an object which is an slice of the queue, from objects between \[`start`\] and \[`end`\] (both included). The copy is shallow (i.e. the entries are not cloned).
