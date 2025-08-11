// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

part of 'gg_value.dart';

enum GgChangeType { remove, insert, update, move }

class GgChange<T> {
  const GgChange({
    required this.newValue,
    required this.oldValue,
    required this.type,
    this.index = -1,
    this.oldIndex = -1,
  });

  final GgChangeType type;
  final T newValue;
  final T oldValue;
  final int index;
  final int oldIndex;
}
