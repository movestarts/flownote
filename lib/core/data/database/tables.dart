part of 'database.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text().named('image_path')();
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get symbol => text().nullable()();
  TextColumn get timeframe => text().nullable()();
  DateTimeColumn get tradeTime => dateTime().named('trade_time').nullable()();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class NoteTags extends Table {
  TextColumn get noteId => text()
      .named('note_id')
      .references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text()
      .named('tag_id')
      .references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

class SavedFilters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get filterPayloadJson => text().named('filter_payload_json')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class RecentUsages extends Table {
  TextColumn get id => text()();
  TextColumn get fieldName => text().named('field_name')();
  TextColumn get fieldValue => text().named('field_value')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
