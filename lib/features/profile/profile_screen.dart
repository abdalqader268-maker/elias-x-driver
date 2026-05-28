import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';

final _profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await api.get('/driver/stats');
  return res.data as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _togglingOnline = false;

  Future<void> _toggleOnline() async {
    setState(() => _togglingOnline = true);
    try {
      await api.patch('/driver/toggle-online');
      ref.invalidate(_profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  Future<void> _logout() async {
    await clearToken();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_profileProvider),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: kMuted))),
        data: (data) {
          final driver   = data['driver']  as Map<String, dynamic>? ?? {};
          final stats    = data['stats']   as Map<String, dynamic>? ?? {};
          final isOnline = driver['isOnline'] as bool? ?? false;
          final status   = driver['status']   as String? ?? 'pending';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + name
              Center(
                child: Column(children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCard,
                      border: Border.all(color: isOnline ? kPrimary : kBorder, width: 3),
                    ),
                    child: const Center(child: Text('🛵', style: TextStyle(fontSize: 44))),
                  ),
                  const SizedBox(height: 12),
                  Text(driver['name'] as String? ?? '—',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _statusBadge(status),
                ]),
              ),
              const SizedBox(height: 20),

              // Online toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isOnline ? kPrimary.withOpacity(.12) : kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isOnline ? kPrimary.withOpacity(.4) : kBorder),
                ),
                child: Row(children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? kPrimary : kMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isOnline ? 'أنت متاح الآن' : 'أنت غير متاح',
                          style: TextStyle(
                            color: isOnline ? kPrimary : Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(isOnline ? 'ستظهر لك الطلبات الجديدة' : 'لن تصلك أي طلبات',
                          style: const TextStyle(color: kMuted, fontSize: 12)),
                    ]),
                  ),
                  _togglingOnline
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5))
                      : Switch(
                          value: isOnline,
                          onChanged: (_) => _toggleOnline(),
                          activeColor: kPrimary,
                        ),
                ]),
              ),
              const SizedBox(height: 16),

              // Stats grid
              Row(children: [
                _StatCard(
                  icon: '📦',
                  value: '${stats['totalDeliveries'] ?? 0}',
                  label: 'إجمالي التوصيلات',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '💰',
                  value: '₪${((stats['totalEarnings'] ?? 0) as num).toStringAsFixed(0)}',
                  label: 'إجمالي الأرباح',
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(
                  icon: '📅',
                  value: '${stats['todayDeliveries'] ?? 0}',
                  label: 'توصيلات اليوم',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '💵',
                  value: '₪${((stats['todayEarnings'] ?? 0) as num).toStringAsFixed(0)}',
                  label: 'أرباح اليوم',
                ),
              ]),
              const SizedBox(height: 16),

              // Driver info
              _InfoCard(rows: [
                _InfoRow(icon: '📞', label: 'الهاتف',   value: driver['phone']   as String? ?? '—'),
                _InfoRow(icon: '🏙️', label: 'المدينة', value: driver['city']    as String? ?? '—'),
                _InfoRow(icon: '🚗', label: 'المركبة',  value: driver['vehicle'] as String? ?? '—'),
                if (driver['licensePlate'] != null)
                  _InfoRow(icon: '🔢', label: 'رقم اللوحة', value: driver['licensePlate'] as String),
              ]),
              const SizedBox(height: 16),

              // Rating
              if ((stats['rating'] as num?)?.toDouble() != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('⭐ تقييمك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(children: [
                      Text(
                        ((stats['rating'] as num).toDouble()).toStringAsFixed(1),
                        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const Text(' / 5', style: TextStyle(color: kMuted)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Week deliveries
              if (stats['weekDeliveries'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('📊 توصيلات هذا الأسبوع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${stats['weekDeliveries']}',
                        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Logout
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'active':  (const Color(0xFF22C55E), 'نشط ✅'),
      'pending': (Colors.orange,            'قيد المراجعة ⏳'),
      'banned':  (Colors.red,               'محظور ❌'),
    };
    final c = colors[status] ?? (kMuted, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.$1.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.$1.withOpacity(.4)),
      ),
      child: Text(c.$2, style: TextStyle(color: c.$1, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon, value, label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 11)),
      ]),
    ),
  );
}

// ─── Info Card ───────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const Divider(color: kBorder, height: 16),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String icon, label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
    const Spacer(),
    Flexible(
      child: Text(value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          textAlign: TextAlign.left),
    ),
  ]);
}
