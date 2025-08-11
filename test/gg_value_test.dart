// @license
// Copyright (c) 2019 - 2021 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this repository.

import 'package:fake_async/fake_async.dart';
import 'package:gg_value/gg_value.dart';
import 'package:test/test.dart';

class Foo {}

void main() {
  // #########################################################################
  group('GgValue', () {
    late GgValue<int> v;
    const seedInt = 0;
    const seedString = 'hello';
    void init() {
      v = GgValue(seed: seedInt);
    }

    // #########################################################################
    group('constructor', () {
      test('should be initialized with seed ', () {
        final nullVal = GgValue<int>(seed: seedInt);
        expect(nullVal.value, seedInt);
      });
    });

    // #########################################################################
    group('hashCode', () {
      test('should return the value\'s hashcode', () {
        final val = GgValue(seed: seedString);
        expect(val.hashCode, val.value.hashCode);
      });
    });

    // #########################################################################
    group('dispose', () {
      test('should close the stream.', () {
        fakeAsync((fake) {
          init();
          var onDoneCalled = false;
          v.stream.listen(null, onDone: () => onDoneCalled = true);
          fake.flushMicrotasks();
          expect(onDoneCalled, false);
          v.dispose();
          fake.flushMicrotasks();
          expect(onDoneCalled, true);
        });
      });

      test(
        'should make sure, scheduled micro tasks are not called anymore',
        () {
          fakeAsync((fake) {
            // Observe a GgValue
            final v = GgValue(seed: 1, spam: false);
            var updatedValue = 0;
            v.stream.listen((value) => updatedValue = value);

            // Make a test change before dispose
            v.value++;
            fake.flushMicrotasks();
            expect(updatedValue, 2);

            // Make a change after dispose
            v.value++;

            // Dispose the value
            v.dispose();
            fake.flushMicrotasks();

            // The change should not be delivered
            expect(updatedValue, 2);
          });
        },
      );
    });

    // #########################################################################
    group('value', () {
      test('should allow to set and get the value', () {
        init();
        const val = 172390;
        v.value = val;
        expect(v.value, val);
      });
    });

    // #########################################################################
    group('forceUpdate()', () {
      test('Should inform listeners about the last value', () {
        fakeAsync((fake) {
          init();
          final receivedUpdates = [];
          v.stream.listen((value) => receivedUpdates.add(value));

          v.value = 10;
          fake.flushMicrotasks();
          expect(receivedUpdates, [10]);
          v.forceUpdate();
          fake.flushMicrotasks();
          expect(receivedUpdates, [10, 10]);
        });
      });
    });

    // #########################################################################
    group('seed', () {
      test('returns the seed value', () {
        init();
        const val = 172390;
        v.value = val;
        expect(v.value, val);
        expect(v.seed, seedInt);
      });
    });

    // #########################################################################
    group('reset', () {
      test('should set value back to seed', () {
        init();
        const val = 172390;
        v.value = val;
        expect(v.value, val);
        v.reset();
        expect(v.value, seedInt);
      });
    });

    // #########################################################################
    group('stringValue', () {
      test('should allow convert an int from and to a string', () {
        final intVal = GgValue(seed: 5);
        intVal.stringValue = '6';
        expect(intVal.value, 6);
        expect(intVal.stringValue, '6');
      });

      test('should allow convert a double from and to a string', () {
        final floatVal = GgValue(seed: 5.5);
        floatVal.stringValue = '6.6';
        expect(floatVal.value, 6.6);
        expect(floatVal.stringValue, '6.6');
      });

      test('should allow convert a string from and to a string', () {
        final stringVal = GgValue(seed: 'hello');
        stringVal.stringValue = 'world';
        expect(stringVal.value, 'world');
        expect(stringVal.stringValue, 'world');
      });

      test('should allow convert a bool from and to a string', () {
        final boolVal = GgValue(seed: false);
        expect(boolVal.stringValue, 'false');
        boolVal.stringValue = 'True';
        expect(boolVal.value, true);
        expect(boolVal.stringValue, 'true');
        boolVal.stringValue = 'no';
        expect(boolVal.value, false);
        boolVal.stringValue = 'yes';
        expect(boolVal.value, true);
        boolVal.stringValue = '0';
        expect(boolVal.value, false);
        boolVal.stringValue = '1';
        expect(boolVal.value, true);
      });

      test('should allow convert a custom type from and to a string', () {
        final foo0 = Foo();
        final foo1 = Foo();
        final fooVal = GgValue(
          seed: foo0,
          parse: (_) => foo1,
          stringify: (_) => 'Foo3',
        );
        expect(fooVal.value, foo0);
        fooVal.stringValue = 'Hey';
        expect(fooVal.value, foo1);
        expect(fooVal.stringValue, 'Foo3');
      });

      test(
        'should throw an exception if no parse method is provided for a custom function',
        () {
          final customVal = GgValue(seed: Foo());

          expect(
            () => customVal.stringValue = 'hello',
            throwsA(
              predicate((ArgumentError e) {
                expect(e.message, 'Missing "parse" method for type "Foo".');
                return true;
              }),
            ),
          );
        },
      );

      test(
        'should throw an exception if no toString method is provided for a custom function',
        () {
          final customVal = GgValue(seed: Foo(), parse: (_) => Foo());

          expect(
            () => customVal.stringValue,
            throwsA(
              predicate((ArgumentError e) {
                expect(
                  e.message,
                  'Missing "toString" method for unknown type "Foo".',
                );
                return true;
              }),
            ),
          );
        },
      );

      test('should work when type becomes dynamic', () {
        final dynamicVal = GgValue<dynamic>(seed: 5.0);
        expect(dynamicVal.stringValue, '5.0');
        dynamicVal.stringValue = '6.0';
        expect(dynamicVal.value, 6.0);
      });
    });

    // #########################################################################
    group('set jsonDecodedValue', () {
      late GgValue<int> intVal;
      late GgValue<double> doubleVal;
      late GgValue<bool> boolVal;

      setUp(() {
        intVal = GgValue(seed: 1);
        doubleVal = GgValue(seed: 1.1);
        boolVal = GgValue(seed: false);
      });
      test('should directly assign values of type int, double or bool. ', () {
        intVal.jsonDecodedValue = 2;
        expect(intVal.value, 2);

        doubleVal.jsonDecodedValue = 2.2;
        expect(doubleVal.value, 2.2);

        boolVal.jsonDecodedValue = true;
        expect(boolVal.value, true);
      });

      test('Should assign string values using stringValue.', () {
        intVal.jsonDecodedValue = '3';
        expect(intVal.value, 3);

        doubleVal.jsonDecodedValue = '3.3';
        expect(doubleVal.value, 3.3);

        boolVal.jsonDecodedValue = 'false';
        expect(boolVal.value, false);
      });

      test('should throw an exception, when type is not supported ', () {
        expect(
          () => intVal.jsonDecodedValue = Foo(),
          throwsA(
            predicate((ArgumentError e) {
              expect(
                e.message,
                'Cannot assign json encoded value Instance of \'Foo\'. The type Foo is not supported.',
              );
              return true;
            }),
          ),
        );
      });
    });

    // #########################################################################
    group('get jsonDecodedValue', () {
      late GgValue<int> intVal;
      late GgValue<double> doubleVal;
      late GgValue<bool> boolVal;
      late GgValue<String> stringVal;

      setUp(() {
        intVal = GgValue(seed: 1);
        doubleVal = GgValue(seed: 1.1);
        boolVal = GgValue(seed: false);
        stringVal = GgValue(seed: 'hello');
      });
      test(
        'should return the value directly if type is int, double, bool or string',
        () {
          expect(intVal.jsonDecodedValue, 1);
          expect(doubleVal.jsonDecodedValue, 1.1);
          expect(boolVal.jsonDecodedValue, false);
          expect(stringVal.jsonDecodedValue, 'hello');
        },
      );
      test('should return stringValue, if type is a non trivial type', () {
        final fooVal = GgValue(seed: Foo(), stringify: (_) => 'Foo');
        expect(fooVal.jsonDecodedValue, 'Foo');
      });
    });

    // #########################################################################
    group('get jsonValue', () {
      test('should directly assign values of type int, double or bool', () {});
    });

    // #########################################################################
    group('spam', () {
      test(
        'If spam is set to false, only the last of multiple synchronous value'
        'changes should be delivered',
        () {
          fakeAsync((fake) {
            init();

            v.spam = false;

            final receivedChanges = [];
            final s = v.stream.listen((value) => receivedChanges.add(value));
            fake.flushMicrotasks();
            expect(receivedChanges, []);
            v.value = 5;
            v.value = 6;
            v.value = 7;
            fake.flushMicrotasks();
            expect(receivedChanges, [7]);

            s.cancel();
          });
        },
      );

      test('If spam is set to true, all synchronous value changes should be'
          'delivered', () {
        fakeAsync((fake) {
          init();

          v.spam = true;

          final receivedChanges = [];
          final s = v.stream.listen((value) => receivedChanges.add(value));
          fake.flushMicrotasks();
          expect(receivedChanges, []);
          v.value = 5;
          v.value = 6;
          v.value = 7;
          fake.flushMicrotasks();
          expect(receivedChanges, [5, 6, 7]);

          s.cancel();
        });
      });
    });

    // #########################################################################
    group('transform', () {
      test('should apply a given transform function to a set value', () {
        int ensureMaxFive(int v) => v > 5 ? 5 : v;
        var v2 = GgValue<int>(seed: 0, transform: ensureMaxFive);
        v2.value = 4;
        expect(v2.value, 4);
        v2.value = 10;
        expect(v2.value, 5);
      });
    });

    // #########################################################################
    group('isOk', () {
      test('value should only be assigned when isOk returns true', () {
        bool allowOnlyEven(int val) => val % 2 == 0;
        var evenOnly = GgValue<int>(seed: 0, isOk: allowOnlyEven);

        evenOnly.value = 4;
        expect(evenOnly.value, 4);

        evenOnly.value = 5;
        expect(evenOnly.value, 4);
      });
    });

    // #########################################################################
    group('stream', () {
      test('should allow to observe changes of the state', () {
        fakeAsync((fake) {
          init();
          final receivedValues = [];
          final s = v.stream.listen((val) => receivedValues.add(val));
          fake.flushMicrotasks();
          expect(receivedValues, []);

          v.value = 5;
          fake.flushMicrotasks();
          expect(receivedValues, [5]);

          v.value = 6;
          fake.flushMicrotasks();
          expect(receivedValues, [5, 6]);

          s.cancel();
        });
      });

      test('should only inform when the value really changes', () {
        fakeAsync((fake) {
          init();
          final receivedValues = [];
          final s = v.stream.listen((val) => receivedValues.add(val));

          fake.flushMicrotasks();
          expect(receivedValues, []);

          v.value = 5;
          fake.flushMicrotasks();
          expect(receivedValues, [5]);

          v.value = 5;
          fake.flushMicrotasks();
          expect(receivedValues, [5]);

          s.cancel();
        });
      });

      test('should allow to listen multiple times', () {
        fakeAsync((fake) {
          init();
          var counter = 0;
          var expectedCounter = 0;
          var secondValue = 2;

          // Create and cancel a first subscription
          final s1 = v.stream.listen((event) => counter++);
          fake.flushMicrotasks();
          expect(counter, expectedCounter);
          v.value = secondValue;
          expectedCounter++;
          fake.flushMicrotasks();
          s1.cancel();

          // Wait a little
          expect(counter, expectedCounter);

          // Create and cancel a second subscription
          final s2 = v.stream.listen((event) => counter++);
          fake.flushMicrotasks();
          expect(counter, expectedCounter);
          s2.cancel();
        });
      });

      test('should allow to read the last value from the stream', () {
        final val = GgValue(seed: 5);
        expect(val.stream.value, 5);
      });
    });

    // #########################################################################
    group('changeStream', () {
      test('should provide details about a change', () {
        fakeAsync((fake) {
          // Create a value
          const seed = 5;
          final value = GgValue(seed: seed);

          // Listen to changes
          GgChange<int>? lastChange;
          value.changeStream.listen((event) => lastChange = event);
          fake.flushMicrotasks();
          expect(lastChange, isNull);

          // Make a change
          value.value++;
          fake.flushMicrotasks();

          // Check the received change
          expect(lastChange!.index, -1);
          expect(lastChange!.oldValue, seed);
          expect(lastChange!.newValue, seed + 1);
          expect(lastChange!.type, GgChangeType.update);
        });
      });
    });

    // #########################################################################
    group('syncStream', () {
      test('should deliver values immediately', () {
        fakeAsync((fake) {
          const seed = 5;
          final value = GgValue(seed: seed);
          int receivedValue = 0;
          value.syncStream.listen((value) => receivedValue = value);

          expect(receivedValue, 0);
          fake.flushMicrotasks();

          // Change a value
          final valueBefore = value.value;
          value.value++;

          // Change should be synchronously emitted
          expect(receivedValue, valueBefore + 1);
        });
      });
    });

    // #########################################################################
    group('.operator==', () {
      test('should return true if the value is the same', () {
        expect(GgValue(seed: 123) == GgValue(seed: 123), true);
      });

      test('should return false if the value is not the same', () {
        expect(GgValue(seed: 123) == GgValue(seed: 456), false);
      });

      test('should use the isEqualFunc when provided in constructor', () {
        bool haveSameFirstLetters(String a, String b) =>
            a.substring(0, 1) == b.substring(0, 1);

        var v3 = GgValue<String>(
          seed: 'Karl',
          compare: haveSameFirstLetters,
          spam: true,
        );

        v3.value = 'Anna';
        expect(v3.value, 'Anna');
        v3.value = 'Arno';
        expect(v3.value, 'Anna');
        v3.value = 'Berta';
        expect(v3.value, 'Berta');
        v3.value = 'Bernd';
        expect(v3.value, 'Berta');
      });
    });

    // #########################################################################
    group('toString()', () {
      test(
        'should return a string containing only the value when name is null',
        () {
          final val = GgValue(seed: 5);
          expect(val.toString(), 'GgValue<int>(value: 5)');
        },
      );

      test(
        'should return a string containing name and value when name is defined',
        () {
          final val = GgValue(name: 'myValue', seed: 6);
          expect(val.toString(), 'GgValue<int>(name: myValue, value: 6)');
        },
      );
    });
  });

  // ###########################################################################
  group('GgValueStream', () {
    group('.map(mapping)', () {
      test('should a return a GgValueStream mapped to another stream', () {
        fakeAsync((fake) {
          // Create a GgValue
          final val = GgValue(seed: 5);

          // Create a mapping
          final stringVal = val.stream.map((val) => '$val');

          // Initially the mapping is feed with the seed
          expect(stringVal.value, '5');

          // Change the value.
          val.value = 6;
          fake.flushMicrotasks();

          // Immediately a mapped value should be provided
          expect(stringVal.value, '6');

          // Lets subscribe
          var mappedValue = '';
          final s = stringVal.listen((event) {
            mappedValue = event;
          });
          fake.flushMicrotasks();

          // The value should not be changed because no value has changed
          // so far.
          expect(mappedValue, '');

          // Change the value another time
          val.value = 7;
          fake.flushMicrotasks();
          expect(mappedValue, '7');

          // Map a mapped stream
          final mappedStringVal = stringVal.map((v) => '$v mapped');
          expect(mappedStringVal.value, '7 mapped');

          // Once the original stream is disposed, the derived stream
          // should be closed too.
          val.dispose();

          val.value = 8;
          fake.flushMicrotasks();
          expect(mappedValue, '7');

          s.cancel();
        });
      });

      test('should call the mapping callback only one time', () {
        fakeAsync((fake) {
          final val = GgValue(seed: 5);
          var counter = 0;
          val.stream.map((_) => counter++).listen((event) {});
          fake.flushMicrotasks();
          expect(counter, 1);
          val.value = 6;
          fake.flushMicrotasks();
          expect(counter, 2);
        });
      });
    });

    group('.where(filter)', () {
      test('should forward only values that match the filter', () {
        fakeAsync((fake) {
          // Create the original value
          final val = GgValue(seed: 5);
          var emittedVal = 0;
          final s = val.stream.listen((value) => emittedVal = value);

          // Create a filtered value stream
          final filteredVal = val.stream.where((val) => val < 5);
          expect(filteredVal.value, val.seed);

          var emittedFilteredVal = 0;
          final s1 = filteredVal.listen((value) => emittedFilteredVal = value);

          // Initially no values should be emitted
          fake.flushMicrotasks();
          expect(emittedVal, 0);
          expect(emittedFilteredVal, 0);

          // Now lets set a value passing the filter.
          val.value = 4;
          fake.flushMicrotasks();
          expect(emittedVal, 4);
          expect(emittedFilteredVal, 4);

          // Now lets set a value not passing the filter.
          val.value = 5;
          fake.flushMicrotasks();
          expect(emittedVal, 5);
          expect(emittedFilteredVal, 4);

          val.dispose();
          fake.flushMicrotasks();

          s.cancel();
          s1.cancel();
        });
      });

      test('should call the filter callback only one time', () {
        fakeAsync((fake) {
          final val = GgValue(seed: 5);
          var counter = 0;
          val.stream
              .where((_) {
                counter++;
                return true;
              })
              .listen((event) {});
          fake.flushMicrotasks();
          expect(counter, 0);
          val.value = 6;
          fake.flushMicrotasks();
          expect(counter, 1);
        });
      });
    });

    group('map(mapping).where(filter)', () {
      test('should work correctly', () {
        fakeAsync((fake) {
          // Create a value
          final original = GgValue(seed: 5, spam: true);

          // Map the value to string
          final mapped = original.stream.map((e) => '$e');

          // Filter the string result
          final filtered = mapped.where((e) => e.length > 1);

          // Listen to filtered values
          final lastReceivedValues = [];
          final s = filtered.listen((event) => lastReceivedValues.add(event));
          fake.flushMicrotasks();

          // Initially we should receive the seed
          expect(lastReceivedValues, []);
          fake.flushMicrotasks();
          expect(lastReceivedValues, []);

          // Set a value which fill be filtered out
          original.value = 9;
          fake.flushMicrotasks();

          // Todo: THIS SHOULD BE CHANGED. THE INITIAL VALUE SHOULD BE
          // DELIVERED AT THE BEGINNING OR NOT AT ALL.
          // It should have been received the initial value
          expect(lastReceivedValues, ['5']);
          lastReceivedValues.clear();

          original.value = 10;
          original.value = 1;
          original.value = 11;
          original.value = 1;
          original.value = 12;
          fake.flushMicrotasks();
          expect(lastReceivedValues, ['10', '11', '12']);

          s.cancel();
        });
      });
    });
  });
}
