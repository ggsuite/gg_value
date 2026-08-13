// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_value/gg_value.dart';

void main() async {
  // ....................................
  // Create a method waiting a short time
  Future<void> flush() => Future.delayed(const Duration(microseconds: 1));

  // ...........................
  // Get synchronously set value
  var v = GgValue<int>(seed: 5, spam: false);
  print('Sync: ${v.value}');

  // Outputs:
  // Sync: 5

  // ...........................
  // When spam is set to false, stream only delivers last change.
  v.spam = false;
  v.stream.listen((val) => print('Async: $val'));
  v.value = 1;
  v.value = 2;
  v.value = 3;
  await flush();

  // Outputs:
  // Async: 3

  // ...........................
  // When spam is set to true, stream delivers each change.
  v.spam = true;
  v.value = 7;
  v.value = 8;
  v.value = 9;
  await flush();

  // Outputs:
  // Async: 7
  // Async: 8
  // Async: 9

  // .........................
  // Transform assigned values
  int ensureMaxFive(int v) => v > 5 ? 5 : v;
  var v2 = GgValue<int>(seed: 0, transform: ensureMaxFive);
  v2.value = 4;
  print('Transformed: ${v2.value}');
  v2.value = 10;
  print('Transformed: ${v2.value}');
  await flush();

  // Outputs:
  // Transformed: 4
  // Transformed: 5

  // .....................
  // Validate input values using isOk
  bool allowOnlyEven(int val) => val % 2 == 0;
  var evenOnly = GgValue<int>(seed: 0, isOk: allowOnlyEven);

  evenOnly.value = 4;
  print('isOk: ${evenOnly.value}');

  evenOnly.value = 5;
  print('isOk: ${evenOnly.value}');

  // Outputs:
  // Transformed: 4
  // Transformed: 4

  // ...............................................
  // Deliver only updates, when values have changed.
  // The param 'isEqual' allows to specify an own comparison function.
  bool haveSameFirstLetters(String a, String b) =>
      a.substring(0, 1) == b.substring(0, 1);

  var v3 = GgValue<String>(
    seed: 'Karl',
    compare: haveSameFirstLetters,
    spam: true,
  );

  final receivedUpdates = [];
  v3.stream.listen((val) => receivedUpdates.add(val));

  v3.value = 'Anna';
  v3.value = 'Arno';
  v3.value = 'Berta';
  v3.value = 'Bernd';

  await flush();

  print(receivedUpdates.join(', '));

  // Outputs:
  // Anna, Berta

  // .........................
  // Set and get string values
  var v4 = GgValue(seed: 0);
  v4.stringValue = '4';
  print(v4.value);
  print(v4.stringValue);

  // Outputs:
  // 4
  // 4

  // .............................................
  // Specify a custom parse and to string function
  int parseEm(String em) => int.parse(em.replaceAll('em', ''));
  String toEmString(int val) => '${val}em';
  var v5 = GgValue(seed: 0, parse: parseEm, stringify: toEmString);
  v5.stringValue = '5em';
  print(v5.value);
  print(v5.stringValue);

  // Outputs:
  // 5
  // 5em

  // .............................................
  // Use jsonDecodedValue to obtain or assig a value representation that can be
  // written to JSON.
  final val6 = GgValue(seed: 6);
  final object = jsonDecode('{"a": 7}');
  val6.jsonDecodedValue = object['a'];
  print(val6.value);

  // Outputs:
  // 7

  // .............................
  // Finally call dispose to close all streams and make sure
  // pending updates are not emitted anymore.
  final val7 = GgValue(seed: 6, spam: false);
  val7.stream.listen((value) => print(value));
  val7.value++;
  val7.dispose();
  await flush();

  // Outputs:
  // Nothing, because value has been disposed

  // ..........................................
  // Sync multiple values using syncWith and unsync
  final valA = GgValue(seed: 'A');
  final valB = GgValue(seed: 'B');
  final valC = GgValue(seed: 'C');

  valA.syncWith(valB);
  print(valA.value);
  print(valB.value);
  valB.syncWith(valC);
  print(valC.value);

  // Outputs:
  // A
  // A
  // A

  valB.value = 'B';
  print(valA.value);
  print(valB.value);
  print(valC.value);

  // Outputs:
  // B
  // B
  // B

  valC.unsync();
  valC.value = 'C';
  print(valA.value);
  print(valB.value);
  print(valC.value);

  // Outputs:
  // B
  // B
  // C

  // .............................
  // Handle lists and it's changes
  final listValue = GgListValue(seed: [0, 1, 2, 3]);
  late GgChange<List<int>> lastChange;
  listValue.changeStream.listen((event) => lastChange = event);

  listValue.add(4);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.insert
  // index: 4
  // old: [0, 1, 2, 3]
  // new: [0, 1, 2, 3, 4]

  listValue.remove(4);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.remove
  // index: 4
  // old: [0, 1, 2, 3, 4]
  // new: [0, 1, 2, 3]

  listValue.insertAfter(3, 4);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.insert
  // index: 4
  // old: [0, 1, 2, 3]
  // new: [0, 1, 2, 3, 4]

  listValue.insertBefore(0, -1);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.insert
  // index: 4
  // old: [0, 1, 2, 3, 4]
  // new: [-1, 0, 1, 2, 3, 4]

  listValue.removeAt(0);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.remove
  // index: 4
  // old: [-1, 0, 1, 2, 3, 4]
  // new: [0, 1, 2, 3, 4]

  listValue.move(fromIndex: 0, toIndex: 5);
  await flush();
  print('type: ${lastChange.type}');
  print('index: ${lastChange.index}');
  print('oldIndex: ${lastChange.oldIndex}');
  print('oldValue: ${lastChange.oldValue}');
  print('newValue: ${lastChange.newValue}');

  // type: GgChangeType.move
  // index: 4
  // oldIndex: 0
  // oldValue: [0, 1, 2, 3, 4]
  // newValue: [1, 2, 3, 4, 0]
}
