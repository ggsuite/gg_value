// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_value/gg_value.dart';
import 'package:test/test.dart';

void main() {
  group('GgChange', () {
    test('should work fine', () {
      const ggchange = GgChange<int>(
        newValue: 5,
        oldValue: 3,
        type: GgChangeType.update,
      );
      expect(ggchange.type, GgChangeType.update);
    });
  });
}
