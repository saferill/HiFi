/// Recorded-shape InnerTube payloads used by the parser and client tests.
///
/// These are trimmed copies of real `music.youtube.com/youtubei/v1` responses:
/// every renderer, key and nesting level the parsers read is present, but each
/// shelf carries two or three entries instead of twenty. Replaying them keeps
/// the suite offline and deterministic — the previous tests called YouTube on
/// every run, which made them fail on any machine without egress.
library;

Map<String, dynamic> responseContext({String visitorData = 'visitor-1'}) {
  return <String, dynamic>{
    'visitorData': visitorData,
    'serviceTrackingParams': <dynamic>[],
  };
}

Map<String, dynamic> _runs(List<Map<String, dynamic>> runs) =>
    <String, dynamic>{'runs': runs};

Map<String, dynamic> _textRun(String text) => <String, dynamic>{'text': text};

Map<String, dynamic> _browseRun(
  String text, {
  required String browseId,
  String? pageType,
}) {
  return <String, dynamic>{
    'text': text,
    'navigationEndpoint': <String, dynamic>{
      'browseEndpoint': <String, dynamic>{
        'browseId': browseId,
        if (pageType != null)
          'browseEndpointContextSupportedConfigs': <String, dynamic>{
            'browseEndpointContextMusicConfig': <String, dynamic>{
              'pageType': pageType,
            },
          },
      },
    },
  };
}

Map<String, dynamic> _thumbnails(String base, {int size = 120}) {
  return <String, dynamic>{
    'thumbnails': <dynamic>[
      <String, dynamic>{
        'url': '$base=w60-h60',
        'width': 60,
        'height': 60,
      },
      <String, dynamic>{
        'url': '$base=w$size-h$size',
        'width': size,
        'height': size,
      },
    ],
  };
}

Map<String, dynamic> _explicitBadge() => <String, dynamic>{
      'musicInlineBadgeRenderer': <String, dynamic>{
        'icon': <String, dynamic>{'iconType': 'MUSIC_EXPLICIT_BADGE'},
      },
    };

// ---------------------------------------------------------------------------
// music/get_search_suggestions
// ---------------------------------------------------------------------------

Map<String, dynamic> searchSuggestionsResponse() {
  return <String, dynamic>{
    'responseContext': responseContext(),
    'contents': <dynamic>[
      <String, dynamic>{
        'searchSuggestionsSectionRenderer': <String, dynamic>{
          'contents': <dynamic>[
            <String, dynamic>{
              'searchSuggestionRenderer': <String, dynamic>{
                'suggestion': _runs(<Map<String, dynamic>>[
                  _textRun('imagine dragons'),
                  _textRun(' bones'),
                ]),
                'navigationEndpoint': <String, dynamic>{
                  'searchEndpoint': <String, dynamic>{
                    'query': 'imagine dragons bones',
                  },
                },
              },
            },
            <String, dynamic>{
              'searchSuggestionRenderer': <String, dynamic>{
                'suggestion': _runs(<Map<String, dynamic>>[
                  _textRun('imagine dragons bones'),
                ]),
                'navigationEndpoint': <String, dynamic>{},
              },
            },
            // A media row: same list, but it carries a real track.
            <String, dynamic>{
              'musicResponsiveListItemRenderer': <String, dynamic>{
                'playlistItemData': <String, dynamic>{
                  'videoId': 'TO-_3tck2tg',
                },
                'flexColumns': <dynamic>[
                  <String, dynamic>{
                    'musicResponsiveListItemFlexColumnRenderer':
                        <String, dynamic>{
                      'text': _runs(<Map<String, dynamic>>[
                        _textRun('Bones'),
                      ]),
                    },
                  },
                  <String, dynamic>{
                    'musicResponsiveListItemFlexColumnRenderer':
                        <String, dynamic>{
                      'text': _runs(<Map<String, dynamic>>[
                        _textRun('Imagine Dragons'),
                      ]),
                    },
                  },
                ],
              },
            },
          ],
        },
      },
    ],
  };
}

// ---------------------------------------------------------------------------
// browse: FEmusic_home
// ---------------------------------------------------------------------------

Map<String, dynamic> homeBrowseResponse() {
  return <String, dynamic>{
    'responseContext': responseContext(),
    'contents': <String, dynamic>{
      'singleColumnBrowseResultsRenderer': <String, dynamic>{
        'tabs': <dynamic>[
          <String, dynamic>{
            'tabRenderer': <String, dynamic>{
              'title': 'Home',
              'selected': true,
              'content': <String, dynamic>{
                'sectionListRenderer': <String, dynamic>{
                  'contents': <dynamic>[
                    // Songs carousel.
                    <String, dynamic>{
                      'musicCarouselShelfRenderer': <String, dynamic>{
                        'header': <String, dynamic>{
                          'musicCarouselShelfBasicHeaderRenderer':
                              <String, dynamic>{
                            'title': _runs(<Map<String, dynamic>>[
                              _textRun('Quick picks'),
                            ]),
                          },
                        },
                        'contents': <dynamic>[
                          <String, dynamic>{
                            'musicTwoRowItemRenderer': <String, dynamic>{
                              'title': _runs(<Map<String, dynamic>>[
                                _textRun('Bones'),
                              ]),
                              'subtitle': _runs(<Map<String, dynamic>>[
                                _textRun('Imagine Dragons'),
                                _textRun(' • '),
                                _textRun('2022'),
                              ]),
                              'thumbnailRenderer': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/bones',
                                  ),
                                },
                              },
                              'aspectRatio':
                                  'MUSIC_TWO_ROW_ITEM_THUMBNAIL_ASPECT_RATIO_SQUARE',
                              'navigationEndpoint': <String, dynamic>{
                                'watchEndpoint': <String, dynamic>{
                                  'videoId': 'TO-_3tck2tg',
                                },
                              },
                              'subtitleBadges': <dynamic>[],
                            },
                          },
                          <String, dynamic>{
                            'musicTwoRowItemRenderer': <String, dynamic>{
                              'title': _runs(<Map<String, dynamic>>[
                                _textRun('Enemy'),
                              ]),
                              'subtitle': _runs(<Map<String, dynamic>>[
                                _textRun('Imagine Dragons'),
                              ]),
                              'thumbnailRenderer': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/enemy',
                                  ),
                                },
                              },
                              'navigationEndpoint': <String, dynamic>{
                                'watchEndpoint': <String, dynamic>{
                                  'videoId': 'D9G1VOjN_84',
                                },
                              },
                              'subtitleBadges': <dynamic>[
                                _explicitBadge(),
                              ],
                            },
                          },
                        ],
                      },
                    },
                    // Albums carousel with a "More" button.
                    <String, dynamic>{
                      'musicCarouselShelfRenderer': <String, dynamic>{
                        'header': <String, dynamic>{
                          'musicCarouselShelfBasicHeaderRenderer':
                              <String, dynamic>{
                            'title': _runs(<Map<String, dynamic>>[
                              _textRun('New releases'),
                            ]),
                            'moreContentButton': <String, dynamic>{
                              'buttonRenderer': <String, dynamic>{
                                'navigationEndpoint': <String, dynamic>{
                                  'browseEndpoint': <String, dynamic>{
                                    'browseId': 'FEmusic_new_releases',
                                    'params': 'ggM8SgQIBxAB',
                                  },
                                },
                              },
                            },
                          },
                        },
                        'contents': <dynamic>[
                          <String, dynamic>{
                            'musicTwoRowItemRenderer': <String, dynamic>{
                              'title': _runs(<Map<String, dynamic>>[
                                _textRun('Mercury - Act 1'),
                              ]),
                              'subtitle': _runs(<Map<String, dynamic>>[
                                _browseRun(
                                  'Imagine Dragons',
                                  browseId: 'UCB0JSO6d5ysH2Mmqz5I9rIw',
                                  pageType: 'MUSIC_PAGE_TYPE_ARTIST',
                                ),
                                _textRun('2021'),
                              ]),
                              'thumbnailRenderer': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/mercury',
                                  ),
                                },
                              },
                              'navigationEndpoint': <String, dynamic>{
                                'browseEndpoint': <String, dynamic>{
                                  'browseId': 'MPREb_9nqEki4ZLQ4',
                                  'browseEndpointContextSupportedConfigs':
                                      <String, dynamic>{
                                    'browseEndpointContextMusicConfig':
                                        <String, dynamic>{
                                      'pageType': 'MUSIC_PAGE_TYPE_ALBUM',
                                    },
                                  },
                                },
                              },
                              'thumbnailOverlay': <String, dynamic>{
                                'musicItemThumbnailOverlayRenderer':
                                    <String, dynamic>{
                                  'content': <String, dynamic>{
                                    'musicPlayButtonRenderer':
                                        <String, dynamic>{
                                      'playNavigationEndpoint':
                                          <String, dynamic>{
                                        'watchPlaylistEndpoint':
                                            <String, dynamic>{
                                          'playlistId': 'OLAK5uy_kMercury',
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                              'subtitleBadges': <dynamic>[],
                            },
                          },
                        ],
                      },
                    },
                    // Moods & genres grid.
                    <String, dynamic>{
                      'gridRenderer': <String, dynamic>{
                        'header': <String, dynamic>{
                          'gridHeaderRenderer': <String, dynamic>{
                            'title': _runs(<Map<String, dynamic>>[
                              _textRun('Moods & genres'),
                            ]),
                          },
                        },
                        'items': <dynamic>[
                          <String, dynamic>{
                            'musicNavigationButtonRenderer':
                                <String, dynamic>{
                              'buttonText': _runs(<Map<String, dynamic>>[
                                _textRun('Chill'),
                              ]),
                              'solid': <String, dynamic>{
                                'leftStripeColor': 4294198070,
                              },
                              'clickCommand': <String, dynamic>{
                                'browseEndpoint': <String, dynamic>{
                                  'browseId':
                                      'FEmusic_moods_and_genres_category',
                                  'params': 'ggMPOg1uX1JOQWZR',
                                },
                              },
                            },
                          },
                          <String, dynamic>{
                            'musicNavigationButtonRenderer':
                                <String, dynamic>{
                              'buttonText': _runs(<Map<String, dynamic>>[
                                _textRun('Workout'),
                              ]),
                              'solid': <String, dynamic>{
                                'leftStripeColor': 4293212469,
                              },
                              'clickCommand': <String, dynamic>{
                                'browseEndpoint': <String, dynamic>{
                                  'browseId':
                                      'FEmusic_moods_and_genres_category',
                                  'params': 'ggMPOg1uX1JOQWZQ',
                                },
                              },
                            },
                          },
                        ],
                      },
                    },
                    // Playlist list shelf.
                    <String, dynamic>{
                      'musicShelfRenderer': <String, dynamic>{
                        'title': _runs(<Map<String, dynamic>>[
                          _textRun('Mixed for you'),
                        ]),
                        'contents': <dynamic>[
                          <String, dynamic>{
                            'musicResponsiveListItemRenderer':
                                <String, dynamic>{
                              'playlistItemData': <String, dynamic>{
                                'videoId': 'kJQP7kiw5Fk',
                              },
                              'flexColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Despacito'),
                                    ]),
                                  },
                                },
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _browseRun(
                                        'Luis Fonsi',
                                        browseId: 'UCxoq-PAQeAdk_zyg8YS0JqA',
                                        pageType: 'MUSIC_PAGE_TYPE_ARTIST',
                                      ),
                                      _textRun(' • '),
                                      _browseRun(
                                        'Vida',
                                        browseId: 'MPREb_xyzVida',
                                        pageType: 'MUSIC_PAGE_TYPE_ALBUM',
                                      ),
                                    ]),
                                  },
                                },
                              ],
                              'fixedColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFixedColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('4:41'),
                                    ]),
                                  },
                                },
                              ],
                              'thumbnail': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/despacito',
                                  ),
                                },
                              },
                              'badges': <dynamic>[],
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            },
          },
        ],
      },
    },
  };
}

// ---------------------------------------------------------------------------
// browse: MPREb_… album page
// ---------------------------------------------------------------------------

Map<String, dynamic> albumBrowseResponse() {
  return <String, dynamic>{
    'responseContext': responseContext(),
    'header': <String, dynamic>{
      'musicDetailHeaderRenderer': <String, dynamic>{
        'title': _runs(<Map<String, dynamic>>[
          _browseRun(
            'Mercury - Act 1',
            browseId: 'MPREb_9nqEki4ZLQ4',
            pageType: 'MUSIC_PAGE_TYPE_ALBUM',
          ),
        ]),
        'subtitle': _runs(<Map<String, dynamic>>[
          _browseRun(
            'Imagine Dragons',
            browseId: 'UCB0JSO6d5ysH2Mmqz5I9rIw',
            pageType: 'MUSIC_PAGE_TYPE_ARTIST',
          ),
          _textRun(' • '),
          _textRun('2021'),
        ]),
        'thumbnail': <String, dynamic>{
          'musicThumbnailRenderer': <String, dynamic>{
            'thumbnail': _thumbnails(
              'https://lh3.googleusercontent.com/mercury',
              size: 544,
            ),
          },
        },
        'subtitleBadges': <dynamic>[],
        'description': _runs(<Map<String, dynamic>>[
          _textRun('Fifth studio album.'),
        ]),
      },
    },
    'contents': <String, dynamic>{
      'twoColumnBrowseResultsRenderer': <String, dynamic>{
        'tabs': <dynamic>[
          <String, dynamic>{
            'tabRenderer': <String, dynamic>{
              'title': 'Album',
              'content': <String, dynamic>{
                'sectionListRenderer': <String, dynamic>{
                  'contents': <dynamic>[
                    <String, dynamic>{
                      'musicPlaylistShelfRenderer': <String, dynamic>{
                        'playlistId': 'OLAK5uy_kMercury',
                        'contents': <dynamic>[
                          <String, dynamic>{
                            'musicResponsiveListItemRenderer':
                                <String, dynamic>{
                              'playlistItemData': <String, dynamic>{
                                'videoId': 'TO-_3tck2tg',
                                'playlistSetVideoId': 'set-1',
                              },
                              'flexColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('My Life'),
                                    ]),
                                  },
                                },
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Imagine Dragons'),
                                    ]),
                                  },
                                },
                              ],
                              'fixedColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFixedColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('3:44'),
                                    ]),
                                  },
                                },
                              ],
                              'thumbnail': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/mylife',
                                  ),
                                },
                              },
                              'badges': <dynamic>[],
                            },
                          },
                          <String, dynamic>{
                            'musicResponsiveListItemRenderer':
                                <String, dynamic>{
                              'playlistItemData': <String, dynamic>{
                                'videoId': 'D9G1VOjN_84',
                                'playlistSetVideoId': 'set-2',
                              },
                              'flexColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Enemy'),
                                    ]),
                                  },
                                },
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Imagine Dragons'),
                                    ]),
                                  },
                                },
                              ],
                              'fixedColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFixedColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('3:53'),
                                    ]),
                                  },
                                },
                              ],
                              'thumbnail': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/enemy',
                                  ),
                                },
                              },
                              'badges': <dynamic>[_explicitBadge()],
                            },
                          },
                        ],
                        'continuations': <dynamic>[
                          <String, dynamic>{
                            'nextContinuationData': <String, dynamic>{
                              'continuation': 'album-page-2',
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            },
          },
        ],
      },
    },
  };
}

// ---------------------------------------------------------------------------
// next: radio queue
// ---------------------------------------------------------------------------

Map<String, dynamic> radioResponse() {
  return <String, dynamic>{
    'responseContext': responseContext(),
    'contents': <String, dynamic>{
      'singleColumnMusicWatchNextResultsRenderer': <String, dynamic>{
        'tabbedRenderer': <String, dynamic>{
          'watchNextTabbedResultsRenderer': <String, dynamic>{
            'tabs': <dynamic>[
              <String, dynamic>{
                'tabRenderer': <String, dynamic>{
                  'content': <String, dynamic>{
                    'musicQueueRenderer': <String, dynamic>{
                      'content': <String, dynamic>{
                        'playlistPanelRenderer': <String, dynamic>{
                          'contents': <dynamic>[
                            <String, dynamic>{
                              'playlistPanelVideoRenderer':
                                  <String, dynamic>{
                                'videoId': 'TO-_3tck2tg',
                                'title': _runs(<Map<String, dynamic>>[
                                  _textRun('Bones'),
                                ]),
                                'longBylineText': _runs(
                                  <Map<String, dynamic>>[
                                    _textRun('Imagine Dragons'),
                                  ],
                                ),
                                'lengthText': _runs(<Map<String, dynamic>>[
                                  _textRun('2:46'),
                                ]),
                                'thumbnail': _thumbnails(
                                  'https://lh3.googleusercontent.com/bones',
                                ),
                              },
                            },
                            <String, dynamic>{
                              'playlistPanelVideoRenderer':
                                  <String, dynamic>{
                                'videoId': 'D9G1VOjN_84',
                                'title': _runs(<Map<String, dynamic>>[
                                  _textRun('Enemy'),
                                ]),
                                'shortBylineText': _runs(
                                  <Map<String, dynamic>>[
                                    _textRun('Imagine Dragons'),
                                  ],
                                ),
                                'lengthText': _runs(<Map<String, dynamic>>[
                                  _textRun('3:53'),
                                ]),
                                'thumbnail': _thumbnails(
                                  'https://lh3.googleusercontent.com/enemy',
                                ),
                              },
                            },
                          ],
                          'continuations': <dynamic>[
                            <String, dynamic>{
                              'nextRadioContinuationData':
                                  <String, dynamic>{
                                'continuation': 'radio-page-2',
                              },
                            },
                          ],
                        },
                      },
                    },
                  },
                },
              },
            ],
          },
        },
      },
    },
  };
}

// ---------------------------------------------------------------------------
// search: musicShelfRenderer with a top result card
// ---------------------------------------------------------------------------

Map<String, dynamic> searchResponse() {
  return <String, dynamic>{
    'responseContext': responseContext(),
    'contents': <String, dynamic>{
      'tabbedSearchResultsRenderer': <String, dynamic>{
        'tabs': <dynamic>[
          <String, dynamic>{
            'tabRenderer': <String, dynamic>{
              'title': 'Songs',
              'content': <String, dynamic>{
                'sectionListRenderer': <String, dynamic>{
                  'contents': <dynamic>[
                    <String, dynamic>{
                      'musicCardShelfRenderer': <String, dynamic>{
                        'title': _runs(<Map<String, dynamic>>[
                          <String, dynamic>{
                            'text': 'Bones',
                            'navigationEndpoint': <String, dynamic>{
                              'watchEndpoint': <String, dynamic>{
                                'videoId': 'TO-_3tck2tg',
                              },
                            },
                          },
                        ]),
                        'subtitle': _runs(<Map<String, dynamic>>[
                          _textRun('Imagine Dragons'),
                          _textRun(' • '),
                          _textRun('Song'),
                          _textRun(' • '),
                          _textRun('2:46'),
                        ]),
                        'thumbnail': <String, dynamic>{
                          'musicThumbnailRenderer': <String, dynamic>{
                            'thumbnail': _thumbnails(
                              'https://lh3.googleusercontent.com/bones',
                            ),
                          },
                        },
                      },
                    },
                    <String, dynamic>{
                      'musicShelfRenderer': <String, dynamic>{
                        'contents': <dynamic>[
                          <String, dynamic>{
                            'musicResponsiveListItemRenderer':
                                <String, dynamic>{
                              'playlistItemData': <String, dynamic>{
                                'videoId': 'D9G1VOjN_84',
                              },
                              'flexColumns': <dynamic>[
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Enemy'),
                                    ]),
                                  },
                                },
                                <String, dynamic>{
                                  'musicResponsiveListItemFlexColumnRenderer':
                                      <String, dynamic>{
                                    'text': _runs(<Map<String, dynamic>>[
                                      _textRun('Imagine Dragons'),
                                      _textRun(' • '),
                                      _textRun('Mercury - Act 1'),
                                      _textRun(' • '),
                                      _textRun('3:53'),
                                    ]),
                                  },
                                },
                              ],
                              'thumbnail': <String, dynamic>{
                                'musicThumbnailRenderer': <String, dynamic>{
                                  'thumbnail': _thumbnails(
                                    'https://lh3.googleusercontent.com/enemy',
                                  ),
                                },
                              },
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            },
          },
        ],
      },
    },
  };
}
