import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/main_scaffold.dart';
import 'group_provider.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(groupProvider.notifier).loadMyGroups());
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: Color(0xFF1976D2)),
            SizedBox(width: 10),
            Text('グループ作成'),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'グループ名',
            prefixIcon: Icon(Icons.group_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('作成'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final success = await ref.read(groupProvider.notifier).createGroup(result);
      if (!success && mounted) {
        final error = ref.read(groupProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'グループの作成に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showInviteTokenDialog(int groupId, String groupName) async {
    final token = await ref.read(groupProvider.notifier).issueInviteToken(groupId);
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('招待トークンの発行に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: Color(0xFF1976D2)),
            const SizedBox(width: 10),
            Expanded(child: Text('$groupName の招待トークン')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('以下のトークンをメンバーに共有してください:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1565C0),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);

    return MainScaffold(

      extraActions: [
        IconButton(
          icon: const Icon(Icons.group_add_rounded),
          tooltip: 'グループに参加',
          onPressed: () => context.push('/groups/join'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'グループ作成',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: groupState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupState.groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          size: 56,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'グループがありません',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'グループを作成して始めましょう',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreateGroupDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('グループを作成する'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(groupProvider.notifier).loadMyGroups(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: groupState.groups.length,
                    itemBuilder: (ctx, i) {
                      final group = groupState.groups[i];
                      final isSelected = groupState.selectedGroupId == group.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFF1976D2)
                                : const Color(0xFFE3F2FD),
                            child: Text(
                              group.name.isNotEmpty ? group.name[0] : 'G',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'ID: ${group.id}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF1976D2)),
                              IconButton(
                                icon: const Icon(Icons.share_rounded,
                                    color: Color(0xFF1976D2)),
                                tooltip: '招待トークン発行',
                                onPressed: () => _showInviteTokenDialog(
                                    group.id, group.name),
                              ),
                            ],
                          ),
                          onTap: () =>
                              ref.read(groupProvider.notifier).selectGroup(group.id),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
