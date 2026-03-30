import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import 'group_state.dart';

// グループ詳細画面から使うシンプルな結果型
class GroupActionResult {
  final bool success;
  final String? error;
  const GroupActionResult({required this.success, this.error});
}

class GroupNotifier extends StateNotifier<GroupState> {
  final Dio _dio;

  GroupNotifier(this._dio) : super(const GroupState());

  Future<void> loadMyGroups() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('/groups/mine');
      final groups = (response.data as List<dynamic>)
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        groups: groups,
        isLoading: false,
        selectedGroupId: state.selectedGroupId ?? (groups.isNotEmpty ? groups.first.id : null),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'グループの読み込みに失敗しました',
      );
    }
  }

  Future<bool> createGroup(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.post('/groups', data: {'name': name});
      final group = Group.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        groups: [...state.groups, group],
        isLoading: false,
        selectedGroupId: group.id,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'グループの作成に失敗しました',
      );
      return false;
    }
  }

  Future<String?> issueInviteToken(int groupId) async {
    try {
      final response = await _dio.post('/groups/$groupId/invite');
      return response.data['token'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<bool> joinGroup(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post('/groups/join', data: {'token': token});
      await loadMyGroups();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'グループへの参加に失敗しました',
      );
      return false;
    }
  }

  void selectGroup(int groupId) {
    state = state.copyWith(selectedGroupId: groupId);
  }

  Future<List<GroupMember>> getMembers(int groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/members');
      return (response.data as List<dynamic>)
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<GroupActionResult> updateGroupName(int groupId, String name) async {
    try {
      final response = await _dio.patch('/groups/$groupId', data: {'name': name});
      final updated = Group.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        groups: state.groups.map((g) => g.id == groupId ? updated : g).toList(),
      );
      return const GroupActionResult(success: true);
    } on DioException catch (e) {
      return GroupActionResult(
        success: false,
        error: e.response?.data?['message']?.toString() ?? 'グループ名の変更に失敗しました',
      );
    }
  }

  Future<GroupActionResult> leaveGroup(int groupId) async {
    try {
      await _dio.post('/groups/$groupId/leave');
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != groupId).toList(),
        clearSelectedGroup: state.selectedGroupId == groupId,
      );
      return const GroupActionResult(success: true);
    } on DioException catch (e) {
      return GroupActionResult(
        success: false,
        error: e.response?.data?['message']?.toString() ?? 'グループの退出に失敗しました',
      );
    }
  }

  Future<GroupActionResult> removeMember(int groupId, int userId) async {
    try {
      await _dio.delete('/groups/$groupId/members/$userId');
      return const GroupActionResult(success: true);
    } on DioException catch (e) {
      return GroupActionResult(
        success: false,
        error: e.response?.data?['message']?.toString() ?? 'メンバーの除名に失敗しました',
      );
    }
  }

  Future<GroupActionResult> transferOwner(int groupId, int newOwnerId) async {
    try {
      final response = await _dio.patch('/groups/$groupId/owner', data: {'newOwnerId': newOwnerId});
      final updated = Group.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        groups: state.groups.map((g) => g.id == groupId ? updated : g).toList(),
      );
      return const GroupActionResult(success: true);
    } on DioException catch (e) {
      return GroupActionResult(
        success: false,
        error: e.response?.data?['message']?.toString() ?? 'オーナーの移譲に失敗しました',
      );
    }
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupNotifier(dio);
});
