import 'package:flutter/material.dart';

/// Centre le contenu avec une largeur maximale sur desktop/web (écrans larges).
/// Sur mobile (largeur < [breakpoint]), le contenu occupe toute la largeur —
/// comportement inchangé pour l'app native.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double breakpoint;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.breakpoint = 700,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpoint) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Vrai si l'écran courant est considéré "desktop/web large" (>= [breakpoint]).
bool isWideScreen(BuildContext context, {double breakpoint = 700}) =>
    MediaQuery.of(context).size.width >= breakpoint;
