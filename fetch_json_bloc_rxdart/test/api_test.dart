import 'package:fetch_json_bloc_rxdart/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

main() {
  group('Test $Api', () {
    final api = Api(http.Client());

    test('Get users', () async {
      final users = await api.getUsers();
      print(users);
    });
  });
}
