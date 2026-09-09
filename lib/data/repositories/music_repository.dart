import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song.dart';
import '../network/innertube_client.dart';
import '../parser/search_parser.dart';
import '../parser/stream_parser.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final innertubeClient = ref.watch(innertubeClientProvider);
  return MusicRepository(innertubeClient: innertubeClient);
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

  MusicRepository({required this.innertubeClient});

  Future<List<Song>> searchSongs(String query) async {
    final rawJson = await innertubeClient.search(query);
    return parseSearchResults(rawJson);
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    final playerJson = await innertubeClient.getPlayerInfo(videoId);
    return extractAudioStreamUrl(playerJson);
  }
}
