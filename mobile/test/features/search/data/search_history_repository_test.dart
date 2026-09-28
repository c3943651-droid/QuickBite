import 'package:flutter_test/flutter_test.dart';

import 'package:quickbite_mobile/src/features/search/data/search_history_repository.dart';
import 'package:quickbite_mobile/src/features/search/domain/search_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SearchHistoryRepository repository;

  setUp(() async {
    // Mock token storage to provide a consistent key for tests
    final tokenStorage = _MockTokenStorage('test-token');
    repository = SQLiteSearchHistoryRepository(tokenStorage);
  });

  group('SearchHistoryRepository (05 D-13, SQLite)', () {
    test('empieza vacío cuando no hay nada guardado', () async {
      expect((await repository.read()).terms, isEmpty);
    });

    test('guarda y relee el historial', () async {
      await repository.save(const SearchHistory(['tacos', 'pastor']));

      expect((await repository.read()).terms, ['tacos', 'pastor']);
    });

    test('la búsqueda más reciente queda primero', () async {
      final history = const SearchHistory.empty()
          .withTerm('tacos')
          .withTerm('pastor');

      expect(history.terms, ['pastor', 'tacos']);

      await repository.save(history);
      expect((await repository.read()).terms, ['pastor', 'tacos']);
    });

    test('no duplica términos repetidos', () async {
      final history = const SearchHistory.empty()
          .withTerm('tacos')
          .withTerm('tacos');

      expect(history.terms, ['tacos']);
    });

    test('conserva como máximo 10 búsquedas (límite de 07.1)', () async {
      var history = const SearchHistory.empty();
      for (final term in List.generate(12, (i) => 'busqueda$i')) {
        history = history.withTerm(term);
      }

      expect(history.terms, hasLength(10));
      expect(history.terms.first, 'busqueda11');
      expect(history.terms.last, 'busqueda2');

      await repository.save(history);
      expect((await repository.read()).terms, hasLength(10));
    });

    test('borra una entrada concreta', () async {
      await repository.save(const SearchHistory(['tacos', 'pastor']));

      await repository.remove('tacos');

      expect(await repository.read().then((h) => h.terms), ['pastor']);
    });

    test('borrar una entrada inexistente no lanza', () async {
      await repository.save(const SearchHistory(['tacos']));

      await repository.remove('no-existe');

      expect(await repository.read().then((h) => h.terms), ['tacos']);
    });

    test('clear vacía el historial persistido', () async {
      await repository.save(const SearchHistory(['tacos', 'pastor']));

      await repository.clear();

      expect((await repository.read()).terms, isEmpty);
    });

    test('ignora términos vacíos o solo con espacios', () async {
      final history = const SearchHistory.empty()
          .withTerm('tacos')
          .withTerm('')
          .withTerm('   ');

      expect(history.terms, ['tacos']);
    });

    test('guarda la persistencia correctamente', () async {
      // Guardar un término
      await repository.save(const SearchHistory(['tacos']));
      
      // Leer lo guardado
      final readHistory = await repository.read();
      expect(readHistory.terms, ['tacos']);
      
      // Guardar otro término
      await repository.save(const SearchHistory(['pastor']));
      
      // Debería tener ambos, con el más reciente primero
      final readHistory2 = await repository.read();
      expect(readHistory2.terms, ['pastor', 'tacos']);
    });
  });
}

class _MockTokenStorage {
  _MockTokenStorage(this._token);

  final String _token;

  String? readAccessToken() => _token;
}