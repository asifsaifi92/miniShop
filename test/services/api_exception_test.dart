import 'package:flutter_test/flutter_test.dart';
import 'package:minishop/services/api_service.dart';

void main() {
  group('ApiException', () {
    test('toString returns the message', () {
      final e = ApiException('No internet connection');
      expect(e.toString(), 'No internet connection');
    });

    test('is catchable as Exception', () {
      expect(
        () => throw ApiException('oops'),
        throwsA(isA<ApiException>()),
      );
    });

    test('is also an Exception', () {
      expect(ApiException('x'), isA<Exception>());
    });
  });
}
