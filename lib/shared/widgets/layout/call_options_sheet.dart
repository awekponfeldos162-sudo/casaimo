import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

/// Affiche le bottom sheet de choix d'appel.
/// [hostPhone] peut être vide — les options directes sont masquées dans ce cas.
void showCallOptionsSheet(
  BuildContext context, {
  required String hostId,
  required String hostName,
  required String hostPhone,
  required String hostAvatar,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CallSheet(
      hostId: hostId,
      hostName: hostName,
      hostPhone: hostPhone,
      hostAvatar: hostAvatar,
    ),
  );
}

class _CallSheet extends StatelessWidget {
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String hostAvatar;

  const _CallSheet({
    required this.hostId,
    required this.hostName,
    required this.hostPhone,
    required this.hostAvatar,
  });

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _cleanPhone => hostPhone.replaceAll(RegExp(r'[\s\-()]'), '');

  @override
  Widget build(BuildContext context) {
    final hasPhone = hostPhone.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Handle
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        )),

        // Host identity row
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: hostAvatar.isNotEmpty ? NetworkImage(hostAvatar) : null,
            child: hostAvatar.isEmpty
                ? Text(
                    hostName.isNotEmpty ? hostName[0].toUpperCase() : 'H',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hostName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Text(
              'Comment souhaitez-vous contacter ?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ])),
        ]),

        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Appel direct
        if (hasPhone) ...[
          _Option(
            iconBg: const Color(0xFF43A047),
            icon: Icons.phone_rounded,
            title: 'Appel direct',
            subtitle: hostPhone,
            onTap: () {
              Navigator.pop(context);
              _launch('tel:$_cleanPhone');
            },
          ),
          const SizedBox(height: 10),

          // WhatsApp
          _Option(
            iconBg: const Color(0xFF25D366),
            icon: Icons.chat_rounded,
            title: 'WhatsApp',
            subtitle: hostPhone,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'WA',
                style: TextStyle(color: Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _launch('https://wa.me/$_cleanPhone');
            },
          ),

          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou via l\'application',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
        ],

        // CasaImo in-app call
        _Option(
          iconBg: AppColors.primary,
          icon: Icons.villa_rounded,
          title: 'Appel CasaImo',
          subtitle: 'Appel audio intégré dans l\'application',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'GRATUIT',
              style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            context.push('/call', extra: {
              'calleeId': hostId,
              'calleeName': hostName,
              'calleeAvatar': hostAvatar,
            });
          },
        ),
      ]),
    );
  }
}

class _Option extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _Option({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF8F9FA),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
          if (trailing != null) trailing!
          else const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ]),
      ),
    ),
  );
}
