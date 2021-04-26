import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      avatar: json['avatar'],
      email: json['email'],
      firstName: json['first_name'],
      id: json['_id'],
      lastName: json['last_name'],
    );
  }

  @override
  String toString() =>
      'User(id=$id, email=$email, firstName=$firstName, lastName=$lastName, avatar=$avatar)';

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        avatar.hashCode;
  }

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        other is User &&
            other.id == this.id &&
            other.email == this.email &&
            other.firstName == this.firstName &&
            other.lastName == this.lastName &&
            other.avatar == this.avatar;
  }
}

class Api {
  static final url =
      Uri.parse('https://mvi-coroutines-flow-server.herokuapp.com/users');

  final http.Client _client;

  const Api(this._client);

  Future<List<User>> getUsers() async {
    final response = await _client.get(url);

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Get user not successfully, status code: ${response.statusCode}',
        uri: url,
      );
    }

    await Future.delayed(const Duration(seconds: 1));

    final decoded = json.decode(response.body) as List;
    return decoded
        .cast<Map<String, dynamic>>()
        .map((json) => User.fromJson(json))
        .toList(growable: false);
  }
}
