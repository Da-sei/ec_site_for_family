class AuthState {
  final bool isAuthenticated;
  final String? accountId;
  final bool isLoading;
  final String? errorMessage;
  final bool isSessionExpired;
  /// アプリ起動時の初期化（トークン確認）が完了するまで true
  final bool isInitializing;

  const AuthState({
    this.isAuthenticated = false,
    this.accountId,
    this.isLoading = false,
    this.errorMessage,
    this.isSessionExpired = false,
    this.isInitializing = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accountId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSessionExpired,
    bool? isInitializing,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accountId: accountId ?? this.accountId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSessionExpired: isSessionExpired ?? this.isSessionExpired,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}
