import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';

final hostByIdProvider = FutureProvider.family<UserModel?, String>((ref, hostId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(hostId).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});
