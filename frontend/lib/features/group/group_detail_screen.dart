import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  List<GroupMember> _members = [];
  bool _isLoading = true;

  late Group _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final members = await ref.read(groupProvider.notifier).getMembers(_group.id);
    if (mounted) setState(() { _members = members; _isLoading = false; });
  }

  bool get _isOwner {
    final accountId = ref.read(authProvider).accountId;
    return _members.any((m) => m.isOwner && m.accountId == accountId);
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: _group.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('グループ名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'グループ名'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty || !mounted) return;
    final res = await ref.read(groupProvider.notifier).updateGroupName(_group.id, result.trim());
    if (!mounted) return;
    if (res.success) {
      final updated = ref.read(groupProvider).groups.firstWhere(
        (g) => g.id == _group.id,
        orElse: () => _group,
      );
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループ名を変更しました'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'エラーが発生しました'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showInviteTokenDialog() async {
    final token = await ref.read(groupProvider.notifier).issueInviteToken(_group.id);
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待トークンの発行に失敗しました'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF1976D2)),
            SizedBox(width: 10),
            Text('招待トークン'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下のトークンをメンバーに共有してください：'),
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
                  fontSize: 13,
                  color: Color(0xFF1565C0),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '有効期限: 48時間',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('コピーしました')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('コピー'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransferOwnerDialog() async {
    final candidates = _members.where((m) => !m.isOwner).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('移譲先のメンバーがいません'), backgroundColor: Colors.orange),
      );
      return;
    }
    GroupMember? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('オーナーを移譲'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('移譲先のメンバーを選択してください。\n移譲後、あなたは一般メンバーになります。'),
              const SizedBox(height: 12),
              ...candidates.map((m) => RadioListTile<GroupMember>(
                title: Text(m.name),
                subtitle: Text('@${m.accountId}'),
                value: m,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('移譲する'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == null || !mounted) return;
    final res = await ref.read(groupProvider.notifier).transferOwner(_group.id, selected!.userId);
    if (!mounted) return;
    if (res.success) {
      await _loadMembers();
      final updated = ref.read(groupProvider).groups.firstWhere(
        (g) => g.id == _group.id,
        orElse: () => _group,
      );
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected!.name}にオーナーを移譲しました'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'エラーが発生しました'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmRemoveMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('メンバーを除名'),
        content: Text('「${member.name}」をグループから除名しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('除名する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await ref.read(groupProvider.notifier).removeMember(_group.id, member.userId);
    if (!mounted) return;
    if (res.success) {
      setState(() => _members.removeWhere((m) => m.userId == member.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name}を除名しました'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'エラーが発生しました'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('グループを退出'),
        content: Text('「${_group.name}」から退出しますか？\n退出後はこのグループの商品を閲覧できなくなります。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await ref.read(groupProvider.notifier).leaveGroup(_group.id);
    if (!mounted) return;
    if (res.success) {
      Navigator.of(context).pop(true); // 退出成功 → 前画面に戻る
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'エラーが発生しました'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(_group.name),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'グループ名を変更',
                  onPressed: _showRenameDialog,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── メンバー ───
                  _SectionHeader(
                    title: 'メンバー（${_members.length}人）',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: _members.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = entry.value;
                        final currentAccountId = ref.read(authProvider).accountId;
                        final isMe = m.accountId == currentAccountId;
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: m.isOwner
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFFE3F2FD),
                                child: Text(
                                  m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: m.isOwner ? Colors.white : const Color(0xFF1976D2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (m.isOwner) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1976D2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'オーナー',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                  if (isMe && !m.isOwner) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'あなた',
                                        style: TextStyle(color: Color(0xFF1565C0), fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                '@${m.accountId}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: isOwner && !m.isOwner
                                  ? IconButton(
                                      icon: const Icon(Icons.person_remove_rounded,
                                          color: Colors.red, size: 20),
                                      tooltip: '除名',
                                      onPressed: () => _confirmRemoveMember(m),
                                    )
                                  : null,
                            ),
                            if (i < _members.length - 1) const Divider(height: 1, indent: 72),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── 招待 ───
                  if (isOwner) ...[
                    const _SectionHeader(title: '招待'),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.vpn_key_rounded,
                              color: Color(0xFF1976D2), size: 20),
                        ),
                        title: const Text('招待トークンを発行'),
                        subtitle: const Text('有効期限 48時間（複数人に共有可）', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: _showInviteTokenDialog,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionHeader(title: 'グループ管理'),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: Colors.orange, size: 20),
                        ),
                        title: const Text('オーナーを移譲'),
                        subtitle: const Text('別のメンバーにオーナー権限を渡す', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: _showTransferOwnerDialog,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ─── 退出 ───
                  if (!isOwner) ...[
                    const _SectionHeader(title: 'グループ操作'),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.exit_to_app_rounded,
                              color: Colors.red, size: 20),
                        ),
                        title: const Text(
                          'グループを退出する',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          '退出後はこのグループの商品を閲覧できなくなります',
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: _confirmLeave,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}
