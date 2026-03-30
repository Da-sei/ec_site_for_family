import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import 'wishlist_state.dart';

class WishlistNotifier extends StateNotifier<WishlistState> {
  final Dio _dio;
  int? _groupId;

  WishlistNotifier(this._dio) : super(const WishlistState());

  void setGroupId(int groupId) {
    if (_groupId != groupId) {
      _groupId = groupId;
      loadWishlistItems();
    }
  }

  Future<void> loadWishlistItems() async {
    if (_groupId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '/wishlist',
        queryParameters: {'groupId': _groupId},
      );
      final items = (response.data as List<dynamic>)
          .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e.response?.data?['message']?.toString() ?? '読み込みに失敗しました',
      );
    }
  }

  Future<bool> createWishlistItem({
    required int groupId,
    required String title,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _dio.post('/wishlist', data: {
        'groupId': groupId,
        'title': title,
        'description': description,
      });
      await loadWishlistItems();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e.response?.data?['message']?.toString() ?? '投稿に失敗しました',
      );
      return false;
    }
  }

  Future<bool> updateWishlistItem({
    required int id,
    required String title,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _dio.patch('/wishlist/$id', data: {
        'title': title,
        'description': description,
      });
      await loadWishlistItems();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e.response?.data?['message']?.toString() ?? '更新に失敗しました',
      );
      return false;
    }
  }

  Future<bool> deleteWishlistItem(int id) async {
    try {
      await _dio.delete('/wishlist/$id');
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        errorMessage:
            e.response?.data?['message']?.toString() ?? '削除に失敗しました',
      );
      return false;
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(dioProvider));
});
