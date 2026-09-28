import 'package:drift/drift.dart';
import 'search_history_table.dart';

class QuickbiteDatabase extends Database {
  SearchHistoryTable get searchHistory => createTable(searchHistoryTable);
}