class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class TagInUseException extends AppException {
  final String tagId;
  final int noteCount;

  const TagInUseException({
    required this.tagId,
    required this.noteCount,
  }) : super(
          '标签正在被 $noteCount 条笔记使用，无法删除',
          code: 'TAG_IN_USE',
        );
}

class FileNotFoundException extends AppException {
  final String path;

  const FileNotFoundException(this.path)
      : super('文件不存在', code: 'FILE_NOT_FOUND');
}

class DatabaseException extends AppException {
  const DatabaseException(String message)
      : super(message, code: 'DATABASE_ERROR');
}

class ValidationException extends AppException {
  const ValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR');
}
