import '../../core/models/models.dart';

class GroupState {
  final List<Group> groups;
  final bool isLoading;
  final String? errorMessage;
  final int? selectedGroupId;

  const GroupState({
    this.groups = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedGroupId,
  });

  GroupState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? errorMessage,
    int? selectedGroupId,
    bool clearError = false,
    bool clearSelectedGroup = false,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedGroupId: clearSelectedGroup ? null : (selectedGroupId ?? this.selectedGroupId),
    );
  }
}
