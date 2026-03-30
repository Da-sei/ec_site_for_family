import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../group/group_provider.dart';
import 'wishlist_provider.dart';

class WishlistCreateScreen extends ConsumerStatefulWidget {
  const WishlistCreateScreen({super.key});

  @override
  ConsumerState<WishlistCreateScreen> createState() =>
      _WishlistCreateScreenState();
}

class _WishlistCreateScreenState extends ConsumerState<WishlistCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(groupProvider.notifier).loadMyGroups();
      final groupState = ref.read(groupProvider);
      setState(() {
        _selectedGroupId = groupState.selectedGroupId;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループを選択してください')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final success = await ref.read(wishlistProvider.notifier).createWishlistItem(
          groupId: _selectedGroupId!,
          title: _titleController.text.trim(),
          description: description.isEmpty ? null : description,
        );

    if (!mounted) return;

    if (success) {
      ref.read(groupProvider.notifier).selectGroup(_selectedGroupId!);
      context.pop();
    } else {
      final errorMessage =
          ref.read(wishlistProvider).errorMessage ?? '投稿に失敗しました';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(wishlistProvider).isSubmitting;
    final groupState = ref.watch(groupProvider);
    final groups = groupState.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('リクエストを投稿'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // グループ選択
            DropdownButtonFormField<int>(
              value: _selectedGroupId,
              decoration: const InputDecoration(
                labelText: '投稿先グループ *',
                prefixIcon: Icon(Icons.group_rounded),
              ),
              items: groups
                  .map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(g.name),
                      ))
                  .toList(),
              onChanged: groupState.isLoading
                  ? null
                  : (val) => setState(() => _selectedGroupId = val),
              validator: (val) => val == null ? 'グループを選択してください' : null,
              hint: groupState.isLoading
                  ? const Text('読み込み中...')
                  : groups.isEmpty
                      ? const Text('参加中のグループがありません')
                      : const Text('グループを選択'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル *',
                hintText: '欲しいものを入力してください',
                prefixIcon: Icon(Icons.card_giftcard_rounded),
              ),
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'タイトルを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                hintText: '詳細や希望条件などを入力してください',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '投稿する',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
