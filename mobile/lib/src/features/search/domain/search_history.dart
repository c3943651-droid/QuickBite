import 'package:equatable/equatable.dart';

/// Historial de búsquedas local (05#D-13). Vive solo en el dispositivo, no se
/// sincroniza y no se borra al cerrar sesión.
class SearchHistory extends Equatable {
  const SearchHistory(this.terms);

  static const maxTerms = 10;

  const SearchHistory.empty() : terms = const [];

  final List<String> terms;

  bool get isEmpty => terms.isEmpty;

  /// El término más reciente encabeza la lista; los repetidos no se duplican y
  /// solo se conservan los 10 últimos (07.1 SCR-CAT-02).
  SearchHistory withTerm(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    return SearchHistory(
      (terms.where((item) => item != trimmed).toList()..insert(0, trimmed))
          .take(maxTerms)
          .toList(growable: false),
    );
  }

  SearchHistory withoutTerm(String term) => SearchHistory(
    terms.where((item) => item != term).toList(growable: false),
  );

  @override
  List<Object?> get props => [terms];
}
