import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A [HttpClientAdapter] that answers from a queue of canned responses and
/// records every [RequestOptions] it was handed.
///
/// Lets the InnerTube client be tested for the things that actually break —
/// request path, body shape, headers, API key, client fallback — without
/// reaching YouTube. `dio` is already a dependency, so this needs no extra
/// test-only package.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this._responses);

  /// One entry per request, consumed in order. The last entry repeats once the
  /// queue is exhausted, so a fallback test can fail the first client and
  /// succeed on the rest with two entries.
  final List<FakeResponse> _responses;

  final List<RequestOptions> requests = <RequestOptions>[];

  /// Bodies decoded from [requests], index-aligned.
  final List<Map<String, dynamic>> requestBodies = <Map<String, dynamic>>[];

  int _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.data is Map) {
      requestBodies.add(Map<String, dynamic>.from(options.data as Map));
    } else {
      requestBodies.add(<String, dynamic>{});
    }

    final response = _responses[_index.clamp(0, _responses.length - 1)];
    _index++;

    if (response.statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: response.statusCode,
        ),
        type: DioExceptionType.badResponse,
        message: 'simulated ${response.statusCode}',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;
}
