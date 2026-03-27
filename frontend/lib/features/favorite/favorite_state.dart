import '../../core/models/models.dart';

class FavoriteState {
  final List<Item> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> favoriteItemIds;

  const FavoriteState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.favoriteItemIds = const {},
  });

  FavoriteState copyWith({
    List<Item>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Set<int>? favoriteItemIds,
  }) {
    return FavoriteState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
    );
  }
}
