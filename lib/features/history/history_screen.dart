import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

final _historyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/driver/orders/history');
  return res.data as Map<String, dynamic>;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التوصيلات'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(_historyProvider))],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: kMuted))),
        data: (data) {
          final orders = List<Map<String, dynamic>>.from(data['data'] as List? ?? []);
          final total  = data['meta']?['total'] ?? 0;

          return Column(children: [
            // Summary bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Stat(value: '$total', label: 'إجمالي التوصيلات', icon: '📦'),
                Container(width: 1, height: 40, color: kBorder),
                _Stat(
                  value: '₪${orders.fold<double>(0, (s, o) => s + ((o['deliveryFee'] ?? 0) as num).toDouble()).toStringAsFixed(0)}',
                  label: 'الأرباح (هذه الصفحة)',
                  icon: '💰',
                ),
              ]),
            ),

            if (orders.isEmpty)
              const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('📭', style: TextStyle(fontSize: 50)),
                SizedBox(height: 12),
                Text('لا توجد توصيلات بعد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ])))
            else
              Expanded(
                child: RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () => ref.refresh(_historyProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      final delivered = o['status'] == 'delivered';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: delivered ? const Color(0xFF22C55E).withOpacity(.15) : Colors.red.withOpacity(.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(delivered ? '✅' : '❌', style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('#${o['orderNumber'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(o['city'] ?? '—', style: const TextStyle(color: kMuted, fontSize: 12)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('₪${((o['deliveryFee'] ?? 0) as num).toStringAsFixed(2)}',
                                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                            if (o['deliveredAt'] != null)
                              Text(
                                _formatDate(o['deliveredAt'] as String),
                                style: const TextStyle(color: kMuted, fontSize: 11),
                              ),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _Stat extends StatelessWidget {
  final String value, label, icon;
  const _Stat({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(icon, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
    Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
  ]);
}
