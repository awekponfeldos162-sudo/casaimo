import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/inputs/search_bar_widget.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(query: query));
    context.go('/search/results', extra: {'query': query});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SearchBarWidget(
            controller: _ctrl,
            hint: 'Ville, quartier, type...',
            onChanged: (v) => ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(query: v)),
            onFilter: () => _showFilters(context),
          ),
          const SizedBox(height: 24),

          Text('Recherches populaires', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            'Cotonou', 'Lomé', 'Abidjan', 'Dakar', 'Villa', 'Piscine', 'Centre-ville',
          ].map((q) => ActionChip(
            label: Text(q),
            onPressed: () { _ctrl.text = q; _search(q); },
            avatar: const Icon(Icons.search_rounded, size: 16),
          )).toList()),
          const SizedBox(height: 24),

          Text('Types de bien', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: AppConstants.listingTypes.map((type) {
              final icons = {
                'Villa': Icons.villa_rounded,
                'Appartement': Icons.apartment_rounded,
                'Maison': Icons.house_rounded,
                'Studio': Icons.single_bed_rounded,
                'Hôtel': Icons.hotel_rounded,
                'Chambre': Icons.bed_rounded,
              };
              return GestureDetector(
                onTap: () {
                  ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(type: type));
                  context.go('/search/results', extra: {'query': type});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icons[type] ?? Icons.home_rounded, size: 32, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(type, style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center),
                  ]),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late SearchFilters _local;

  @override
  void initState() {
    super.initState();
    _local = ref.read(searchFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Filtres', style: Theme.of(context).textTheme.headlineSmall),
              TextButton(onPressed: () => setState(() => _local = _local.reset()), child: const Text('Réinitialiser')),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
              // Price range
              Text('Budget / nuit (FCFA)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_local.minPrice.toInt()} FCFA', style: Theme.of(context).textTheme.bodySmall),
                Text('${_local.maxPrice.toInt()} FCFA', style: Theme.of(context).textTheme.bodySmall),
              ]),
              RangeSlider(
                values: RangeValues(_local.minPrice, _local.maxPrice),
                min: 0, max: 500000, divisions: 100,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _local = _local.copyWith(minPrice: v.start, maxPrice: v.end)),
              ),
              const SizedBox(height: 20),

              // Type
              Text('Type de bien', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                'Tous', ...AppConstants.listingTypes
              ].map((t) {
                final selected = t == 'Tous' ? _local.type == null : _local.type == t;
                return ChoiceChip(
                  label: Text(t), selected: selected,
                  onSelected: (_) => setState(() => _local = _local.copyWith(type: t == 'Tous' ? null : t)),
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList()),
              const SizedBox(height: 20),

              // Bedrooms
              _CounterRow(label: 'Chambres min.', value: _local.minBedrooms ?? 0, onChanged: (v) => setState(() => _local = _local.copyWith(minBedrooms: v == 0 ? null : v))),
              const SizedBox(height: 12),
              _CounterRow(label: 'Salles de bain min.', value: _local.minBathrooms ?? 0, onChanged: (v) => setState(() => _local = _local.copyWith(minBathrooms: v == 0 ? null : v))),
              const SizedBox(height: 20),

              // Rating
              Text('Note minimale', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [0, 3, 4, 4.5].map((r) {
                final rr = r.toDouble();
                return ChoiceChip(
                  label: Text(r == 0 ? 'Toutes' : '⭐ $r+'),
                  selected: _local.minRating == rr,
                  onSelected: (_) => setState(() => _local = _local.copyWith(minRating: rr)),
                  selectedColor: AppColors.primaryContainer,
                );
              }).toList()),
              const SizedBox(height: 32),
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: ElevatedButton(
              onPressed: () {
                ref.read(searchFiltersProvider.notifier).state = _local;
                Navigator.pop(context);
                context.go('/search/results', extra: {'query': _local.query});
              },
              child: const Text('Appliquer les filtres'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _CounterRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      Row(children: [
        _CircleBtn(icon: Icons.remove, onTap: value > 0 ? () => onChanged(value - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: Theme.of(context).textTheme.titleMedium),
        ),
        _CircleBtn(icon: Icons.add, onTap: () => onChanged(value + 1)),
      ]),
    ]);
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onTap != null ? AppColors.primary : AppColors.border),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.textHint),
      ),
    );
  }
}
