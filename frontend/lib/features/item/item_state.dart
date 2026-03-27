import '../../core/models/models.dart';

class ItemListState {
  final List<Item> items;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? keyword;
  final int? categoryId;
  final String? errorMessage;

  const ItemListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.keyword,
    this.categoryId,
    this.errorMessage,
  });

  ItemListState copyWith({
    List<Item>? items,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? keyword,
    int? categoryId,
    String? errorMessage,
    bool clearError = false,
    bool clearKeyword = false,
    bool clearCategoryId = false,
  }) {
    return ItemListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
