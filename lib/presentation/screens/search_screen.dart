import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/music_repository.dart';
import '../../domain/entities/search_suggestion.dart';
import '../../domain/entities/song.dart';
import '../player/player_controller.dart';
import '../widgets/song_tile.dart';

/// How long typing has to pause before a suggestion request goes out.
///
/// YouTube rate-limits the suggestions endpoint, and every keystroke would
/// otherwise be a request.
const Duration _suggestionDebounce = Duration(milliseconds: 250);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  /// The text used for the last *submitted* search. Kept separate from the
  /// controller so typing does not re-run the search under the user.
  String _submittedQuery = '';

  /// The text the suggestion list is currently keyed on.
  String _suggestionInput = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _suggestionInput = '');
      return;
    }
    // Rebuild now so the clear button appears with the first character;
    // only the suggestion lookup is debounced.
    setState(() {});
    _debounce = Timer(_suggestionDebounce, () {
      if (mounted) setState(() => _suggestionInput = trimmed);
    });
  }

  void _submit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    _controller.text = trimmed;
    setState(() {
      _submittedQuery = trimmed;
      _suggestionInput = '';
    });
  }

  void _playSuggestion(SearchSuggestion suggestion) {
    if (suggestion.videoId == null) {
      _submit(suggestion.query);
      return;
    }

    _controller.text = suggestion.query;
    setState(() {
      _submittedQuery = suggestion.query;
      _suggestionInput = '';
    });

    ref.read(playerControllerProvider.notifier).playSong(
          Song(
            videoId: suggestion.videoId!,
            title: suggestion.query,
            artist: '',
            thumbnailUrl: '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSuggestions = _suggestionInput.isNotEmpty;
    final searchAsync = _submittedQuery.isEmpty
        ? null
        : ref.watch(searchSongsProvider(_submittedQuery));

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      tooltip: 'Clear',
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _submittedQuery = '';
                          _suggestionInput = '';
                        });
                      },
                    ),
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        Expanded(
          child: showSuggestions
              ? _SuggestionList(
                  input: _suggestionInput,
                  onSelected: _playSuggestion,
                )
              : _Results(
                  query: _submittedQuery,
                  searchAsync: searchAsync,
                ),
        ),
      ],
    );
  }
}

class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({required this.input, required this.onSelected});

  final String input;
  final void Function(SearchSuggestion) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider(input));

    return suggestions.when(
      loading: () => const SizedBox.shrink(),
      // A failed suggestion lookup must not interrupt typing.
      error: (error, stack) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final suggestion = items[index];
            return ListTile(
              dense: true,
              leading: Icon(
                suggestion.videoId == null
                    ? Icons.search_rounded
                    : Icons.play_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                suggestion.query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelected(suggestion),
            );
          },
        );
      },
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.searchAsync});

  final String query;
  final AsyncValue<List<Song>>? searchAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (searchAsync == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.music_note_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for music on YouTube Music',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return searchAsync!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load search results',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(searchSongsProvider(query)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return Center(
            child: Text(
              'No songs found for "$query"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final playerState = ref.watch(playerControllerProvider);

            return SongTile(
              song: song,
              isSelected: playerState.currentSong?.videoId == song.videoId,
              isPlaying: playerState.isPlaying,
              onTap: () => ref
                  .read(playerControllerProvider.notifier)
                  .playQueue(songs, index),
            );
          },
        );
      },
    );
  }
}
