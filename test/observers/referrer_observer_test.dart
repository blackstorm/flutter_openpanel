import 'package:flutter_test/flutter_test.dart';
import 'package:openpanel_flutter/src/observers/referrer_observer.dart';

void main() {
  test('keeps only safe UTM acquisition dimensions', () {
    final properties = installReferrerProperties(
      'utm_source=google&utm_medium=cpc&utm_campaign=summer_2026&email=parent@example.com',
    );

    expect(properties, {
      'acquisition_source': 'google',
      'acquisition_medium': 'cpc',
      'acquisition_campaign': 'summer_2026',
    });
  });

  test('drops unsafe acquisition values', () {
    final properties = installReferrerProperties(
      'utm_source=parent@example.com&utm_campaign=hello%20world',
    );

    expect(properties, isEmpty);
  });
}
