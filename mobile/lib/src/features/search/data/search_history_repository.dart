import 'package:shared_preferences/shared_preferences.dart';

import '../domain/search_history.dart';

/// Persistencia local del historial de búsquedas (05#D-13). No hay endpoint en
/// 04 a propósito: la información es de bajo valor y solo vive en el dispositivo.
class SearchHistoryRepository {
  const SearchHistoryRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _key = 'quickbite_search_history';

  Future<SearchHistory> read() async {
    final List<String>? raw;
    try {
      raw = _preferences.getStringList(_key);
    } on Object {
      // Una clave con otro tipo (app actualizada, dato corrupto) no debe
      // tirar la app: se trata como historial vacío.
      return const SearchHistory.empty();
    }
    if (raw == null) {
      return const SearchHistory.empty();
    }
    return SearchHistory(
      raw.map((term) => term.trim()).where((term) => term.isNotEmpty).toList(),
    );
  }

  Future<void> save(SearchHistory history) async {
    await _preferences.setStringList(_key, history.terms);
  }

  Future<void> remove(String term) async {
    final current = await read();
    await save(current.withoutTerm(term));
  }

  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}
