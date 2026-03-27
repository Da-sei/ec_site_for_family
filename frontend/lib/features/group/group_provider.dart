import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import 'group_state.dart';

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
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupNotifier(dio);
});
