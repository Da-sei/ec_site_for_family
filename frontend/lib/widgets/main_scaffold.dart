import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final bool showSearch;
  final TextEditingController? searchController;
  final VoidCallback? onSearchSubmit;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? extraActions;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    this.selectedIndex = 0,
    this.showSearch = false,
    this.searchController,
    this.onSearchSubmit,
    this.onSearchChanged,
    this.extraActions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
        ),
        title: showSearch
            ? _SearchTextField(
                controller: searchController,
                onSubmit: onSearchSubmit,
                onChanged: onSearchChanged,
              )
            : null,
        actions: [
          if (extraActions != null) ...extraActions!,
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 26,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/favorites');
            case 2:
              context.go('/requests');
            case 3:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'いいね',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_rounded),
            label: '申し込み',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }
}

class _SearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSubmit;
  final ValueChanged<String>? onChanged;

  const _SearchTextField({
    this.controller,
    this.onSubmit,
    this.onChanged,
  });

  @override
  State<_SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'キーワードで検索',
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        suffixIcon: widget.controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                onPressed: () {
                  widget.controller!.clear();
                  widget.onChanged?.call('');
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.18),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onSubmitted: (_) => widget.onSubmit?.call(),
      onChanged: (v) {
        widget.onChanged?.call(v);
        setState(() {});
      },
    );
  }
}
