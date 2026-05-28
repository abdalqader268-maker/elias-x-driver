import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

// Polling كل 10 ثواني
final _availableOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  while (true) {
    try {
      final res = await api.get('/driver/orders/available');
      yield List<Map<String, dynamic>>.from(res.data as List);
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 10));
  }
});

const _typeLabel = {
  'restaurant':  '🍔 مطعم',
  'supermarket': '🛒 سوبرماركت',
  'pharmacy':    '💊 صيدلية',
  'e_commerce':  '🌐 تجارة إلكترونية',
  'package':     '📦 طرد',
};
const _payLabel = {'cash': '💵 كاش', 'online': '💳 إلكتروني'};

class AvailableOrdersScreen extends ConsumerWidget {
  const AvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_availableOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات المتاحة'),
        actions: [
          orders.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kPrimary.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${list.length}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
              )),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('$e', style: const TextStyle(color: kMuted), textAlign: TextAlign.center),
          ]),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🕐', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text('لا توجد طلبات متاحة الآن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('ستظهر الطلبات هنا فور وصولها', style: TextStyle(color: kMuted)),
              const SizedBox(height: 16),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
                SizedBox(width: 8),
                Text('يُحدَّث كل 10 ثواني', style: TextStyle(color: kMuted, fontSize: 12)),
              ]),
            ]));
          }

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async { ref.invalidate(_availableOrdersProvider); },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _OrderCard(order: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await api.post('/driver/orders/${widget.order['id']}/accept');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم قبول الطلب! انتقل لتبويب "نشط الآن"'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        ref.invalidate(_availableOrdersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: [
        // Top strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(.08),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_typeLabel[o['type']] ?? '📦 طلب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('#${o['orderNumber'] ?? ''}', style: const TextStyle(color: kMuted, fontSize: 12, fontFamily: 'monospace')),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Delivery address
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('📍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(o['deliveryAddress'] as String? ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
            ]),
            const SizedBox(height: 10),

            // Details row
            Row(children: [
              _chip('💰 ₪${((o['deliveryFee'] ?? 0) as num).toStringAsFixed(2)} أجرة', kPrimary),
              const SizedBox(width: 8),
              _chip(_payLabel[o['paymentMethod']] ?? '💵', kMuted),
              if (o['city'] != null) ...[
                const SizedBox(width: 8),
                _chip('🏙️ ${o['city']}', kMuted),
              ],
            ]),

            if (o['notes'] != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Text('📝 ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(o['notes'] as String, style: const TextStyle(color: kMuted, fontSize: 13))),
              ]),
            ],
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            onPressed: _accepting ? null : _accept,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: _accepting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.delivery_dining, size: 20),
                    SizedBox(width: 8),
                    Text('قبول الطلب'),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
