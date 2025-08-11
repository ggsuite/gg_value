// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

part of 'gg_value.dart';

/// Represents a list value including special updates
class GgListValue<T> extends GgValue<List<T>> {
  // ...........................................................................
  GgListValue({
    super.seed = const [],
    super.spam,
    super.compare,
    super.transform,
    super.isOk,
    super.parse,
    super.stringify,
    super.name,
  });

  // ...........................................................................
  /// Adds a new item to the list
  void add(T newVal) {
    final updatedValue = [...value, newVal];
    final change = GgChange(
      newValue: updatedValue,
      oldValue: value,
      type: GgChangeType.insert,
      index: value.length,
    );
    _syncAndApplyChange(change);
  }

  // ...........................................................................
  /// Removes an item from the list
  void removeAt(int index) {
    final newVal = [...value]..removeAt(index);
    final change = GgChange(
      newValue: newVal,
      oldValue: value,
      type: GgChangeType.remove,
      index: index,
    );
    _syncAndApplyChange(change);
  }

  // ...........................................................................
  /// Removes the first occurence of the item
  void remove(T val) {
    final index = value.indexWhere((element) => element == val);

    removeAt(index);
  }

  // ...........................................................................
  /// Inserts a new value after a given index
  void insertAfter(int index, T newVal) {
    index = min(value.length - 1, index);
    index = max(-1, index);
    index += 1;
    final change = GgChange(
      oldValue: value,
      newValue: [...value]..insert(index, newVal),
      type: GgChangeType.insert,
      index: index,
    );
    _syncAndApplyChange(change);
  }

  // ...........................................................................
  /// Moves an element in a list to another position.
  ///
  /// [fromIndex] and [toIndex] both point to the places in the old array.
  void move({required int fromIndex, required int toIndex}) {
    final maxIndex = value.length <= 2 ? value.length - 1 : value.length;
    toIndex = min(toIndex, maxIndex);

    final newToIndex = value.length <= 2
        ? toIndex
        : fromIndex < toIndex
        ? toIndex - 1
        : toIndex;

    final oldValue = value;
    final newValue = [...oldValue];

    final element = newValue.removeAt(fromIndex);
    newValue.insert(newToIndex, element);

    final change = GgChange(
      oldValue: oldValue,
      newValue: newValue,
      type: GgChangeType.move,
      oldIndex: fromIndex,
      index: newToIndex,
    );
    _syncAndApplyChange(change);
  }

  // ...........................................................................
  /// Inserts a new value before a given index
  void insertBefore(int index, T newVal) {
    insertAfter(index - 1, newVal);
  }
}
