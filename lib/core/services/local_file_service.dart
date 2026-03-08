import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalFileService {
  static const String _imageDirName = 'note_images';
  final Uuid _uuid;

  LocalFileService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<String> copyImageToAppDirectory(String sourcePath) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, _imageDirName));

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final extension = p.extension(sourcePath);
    final newFileName = '${_uuid.v4()}$extension';
    final destPath = p.join(imageDir.path, newFileName);

    await sourceFile.copy(destPath);

    return destPath;
  }

  Future<bool> imageExists(String imagePath) async {
    final file = File(imagePath);
    return file.exists();
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> getAppImageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, _imageDirName);
  }

  Future<List<String>> getAllStoredImages() async {
    final imageDirPath = await getAppImageDirectory();
    final imageDir = Directory(imageDirPath);

    if (!await imageDir.exists()) {
      return [];
    }

    final files = await imageDir.list().toList();
    return files
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => _isImageFile(p))
        .toList();
  }

  bool _isImageFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext);
  }
}
