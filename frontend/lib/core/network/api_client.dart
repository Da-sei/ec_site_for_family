import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

// ビルド時に --dart-define=API_BASE_URL=https://... で注入できる。
// 未指定の場合はローカル開発用のフォールバックを使用する。
const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

String get baseUrl {
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 401 エラー発生時にインクリメントされるカウンター。
/// authProvider がこれを監視してログアウト処理を実行する。
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

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
          await authRepo.clearAll();
          ref.read(sessionExpiredProvider.notifier).state++;
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
