import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/layout/responsive_center.dart';
import '../providers/auth_provider.dart';

class HostSignupScreen extends ConsumerStatefulWidget {
  const HostSignupScreen({super.key});

  @override
  ConsumerState<HostSignupScreen> createState() => _HostSignupScreenState();
}

class _HostSignupScreenState extends ConsumerState<HostSignupScreen> {
  int _step = 0;
  bool _loading = false;

  // Étape 1 — Personnel
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _googlePrefilled = false;
  String _googleAvatar = '';

  // Étape 2 — Activité
  final _bizNameCtrl    = TextEditingController();
  final _bizAddressCtrl = TextEditingController();
  final _bizDescCtrl    = TextEditingController();
  String _bizType = 'Particulier';

  static const _bizTypes = ['Particulier', 'Hôtel', 'Agence immobilière', 'Résidence'];

  static const _stepTitles = ['Informations personnelles', 'Votre activité', 'Récapitulatif'];
  static const _stepSubs   = [
    'Ces informations vous identifient sur la plateforme.',
    'Ces informations seront visibles par les clients.',
    'Vérifiez vos informations avant de créer votre compte.',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose();
    _bizNameCtrl.dispose(); _bizAddressCtrl.dispose(); _bizDescCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error),
  );

  Future<void> _prefillWithGoogle() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(authProvider.notifier).getGooglePreFillData();
      setState(() {
        _nameCtrl.text = data.name;
        _emailCtrl.text = data.email;
        _googleAvatar = data.avatarUrl;
        _googlePrefilled = true;
      });
    } catch (e) {
      final msg = e.toString();
      if (mounted && !msg.contains('Annulé') && !msg.contains('cancel')) {
        _showError('Erreur de connexion Google');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearGoogle() => setState(() {
    _googlePrefilled = false;
    _googleAvatar = '';
    _nameCtrl.clear();
    _emailCtrl.clear();
  });

  bool _validateStep1() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Nom complet requis');
      return false;
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Email requis');
      return false;
    }
    if (!_googlePrefilled && !email.toLowerCase().endsWith('@gmail.com')) {
      _showError('L\'adresse email doit être une adresse Gmail (ex: nom@gmail.com)');
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Téléphone requis');
      return false;
    }
    if (!_googlePrefilled && _passCtrl.text.isEmpty) {
      _showError('Mot de passe requis');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_bizNameCtrl.text.trim().isEmpty)    { _showError('Nom commercial requis'); return false; }
    if (_bizAddressCtrl.text.trim().isEmpty) { _showError('Adresse requise'); return false; }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final extra = {
        'businessName':        _bizNameCtrl.text.trim(),
        'businessType':        _bizType,
        'businessAddress':     _bizAddressCtrl.text.trim(),
        'businessDescription': _bizDescCtrl.text.trim(),
      };
      if (_googlePrefilled) {
        await ref.read(authProvider.notifier).signUpWithGoogleCredential(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          avatarUrl: _googleAvatar,
          role: 'host',
          extra: extra,
        );
      } else {
        await ref.read(authProvider.notifier).signUpWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          role: 'host',
          extra: extra,
        );
      }
      if (mounted) {
        context.go('/host/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('email-already-in-use')) {
          _showError('Cette adresse email est déjà utilisée.');
        } else if (msg.contains('password') || msg.contains('weak')) {
          _showError('Mot de passe insuffisant — vérifiez les exigences ci-dessous.');
        } else {
          _showError('Inscription échouée. Réessayez.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
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

          // ── Section supérieure verte ────────────────────────────────
          Container(
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
              Positioned(top: -20, right: -20, child: _DecorCircle(size: 140, opacity: 0.07)),
              Positioned(bottom: 20, left: -40, child: _DecorCircle(size: 160, opacity: 0.05)),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Ligne retour + badge
                    Row(children: [
                      GestureDetector(
                        onTap: _back,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      if (_step == 0 && _googlePrefilled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Google',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 26),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Inscription Propriétaire',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(_stepTitles[_step],
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_stepSubs[_step],
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 18),

                    // Indicateurs d'étapes
                    Row(children: List.generate(3, (i) {
                      final done = i < _step;
                      final active = i == _step;
                      return Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: active ? 36 : 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: done || active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.primary)
                                : Text('${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? AppColors.primary
                                          : Colors.white.withValues(alpha: 0.6),
                                    )),
                          ),
                        ),
                        if (i < 2)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: size.width * 0.12,
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: i < _step
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                      ]);
                    })),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Corps selon l'étape ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            child: [
              _buildStep1(context),
              _buildStep2(context),
              _buildStep3(context),
            ][_step],
          ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Étape 1 : Personnel ────────────────────────────────────────────
  Widget _buildStep1(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

    // Bandeau Google actif (en haut si pré-rempli)
    if (_googlePrefilled)
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Google · ${_emailCtrl.text}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _clearGoogle,
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
          ),
        ]),
      ),

    _InputField(
        controller: _nameCtrl,
        hint: 'Nom complet *',
        icon: Icons.person_outline_rounded,
        readOnly: _googlePrefilled),
    const SizedBox(height: 12),
    _InputField(
        controller: _emailCtrl,
        hint: 'Email *',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        readOnly: _googlePrefilled),
    const SizedBox(height: 12),
    _InputField(
        controller: _phoneCtrl,
        hint: 'Téléphone *',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone),

    // Mot de passe + indicateur + bouton Google (masqués si Google pré-rempli)
    if (!_googlePrefilled) ...[
      const SizedBox(height: 12),
      _InputField(
        controller: _passCtrl,
        hint: 'Mot de passe *',
        icon: Icons.lock_outline_rounded,
        obscureText: _obscure,
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20, color: AppColors.textSecondary),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _passCtrl,
        builder: (context, value, child) => value.text.isEmpty
            ? const SizedBox.shrink()
            : _PasswordStrength(password: value.text),
      ),
      const SizedBox(height: 16),
      const Row(children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ]),
      const SizedBox(height: 16),
      _GoogleButton(onTap: _loading ? null : _prefillWithGoogle),
    ],

    const SizedBox(height: 28),
    _ContinueButton(
      label: 'Continuer',
      onTap: () {
        if (_validateStep1()) {
          setState(() => _step = 1);
        }
      },
    ),
  ]);

  // ── Étape 2 : Activité ─────────────────────────────────────────────
  Widget _buildStep2(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("Type d'activité *",
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
    const SizedBox(height: 10),
    Wrap(
      spacing: 8, runSpacing: 8,
      children: _bizTypes.map((t) {
        final sel = _bizType == t;
        return GestureDetector(
          onTap: () => setState(() => _bizType = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: sel ? AppColors.primary : AppColors.border),
            ),
            child: Text(t, style: TextStyle(
              color: sel ? Colors.white : AppColors.textSecondary,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            )),
          ),
        );
      }).toList(),
    ),
    const SizedBox(height: 16),
    _InputField(controller: _bizNameCtrl,    hint: 'Nom commercial *', icon: Icons.business_rounded),
    const SizedBox(height: 12),
    _InputField(controller: _bizAddressCtrl, hint: 'Adresse *',        icon: Icons.location_on_outlined),
    const SizedBox(height: 12),
    TextField(
      controller: _bizDescCtrl,
      maxLines: 3,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Description (optionnel)',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 42),
          child: Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    ),
    const SizedBox(height: 28),
    _ContinueButton(
      label: 'Continuer',
      onTap: () {
        if (_validateStep2()) {
          setState(() => _step = 2);
        }
      },
    ),
  ]);

  // ── Étape 3 : Récapitulatif ────────────────────────────────────────
  Widget _buildStep3(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _SummaryCard(
      icon: Icons.person_rounded,
      title: 'Profil personnel',
      rows: [
        ('Nom',       _nameCtrl.text),
        ('Email',     _emailCtrl.text),
        ('Téléphone', _phoneCtrl.text),
        if (_googlePrefilled) ('Connexion', 'Google'),
      ],
    ),
    const SizedBox(height: 14),
    _SummaryCard(
      icon: Icons.business_rounded,
      title: 'Activité professionnelle',
      rows: [
        ('Type',           _bizType),
        ('Nom commercial', _bizNameCtrl.text),
        ('Adresse',        _bizAddressCtrl.text),
      ],
    ),
    const SizedBox(height: 28),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Créer mon compte propriétaire',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ),
    const SizedBox(height: 16),
    Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Déjà un compte ?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        TextButton(
          onPressed: () => context.go('/login'),
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              foregroundColor: AppColors.primary),
          child: const Text('Se connecter',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
    ),
  ]);
}

// ── Widgets partagés ───────────────────────────────────────────────────────────

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  @override
  Widget build(BuildContext context) {
    final hasUpper   = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower   = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit   = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _Req(label: 'Majuscule',         met: hasUpper),
          _Req(label: 'Minuscule',         met: hasLower),
          _Req(label: 'Chiffre',           met: hasDigit),
          _Req(label: 'Caractère spécial', met: hasSpecial),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final String label;
  final bool met;
  const _Req({required this.label, required this.met});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 13,
        color: met ? const Color(0xFF22C55E) : AppColors.textHint,
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: met ? const Color(0xFF22C55E) : AppColors.textHint,
          fontWeight: met ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text('G',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Continuer avec Google',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ]),
      ),
    ),
  );
}

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
  final bool readOnly;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: readOnly,
    obscureText: obscureText,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffix ??
          (readOnly
              ? const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textHint)
              : null),
      filled: true,
      fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: readOnly ? Colors.transparent : AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: readOnly ? Colors.transparent : AppColors.primary, width: 1.5)),
    ),
  );
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ContinueButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
      ]),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<(String, String)> rows;
  const _SummaryCard({required this.icon, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
      const SizedBox(height: 12),
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(r.$1,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(
              child: Text(r.$2.isEmpty ? '—' : r.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      )),
    ]),
  );
}
