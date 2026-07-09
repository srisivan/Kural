import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../services/kural_share_actions.dart';
import '../widgets/kural_carousel_view.dart';
import '../theme.dart';

/// Read-only detail view for a single kural (reached from Explore). Same look
/// and carousel as the daily screen; can share/download the landed-on
/// interpretation.
class KuralDetailScreen extends ConsumerStatefulWidget {
  final int kuralNumber;
  const KuralDetailScreen({super.key, required this.kuralNumber});

  @override
  ConsumerState<KuralDetailScreen> createState() => _KuralDetailScreenState();
}

class _KuralDetailScreenState extends ConsumerState<KuralDetailScreen>
    with KuralShareActions {
  String _selectedKey = 'mv';

  TodaysKural _withKey(TodaysKural view) => TodaysKural(
        kural: view.kural,
        interpretationKey: _selectedKey,
        interpretationText: view.kural.interpretation(_selectedKey),
        chapter: view.chapter,
      );

  @override
  Widget build(BuildContext context) {
    final kuralsAsync = ref.watch(kuralsProvider);
    final chaptersAsync = ref.watch(chaptersProvider);
    final ready = kuralsAsync.hasValue && chaptersAsync.hasValue;

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('குறள் ${widget.kuralNumber}',
            style: GoogleFonts.anekTamil()),
        actions: [
          if (ready)
            if (shareBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () {
                  final view = buildKuralView(kuralsAsync.value!,
                      chaptersAsync.value!, widget.kuralNumber);
                  openShareSheet(_withKey(view));
                },
              ),
        ],
      ),
      body: SafeArea(
        child: !ready
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: SingleChildScrollView(
                  child: Builder(builder: (context) {
                    final view = buildKuralView(kuralsAsync.value!,
                        chaptersAsync.value!, widget.kuralNumber);
                    return KuralCarouselView(
                      data: view,
                      selectedKey: _selectedKey,
                      onKeyChanged: (k) => setState(() => _selectedKey = k),
                    );
                  }),
                ),
              ),
      ),
    );
  }
}
