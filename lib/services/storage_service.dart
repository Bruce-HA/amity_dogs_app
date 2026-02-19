import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final supabase = Supabase.instance.client;

  static const bucket = 'dogs_files';

  static Future<String> uploadDogPhoto({
    required String dogId,
    required List<int> bytes,
  }) async {
    final fileName = '${const Uuid().v4()}.jpg';

    final path = '$dogId/photo/$fileName';

    await supabase.storage.from(bucket).uploadBinary(path, bytes);

    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  static Future<String> uploadDogFile({
    required String dogId,
    required List<int> bytes,
    required String extension,
  }) async {
    final fileName = '${const Uuid().v4()}.$extension';

    final path = '$dogId/document/$fileName';

    await supabase.storage.from(bucket).uploadBinary(path, bytes);

    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
