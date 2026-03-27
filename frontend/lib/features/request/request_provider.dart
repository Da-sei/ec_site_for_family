import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';

class RequestState {
  final List<ItemRequest> requests;
  final List<ItemRequest> myRequests;
  final List<ItemRequest> history;
  final bool isLoading;
  final String? errorMessage;

  const RequestState({
    this.requests = const [],
    this.myRequests = const [],
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RequestState copyWith({
    List<ItemRequest>? requests,
    List<ItemRequest>? myRequests,
    List<ItemRequest>? history,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RequestState(
      requests: requests ?? this.requests,
      myRequests: myRequests ?? this.myRequests,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RequestNotifier extends StateNotifier<RequestState> {
  final Dio _dio;

  RequestNotifier(this._dio) : super(const RequestState());

  Future<List<ItemRequest>> getRequestsForItem(int itemId) async {
    try {
      final response = await _dio.get('/requests', queryParameters: {'itemId': itemId});
      return (response.data as List<dynamic>)
          .map((e) => ItemRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<bool> applyForItem(int itemId, String deliveryMethod) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/requests', data: {'itemId': itemId, 'deliveryMethod': deliveryMethod});
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '申し込みに失敗しました',
      );
      return false;
    }
  }

  Future<bool> approveRequest(int requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/requests/$requestId/approve');
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '承認に失敗しました',
      );
      return false;
    }
  }

  Future<bool> declineRequest(int requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/requests/$requestId/decline');
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '断りに失敗しました',
      );
      return false;
    }
  }

  Future<bool> cancelRequest(int requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/requests/$requestId/cancel');
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'キャンセルに失敗しました',
      );
      return false;
    }
  }

  Future<bool> completeRequest(int requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/requests/$requestId/complete');
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '完了処理に失敗しました',
      );
      return false;
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/requests/history');
      final history = (response.data as List<dynamic>)
          .map((e) => ItemRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(history: history, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '履歴の読み込みに失敗しました',
      );
    }
  }

  Future<void> loadMyRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/requests/my-requests');
      final myRequests = (response.data as List<dynamic>)
          .map((e) => ItemRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(myRequests: myRequests, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '申請リストの読み込みに失敗しました',
      );
    }
  }
}

final requestProvider = StateNotifierProvider<RequestNotifier, RequestState>((ref) {
  final dio = ref.watch(dioProvider);
  return RequestNotifier(dio);
});
