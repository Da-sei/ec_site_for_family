import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// Web: ブラウザから直接 localhost:3000 へ
// Android emulator: 10.0.2.2 でホストの localhost にアクセス
// iOS simulator / その他: localhost
String get baseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final dioProvider = Provider<Dio>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authRepo.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await authRepo.clearToken();
          // The router redirect will handle navigation to login
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
