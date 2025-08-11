// @license
// Copyright (c) 2019 - 2021 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this repository.

import 'dart:async';
import 'dart:math';

part 'gg_change.dart';
part 'gg_list_value.dart';
part 'gg_sync.dart';

// #############################################################################
/// [GgValueStream] is an ordinary stream that provides a [value] method that
/// returns the last value or will be emitted by the stream.
abstract class GgValueStream<T> extends Stream<T> {
  /// Returns the last value that was or will be emitted by the stream.
  T get value;

  // ...........................................................................
  /// Returns a new stream which delivers the elements of the original stream
  /// mapped using the [mapping] function.
  @override
  GgValueStream<S> map<S>(S Function(T) mapping) =>
      _MappedValueStream(this, mapping);

  // ...........................................................................
  /// Returns a new stream which only delivers elements that match [filter].
  /// Important: The first value yielded by this stream might not match
  /// the filter. This is necessary to provide a non-nullable value.
  @override
  GgValueStream<T> where(bool Function(T) filter) =>
      _WhereValueStream(this, filter);

  // ...........................................................................
  Stream<T> get baseStream;
}

// #############################################################################
class _MappedValueStream<S, T> extends GgValueStream<S> {
  _MappedValueStream(this.parent, this.mapping)
    : _value = mapping(parent.value) {
    _listenToParentStreamAndUpdateValue();
  }

  // ...........................................................................
  @override
  S get value => _value;

  // ...........................................................................
  /// Returns own stream yielding the mapped value
  @override
  Stream<S> get baseStream => parent.baseStream.map((_) => _value).distinct();

  // ...........................................................................
  @override
  StreamSubscription<S> listen(
    void Function(S value)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return baseStream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  final List<Function()> _dispose = [];

  // ...........................................................................
  S _value;
  GgValueStream<T> parent;

  // ...........................................................................
  final S Function(T) mapping;

  // ...........................................................................
  void _listenToParentStreamAndUpdateValue() {
    final s = parent.baseStream.listen(
      (event) => _value = mapping(event),
      onDone: () {
        for (final func in _dispose.reversed) {
          func();
        }
      },
    );
    _dispose.add(s.cancel);
  }
}

// #############################################################################
class _WhereValueStream<T> extends GgValueStream<T> {
  _WhereValueStream(this.parent, this.filter) : _value = parent.value {
    final s = parent.baseStream
        .where(filter)
        .listen(
          (event) => _value = event,
          onDone: () {
            for (final func in _dispose.reversed) {
              func();
            }
          },
        );
    _dispose.add(s.cancel);
  }

  // ...........................................................................
  @override // coverage:ignore-line
  T get value => _value; // coverage:ignore-line

  @override
  Stream<T> get baseStream => parent.baseStream.map((_) => _value).distinct();

  // ...........................................................................
  @override
  StreamSubscription<T> listen(
    void Function(T value)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return baseStream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  final List<Function()> _dispose = [];

  // ...........................................................................
  T _value;
  GgValueStream<T> parent;

  // ...........................................................................
  final bool Function(T) filter;
}

// #############################################################################
/// Returns the stream together with a value getter.
class _GgValueStream<T> extends GgValueStream<T> {
  _GgValueStream({required T Function() value, required this.baseStream})
    : _value = value;

  // ...........................................................................
  @override
  StreamSubscription<T> listen(
    void Function(T value)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => baseStream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  final Stream<T> baseStream;

  // ...........................................................................
  @override
  T get value => _value();

  // ######################
  // Private
  // ######################

  final T Function() _value;
}

// #############################################################################
/// Interface for the the read only part of a GgValue
abstract class GgReadOnlyValue<T> {
  /// An optional name.
  String? get name;

  /// Returns the value
  T get value;

  /// The default value
  T get seed;

  /// Converts the value into a string value and returns the result.
  String get stringValue;

  /// For all other types [stringValue] is returned.
  dynamic get jsonDecodedValue;

  /// When [spam] is true, GgValue will emit every change. If [spam] is false,
  /// only one update per run loop cycle will be emitted.
  bool get spam;

  /// Returns a stream informing about changes on the value
  // ignore: library_private_types_in_public_api
  _GgValueStream<T> get stream;

  /// Returns a sync stream informing about changes on the value
  // ignore: library_private_types_in_public_api
  _GgValueStream<T> get syncStream;
}

// #############################################################################
/// Represents a value of Type T in the memory.
class GgValue<T> implements GgReadOnlyValue<T> {
  // ...........................................................................
  /// - [seed] The initial seed of the value.
  /// - If [spam] is true, each change of the value will be added to the
  ///   stream.
  /// - If [spam] is false, updates of the value are scheduled as micro
  ///   tasks. New updates are not added until the last update has been delivered.
  ///   Only the last set value will be delivered.
  /// - [transform] allows you to keep value in a given range or transform it.
  /// - [parse] is needed when [T] is not [String], [int], [double] or [bool].
  ///   It converts a string into [T].
  /// - [stringify] is needed when [T] is not [String], [int], [double] or [bool].
  ///   It converts the value into a [String].
  /// - [name] is an optional identifier for the value.
  GgValue({
    required T seed,
    this.spam = false,
    this.compare,
    this.transform,
    this.isOk,
    T Function(String)? parse,
    String Function(T)? stringify,
    this.name,
  }) : _value = seed,
       _seed = seed,
       _parse = parse,
       _stringify = stringify {
    _initController();
    _initSync();
  }

  // ...........................................................................
  @override
  final String? name;

  // ...........................................................................
  /// Sets the value and triggers an update on the stream.
  set value(T newVal) {
    if (newVal == _value) {
      return;
    }

    if (compare != null && compare!(newVal, _value)) {
      return;
    }

    final change = _change(newVal);
    _syncAndApplyChange(change);
  }

  // ...........................................................................
  GgChange<T> _change(T newVal) =>
      GgChange(newValue: newVal, oldValue: _value, type: GgChangeType.update);

  // ...........................................................................
  /// Informs all listeners about a change.
  void forceUpdate() {
    _controller.add(_value);
  }

  // ...........................................................................
  @override
  T get value => _value;

  // ...........................................................................
  @override
  T get seed => _seed;

  // ...........................................................................
  void reset() {
    if (_sync != null) {
      // coverage:ignore-start
      throw ArgumentError('Don\'t reset values that are currently synced.');
      // coverage:ignore-end
    } else {
      value = _seed;
    }
  }

  // ...........................................................................
  /// Parses [str] and writes the result into value.
  set stringValue(String str) {
    final t = _value.runtimeType;

    if (_parse != null) {
      value = _parse.call(str);
    } else if (t == int) {
      value = int.parse(str) as T;
    } else if (t == double) {
      value = double.parse(str) as T;
    } else if (t == bool) {
      switch (str.toLowerCase()) {
        case 'false':
        case '0':
        case 'no':
          value = false as T;
          break;
        case 'true':
        case '1':
        case 'yes':
          value = true as T;
      }
    } else if (t == String) {
      value = str as T;
    } else {
      throw ArgumentError('Missing "parse" method for type "${T.toString()}".');
    }
  }

  // ...........................................................................
  @override
  String get stringValue {
    final t = _value.runtimeType;
    if (_stringify != null) {
      return _stringify.call(_value);
    } else if (t == String) {
      return _value as String;
    } else if (t == bool) {
      return (_value as bool) ? 'true' : 'false';
    } else if (t == int || t == double) {
      return _value.toString();
    } else {
      throw ArgumentError(
        'Missing "toString" method for unknown type "${T.toString()}".',
      );
    }
  }

  // ...........................................................................
  static bool isSimpleJsonValue(dynamic value) =>
      value is int || value is double || value is bool || value is String;

  // ...........................................................................
  /// Returns int, double and bool and string as they are.
  @override
  dynamic get jsonDecodedValue {
    if (isSimpleJsonValue(_value)) {
      return _value;
    } else {
      return stringValue;
    }
  }

  // ...........................................................................
  /// Values of type int, double, bool and string are assigned directly to [value].
  /// Values of type string are assigned to [stringValue]
  set jsonDecodedValue(dynamic value) {
    if (value is String) {
      stringValue = value;
    } else if (isSimpleJsonValue(value)) {
      this.value = value;
    } else {
      throw ArgumentError(
        'Cannot assign json encoded value $value. The type ${value.runtimeType} is not supported.',
      );
    }
  }

  // ...........................................................................
  /// Allows reducing the number of updates delivered when the value is changed
  /// multiple times.
  ///
  /// - If [spam] is true, each change of the value will be added to the stream.
  /// - If [spam] is false, updates of the value are scheduled as micro tasks.
  /// New updates are not added until the last update has been delivered.
  /// Only the last set value will be delivered.
  @override
  bool spam;

  // ...........................................................................
  @override
  // ignore: library_private_types_in_public_api
  _GgValueStream<T> get stream => _stream;

  @override
  // ignore: library_private_types_in_public_api
  _GgValueStream<T> get syncStream => _findOrCreateSyncStream;

  // ...........................................................................
  /// Call this method when the value is about to be released.
  void dispose() {
    for (final func in _dispose.reversed) {
      func();
    }
    _dispose.clear();
  }

  // ...........................................................................
  /// Is used to transform assigned values to other ones,
  /// e.g. to keep the value in a given range.
  final T Function(T)? transform;

  // ...........................................................................
  /// Use that callback to perform some validation
  final bool Function(T)? isOk;

  // ...........................................................................
  /// Set a custom comparison operator
  final bool Function(T a, T b)? compare;

  // ...........................................................................
  /// This operator compares to GgValue objects based on the value. When given,
  /// the [compare] function is used to make the comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GgValue<T> &&
          ((compare != null && compare!(_value, other._value)) ||
              _value == other._value);

  // ...........................................................................
  /// The hashcode of a GgValue is calculated based on the value.
  @override
  int get hashCode => _value.hashCode;

  // ...........................................................................
  /// Returns a string representation of the GgValue.
  @override
  String toString() {
    return 'GgValue<${T.toString()}>(${name != null ? 'name: $name, ' : ''}value: $value)';
  }

  // ...........................................................................
  GgSync? _sync;
  void _initSync() {
    _dispose.add(unsync);
  }

  // ...........................................................................
  /// Two way sync this value with another value
  // coverage:ignore-start
  void syncWith(GgValue<T> other) {
    if (identical(other, this)) {
      return;
    }

    _sync ??= GgSync<T>._(firstValue: this);
    _sync!._addValue(other);
  }
  // coverage:ignore-end

  // ...........................................................................
  /// Remove the synchronization with another element
  void unsync() {
    _sync?._removeValue(this);
  }

  // ...........................................................................
  bool get isSynced => _sync != null; // coverage:ignore-line

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];
  bool get _isDisposed => _dispose.isEmpty;

  // .............
  // Stream

  // ...........................................................................
  final StreamController<T> _controller = StreamController<T>.broadcast();
  StreamController<T>? _syncController;
  late _GgValueStream<T> _stream;
  _GgValueStream<T>? _syncStream;

  void _initController() {
    _dispose.add(_controller.close);
    _dispose.add(() => _syncController?.close);
    _stream = _GgValueStream(
      baseStream: _controller.stream,
      value: () => value,
    );
  }

  // ...........................................................................
  StreamController<T> get _findOrCreateSyncController {
    if (_syncController == null) {
      _syncController = StreamController<T>.broadcast(sync: true);
      _dispose.add(_syncController!.close);
    }
    return _syncController!;
  }

  // ...........................................................................
  _GgValueStream<T> get _findOrCreateSyncStream {
    _syncStream ??= _GgValueStream(
      baseStream: _findOrCreateSyncController.stream,
      value: () => value, // coverage:ignore-line
    );
    return _syncStream!;
  }

  // .............
  // Change Stream

  // ...........................................................................
  StreamController<GgChange<T>>? _changeController;

  void _initChangeController() {
    _changeController = StreamController<GgChange<T>>.broadcast();
    _dispose.add(_changeController!.close);
  }

  // ...........................................................................
  Stream<GgChange<T>> get changeStream {
    if (_changeController == null) {
      _initChangeController();
    }

    return _changeController!.stream;
  }

  // ...........................................................................
  T _value;

  // ...........................................................................
  GgChange<T>? _changeToBeApplied;

  void _applyChange(GgChange<T> change) {
    if (isOk?.call(change.newValue) == false) {
      return;
    }
    _value = transform == null ? change.newValue : transform!(change.newValue);
    _changeToBeApplied = change;

    if (_syncController?.hasListener == true && !_isDisposed) {
      _syncController?.add(_value);
    }

    if (spam) {
      _controller.add(_value);
      _changeController?.add(change);
    } else if (!_isAlreadyTriggered) {
      _isAlreadyTriggered = true;
      scheduleMicrotask(() {
        _isAlreadyTriggered = false;
        if (_controller.hasListener && !_isDisposed) {
          _controller.add(_value);
        }

        if (_changeController?.hasListener == true && !_isDisposed) {
          _changeController?.add(_changeToBeApplied!);
        }
      });
    }
  }

  // ...........................................................................
  void _syncAndApplyChange(GgChange<T> change) {
    if (_sync == null) {
      _applyChange(change);
    } else {
      _sync!.applyChange(change); // coverage:ignore-line
    }
  }

  // ...........................................................................
  final T _seed;

  // ...........................................................................
  bool _isAlreadyTriggered = false;

  // ...........................................................................
  final T Function(String)? _parse;

  // ...........................................................................
  final String Function(T)? _stringify;
}
