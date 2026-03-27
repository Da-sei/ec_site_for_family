import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final AuthRepository _authRepo;

  AuthNotifier(this._dio, this._authRepo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final hasToken = await _authRepo.hasToken();
    if (hasToken) {
      final savedAccountId = await _authRepo.getAccountId();
      state = state.copyWith(isAuthenticated: true, accountId: savedAccountId);
    }
  }

  Future<bool> login(String accountId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'accountId': accountId,
        'password': password,
      });
      final token = response.data['accessToken'] as String;
      await _authRepo.saveToken(token);
      state = state.copyWith(
        isAuthenticated: true,
        accountId: accountId,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'ログインに失敗しました';
      state = state.copyWith(
        isLoading: false,
        errorMessage: message is List ? message.join('\n') : message.toString(),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ログインに失敗しました',
      );
      return false;
    }
  }

  /// 登録成功時はアカウントIDを返す。失敗時は null。
  /// isAuthenticated は completeRegistration() で後からセットする（
  /// ダイアログ表示前にルーターリダイレクトが走るのを防ぐため）。
  Future<String?> register(String name, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'password': password,
      });
      final token = response.data['accessToken'] as String;
      final returnedAccountId = response.data['accountId'] as String?;
      await _authRepo.saveToken(token);
      if (returnedAccountId != null) {
        await _authRepo.saveAccountId(returnedAccountId);
      }
      // isAuthenticated はここでは true にしない。
      // true にすると router が即座に / へリダイレクトし、
      // アカウントID表示ダイアログが開く前に RegisterScreen がアンマウントされてしまう。
      state = state.copyWith(
        accountId: returnedAccountId,
        isLoading: false,
      );
      return returnedAccountId;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? '登録に失敗しました';
      state = state.copyWith(
        isLoading: false,
        errorMessage: message is List ? message.join('\n') : message.toString(),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '登録に失敗しました',
      );
      return null;
    }
  }

  /// ダイアログでアカウントIDを確認した後に呼ぶ。
  /// isAuthenticated を true にすることで router が / へリダイレクトする。
  void completeRegistration() {
    state = state.copyWith(isAuthenticated: true);
  }

  Future<void> logout() async {
    await _authRepo.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(dio, authRepo);
});
