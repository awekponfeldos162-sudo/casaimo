import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/listing_card.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/search_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? [];
    final filters = ref.watch(searchFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(query.isEmpty ? 'Tous les biens' : '"$query"'),
        leading: BackButton(onPressed: () => context.go('/search')),
        actions: [
          TextButton.icon(
            onPressed: () => _showSort(context, ref, filters.sortBy),
            icon: const Icon(Icons.sort_rounded, size: 18),
            label: const Text('Trier'),
          ),
        ],
      ),
      body: resultsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Aucun résultat',
                  subtitle: 'Essayez de modifier vos filtres ou votre recherche.',
                  actionLabel: 'Modifier les filtres',
                  onAction: () => context.go('/search'),
                )
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${results.length} résultat${results.length > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton.icon(
                        onPressed: () => _showFilters(context, ref),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Filtres'),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final l = results[i];
                        return ListingCard(
                          listing: l,
                          isHorizontal: true,
                          isFavorite: ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                          onTap: () => context.push('/listing/${l.id}'),
                          onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(l.id),
                        );
                      },
                    ),
                  ),
                ]),
    );
  }

  void _showSort(BuildContext context, WidgetRef ref, String current) {
    final options = [
      ('pertinence', 'Pertinence'),
      ('prix_asc', 'Prix croissant'),
      ('prix_desc', 'Prix décroissant'),
      ('note', 'Mieux notés'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trier par', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...options.map((o) => ListTile(
            title: Text(o.$2),
            trailing: current == o.$1 ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () {
              ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(sortBy: o.$1));
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    context.go('/search');
  }
}
