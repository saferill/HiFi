import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/network/innertube_client.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;

  Future<void> _testSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = ref.read(innertubeClientProvider);
      final result = await client.search('test');

      debugPrint('=== INNERTUBE SEARCH RESULT ===');
      debugPrint('Top-level keys: ${result.keys.toList()}');
      debugPrint('Full JSON:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(result));
      developer.log('Innertube response keys: ${result.keys.toList()}', name: 'TestSearch');
    } catch (e, stack) {
      debugPrint('Innertube search error: $e');
      developer.log('Search error', name: 'TestSearch', error: e, stackTrace: stack);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HiFi',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clean Architecture • Riverpod • GoRouter',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _testSearch,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Test Search'),
            ),
          ],
        ),
      ),
    );
  }
}
