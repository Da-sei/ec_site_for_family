import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/network/api_client.dart';
import '../../widgets/main_scaffold.dart';
import '../group/group_provider.dart';

// Hardcoded categories — in a real app, fetch from /categories
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


class ItemCreateScreen extends ConsumerStatefulWidget {
  const ItemCreateScreen({super.key});

  @override
  ConsumerState<ItemCreateScreen> createState() => _ItemCreateScreenState();
}

class _ItemCreateScreenState extends ConsumerState<ItemCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedCategoryId = 8;
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-2196054972001278/2437346328',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final groupId = ref.read(groupProvider).selectedGroupId;
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('グループを選択してください'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/items', data: {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'categoryId': _selectedCategoryId,
        'groupId': groupId,
      });

      final itemId = response.data['id'] as int;

      for (final image in _selectedImages) {
        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(image.path, filename: image.name),
          });
          await dio.post('/items/$itemId/images', data: formData);
        } catch (_) {}
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を出品しました'), backgroundColor: Colors.green),
        );
        if (_interstitialAd != null) {
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) context.go('/items/$itemId');
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              if (mounted) context.go('/items/$itemId');
            },
          );
          _interstitialAd!.show();
          _interstitialAd = null;
        } else {
          context.go('/items/$itemId');
        }
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.response?.data?['message'];
        final error = msg is List ? msg.join('\n') : msg?.toString() ?? '出品に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像
              _SectionLabel(label: '画像', icon: Icons.photo_library_rounded),
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._selectedImages.asMap().entries.map((entry) => Stack(
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
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(entry.key)),
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

              // 出品ボタン
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
                      : const Icon(Icons.sell_rounded),
                  label: const Text(
                    '出品する',
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
