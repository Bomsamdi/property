import 'package:flutter_test/flutter_test.dart';

import 'package:property/property.dart';

void main() {
  test('create property test type int value 1', () {
    final property = Property<int>(1);
    expect(property.value, 1);
  });
  test('property test increment value type int', () {
    final property = Property<int>(1);
    expect(property.value, 1);
    property.value += 1;
    expect(property.value, 2);
  });
}
