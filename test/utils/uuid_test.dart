import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/utils/uuid.dart';

void main() {
  test('newUuidV4 matches UUID shape', () {
    final id = newUuidV4();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newUuidV4(), isNot(id));
  });
}
