import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Ouvre la galerie et upload une image vers Storage.
  /// Retourne l'URL de téléchargement ou null si annulé.
  static Future<String?> pickAndUploadImage(
    String hostId, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    return _uploadFile(
      File(file.path),
      'listings/$hostId/${_uuid.v4()}.jpg',
      onProgress: onProgress,
    );
  }

  /// Ouvre la galerie et upload une vidéo (max 1 min) vers Storage.
  /// Retourne l'URL de téléchargement ou null si annulé.
  static Future<String?> pickAndUploadVideo(
    String hostId, {
    void Function(double progress)? onProgress,
  }) async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );
    if (file == null) return null;
    return _uploadFile(
      File(file.path),
      'listings/$hostId/videos/${_uuid.v4()}.mp4',
      onProgress: onProgress,
    );
  }

  /// Upload un fichier quelconque et retourne son URL publique.
  static Future<String> _uploadFile(
    File file,
    String storagePath, {
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final task = ref.putFile(file);

    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  /// Supprime un fichier depuis son URL Firebase Storage.
  static Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore si le fichier n'existe plus
    }
  }
}
