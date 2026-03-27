import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/main_scaffold.dart';
import 'group_provider.dart';

class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({super.key});

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await ref.read(groupProvider.notifier).joinGroup(_tokenController.text.trim());
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('グループに参加しました'), backgroundColor: Colors.green),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(groupProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? '参加に失敗しました'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);

    return MainScaffold(

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アイコンエリア
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 48,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'グループに参加',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '招待トークンを入力してグループに参加してください',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: '招待トークン',
                  prefixIcon: Icon(Icons.vpn_key_rounded),
                  hintText: 'トークンを入力',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? '招待トークンを入力してください' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: groupState.isLoading ? null : _join,
                icon: groupState.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text(
                  '参加する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
