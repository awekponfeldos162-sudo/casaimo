import 'package:flutter_test/flutter_test.dart';
import 'package:casaimo/features/reviews/data/models/review_model.dart';

void main() {
  final testDate = DateTime(2026, 6, 30, 12, 0);

  ReviewModel makeReview({
    String id = 'rev_001',
    String listingId = 'lst_abc',
    String bookingId = 'bk_xyz',
    String guestId = 'usr_g1',
    String guestName = 'Alice',
    String guestAvatar = 'https://example.com/avatar.jpg',
    double rating = 4.5,
    String text = 'Super logement, très propre.',
  }) =>
      ReviewModel(
        id: id,
        listingId: listingId,
        bookingId: bookingId,
        guestId: guestId,
        guestName: guestName,
        guestAvatar: guestAvatar,
        rating: rating,
        text: text,
        createdAt: testDate,
      );

  group('ReviewModel construction', () {
    test('holds all fields after construction', () {
      final r = makeReview();
      expect(r.id, 'rev_001');
      expect(r.listingId, 'lst_abc');
      expect(r.bookingId, 'bk_xyz');
      expect(r.guestId, 'usr_g1');
      expect(r.guestName, 'Alice');
      expect(r.guestAvatar, 'https://example.com/avatar.jpg');
      expect(r.rating, 4.5);
      expect(r.text, 'Super logement, très propre.');
      expect(r.createdAt, testDate);
    });

    test('accepts rating of 1.0', () {
      final r = makeReview(rating: 1.0);
      expect(r.rating, 1.0);
    });

    test('accepts rating of 5.0', () {
      final r = makeReview(rating: 5.0);
      expect(r.rating, 5.0);
    });

    test('accepts empty avatar URL', () {
      final r = makeReview(guestAvatar: '');
      expect(r.guestAvatar, '');
    });
  });

  group('ReviewModel.toFirestore', () {
    test('includes all required keys', () {
      final map = makeReview().toFirestore();
      expect(map.containsKey('listingId'),   isTrue);
      expect(map.containsKey('bookingId'),   isTrue);
      expect(map.containsKey('guestId'),     isTrue);
      expect(map.containsKey('guestName'),   isTrue);
      expect(map.containsKey('guestAvatar'), isTrue);
      expect(map.containsKey('rating'),      isTrue);
      expect(map.containsKey('text'),        isTrue);
      expect(map.containsKey('createdAt'),   isTrue);
    });

    test('does not include id (managed by Firestore)', () {
      final map = makeReview().toFirestore();
      expect(map.containsKey('id'), isFalse);
    });

    test('rating value is preserved', () {
      final map = makeReview(rating: 3.5).toFirestore();
      expect(map['rating'], 3.5);
    });

    test('text value is preserved', () {
      final map = makeReview(text: 'Excellent séjour!').toFirestore();
      expect(map['text'], 'Excellent séjour!');
    });
  });
}
