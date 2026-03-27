import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/main_scaffold.dart';
import 'request_provider.dart';

class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key});

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(requestProvider.notifier).loadMyRequests());
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestProvider);

    return MainScaffold(
      selectedIndex: 2,
      body: requestState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requestState.myRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '申し込みはありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(requestProvider.notifier).loadMyRequests(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: requestState.myRequests.length,
                    itemBuilder: (ctx, i) {
                      final req = requestState.myRequests[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE3F2FD),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              color: const Color(0xFF1976D2),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '商品ID: ${req.itemId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '申請者: ${req.requester.name}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: _StatusBadge(
                              status: req.status, label: req.statusDisplay),
                          onTap: () => context.push('/items/${req.itemId}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  Color get _color {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return const Color(0xFF1976D2);
      case 'DECLINED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      case 'COMPLETED':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
