import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';

class ReviewsListScreen extends ConsumerWidget {
  final String listingId;
  final String listingTitle;
  const ReviewsListScreen({super.key, required this.listingId, required this.listingTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(listingReviewsProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: Text('Avis · $listingTitle', overflow: TextOverflow.ellipsis)),
      body: asyncReviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyState(
              icon: Icons.star_border_rounded,

              title: 'Aucun avis',
              subtitle: 'Soyez le premier à laisser un avis sur ce logement.',
            );
          }
          final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          return Column(children: [
            _RatingSummary(reviews: reviews, avg: avg),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: reviews.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double avg;
  const _RatingSummary({required this.reviews, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Column(children: [
          Text(avg.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
          RatingBarIndicator(
            rating: avg, itemSize: 18,
            itemBuilder: (ctx, i) => const Icon(Icons.star_rounded, color: AppColors.star),
          ),
          const SizedBox(height: 4),
          Text('${reviews.length} avis',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final count = reviews.where((r) => r.rating >= star && r.rating < star + 1).length;
              final pct = reviews.isEmpty ? 0.0 : count / reviews.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Text('$star', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 22,
                      child: Text('$count',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          textAlign: TextAlign.end)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: review.guestAvatar.isNotEmpty ? NetworkImage(review.guestAvatar) : null,
            child: review.guestAvatar.isEmpty
                ? Text(
                    review.guestName.isNotEmpty ? review.guestName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(review.guestName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(AppUtils.timeAgo(review.createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          RatingBarIndicator(
            rating: review.rating,
            itemSize: 16,
            itemBuilder: (ctx, i) => const Icon(Icons.star_rounded, color: AppColors.star),
          ),
        ]),
        if (review.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(review.text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ]),
    );
  }
}
