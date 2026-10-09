import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_session_service.dart';

class RecipeImageService {
  static const bucket = 'recipe-images';
  static const maxUploadBytes = 10 * 1024 * 1024;
  // Signed URLs are deliberately short-lived. Callers resolve them again when
  // loading a recipe after expiry instead of persisting long-lived bearer URLs.
  static const signedUrlLifetimeSeconds = 60 * 60 * 24 * 7;

  final SupabaseClient client;

  RecipeImageService({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) {
    // Keep uploads comfortably below the private bucket's 10 MiB limit.
    // image_picker re-encodes picked photos when imageQuality is specified.
    return ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
  }

  Future<RecipeImageUpload> upload({required String recipeId, required XFile file}) async {
    final extension = _extension(file.name, file.mimeType);
    final path = '$recipeId/cover.$extension';
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Das ausgewählte Bild ist leer. Bitte wähle ein anderes Bild.');
    }
    if (bytes.length > maxUploadBytes) {
      throw const FormatException(
        'Das Bild ist zu groß. Bitte wähle ein kleineres Bild oder mache einen Screenshot davon.',
      );
    }

    await AuthSessionService.runWithRefresh(
      client: client,
      action: () => client.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          // Use the same allow-listed format as the storage object extension.
          // Some platforms report the source image's MIME type even though
          // image_picker has re-encoded the picked image.
          contentType: _mimeType(extension),
          upsert: true,
        ),
      ),
    );

    final signedUrl = await AuthSessionService.runWithRefresh(
      client: client,
      action: () => client.storage.from(bucket).createSignedUrl(path, signedUrlLifetimeSeconds),
    );
    return RecipeImageUpload(path: path, signedUrl: signedUrl);
  }

  Future<String?> resolveSignedUrl(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return null;
    try {
      return await AuthSessionService.runWithRefresh(
        client: client,
        action: () => client.storage.from(bucket).createSignedUrl(normalized, signedUrlLifetimeSeconds),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return;
    await client.storage.from(bucket).remove([normalized]);
  }

  String _extension(String name, String? mimeType) {
    final fromName = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(fromName)) return fromName == 'jpeg' ? 'jpg' : fromName;
    return switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      // image_picker re-encodes picked photos as JPEG, including sources such
      // as HEIC that Supabase Storage does not allow.
      _ => 'jpg',
    };
  }

  String _mimeType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

class RecipeImageUpload {
  final String path;
  final String signedUrl;

  const RecipeImageUpload({required this.path, required this.signedUrl});
}
