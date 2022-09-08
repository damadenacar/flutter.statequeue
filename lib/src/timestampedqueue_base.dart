import 'dart:math';
import 'timestampedqueue_legacytimefunctions.dart';

class TimestampedEntry<T> {
  T entry;
  late final int time;

  TimestampedEntry(this.entry, [ int? time ]) {
    this.time = time??DateTime.now().millisecondsSinceEpoch;
  }

  @override
  String toString() {
    return "($entry, $time)";
  }
}

/// A class to manage a queue that associates a timestamp to the entries in the queue, so that it is possible
///   to calculate the elapsed time between to entries in the queue.
/// 
/// It is possible to use it in a list-like fashion: getting the last element, slicing it, etc. And it is also
///   possible to search sequences of entries to check it they have been done in a period of time.
class TimestampedQueue<T> {
  final List<TimestampedEntry<T>> _timestampedQueue = [];
  late final int? depth;
  late final bool allowRepeatedEntries;
  late final TimeFunction defaultTimeFunction;

  /// Creates a timestamped queue, that has a depth of [depth] elements at most (the others will be discarded). If [depth] is set to null, no element will be discarded.
  /// 
  /// If [allowRepeatedEntries] is set to false, two consecutive entries in the queue will not have the same value. So, in case of adding a new entry with the same value
  ///   than the last one, the timestamp will be updated.
  /// 
  /// [defaultTimeFunction] is a function that returns an integer that represents the time at this moment, so that it is possible to adjust it to make that new entries
  ///   get the current time. The default time function returns the current time in milliseconds, but anyone may need (e.g.) a microseconds resolution.
  TimestampedQueue({this.depth, this.allowRepeatedEntries = true, this.defaultTimeFunction = LegacyTimeFunction.millisecondsNow});

  /// Adds the new value [entry] to the queue, and sets its timestamp to [time]. If [time] is set to null, the value will be set to the current time in milliseconds.
  /// 
  /// If value [allowRepeatedEntries] of the queue is set to _false_, and the entry is the same than the current one, the timestamp is just updated.
  void add(entry, [ int? time ]) {
    time = time??defaultTimeFunction();

    if (_timestampedQueue.isNotEmpty) {
      if (time <= _timestampedQueue.last.time) {
        throw ArgumentError.value(time, "time");
      }
      if (! allowRepeatedEntries) {
        if (_timestampedQueue.last.entry == entry) {
          _timestampedQueue.removeLast();
        }
      }
    }
    _timestampedQueue.add(TimestampedEntry(entry, time));
    if (depth != null) {
      while (_timestampedQueue.length > depth!) {
        _timestampedQueue.removeAt(0);
      }
    }
  }

  /// Removes the first entry from the queue (i.e. the older one) and retrieves it.
  TimestampedEntry<T> pop() {
    if (_timestampedQueue.isEmpty) {
      throw Exception("the queue is empty");
    }
    return _timestampedQueue.removeAt(0);
  }

  /// This is an alias for `add` method, to match the push/pop semantics
  void push(entry, [ int? time ]) => add(entry, time);

  /// Obtains the last entry in the queue (including the timestamp)
  TimestampedEntry<T> get last {
    if (_timestampedQueue.isEmpty) {
      throw Exception("the queue is empty");
    }
    return _timestampedQueue.last;
  }

  /// Obtains the value of the last entry in the queue
  T get lastEntry {
    if (_timestampedQueue.isEmpty) {
      throw Exception("the queue is empty");
    }
    return last.entry;
  }

  /// Returns the number of entries in the queue
  int get length {
    return _timestampedQueue.length;
  }

  /// Returns the elapsed time between the first and the last element in the queue.
  /// 
  /// * if the queue is empty, it will return _null_.
  int? get elapsed {
    if (_timestampedQueue.isEmpty) {
      return null;
    }
    return _timestampedQueue.last.time - _timestampedQueue.first.time;
  }

  /// Returns an object which is an slice of the queue, from objects between [start] and [end] (both included). The copy is shallow (i.e. the entries
  ///   are not cloned).
  /// 
  /// If [start] is negative, the starting element will start from the end (i.e. -4 means the 4th element from the later one).
  TimestampedQueue<T> slice(int start, [ int? end ]) {
    end = end??_timestampedQueue.length - 1;
    end += 1;

    if (end > _timestampedQueue.length) {
      end = _timestampedQueue.length;
    }

    if (start < 0) {
      start = _timestampedQueue.length + start;
    }
    final resultQueue = TimestampedQueue<T>(depth: depth, allowRepeatedEntries: allowRepeatedEntries);
    if (end > start) {
      resultQueue._timestampedQueue.addAll(_timestampedQueue.sublist(start, end));
    }
    return resultQueue;
  }
  
  /// Returns true if the [sequence] exists at position [position] and the time elapsed between the first entry
  ///   and the last entry in the queue is less than [timeDone] milliseconds.
  /// 
  /// If [timeDone] is null, the time available to be done is considered to be infinite. So if the sequence matches
  ///   at the requested position, it will return "true", independent from the time elapsed between the first and
  ///   the last entry.
  /// 
  /// When calculating the time used for the sequence, it is possible to use [skipEntriesForTimestamp] to skip a number
  ///   of entries from the beginning. (e.g.) if having 4 entries in the sequence, is [skipEntriesForTimestamp] is 1, the
  ///   time will be the amount between entry in position \#1 and position \#4
  bool isSequenceAt(List<T?> sequence, int position, { int? timeDone, int skipEntriesForTimestamp = 0, bool matchNull = false }) {
    if (sequence.isEmpty) {
      return true;
    }
    if (_timestampedQueue.isEmpty) {
      return false;
    }
    if (position < 0) {
      return false;
    }
    if (position + sequence.length > _timestampedQueue.length) {
      return false;
    }
    if (skipEntriesForTimestamp > sequence.length) {
      return false;
    }

    // Check whether the sequence is found or not
    bool sequenceFound = true;
    for (var j = 0; j < sequence.length; j++) {
      if ((matchNull) || (sequence[j] != null)) {
        if (sequence[j] != _timestampedQueue[position + j].entry) {
          // If any of the states is not at its relative position in the queue, the sequence is not found
          sequenceFound = false;
          break;
        }
      }
    }

    if (sequenceFound) {
      // Let's check whether the sequence was done in time
      if (timeDone != null) {
        final timeElapsed = _timestampedQueue[position + sequence.length - 1 ].time - _timestampedQueue[position + skipEntriesForTimestamp].time;
        if (timeDone < timeElapsed) {
          sequenceFound = false;
        }
      } 
    }

    return sequenceFound;
  }

  /// Returns the first position in which the [sequence] has appeared, and the elapsed time between the beginning of the
  ///   sequence and the end is less or equal than [timeDone]. If the sequence does not appear or the time of appearance
  ///   is greater than the requested one, the funcion will return _null_.
  /// 
  /// [sequence] is a list of T or null values; the null value matches with any entry unless [matchNull] is set to
  ///   true; in that case, null values need to match with the entries in the queue.
  /// 
  /// In case that [timeDone] is null, the time considered is unlimited, so in case that the sequence appears, it
  ///   will return its position.
  /// 
  /// When calculating the time used for the sequence, it is possible to use [skipEntriesForTimestamp] to skip a number
  ///   of entries from the beginning. (e.g.) if having 4 entries in the sequence, is [skipEntriesForTimestamp] is 1, the
  ///   time will be the amount between entry in position \#1 and position \#4
  /// 
  /// Searching the sequence starts at the beginning of the queue, but it is possible to skip [offset] entries. This
  ///   is specially useful to search multiple 
  int? sequenceFind(List<T?> sequence, { int? timeDone, int offset = 0, int skipEntriesForTimestamp = 0, bool matchNull = false }) {
    // Skip the impossible cases
    if (offset + sequence.length > _timestampedQueue.length) {
      return null;
    }
    // An empty sequence is always found at the beginning
    if (sequence.isEmpty) {
      return offset;
    }
    // The position in which the sequence if found (while it is null, the sequence has not been found in time)
    int? positionFound;
    
    for (var i = offset; (i <= _timestampedQueue.length - sequence.length) && (positionFound == null); i++) {
      if (isSequenceAt(sequence, i, timeDone: timeDone, matchNull: matchNull, skipEntriesForTimestamp: skipEntriesForTimestamp)) {
        positionFound = i;
        break;
      }
    }

    return positionFound;
  }

  /// Returns the last position in which the [sequence] has appeared, and the elapsed time between the beginning of the
  ///   sequence and the end is less or equal than [timeDone]. If the sequence does not appear or the time of appearance 
  ///   is greater than the requested one, the funcion will return _null_.
  /// 
  /// If [offset] is specified, the search will begin at this entry position; if [offset] is negative, the search
  ///   will begin from this position, starting from the end. 
  ///   e.g. having a queue of 1000, and a search sequence of 5 values; offset = 30 means to search from 30 to 1000,
  ///        while offset = -30 means to search from 0 to 970 (so the first posible position will be 965, as the
  ///        sequence is of 5 entries).
  /// 
  /// Please see `sequenceFind` for the details of the other parameters.
  int? sequenceReverseFind(List<T?> sequence, { int? timeDone, int? offset, int skipEntriesForTimestamp = 0, bool matchNull = false }) {
    // Adjust the maximum position to find the sequence
    offset = offset??0;
    int searchStart = 0;
    int searchEnd = _timestampedQueue.length - sequence.length;

    if (offset >= 0) {
      searchStart = offset;
    }
    if (offset < 0) {
      searchEnd = min(searchEnd, _timestampedQueue.length + offset);
    }
    // In these cases the sequence cannot be found; either because there is no search space or because there is no room for the sequence searched
    if (searchEnd < searchStart) {
      return null;
    }
    if ((searchEnd - searchStart + 1) < sequence.length) {
      return null;
    }
    // An empty sequence is always found at the beginning
    if (sequence.isEmpty) {
      return searchEnd;
    }
    // The position in which the sequence if found (while it is null, the sequence has not been found in time)
    int? positionFound;

    for (var i = searchEnd; (i >= searchStart) && (positionFound == null); i--) {
      // If the sequence has been actually found, mark it
      if (isSequenceAt(sequence, i, timeDone: timeDone, matchNull: matchNull, skipEntriesForTimestamp: skipEntriesForTimestamp)) {
        positionFound = i;
        break;
      }
    }

    return positionFound;
  }

  /// Returns true if the last sequence done is [sequence], and it the elapsed time between the first and the last entry of the
  ///   sequence is less or equal than [timeDone].
  /// 
  /// Please see `sequenceFind` for the details of parameters.
  bool lastSequenceDone(List<T?> sequence, { int? timeDone, int skipEntriesForTimestamp = 0, bool matchNull = false }) {
    int? positionFound = sequenceReverseFind(sequence, timeDone: timeDone, skipEntriesForTimestamp: skipEntriesForTimestamp);
    if (positionFound == null) {
      return false;
    }
    return (positionFound == (_timestampedQueue.length - sequence.length));
  }


  /// Finds the position of the first occurrence of [item] in the queue.
  /// 
  /// If [offset] is specified, the search will begin at this entry position; if [offset] is negative, the search
  ///   will begin from this position, starting from the end. 
  /// 
  /// If [item] is null, it will match any entry so it will return the first element in the queue, unless [matchNull]
  ///   is set to true. 
  /// 
  /// If [matchNull] is set to true, it is considered that the items in the queue can be null, so setting item to
  ///   null, will return the first occurrence of a null value.
  int? find(T? item, { int offset = 0, bool matchNull = false }) {
    return sequenceFind([item], offset: offset, matchNull: matchNull);
  }

  /// Finds the position of the last occurrence of [item] in the queue
  /// 
  /// [offset] is interpreted as in _sequenceReverseFind_; [matchNull] is interpreted as in _find_
  int? reverseFind(T? item, { int offset = 0, bool matchNull = false }) {
    return sequenceReverseFind([item], offset: offset, matchNull: matchNull);
  }

  /// Obtains element with index [index] in the queue
  TimestampedEntry<T> operator [](int index) {
    if ((index < 0) || (index > _timestampedQueue.length)) {
      throw IndexError(index, this);
    }
    return _timestampedQueue[index];
  }

  @override
  /// Obtains a string representation of the queue
  String toString([int count = 10]) {
    final start = max(0, _timestampedQueue.length - count);
    return "Elements in queue: " + (start>0?"...":"") + _timestampedQueue.sublist(start).fold<String>("", (previousValue, element) => "$previousValue $element").trim();
  }  
}