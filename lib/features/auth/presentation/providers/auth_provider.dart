import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/user_model.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null) {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChange);
  }

  final _usersCol = FirebaseFirestore.instance.collection('users');
  bool _skipNextAutoCreate = false;
  AuthCredential? _pendingGoogleCredential;

  Future<void> _onAuthChange(User? user) async {
    if (user == null) {
      state = null;
      return;
    }
    final doc = await _usersCol.doc(user.uid).get();
    if (doc.exists) {
      state = UserModel.fromFirestore(doc);
      NotificationService.saveTokenForUser(user.uid);
    } else if (_skipNextAutoCreate) {
      // Google signup flow — let the signup screen create the Firestore doc
      _skipNextAutoCreate = false;
    } else {
      // First login via email/phone → create user document in Firestore
      final newUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        phone: user.phoneNumber ?? '',
        avatarUrl: user.photoURL ?? '',
        role: UserRole.guest,
        isVerified: user.emailVerified,
        favoriteIds: const [],
        createdAt: DateTime.now(),
      );
      await _usersCol.doc(user.uid).set(newUser.toFirestore());
      state = newUser;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name, {
    String phone = '',
    String role = 'guest',
    Map<String, dynamic> extra = const {},
  }) async {
    _skipNextAutoCreate = true;
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await cred.user?.updateDisplayName(name);
      final uid = cred.user!.uid;
      final userRole = UserRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => UserRole.guest,
      );
      final newUser = UserModel(
        id: uid,
        email: email,
        name: name,
        phone: phone,
        avatarUrl: '',
        role: userRole,
        isVerified: false,
        favoriteIds: const [],
        createdAt: DateTime.now(),
      );
      await _usersCol.doc(uid).set({...newUser.toFirestore(), ...extra});
      state = newUser;
    } catch (e) {
      _skipNextAutoCreate = false;
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Annulé');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Ouvre le sélecteur Google et renvoie les données sans créer de compte Firebase.
  /// Stocke le credential en mémoire pour [signUpWithGoogleCredential].
  Future<({String name, String email, String avatarUrl})> getGooglePreFillData() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Annulé');
    final googleAuth = await googleUser.authentication;
    _pendingGoogleCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return (
      name: googleUser.displayName ?? '',
      email: googleUser.email,
      avatarUrl: googleUser.photoUrl ?? '',
    );
  }

  /// Crée le compte Firebase + le document Firestore complet après pré-remplissage Google.
  Future<void> signUpWithGoogleCredential({
    required String name,
    required String phone,
    required String avatarUrl,
    required String role,
    Map<String, dynamic> extra = const {},
  }) async {
    final cred = _pendingGoogleCredential;
    if (cred == null) throw Exception('Pas de credential Google en attente');
    _skipNextAutoCreate = true;
    _pendingGoogleCredential = null;

    final userCredential = await FirebaseAuth.instance.signInWithCredential(cred);
    final uid = userCredential.user!.uid;

    // Si le compte existe déjà (utilisateur revenant), ne pas écraser
    final existingDoc = await _usersCol.doc(uid).get();
    if (existingDoc.exists) {
      state = UserModel.fromFirestore(existingDoc);
      return;
    }

    final userRole = UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.guest,
    );
    final newUser = UserModel(
      id: uid,
      email: userCredential.user!.email ?? '',
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      role: userRole,
      isVerified: true,
      favoriteIds: const [],
      createdAt: DateTime.now(),
    );
    await _usersCol.doc(uid).set({...newUser.toFirestore(), ...extra});
    state = newUser;
  }

  Future<void> sendOtp(String phone, {
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async =>
          await FirebaseAuth.instance.signInWithCredential(cred),
      verificationFailed: (e) => onError(e.message ?? 'Erreur OTP'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (state != null) {
      await NotificationService.clearTokenForUser(state!.id);
    }
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> toggleFavorite(String listingId) async {
    if (state == null) return;
    final favs = List<String>.from(state!.favoriteIds);
    if (favs.contains(listingId)) {
      favs.remove(listingId);
    } else {
      favs.add(listingId);
    }
    // Update local state immediately (optimistic)
    state = state!.copyWith(favoriteIds: favs);
    // Persist to Firestore
    await _usersCol.doc(state!.id).update({'favoriteIds': favs});
  }

  bool isFavorite(String listingId) => state?.favoriteIds.contains(listingId) ?? false;

  Future<void> refreshUser() async {
    if (state == null) return;
    final doc = await _usersCol.doc(state!.id).get();
    if (doc.exists) state = UserModel.fromFirestore(doc);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>(
  (ref) => AuthNotifier(),
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider) != null,
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider),
);
