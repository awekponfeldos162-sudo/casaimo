import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingRepository {
  final _col = FirebaseFirestore.instance.collection('listings');

  Stream<List<ListingModel>> watchAll() {
    return _col
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ListingModel.fromFirestore).toList());
  }

  Stream<List<ListingModel>> watchByHost(String hostId) {
    return _col
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ListingModel.fromFirestore).toList());
  }

  Future<ListingModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  Stream<List<ListingModel>> watchWithFilters({
    String query = '',
    String? type,
    double minPrice = 0,
    double maxPrice = 9999999,
    int? minBedrooms,
    int? minBathrooms,
    double minRating = 0,
    String sortBy = 'pertinence',
  }) {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'published');

    final hasPriceFilter = minPrice > 0 || maxPrice < 9999999;

    if (hasPriceFilter) {
      q = q
          .where('pricePerNight', isGreaterThanOrEqualTo: minPrice)
          .where('pricePerNight', isLessThanOrEqualTo: maxPrice)
          .orderBy('pricePerNight');
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    return q.snapshots().map((snap) {
      var list = snap.docs.map(ListingModel.fromFirestore).toList();

      if (type != null) {
        list = list.where((l) => l.type == type).toList();
      }
      if (query.isNotEmpty) {
        final kw = query.toLowerCase();
        list = list.where((l) =>
          l.title.toLowerCase().contains(kw) ||
          l.city.toLowerCase().contains(kw) ||
          l.address.toLowerCase().contains(kw) ||
          l.type.toLowerCase().contains(kw),
        ).toList();
      }
      if (minBedrooms != null) list = list.where((l) => l.bedrooms >= minBedrooms).toList();
      if (minBathrooms != null) list = list.where((l) => l.bathrooms >= minBathrooms).toList();
      if (minRating > 0) list = list.where((l) => l.avgRating >= minRating).toList();

      switch (sortBy) {
        case 'prix_asc': list.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        case 'prix_desc': list.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        case 'note': list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      }

      return list;
    });
  }

  Future<String> create(ListingModel listing) async {
    final ref = await _col.add(listing.toFirestore());
    return ref.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
