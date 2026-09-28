import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../database/quickbite_database.dart';
import '../database/search_history_table.dart';
import '../session/token_storage.dart';
import 'search_history_repository.dart';

/// Implementación de SearchHistoryRepository usando SQLite.
///
/// H0.4 exige persistencia local del historial de búsquedas con `drift`/SQLite.
class SQLiteSearchHistoryRepository implements SearchHistoryRepository {
  SQLiteSearchHistoryRepository(this._tokenStorage);

  final TokenStorage _tokenStorage;

  late final QuickbiteDatabase _db;

  /// Inicializa la base de datos SQLite con las librerías nativas optimizadas.
  ///
  /// Usa lazy initialization para evitar overhead en la app start.
  Future<void> _ensureInitialized() async {
    if (_db is QuickbiteDatabase) return;
    final sqlite3 = await _openConnection();
    _db = QuickbiteDatabase(Connection(sqlite3));
  }

  Future<Sqlite3> _openConnection() async {
    await mergeEngineLibraries();
    final dbFolder = await _dbFolder();
    final dbPath = join(dbFolder.path, 'quickbite.db');
    return await openConnection(
      key: _getDbKey(),
      databaseFilePath: dbPath,
    );
  }

  Future<String> _dbFolder() async {
    final baseFolder = await getApplicationDocumentsDirectory();
    final dbFolder = Directory(join(baseFolder.path, 'QuickBiteDb'));
    if (!dbFolder.existsSync()) {
      await dbFolder.create(recursive: true);
    }
    return dbFolder;
  }

  /// Genera una clave de base de datos única basada en el token de sesión actual.
  ///
  /// Los datos de la base de datos se cifran con el token de sesión, así que cuando
  /// el usuario cierra sesión, toda la base de datos se vuelve inaccesible (no se
  /// borra para evitar corrupción si el usuario vuelve a loguearse rápido).
  String _getDbKey() {
    final sessionToken = _tokenStorage.readAccessToken();
    return sessionToken ?? 'default';
  }

  Future<Connection> _openConnection(Sqlite3 sqlite3) async {
    return NativeDatabase(sqlite3);
  }

  @override
  Future<SearchHistory> read() async {
    await _ensureInitialized();
    final query = _db.select(_db.searchHistory)
      ..where((table) => table.timestamp.equals(0))
      ..orderBy([(table) => OrderingTerm.asc(table.timestamp)]);

    final terms = await query.map((row) => row.read(term)).toList();
    return SearchHistory(terms);
  }

  @override
  Future<void> save(SearchHistory history) async {
    await _ensureInitialized();

    final table = _db.into(_db.searchHistory);
    await _db.batch((batch) {
      // Limpiar historial anterior
      batch.delete(_db.searchHistory);
      // Guardar términos nuevos
      for (final term in history.terms) {
        batch.insert(
          _db.searchHistory,
          SearchHistoryData(term: term, timestamp: DateTime.now().millisecondsSinceEpoch),
        );
      }
    });
  }

  @override
  Future<void> remove(String term) async {
    await _ensureInitialized();
    await _db.remove(_db.searchHistory, where: (table) => table.term.equals(term));
  }

  @override
  Future<void> clear() async {
    await _ensureInitialized();
    await _db.delete(_db.searchHistory);
  }
}
