import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

final activeOrderProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final res = await api.get('/driver/orders/active');
  if (res.data == null) return null;
  return res.data as Map<String, dynamic>;
});

const _statusSteps = ['accepted', 'preparing', 'picked_up', 'on_the_way', 'delivered'];
const _statusLabel = {
  'accepted':   'تم القبول',
  'preparing':  'يُحضَّر',
  'picked_up':  'تم الاستلام',
  'on_the_way': 'في الطريق',
  'delivered':  'تم التوصيل',
};
const _nextAction = {
  'accepted':   ('picked_up',  'استلمت الطلب 📦'),
  'preparing':  ('picked_up',  'استلمت الطلب 📦'),
  'picked_up':  ('on_the_way', 'في الطريق 🛵'),
  'on_the_way': ('delivered',  'تم التوصيل ✅'),
};

class ActiveOrderScreen extends ConsumerWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(activeOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلب النشط'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(activeOrderProvider)),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: kMuted))),
        data: (order) {
          if (order == null) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🛵', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              const Text('لا يوجد طلب نشط', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('اقبل طلباً من قائمة الطلبات المتاحة', style: TextStyle(color: kMuted)),
            ]));
          }

          final status = order['status'] as String? ?? 'accepted';
          final stepIdx = _statusSteps.indexOf(status);
          final next = _nextAction[status];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Order info card
              _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('#${order['orderNumber'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(_statusLabel[status] ?? status,
                        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Progress stepper
                Row(children: List.generate(_statusSteps.length - 1, (i) {
                  final done = i <= stepIdx;
                  return Expanded(child: Row(children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? kPrimary : kBorder,
                      ),
                      child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                    ),
                    Expanded(child: Container(height: 2, color: i < stepIdx ? kPrimary : kBorder)),
                  ]));
                })
                ..add(Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stepIdx >= _statusSteps.length - 1 ? kPrimary : kBorder,
                  ),
                  child: stepIdx >= _statusSteps.length - 1
                      ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ))),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _statusSteps.map((s) => Text(_statusLabel[s] ?? s,
                        style: const TextStyle(color: kMuted, fontSize: 9))).toList()),
              ])),
              const SizedBox(height: 12),

              // Customer info
              _Card(child: Column(children: [
                _Row(icon: '👤', label: 'الزبون',    value: order['customerName'] ?? '—'),
                const Divider(color: kBorder, height: 16),
                _Row(icon: '📞', label: 'الهاتف',    value: order['customerPhone'] ?? '—'),
                const Divider(color: kBorder, height: 16),
                _Row(icon: '📍', label: 'العنوان',   value: order['deliveryAddress'] ?? '—'),
                if (order['city'] != null) ...[
                  const Divider(color: kBorder, height: 16),
                  _Row(icon: '🏙️', label: 'المدينة', value: order['city'] as String),
                ],
              ])),
              const SizedBox(height: 12),

              // Financials
              _Card(child: Column(children: [
                _Row(icon: '💰', label: 'أجرة التوصيل', value: '₪${((order['deliveryFee'] ?? 0) as num).toStringAsFixed(2)}'),
                const Divider(color: kBorder, height: 16),
                _Row(icon: '💵', label: 'طريقة الدفع',
                    value: order['paymentMethod'] == 'cash' ? 'كاش 💵' : 'إلكتروني 💳'),
              ])),

              // Items
              if ((order['items'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('المنتجات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...(order['items'] as List).map((item) {
                    final m = item as Map;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${m['quantity']}× ${m['name']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Text('₪${((m['total'] ?? 0) as num).toStringAsFixed(2)}', style: const TextStyle(color: kMuted, fontSize: 13)),
                      ]),
                    );
                  }),
                ])),
              ],

              const SizedBox(height: 20),

              // Action button
              if (next != null && status != 'delivered')
                ElevatedButton.icon(
                  onPressed: () async {
                    await api.patch('/driver/orders/${order['id']}/status', data: {'status': next.$1});
                    ref.invalidate(activeOrderProvider);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(next.$2),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                ),

              if (status == 'delivered')
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: kPrimary.withOpacity(.3))),
                  child: const Column(children: [
                    Text('🎉', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('تم التوصيل بنجاح!', style: TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('أحسنت! تم إضافة الأجرة لأرباحك', style: TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
    child: child,
  );
}

class _Row extends StatelessWidget {
  final String icon, label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
    const Spacer(),
    Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.left)),
  ]);
}
