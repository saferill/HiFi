/// InnerTube client contexts and locale, ported from SimpMusic.
///
/// Source of truth: `core/service/kotlinYtmusicScraper/.../models/YouTubeClient.kt`
/// and `Context.kt` in https://github.com/maxrave-dev/core.
///
/// YouTube Music's InnerTube endpoint answers differently depending on which
/// client claims to be asking, and stale `clientVersion` values start getting
/// empty or truncated responses. Keeping the whole client matrix in one place
/// (instead of one hard-coded `WEB_REMIX` blob at the call site) is what lets
/// the repository fall back to another client when one of them fails.
library;

class YouTubeLocale {
  const YouTubeLocale({this.gl = 'US', this.hl = 'en'});

  /// Country code, e.g. `US`, `ID`. Drives charts and regional home content.
  final String gl;

  /// Language code, e.g. `en`, `id`. Drives response text.
  final String hl;

  YouTubeLocale copyWith({String? gl, String? hl}) =>
      YouTubeLocale(gl: gl ?? this.gl, hl: hl ?? this.hl);

  @override
  String toString() => 'YouTubeLocale(gl: $gl, hl: $hl)';
}

class YouTubeClient {
  const YouTubeClient({
    required this.clientName,
    required this.clientVersion,
    required this.apiKey,
    required this.userAgent,
    this.osVersion,
    this.referer,
    this.deviceMake,
    this.deviceModel,
    this.osName,
    this.timeZone,
    this.utcOffsetMinutes,
  });

  final String clientName;
  final String clientVersion;
  final String apiKey;
  final String userAgent;
  final String? osVersion;
  final String? referer;
  final String? deviceMake;
  final String? deviceModel;
  final String? osName;
  final String? timeZone;
  final int? utcOffsetMinutes;

  /// The `context` object InnerTube expects in every request body.
  Map<String, dynamic> toContext(YouTubeLocale locale, {String? visitorData}) {
    return <String, dynamic>{
      'client': <String, dynamic>{
        'clientName': clientName,
        'clientVersion': clientVersion,
        'gl': locale.gl,
        'hl': locale.hl,
        'userAgent': userAgent,
        if (deviceMake != null) 'deviceMake': deviceMake,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (osName != null) 'osName': osName,
        if (osVersion != null) 'osVersion': osVersion,
        if (timeZone != null) 'timeZone': timeZone,
        if (utcOffsetMinutes != null) 'utcOffsetMinutes': utcOffsetMinutes,
        if (visitorData != null && visitorData.isNotEmpty)
          'visitorData': visitorData,
      },
    };
  }

  @override
  String toString() => 'YouTubeClient($clientName $clientVersion)';

  static const String userAgentWeb =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36';

  static const String userAgentAndroid =
      'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 11) gzip';

  static const String userAgentIos =
      'com.google.ios.youtube/19.45.4 (iPhone16,2; U; CPU iOS 18_1_0 like Mac OS X;)';

  static const String userAgentMweb =
      'Mozilla/5.0 (iPad; CPU OS 16_7_10 like Mac OS X) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1,gzip(gfe)';

  static const String refererYouTubeMusic = 'https://music.youtube.com/';

  /// The YouTube Music web client. Default for search, browse and `next`.
  static const YouTubeClient webRemix = YouTubeClient(
    clientName: 'WEB_REMIX',
    clientVersion: '1.20260304.03.00',
    apiKey: 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
    userAgent: userAgentWeb,
    referer: refererYouTubeMusic,
  );

  static const YouTubeClient web = YouTubeClient(
    clientName: 'WEB',
    clientVersion: '2.20250312.04.00',
    apiKey: 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX3',
    userAgent: userAgentWeb,
  );

  /// The YouTube Music Android client. Returns stream URLs the web clients
  /// withhold, which is why it is the preferred fallback for playback.
  static const YouTubeClient androidMusic = YouTubeClient(
    clientName: 'ANDROID_MUSIC',
    clientVersion: '7.27.52',
    apiKey: 'AIzaSyAOghZGza2MQSZkY_zfZ370N-PUdXEo8AI',
    userAgent: userAgentAndroid,
    osName: 'Android',
    osVersion: '11',
  );

  static const YouTubeClient android = YouTubeClient(
    clientName: 'ANDROID',
    clientVersion: '17.13.3',
    apiKey: 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
    userAgent: userAgentAndroid,
  );

  static const YouTubeClient ios = YouTubeClient(
    clientName: 'IOS',
    clientVersion: '19.45.4',
    apiKey: 'AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc',
    userAgent: userAgentIos,
    deviceMake: 'Apple',
    deviceModel: 'iPhone16,2',
    osName: 'iPhone',
    osVersion: '17.5.1.21F90',
    timeZone: 'UTC',
    utcOffsetMinutes: 0,
  );

  static const YouTubeClient mweb = YouTubeClient(
    clientName: 'MWEB',
    clientVersion: '2.20241202.07.00',
    apiKey: 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX3',
    userAgent: userAgentMweb,
    timeZone: 'UTC',
    utcOffsetMinutes: 0,
  );

  /// Clients worth trying, in order, when the primary one answers badly.
  static const List<YouTubeClient> fallbacks = <YouTubeClient>[
    webRemix,
    androidMusic,
    mweb,
    web,
  ];
}
