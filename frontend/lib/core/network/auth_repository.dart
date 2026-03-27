import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'access_token';
const _accountIdKey = 'account_id';

class AuthRepository {
  final FlutterSecureStorage _storage;

  AuthRepository() : _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccountId() async {
    return _storage.read(key: _accountIdKey);
  }

  Future<void> saveAccountId(String accountId) async {
    await _storage.write(key: _accountIdKey, value: accountId);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _accountIdKey);
  }
}
