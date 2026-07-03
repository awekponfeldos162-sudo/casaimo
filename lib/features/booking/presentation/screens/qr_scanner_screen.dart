import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _processing = false;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _done) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non authentifié');

      final bookingId = barcode!.rawValue!;
      final fs = FirebaseFirestore.instance;
      final bookingRef = fs.collection('bookings').doc(bookingId);
      final bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) throw Exception('Réservation introuvable');
      final data = bookingDoc.data()!;

      if (data['hostId'] != uid) throw Exception('Ce QR code ne vous appartient pas');
      if (data['status'] == 'checked_in') throw Exception('Voyageur déjà enregistré');
      if (data['status'] != 'confirmed') throw Exception('Statut invalide: ${data['status']}');

      await bookingRef.update({
        'status': 'checked_in',
        'checkedInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _done = true);
      if (mounted) {
        _showSuccess({
          'guestName': data['guestName'] ?? '',
          'listingTitle': data['listingTitle'] ?? '',
          'checkIn': (data['checkIn'] as Timestamp).toDate().toIso8601String(),
          'checkOut': (data['checkOut'] as Timestamp).toDate().toIso8601String(),
          'guests': data['guests'] ?? 1,
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) _showError('[${e.code}] ${e.message ?? 'Erreur Firebase'}');
      await _controller.start();
    } catch (e) {
      if (mounted) _showError('$e');
      await _controller.start();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess(Map<String, dynamic> data) {
    final checkIn = DateTime.tryParse(data['checkIn'] ?? '');
    final checkOut = DateTime.tryParse(data['checkOut'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Enregistrement validé !', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _InfoTile(label: 'Voyageur', value: data['guestName'] ?? ''),
          _InfoTile(label: 'Logement', value: data['listingTitle'] ?? ''),
          if (checkIn != null) _InfoTile(label: 'Arrivée', value: AppUtils.formatDate(checkIn)),
          if (checkOut != null) _InfoTile(label: 'Départ', value: AppUtils.formatDate(checkOut)),
          _InfoTile(label: 'Personnes', value: '${data['guests'] ?? 1}'),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terminer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() => _done = false); _controller.start(); },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scanner QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, state, _) => IconButton(
              icon: Icon(
                state.torchState == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: Colors.white,
              ),
              onPressed: _controller.toggleTorch,
            ),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),

        // Cadre de scan
        Center(
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Overlay sombre autour du cadre
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
          child: Stack(children: [
            Container(color: Colors.black),
            Center(
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ]),
        ),

        // Indicateur chargement
        if (_processing)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        // Label bas
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Column(children: [
            const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              'Placez le QR code du voyageur\ndans le cadre',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    ]),
  );
}
