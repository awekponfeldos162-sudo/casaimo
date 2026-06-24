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
