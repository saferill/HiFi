import 'package:app/core/network/innertube_client.dart';
import 'package:app/core/network/youtube_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/fake_http_adapter.dart';
import 'fixtures/innertube_fixtures.dart';

    expect(result, isNotEmpty);
    expect(result.containsKey('responseContext'), isTrue);
    print('STATUS: 200 OK');
    print('TOP_LEVEL_KEYS: ${result.keys.toList()}');
    if (result['contents'] is Map) {
      final contents = result['contents'] as Map<String, dynamic>;
      print('CONTENTS_KEYS: ${contents.keys.toList()}');
      final tabbed = contents['tabbedSearchResultsRenderer'];
      if (tabbed is Map && tabbed['tabs'] is List) {
        final tabs = tabbed['tabs'] as List;
        print('TABS_COUNT: ${tabs.length}');
        if (tabs.isNotEmpty && tabs[0]['tabRenderer'] != null) {
          final tabRenderer = tabs[0]['tabRenderer'] as Map<String, dynamic>;
          print('TAB_RENDERER_TITLE: ${tabRenderer['title']}');
          print(
            'TAB_CONTENT_KEYS: ${(tabRenderer['content'] as Map<String, dynamic>?)?.keys.toList()}',
          );
        }
      }
    }
  });
}
