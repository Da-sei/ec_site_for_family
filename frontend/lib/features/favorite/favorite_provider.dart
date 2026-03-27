import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import 'favorite_state.dart';

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  FavoriteNotifier(this._dio) : super(const FavoriteState());
  final Dio _dio;

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/favorites');
      final items = (response.data as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      final ids = items.map((item) => item.id).toSet();
      state = state.copyWith(
        items: items,
        isLoading: false,
        favoriteItemIds: ids,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?['message']?.toString() ?? 'お気に入りの読み込みに失敗しました',
      );
    }
  }

  Future<void> toggleFavorite(int itemId) async {
    final isFavorited = state.favoriteItemIds.contains(itemId);
    try {
      if (isFavorited) {
        await _dio.delete('/favorites/$itemId');
        final newIds = Set<int>.from(state.favoriteItemIds)..remove(itemId);
        state = state.copyWith(
          favoriteItemIds: newIds,
          items: state.items.where((item) => item.id != itemId).toList(),
        );
      } else {
        await _dio.post('/favorites/$itemId');
        final newIds = Set<int>.from(state.favoriteItemIds)..add(itemId);
        state = state.copyWith(favoriteItemIds: newIds);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        errorMessage: e.response?.data?['message']?.toString() ??
            'お気に入りの更新に失敗しました',
      );
    }
  }

  Future<void> checkFavoriteStatus(int itemId) async {
    try {
      final response = await _dio.get('/favorites/$itemId/status');
      final isFavorited = response.data['isFavorited'] as bool;
      final newIds = Set<int>.from(state.favoriteItemIds);
      if (isFavorited) {
        newIds.add(itemId);
      } else {
        newIds.remove(itemId);
      }
      state = state.copyWith(favoriteItemIds: newIds);
    } on DioException {
      // ステータス確認失敗は無視
    }
  }
}

final favoriteProvider =
    StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier(ref.watch(dioProvider));
});
