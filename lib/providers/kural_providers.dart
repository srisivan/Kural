import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kural.dart';
import '../models/chapter.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';

final dataServiceProvider = Provider((ref) => DataService());
final progressServiceProvider = Provider((ref) => ProgressService());

final kuralsProvider = FutureProvider<List<Kural>>((ref) async {
  return ref.read(dataServiceProvider).loadKurals();
});

final chaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  return ref.read(dataServiceProvider).loadChapters();
});

const interpretationKeys = ['mv', 'sp', 'mk'];

class TodaysKural {
  final Kural kural;
  final String interpretationKey;
  final String interpretationText;
  final Chapter chapter;

  TodaysKural({
    required this.kural,
    required this.interpretationKey,
    required this.interpretationText,
    required this.chapter,
  });
}

/// Builds a [TodaysKural] bundle for an arbitrary kural number — used by the
/// (read-only) explore screens, so they can reuse the shareable cards without
/// touching the daily progress. Defaults to the 'mv' interpretation.
TodaysKural buildKuralView(
  List<Kural> kurals,
  List<Chapter> chapters,
  int number, {
  String interpretationKey = 'mv',
}) {
  final kural = kurals.firstWhere((k) => k.number == number);
  final chapter = chapters
      .firstWhere((c) => number >= c.start && number <= c.end);
  return TodaysKural(
    kural: kural,
    interpretationKey: interpretationKey,
    interpretationText: kural.interpretation(interpretationKey),
    chapter: chapter,
  );
}

/// Notifier that decides which kural to show today, advancing sequentially
/// through the selected chapter and picking a random interpretation type
/// deterministically for the day (stable across rebuilds).
class TodaysKuralNotifier extends AsyncNotifier<TodaysKural> {
  @override
  Future<TodaysKural> build() async {
    final kurals = await ref.watch(kuralsProvider.future);
    final chapters = await ref.watch(chaptersProvider.future);
    final progress = ref.read(progressServiceProvider);

    final startChapterNumber = progress.selectedChapter ?? chapters.first.number;

    final todayStr = _todayString();
    final lastDate = progress.lastServedDate;
    final lastKuralNum = progress.lastServedKuralNumber;

    final int firstKural = kurals.first.number; // 1
    final int lastKural = kurals.last.number; // 1330

    int nextKuralNumber;
    String interpretationKey;

    if (lastDate == todayStr && lastKuralNum != null) {
      // Already served today — show the same one again (idempotent).
      nextKuralNumber = lastKuralNum;
      interpretationKey = progress.lastInterpretation ?? 'mv';
    } else {
      if (lastKuralNum == null) {
        // First run — start at the chosen chapter's first kural.
        final startChapter =
            chapters.firstWhere((c) => c.number == startChapterNumber);
        nextKuralNumber = startChapter.start;
      } else {
        // Continue to the next kural. Because kural numbers are contiguous
        // across the whole text, this naturally flows into the next chapter
        // once the current one is finished; wrap to the start after 1330.
        nextKuralNumber = lastKuralNum + 1;
        if (nextKuralNumber > lastKural) nextKuralNumber = firstKural;
      }
      interpretationKey = _pickInterpretationForDate(todayStr);
      await progress.saveServed(
        kuralNumber: nextKuralNumber,
        date: todayStr,
        interpretationKey: interpretationKey,
      );
    }

    // The chapter that actually contains today's kural — this may differ from
    // the originally chosen chapter once the flow has crossed into the next.
    final chapter = chapters.firstWhere(
        (c) => nextKuralNumber >= c.start && nextKuralNumber <= c.end);

    // Keep the stored chapter in sync (so the picker highlights where we are)
    // without resetting progress within it.
    if (progress.selectedChapter != chapter.number) {
      await progress.syncCurrentChapter(chapter.number);
    }

    final kural = kurals.firstWhere((k) => k.number == nextKuralNumber);

    return TodaysKural(
      kural: kural,
      interpretationKey: interpretationKey,
      interpretationText: kural.interpretation(interpretationKey),
      chapter: chapter,
    );
  }

  /// Call when the user picks a new chapter from the picker screen.
  Future<void> selectChapter(int chapterNumber) async {
    final progress = ref.read(progressServiceProvider);
    await progress.setSelectedChapter(chapterNumber);
    ref.invalidateSelf();
    await future; // wait for rebuild to settle
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Deterministic "random" pick seeded by date, so it doesn't change
  /// if the widget rebuilds during the same day.
  String _pickInterpretationForDate(String dateStr) {
    final seed = int.parse(dateStr.replaceAll('-', ''));
    final rand = Random(seed);
    return interpretationKeys[rand.nextInt(interpretationKeys.length)];
  }
}

final todaysKuralProvider =
    AsyncNotifierProvider<TodaysKuralNotifier, TodaysKural>(
  TodaysKuralNotifier.new,
);
