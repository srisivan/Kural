import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../providers/kural_providers.dart';
import '../services/kural_share_actions.dart';
import '../theme.dart';

/// Read-only detail view for a single kural (reached from Explore).
/// Shows all three commentaries and lets the user share/download.
class KuralDetailScreen extends ConsumerStatefulWidget {
  final int kuralNumber;
  const KuralDetailScreen({super.key, required this.kuralNumber});

  @override
  ConsumerState<KuralDetailScreen> createState() => _KuralDetailScreenState();
}

class _KuralDetailScreenState extends ConsumerState<KuralDetailScreen>
    with KuralShareActions {
  @override
  Widget build(BuildContext context) {
    final kuralsAsync = ref.watch(kuralsProvider);
    final chaptersAsync = ref.watch(chaptersProvider);

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('குறள் ${widget.kuralNumber}',
            style: GoogleFonts.anekTamil()),
        actions: [
          if (kuralsAsync.hasValue && chaptersAsync.hasValue)
            IconButton(
              icon: shareBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: shareBusy
                  ? null
                  : () {
                      final view = buildKuralView(kuralsAsync.value!,
                          chaptersAsync.value!, widget.kuralNumber);
                      openShareSheet(view);
                    },
            ),
        ],
      ),
      body: SafeArea(
        child: (kuralsAsync.isLoading || chaptersAsync.isLoading)
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Builder(builder: (context) {
                final view = buildKuralView(
                    kuralsAsync.value!, chaptersAsync.value!, widget.kuralNumber);
                return SingleChildScrollView(
                  child: Screenshot(
                    controller: screenCaptureController,
                    child: _DetailCard(view: view),
                  ),
                );
              }),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final TodaysKural view;
  const _DetailCard({required this.view});

  @override
  Widget build(BuildContext context) {
    final kural = view.kural;
    return Container(
      color: kBrandBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kural.
          _Tile(
            child: Column(
              children: [
                Text(
                  kural.combinedLines,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.anekTamil(
                    fontSize: 22,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 14),
                Text(
                  view.chapter.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.anekTamil(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'அதிகாரம் ${view.chapter.number}   ·   குறள் ${kural.number}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.anekTamil(
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          if (kural.translation.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Tile(
              child: Text(
                kural.translation,
                style: GoogleFonts.anekTamil(
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          // All three Tamil commentaries.
          _commentary('மு. வரதராசன்', kural.mv),
          _commentary('சாலமன் பாப்பையா', kural.sp),
          _commentary('கலைஞர் மு. கருணாநிதி', kural.mk),
        ],
      ),
    );
  }

  Widget _commentary(String author, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _Tile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: GoogleFonts.anekTamil(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: GoogleFonts.anekTamil(
                fontSize: 16,
                height: 1.7,
                color: Colors.white.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget child;
  const _Tile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: kTileFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kTileBorder),
      ),
      child: child,
    );
  }
}
