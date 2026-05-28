import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/api.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String  _code    = '';
  bool    _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await api.post('/auth/verify-otp', data: {'phone': widget.phone, 'otp': _code});
      final role = res.data['user']?['role'] ?? res.data['role'];
      if (role != 'driver') {
        setState(() => _error = 'ليس لديك صلاحية الدخول كسائق');
        return;
      }
      await saveToken(res.data['accessToken'] as String);
      if (mounted) context.go('/orders');
    } catch (e) {
      setState(() => _error = 'رمز التحقق غير صحيح أو منتهي الصلاحية');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من رمز OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 24),
            Text('تم إرسال رمز OTP إلى\n${widget.phone}',
                textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.6)),
            const SizedBox(height: 36),

            PinCodeTextField(
              appContext: context, length: 6,
              keyboardType: TextInputType.number,
              textStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box, borderRadius: BorderRadius.circular(12),
                fieldHeight: 56, fieldWidth: 48,
                activeFillColor: kCard, selectedFillColor: kCard, inactiveFillColor: kCard,
                activeColor: kPrimary, selectedColor: kPrimary, inactiveColor: kBorder,
              ),
              enableActiveFill: true,
              onCompleted: (v) { _code = v; _verify(); },
              onChanged: (v) => _code = v,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(.3))),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading || _code.length < 6 ? null : _verify,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('دخول'),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => context.pop(), child: const Text('تغيير رقم الهاتف', style: TextStyle(color: kMuted))),
          ]),
        ),
      ),
    );
  }
}
