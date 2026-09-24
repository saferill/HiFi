import 'package:app/data/parser/search_suggestion_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/innertube_fixtures.dart';

void main() {
  group('parseSearchSuggestions', () {
    test('joins the suggestion runs into one query', () {
      final suggestions = parseSearchSuggestions(searchSuggestionsResponse());

      // The first two rows spell the same query, so they collapse into one.
      expect(suggestions, hasLength(2));
      expect(suggestions.first.query, 'imagine dragons bones');
      expect(suggestions.first.videoId, isNull);
    });

    test('carries the videoId of media rows so they can play directly', () {
      final suggestions = parseSearchSuggestions(searchSuggestionsResponse());
      final media = suggestions.last;

      expect(media.query, 'Bones');
      expect(media.videoId, 'TO-_3tck2tg');
    });

    test('drops duplicates case-insensitively', () {
      final suggestions = parseSearchSuggestions(<String, dynamic>{
        'contents': <dynamic>[
          <String, dynamic>{
            'searchSuggestionsSectionRenderer': <String, dynamic>{
              'contents': <dynamic>[
                <String, dynamic>{
                  'searchSuggestionRenderer': <String, dynamic>{
                    'suggestion': <String, dynamic>{
                      'runs': <dynamic>[
                        <String, dynamic>{'text': 'Bones'},
                      ],
                    },
                  },
                },
                <String, dynamic>{
                  'searchSuggestionRenderer': <String, dynamic>{
                    'suggestion': <String, dynamic>{
                      'runs': <dynamic>[
                        <String, dynamic>{'text': 'bones'},
                      ],
                    },
                  },
                },
              ],
            },
          },
        ],
      });

      expect(suggestions, hasLength(1));
      expect(suggestions.single.query, 'Bones');
    });

    test('returns nothing for an empty or malformed payload', () {
      expect(parseSearchSuggestions(<String, dynamic>{}), isEmpty);
      expect(
        parseSearchSuggestions(<String, dynamic>{'contents': 'nope'}),
        isEmpty,
      );
      expect(
        parseSearchSuggestions(<String, dynamic>{
          'contents': <dynamic>[
            <String, dynamic>{'searchSuggestionsSectionRenderer': 42},
          ],
        }),
        isEmpty,
      );
    });
  });
}
