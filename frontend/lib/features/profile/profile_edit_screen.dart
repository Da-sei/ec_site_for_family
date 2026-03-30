import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final String initialName;

  const ProfileEditScreen({super.key, required this.initialName});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _changePassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{};

      final newName = _nameCtrl.text.trim();
      if (newName != widget.initialName) {
        body['name'] = newName;
      }

      if (_changePassword) {
        body['currentPassword'] = _currentPasswordCtrl.text;
        body['newPassword'] = _newPasswordCtrl.text;
      }

      if (body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('変更する内容がありません')),
          );
        }
        return;
      }

      await dio.patch('/users/me', data: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.pop(context, true); // true = updated
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['message'];
        final message = msg is List ? msg.join('\n') : msg?.toString() ?? '更新に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── 名前 ───
            _SectionLabel(label: '表示名'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration(
                label: '名前',
                icon: Icons.person_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '名前を入力してください';
                if (v.trim().length > 50) return '50文字以内で入力してください';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ─── パスワード変更 ───
            Row(
              children: [
                const _SectionLabel(label: 'パスワード変更'),
                const Spacer(),
                Switch(
                  value: _changePassword,
                  activeColor: const Color(0xFF1976D2),
                  onChanged: (v) => setState(() {
                    _changePassword = v;
                    if (!v) {
                      _currentPasswordCtrl.clear();
                      _newPasswordCtrl.clear();
                      _confirmPasswordCtrl.clear();
                    }
                  }),
                ),
              ],
            ),

            if (_changePassword) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordCtrl,
                obscureText: _obscureCurrent,
                decoration: _inputDecoration(
                  label: '現在のパスワード',
                  icon: Icons.lock_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: _changePassword
                    ? (v) {
                        if (v == null || v.isEmpty) return '現在のパスワードを入力してください';
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                decoration: _inputDecoration(
                  label: '新しいパスワード（6文字以上）',
                  icon: Icons.lock_open_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: _changePassword
                    ? (v) {
                        if (v == null || v.isEmpty) return '新しいパスワードを入力してください';
                        if (v.length < 6) return '6文字以上で入力してください';
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration(
                  label: '新しいパスワード（確認）',
                  icon: Icons.lock_open_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _changePassword
                    ? (v) {
                        if (v != _newPasswordCtrl.text) return 'パスワードが一致しません';
                        return null;
                      }
                    : null,
              ),
            ],

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('保存する',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}
