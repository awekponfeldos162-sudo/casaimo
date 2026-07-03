import 'package:flutter_test/flutter_test.dart';
import 'package:casaimo/features/booking/data/models/booking_model.dart';

void main() {
  group('BookingStatus', () {
    test('fromString returns correct status for all known values', () {
      expect(BookingStatus.fromString('pending_approval'), BookingStatus.pendingApproval);
      expect(BookingStatus.fromString('confirmed'),        BookingStatus.confirmed);
      expect(BookingStatus.fromString('rejected'),         BookingStatus.rejected);
      expect(BookingStatus.fromString('checked_in'),       BookingStatus.checkedIn);
      expect(BookingStatus.fromString('active'),           BookingStatus.active);
      expect(BookingStatus.fromString('completed'),        BookingStatus.completed);
      expect(BookingStatus.fromString('cancelled'),        BookingStatus.cancelled);
    });

    test('fromString returns pendingApproval for unknown / null string', () {
      expect(BookingStatus.fromString(null),      BookingStatus.pendingApproval);
      expect(BookingStatus.fromString(''),        BookingStatus.pendingApproval);
      expect(BookingStatus.fromString('unknown'), BookingStatus.pendingApproval);
    });

    test('firestoreName roundtrip via fromString is identity for every status', () {
      for (final status in BookingStatus.values) {
        expect(
          BookingStatus.fromString(status.firestoreName),
          status,
          reason: '${status.name}.firestoreName → fromString should be identity',
        );
      }
    });

    test('label is non-empty for all statuses', () {
      for (final status in BookingStatus.values) {
        expect(status.label.isNotEmpty, isTrue, reason: '${status.name}.label must not be empty');
      }
    });

    test('firestoreName contains only lowercase and underscores', () {
      final pattern = RegExp(r'^[a-z_]+$');
      for (final status in BookingStatus.values) {
        expect(
          pattern.hasMatch(status.firestoreName),
          isTrue,
          reason: '${status.name}.firestoreName "${status.firestoreName}" has invalid chars',
        );
      }
    });
  });

  group('BookingModel.nights', () {
    test('nights equals checkOut minus checkIn in full days', () {
      final checkIn  = DateTime(2026, 7, 10);
      final checkOut = DateTime(2026, 7, 13);
      expect(checkOut.difference(checkIn).inDays, 3);
    });
  });
}
