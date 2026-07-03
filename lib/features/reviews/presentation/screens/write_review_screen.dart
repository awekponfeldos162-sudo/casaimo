import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/data/models/booking_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  const WriteReviewScreen({super.key, required this.booking});

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  double _rating = 5;
  final _textCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire un avis')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = ref.read(authProvider)!;
      await ReviewRepository().submitReview(ReviewModel(
        id: '',
        listingId: widget.booking.listingId,
        bookingId: widget.booking.id,
        guestId: user.id,
        guestName: user.name,
        guestAvatar: user.avatarUrl,
        rating: _rating,
        text: _textCtrl.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis publié. Merci !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laisser un avis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Logement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.booking.listingImage.isNotEmpty
                    ? Image.network(widget.booking.listingImage, width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (ctx, url, err) => Container(width: 60, height: 60, color: AppColors.primary.withValues(alpha: 0.2)))
                    : Container(width: 60, height: 60, color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.booking.listingTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2),
                const SizedBox(height: 4),
                Text('Séjour terminé · ${widget.booking.nights} nuit${widget.booking.nights > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 28),

          // Note
          const Text('Votre note globale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              itemSize: 50,
              itemPadding: const EdgeInsets.symmetric(horizontal: 6),
              itemBuilder: (ctx, i) => const Icon(Icons.star_rounded, color: AppColors.star),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _ratingLabel(_rating),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(height: 28),

          // Commentaire
          const Text('Votre commentaire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Propreté, emplacement, accueil, rapport qualité-prix...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Publier mon avis',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  String _ratingLabel(double r) => switch (r.toInt()) {
    5 => 'Excellent !',
    4 => 'Très bien',
    3 => 'Bien',
    2 => 'Passable',
    _ => 'Décevant',
  };
}
