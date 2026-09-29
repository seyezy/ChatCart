import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage storage;
  final ImagePicker picker;
  final Uuid uuid;

  StorageService({FirebaseStorage? storage, ImagePicker? picker, Uuid? uuid})
      : storage = storage ?? FirebaseStorage.instance,
        picker = picker ?? ImagePicker(),
        uuid = uuid ?? const Uuid();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) => picker.pickImage(source: source, imageQuality: 88, maxWidth: 2048);

  Future<String> uploadChatImage({required String conversationId, required String userId, required XFile file}) async {
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final ref = storage.ref('chat_media/$conversationId/$userId/${uuid.v4()}.$ext');
    final task = await ref.putFile(File(file.path), SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'));
    return task.ref.getDownloadURL();
  }

  Future<String> uploadKycImage({required String userId, required XFile file, required String kind}) async {
    final safeKind = kind.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final ref = storage.ref('kyc/$userId/$safeKind-${uuid.v4()}.$ext');
    final task = await ref.putFile(File(file.path), SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'));
    // KYC records store the protected Storage path, not a public download URL.
    return task.ref.fullPath;
  }

  Future<String> uploadProductImage({required String userId, required XFile file}) async {
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final ref = storage.ref('marketplace/$userId/${uuid.v4()}.$ext');
    final task = await ref.putFile(File(file.path), SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'));
    return task.ref.getDownloadURL();
  }
}
