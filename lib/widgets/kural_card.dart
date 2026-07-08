import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';

/// The visual card shown on screen AND captured for sharing.
/// Keeping it a standalone widget means the on-screen view and the
/// screenshot are guaranteed to look identical.
class KuralCard extends StatelessWidget {
  final TodaysKural data;

  const KuralCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tamilStyle = GoogleFonts.notoSansTamil(
      fontSize: 22,
      height: 1.6,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final interpretationStyle = GoogleFonts.notoSansTamil(
      fontSize: 16,
      height: 1.5,
      color: Colors.black54,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'குறள் ${data.kural.number}',
            style: GoogleFonts.notoSansTamil(
              fontSize: 14,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.kural.combinedLines,
            textAlign: TextAlign.center,
            style: tamilStyle,
          ),
          const SizedBox(height: 28),
          Container(height: 1, width: 60, color: Colors.black12),
          const SizedBox(height: 28),
          Text(
            data.interpretationText,
            textAlign: TextAlign.center,
            style: interpretationStyle,
          ),
          const SizedBox(height: 24),
          Text(
            data.chapter.translation,
            style: GoogleFonts.notoSansTamil(
              fontSize: 12,
              color: Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
