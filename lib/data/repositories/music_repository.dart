import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song.dart';
import '../network/innertube_client.dart';
import '../parser/search_parser.dart';
import '../services/stream_service.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final innertubeClient = ref.watch(innertubeClientProvider);
  final streamService = ref.watch(streamServiceProvider);
  return MusicRepository(
    innertubeClient: innertubeClient,
    streamService: streamService,
  );
});

final searchSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }
  final repository = ref.watch(musicRepositoryProvider);
  return repository.searchSongs(query);
});

class MusicRepository {
  final InnertubeClient innertubeClient;
  final StreamService streamService;

  MusicRepository({
    required this.innertubeClient,
    required this.streamService,
  });

  Future<List<Song>> searchSongs(String query) async {
    final rawJson = await innertubeClient.search(query);
    return parseSearchResults(rawJson);
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    return streamService.getAudioStreamUrl(videoId);
  }
}
