import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../widgets/main_scaffold.dart';
import 'request_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(requestProvider.notifier).loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(requestProvider);

    return MainScaffold(
      selectedIndex: 3,
      body: requestState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requestState.history.isEmpty
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
                          Icons.history_rounded,
                          size: 48,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '取引履歴はありません',
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
                      ref.read(requestProvider.notifier).loadHistory(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: requestState.history.length,
                    itemBuilder: (ctx, i) {
                      final req = requestState.history[i];
                      return _HistoryCard(request: req);
                    },
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ItemRequest request;

  const _HistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/items/${request.itemId}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _statusColor,
                child: Icon(_statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '商品ID: ${request.itemId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '相手: ${request.requester.name}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '申請日: ${_formatDate(request.createdAt)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (request.completedAt != null)
                      Text(
                        '完了日: ${_formatDate(request.completedAt!)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.statusDisplay,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (request.status) {
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

  IconData get _statusIcon {
    switch (request.status) {
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'APPROVED':
        return Icons.check_rounded;
      case 'DECLINED':
        return Icons.close_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      case 'COMPLETED':
        return Icons.done_all_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
