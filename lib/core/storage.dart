import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

Future<String?> getToken()         => _storage.read(key: 'driver_token');
Future<void>    saveToken(String t) => _storage.write(key: 'driver_token', value: t);
Future<void>    clearToken()        => _storage.delete(key: 'driver_token');
Future<bool>    hasToken()          async => (await getToken()) != null;
