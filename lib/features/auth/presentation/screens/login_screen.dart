import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/layout/responsive_center.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _redirectAfterLogin() {
    final user = ref.read(authProvider);
    if (user?.isHost == true) {
      context.go('/host/dashboard');
    } else {
      context.go('/home');
    }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).signInWithEmail(email, pass);
      if (mounted) _redirectAfterLogin();
    } catch (e) {
      if (mounted) _showError('Email ou mot de passe incorrect');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email = ctrl.text.trim();
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de réinitialisation envoyé')),
        );
      }
    } catch (e) {
      if (mounted) _showError('Email introuvable ou invalide');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = isWideScreen(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isWide ? 48 : 0),
          child: ResponsiveCenter(
            maxWidth: 460,
            child: DecoratedBox(
              decoration: isWide
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    )
                  : const BoxDecoration(),
              child: ClipRRect(
                borderRadius: isWide ? BorderRadius.circular(28) : BorderRadius.zero,
                child: Column(children: [

                    // ── Section supérieure verte ────────────────────────────────────
                    Container(
                      height: isWide ? 220 : size.height * 0.38,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: isWide
                            ? BorderRadius.zero
                            : const BorderRadius.vertical(bottom: Radius.circular(40)),
                      ),
              child: Stack(children: [
                // Cercles décoratifs
                Positioned(top: -30, right: -30, child: _DecorCircle(size: 160, opacity: 0.07)),
                Positioned(bottom: 40, left: -50, child: _DecorCircle(size: 200, opacity: 0.05)),
                Positioned(top: 60, left: 20, child: _DecorCircle(size: 80, opacity: 0.08)),

                // Contenu
                SafeArea(
                  bottom: false,
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Logo
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo1.png',
                            width: 80, height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, _) => const Icon(Icons.home_rounded, size: 44, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'CASAIMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Votre maison de rêve, à portée de main',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Section formulaire ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Titre
                  const Text(
                    'Connexion',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bienvenue ! Connectez-vous pour continuer.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 20),

                  // Champ email
                  _InputField(
                    controller: _emailCtrl,
                    hint: 'Adresse email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Champ mot de passe
                  _InputField(
                    controller: _passCtrl,
                    hint: 'Mot de passe',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // Bouton Se connecter
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Se connecter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Créer un compte
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text("Pas de compte ?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      TextButton(
                        onPressed: () => context.go('/role-select'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text("S'inscrire",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Explorer sans compte
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.explore_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('Explorer sans compte',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.grey.shade400,
                              )),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size, opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: opacity), width: 1.5),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
