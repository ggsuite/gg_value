// @license
// Copyright (c) ggsuite
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
