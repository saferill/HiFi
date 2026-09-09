// ignore_for_file: avoid_print
@Timeout(Duration(seconds: 120))
library;

import 'package:app/data/services/stream_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StreamService instantiates and closes cleanly', () async {
    final service = StreamService();
    expect(service, isNotNull);
    service.dispose();
  });
}
