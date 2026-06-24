import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.phone;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) { _showMsg('Entrez votre numéro'); return; }
    if (!phone.startsWith('+')) { _showMsg('Incluez l\'indicatif pays, ex: +22997000000'); return; }
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).sendOtp(
      phone,
      onCodeSent: (id) {
        setState(() { _verificationId = id; _codeSent = true; _loading = false; });
        _showMsg('Code envoyé !', isError: false);
      },
      onError: (e) {
        setState(() => _loading = false);
        _showMsg(e);
      },
    );
  }

  Future<void> _verify() async {
    if (_verificationId == null || _otpCtrl.text.length < 6) {
      _showMsg('Entrez le code à 6 chiffres'); return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).verifyOtp(_verificationId!, _otpCtrl.text.trim());
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) _showMsg('Code incorrect');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg, {bool isError = true}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion par téléphone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(_codeSent ? 'Entrez le code reçu' : 'Votre numéro de téléphone', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_codeSent ? 'Code envoyé au ${_phoneCtrl.text}' : 'Nous vous enverrons un SMS de vérification', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            if (!_codeSent) ...[
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Numéro de téléphone', hintText: 'ex: +22997000000', prefixIcon: Icon(Icons.phone_rounded)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Envoyer le code'),
              ),
            ] else ...[
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: const InputDecoration(labelText: 'Code OTP', counterText: ''),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Vérifier'),
              ),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => setState(() { _codeSent = false; _verificationId = null; }), child: const Text('Changer de numéro'))),
            ],
          ],
        ),
      ),
    );
  }
}
