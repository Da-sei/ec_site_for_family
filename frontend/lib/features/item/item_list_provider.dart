import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import 'item_state.dart';

const _limit = 20;

class ItemListNotifier extends StateNotifier<ItemListState> {
  final Dio _dio;
  int? _groupId;

  ItemListNotifier(this._dio) : super(const ItemListState());

  void setGroupId(int groupId) {
    if (_groupId != groupId) {
      _groupId = groupId;
      refresh();
    }
  }

  Future<void> refresh({String? keyword, int? categoryId, bool clearCategory = false}) async {
    if (_groupId == null) return;
    state = ItemListState(
      keyword: keyword ?? state.keyword,
      categoryId: clearCategory ? null : (categoryId ?? state.categoryId),
    );
    await _fetchItems(isRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _groupId == null) return;
    await _fetchItems(isRefresh: false);
  }

  Future<void> _fetchItems({required bool isRefresh}) async {
    if (_groupId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'groupId': _groupId,
        'offset': isRefresh ? 0 : state.offset,
        'limit': _limit,
      };
      if (state.keyword != null && state.keyword!.isNotEmpty) {
        queryParams['keyword'] = state.keyword;
      }
      if (state.categoryId != null) {
        queryParams['categoryId'] = state.categoryId;
      }

      final response = await _dio.get('/items', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final newItems = (data['items'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['total'] as int;

      final allItems = isRefresh ? newItems : [...state.items, ...newItems];
      state = state.copyWith(
        items: allItems,
        isLoading: false,
        hasMore: allItems.length < total,
        offset: allItems.length,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? '商品の読み込みに失敗しました',
      );
    }
  }

  Future<bool> deleteItem(int itemId) async {
    try {
      await _dio.delete('/items/$itemId');
      state = state.copyWith(
        items: state.items.where((item) => item.id != itemId).toList(),
      );
      return true;
    } on DioException {
      return false;
    }
  }
}

final itemListProvider = StateNotifierProvider<ItemListNotifier, ItemListState>((ref) {
  final dio = ref.watch(dioProvider);
  return ItemListNotifier(dio);
});
