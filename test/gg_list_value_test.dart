// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:fake_async/fake_async.dart';
import 'package:gg_value/gg_value.dart';
import 'package:test/test.dart';

void main() {
  const seed = [0, 1, 2, 3];
  final GgListValue<int> listValue = GgListValue(seed: seed);

  late GgChange lastChange;

  listValue.changeStream.listen(((event) => lastChange = event));

  void init() {
    listValue.reset();
  }

  void dispose() {}

  void expectInsert({required int index, required List<int> changedValue}) {
    expect(listValue.value, changedValue);
    expect(lastChange.index, index);
    expect(lastChange.type, GgChangeType.insert);
    expect(lastChange.oldValue, seed);
    expect(lastChange.newValue, changedValue);
  }

  group('GgListValue', () {
    // #########################################################################
    group('add', () {
      test('should work correctly', () {
        fakeAsync((fake) {
          init();

          // Make a change
          const changedValue = [0, 1, 2, 3, 4];
          listValue.add(4);
          fake.flushMicrotasks();

          // Was the right change emiited?
          expect(listValue.value, changedValue);
          expect(lastChange.index, listValue.value.length - 1);
          expect(lastChange.type, GgChangeType.insert);
          expect(lastChange.oldValue, seed);
          expect(lastChange.newValue, [...seed, 4]);
          expect(lastChange.type, GgChangeType.insert);

          dispose();
        });
      });
    });

    group('removeAt', () {
      test('should work correctly', () {
        fakeAsync((fake) {
          init();

          // Delete an element
          const deleteIndex = 3;
          const changedValue = [0, 1, 2];
          listValue.removeAt(deleteIndex);
          fake.flushMicrotasks();

          // Was the right change emiited?
          expect(listValue.value, changedValue);
          expect(lastChange.index, deleteIndex);
          expect(lastChange.type, GgChangeType.remove);
          expect(lastChange.oldValue, seed);
          expect(lastChange.newValue, changedValue);
          dispose();
        });
      });
    });

    group('remove', () {
      test('should work correctly', () {
        fakeAsync((fake) {
          init();

          // Remove a value
          const deleteIndex = 2;
          const expectedValue = [0, 1, 3];
          const valueToBeRemoved = 2;
          listValue.remove(valueToBeRemoved);
          fake.flushMicrotasks();

          // Was the right change emitted?
          expect(listValue.value, expectedValue);
          expect(lastChange.index, deleteIndex);
          expect(lastChange.type, GgChangeType.remove);
          expect(lastChange.oldValue, seed);
          expect(lastChange.newValue, expectedValue);

          dispose();
        });
      });
    });

    group('insertAfter', () {
      test('should work correctly', () {
        fakeAsync((fake) {
          init();

          listValue.insertAfter(10, 4);
          fake.flushMicrotasks();
          expectInsert(index: 4, changedValue: [0, 1, 2, 3, 4]);

          listValue.reset();
          listValue.insertAfter(-10, -1);
          fake.flushMicrotasks();
          expectInsert(index: 0, changedValue: [-1, 0, 1, 2, 3]);

          listValue.reset();
          listValue.insertAfter(0, 1);
          fake.flushMicrotasks();
          expectInsert(index: 1, changedValue: [0, 1, 1, 2, 3]);

          listValue.reset();
          listValue.insertAfter(1, 2);
          fake.flushMicrotasks();
          expectInsert(index: 2, changedValue: [0, 1, 2, 2, 3]);

          dispose();
        });
      });
    });

    test('insertBefore', () {
      fakeAsync((fake) {
        init();

        listValue.insertBefore(-10, -1);
        fake.flushMicrotasks();
        expectInsert(index: 0, changedValue: [-1, 0, 1, 2, 3]);

        listValue.reset();
        listValue.insertBefore(0, -1);
        fake.flushMicrotasks();
        expectInsert(index: 0, changedValue: [-1, 0, 1, 2, 3]);

        listValue.reset();
        listValue.insertBefore(2, 1);
        fake.flushMicrotasks();
        expectInsert(index: 2, changedValue: [0, 1, 1, 2, 3]);

        listValue.reset();
        listValue.insertBefore(listValue.value.length, 4);
        fake.flushMicrotasks();
        expectInsert(index: 4, changedValue: [0, 1, 2, 3, 4]);

        listValue.reset();
        listValue.insertBefore(100, 4);
        fake.flushMicrotasks();
        expectInsert(index: 4, changedValue: [0, 1, 2, 3, 4]);

        dispose();
      });
    });

    group('move', () {
      test('should move item from beginning to end correctly', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1, 2, 3];
          final newValue = [1, 2, 3, 0];
          listValue.value = oldValue;

          // Move item 0 to the last position
          var fromIndex = 0;
          var toIndex = 4;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex - 1);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });

      test('should move item from end to beginning correctly', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1, 2, 3];
          final newValue = [3, 0, 1, 2];
          listValue.value = oldValue;

          // Move last item to 0
          var fromIndex = 3;
          var toIndex = 0;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });

      test('should move item from second to second last position', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1, 2, 3];
          final newValue = [0, 2, 1, 3];
          listValue.value = oldValue;

          // Move last item to 0
          var fromIndex = 1;
          var toIndex = 3;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex - 1);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });

      group('should move item to index far behind last index', () {
        test('with a list with more then two items', () {
          fakeAsync((fake) {
            init();

            // Some vars
            const oldValue = [0, 1, 2, 3];
            final newValue = [0, 2, 3, 1];
            listValue.value = oldValue;

            // Move last item to 0
            var fromIndex = 1;
            var toIndex = 1000;
            listValue.move(fromIndex: fromIndex, toIndex: toIndex);
            fake.flushMicrotasks();

            // Check outcome
            expect(listValue.value, newValue);

            // Check change
            expect(lastChange.index, oldValue.length - 1);
            expect(lastChange.oldIndex, fromIndex);
            expect(lastChange.type, GgChangeType.move);
            expect(lastChange.oldValue, oldValue);
            expect(lastChange.newValue, newValue);

            dispose();
          });
        });

        test('with a list less or equal two items', () {
          fakeAsync((fake) {
            init();

            // Some vars
            const oldValue = [0, 1];
            final newValue = [1, 0];
            listValue.value = oldValue;

            // Move last item to 0
            var fromIndex = 0;
            var toIndex = 1000;
            listValue.move(fromIndex: fromIndex, toIndex: toIndex);
            fake.flushMicrotasks();

            // Check outcome
            expect(listValue.value, newValue);

            // Check change
            expect(lastChange.index, oldValue.length - 1);
            expect(lastChange.oldIndex, fromIndex);
            expect(lastChange.type, GgChangeType.move);
            expect(lastChange.oldValue, oldValue);
            expect(lastChange.newValue, newValue);

            dispose();
          });
        });
      });

      test('should move item from second last to second position', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1, 2, 3];
          final newValue = [0, 2, 1, 3];
          listValue.value = oldValue;

          // Move last item to 0
          var fromIndex = 2;
          var toIndex = 1;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });

      test('should move item from first to second position', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1];
          final newValue = [1, 0];
          listValue.value = oldValue;

          // Move last item to 0
          var fromIndex = 0;
          var toIndex = 1;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });

      test('should move item from second to first position', () {
        fakeAsync((fake) {
          init();

          // Some vars
          const oldValue = [0, 1];
          final newValue = [1, 0];
          listValue.value = oldValue;

          // Move last item to 0
          var fromIndex = 1;
          var toIndex = 0;
          listValue.move(fromIndex: fromIndex, toIndex: toIndex);
          fake.flushMicrotasks();

          // Check outcome
          expect(listValue.value, newValue);

          // Check change
          expect(lastChange.index, toIndex);
          expect(lastChange.oldIndex, fromIndex);
          expect(lastChange.type, GgChangeType.move);
          expect(lastChange.oldValue, oldValue);
          expect(lastChange.newValue, newValue);

          dispose();
        });
      });
    });
  });
}
