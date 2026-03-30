import '../../core/models/models.dart';

class WishlistState {
  final List<WishlistItem> items;
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitting;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSubmitting = false,
  });

  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
