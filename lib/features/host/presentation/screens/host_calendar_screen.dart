import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HostCalendarScreen extends ConsumerStatefulWidget {
  const HostCalendarScreen({super.key});

  @override
  ConsumerState<HostCalendarScreen> createState() => _HostCalendarScreenState();
}

class _HostCalendarScreenState extends ConsumerState<HostCalendarScreen> {
  DateTime _focused = DateTime.now();
  Set<DateTime> _blocked = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    final user = ref.read(currentUserProvider);
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hostAvailability')
          .doc(user.id)
          .get();
      if (doc.exists) {
        final raw = List<Timestamp>.from(doc.data()?['blocked'] ?? []);
        setState(() {
          _blocked = raw.map((t) {
            final d = t.toDate();
            return DateTime(d.year, d.month, d.day);
          }).toSet();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final timestamps = _blocked.map((d) => Timestamp.fromDate(d)).toList();
      await FirebaseFirestore.instance
          .collection('hostAvailability')
          .doc(user.id)
          .set({'blocked': timestamps, 'updatedAt': FieldValue.serverTimestamp()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilités enregistrées')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier de disponibilité'),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(onPressed: _save, child: const Text('Sauvegarder')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _Legend(color: AppColors.primary, label: 'Disponible'),
                  const SizedBox(width: 16),
                  _Legend(color: AppColors.error.withValues(alpha: 0.7), label: 'Bloqué'),
                  const SizedBox(width: 16),
                  _Legend(color: AppColors.warning.withValues(alpha: 0.7), label: 'Réservé'),
                ]),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 30)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focused,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    markerDecoration: BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                  ),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _focused = focused;
                      final day = DateTime(selected.year, selected.month, selected.day);
                      if (_blocked.contains(day)) {
                        _blocked.remove(day);
                      } else {
                        _blocked.add(day);
                      }
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, day, focused) {
                      final d = DateTime(day.year, day.month, day.day);
                      if (_blocked.contains(d)) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Center(child: Text('${day.day}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500))),
                        );
                      }
                      return null;
                    },
                  ),
                  onPageChanged: (focused) => setState(() => _focused = focused),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: const Row(children: [
                    Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text('Appuyez sur une date pour la bloquer ou la débloquer.', style: TextStyle(color: AppColors.primary, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
                Text('Règles de séjour', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _RuleRow(label: 'Séjour minimum', value: '1 nuit'),
                const SizedBox(height: 8),
                _RuleRow(label: 'Séjour maximum', value: '30 nuits'),
                const SizedBox(height: 8),
                _RuleRow(label: 'Délai de préparation', value: '1 jour'),
              ]),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

class _RuleRow extends StatelessWidget {
  final String label, value;
  const _RuleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      Row(children: [
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 8),
        const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
      ]),
    ]);
  }
}
