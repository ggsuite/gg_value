// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_value/gg_value.dart';
import 'package:test/test.dart';

void main() {
  // #########################################################################
  group('GgSync', () {
    test('should allow to sync GgValues', () {
      // Create three GgValues
      final val0 = GgValue<int>(seed: 0);
      final val1 = GgValue<int>(seed: 1);
      final val2 = GgValue<int>(seed: 2);

      // Create a Ggsync with two of the three values and a seed
      val0.syncWith(val1);

      // Make sure the seed was written to all two values, but not the third one
      expect(val0.value, val0.value);
      expect(val1.value, val0.value);
      expect(val2.value, isNot(val0.value));

      // Add the third value and check if the seed is also synced.
      val1.syncWith(val2);
      expect(val2.value, val1.value);

      // Change the value of one of the values.
      final change0 = val2.value + 1;
      val2.value = change0;

      // Make sure the change is applied to all three values.
      expect(val0.value, change0);
      expect(val1.value, change0);
      expect(val2.value, change0);

      // Remove one of the values.
      final removedValue = val1;
      removedValue.unsync();

      // Change one of the synced values.
      final change1 = val0.value + 1;
      val0.value = change1;

      // The change should not be applied to the removed value.
      expect(removedValue, val1);
      expect(val0.value, change1);
      expect(val1.value, isNot(change1));
      expect(val2.value, change1);

      // Change the removed value.
      const change2 = 123;
      removedValue.value = change2;

      // The change should not be applied to the values still synced.
      expect(val0.value, isNot(change2));
      expect(val1.value, change2);
      expect(val2.value, isNot(change2));

      // It should throw when reset is called while a value is synced to others.
      expect(() => val0.reset(), throwsArgumentError);

      // If the second last value is unsynced,
      // the sync should be removed from all
      expect(val0.isSynced, true);
      expect(val2.isSynced, true);

      val0.unsync();
      expect(val0.isSynced, false);
      expect(val2.isSynced, false);
    });

    test('should allow to sync GgListValue', () {
      // Create three GgList values
      final val0 = GgListValue<int>();
      final val1 = GgListValue<int>();
      final val2 = GgListValue<int>();

      // Sync all three with each other
      val0.syncWith(val1);
      val1.syncWith(val2);

      // Make a change
      val1.add(5);

      // Check if change was synced
      expect(val0.value, [5]);
      expect(val1.value, [5]);
      expect(val2.value, [5]);
    });
  });
}
