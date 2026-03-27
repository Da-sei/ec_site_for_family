import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../widgets/main_scaffold.dart';
import 'item_list_provider.dart';

const _categories = [
  {'id': 1, 'name': '食品・飲み物'},
  {'id': 2, 'name': '衣類・ファッション'},
  {'id': 3, 'name': '家電・電子機器'},
  {'id': 4, 'name': '本・雑誌'},
  {'id': 5, 'name': 'おもちゃ・ゲーム'},
  {'id': 6, 'name': '家具・インテリア'},
  {'id': 7, 'name': 'スポーツ・アウトドア'},
  {'id': 8, 'name': 'その他'},
];


class ItemEditScreen extends ConsumerStatefulWidget {
  final Item item;

  const ItemEditScreen({super.key, required this.item});

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _selectedCategoryId;
  final List<XFile> _newImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController =
        TextEditingController(text: widget.item.description ?? '');
    _selectedCategoryId = widget.item.category.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _newImages.add(image));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/items/${widget.item.id}', data: {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'categoryId': _selectedCategoryId,
      });

      for (final image in _newImages) {
        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(image.path, filename: image.name),
          });
          await dio.post('/items/${widget.item.id}/images', data: formData);
        } catch (_) {}
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を更新しました'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.response?.data?['message'];
        final error =
            msg is List ? msg.join('\n') : msg?.toString() ?? '更新に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('商品を削除'),
          ],
        ),
        content: const Text('この商品を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final success =
          await ref.read(itemListProvider.notifier).deleteItem(widget.item.id);
      setState(() => _isLoading = false);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を削除しました'), backgroundColor: Colors.green),
        );
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('削除に失敗しました'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 0,
      extraActions: [
        IconButton(
          icon: const Icon(Icons.delete_rounded, color: Colors.white70),
          onPressed: _isLoading ? null : _confirmDelete,
          tooltip: '削除',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 既存画像
              if (widget.item.images.isNotEmpty) ...[
                _SectionLabel(label: '現在の画像', icon: Icons.photo_library_rounded),
                const SizedBox(height: 10),
                SizedBox(
                  height: 108,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.item.images.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.item.images[i].imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            width: 100,
                            height: 100,
                            color: const Color(0xFFE3F2FD),
                            child: const Icon(Icons.image_rounded,
                                color: Color(0xFF90CAF9)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 新しい画像
              _SectionLabel(label: '新しい画像を追加', icon: Icons.add_photo_alternate_rounded),
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._newImages.asMap().entries.map((entry) => Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(entry.value.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 10,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _newImages.removeAt(entry.key)),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          border: Border.all(
                              color: const Color(0xFFBBDEFB), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: Color(0xFF1976D2), size: 28),
                            SizedBox(height: 4),
                            Text('追加',
                                style: TextStyle(
                                    color: Color(0xFF1976D2), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // タイトル
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                maxLength: 200,
                validator: (v) =>
                    v == null || v.isEmpty ? 'タイトルを入力してください' : null,
              ),
              const SizedBox(height: 16),

              // 説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // カテゴリ
              _SectionLabel(label: 'カテゴリ *', icon: Icons.category_rounded),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.grid_view_rounded),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name'] as String),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v!),
              ),
              const SizedBox(height: 20),

              // 更新ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text(
                    '更新する',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1976D2)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
