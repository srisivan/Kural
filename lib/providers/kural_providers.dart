import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kural.dart';
import '../models/chapter.dart';
import '../models/aathichudi.dart';
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

final aathichudiProvider = FutureProvider<List<Aathichudi>>((ref) async {
  return ref.read(dataServiceProvider).loadAathichudi();
});

/// Which text the home screen shows: 'kural' | 'aathichudi'.
class ContentModeNotifier extends Notifier<String> {
  @override
  String build() => ref.read(progressServiceProvider).contentMode;

  Future<void> setMode(String mode) async {
    await ref.read(progressServiceProvider).setContentMode(mode);
    state = mode;
  }

  Future<void> toggle() =>
      setMode(state == 'kural' ? 'aathichudi' : 'kural');
}

final contentModeProvider =
    NotifierProvider<ContentModeNotifier, String>(ContentModeNotifier.new);

String todayString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

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
      interpretationKey = progress.lastInterpretation ?? 'sp';
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
      // Always start the day on the first interpretation in the carousel
      // order (sp); the user can swipe through the rest.
      interpretationKey = 'sp';
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

  String _todayString() => todayString();
}

final todaysKuralProvider =
    AsyncNotifierProvider<TodaysKuralNotifier, TodaysKural>(
  TodaysKuralNotifier.new,
);

// ---------------------------------------------------------------------------
// Aathichudi
// ---------------------------------------------------------------------------

Aathichudi aathichudiByNumber(List<Aathichudi> list, int number) =>
    list.firstWhere((a) => a.number == number);

/// Today's aathichudi. [needsEndChoice] is true once the whole set is finished
/// and the user hasn't yet chosen to repeat or randomize.
class TodaysAathichudi {
  final Aathichudi? item;
  final bool needsEndChoice;
  const TodaysAathichudi({this.item, this.needsEndChoice = false});
}

class TodaysAathichudiNotifier extends AsyncNotifier<TodaysAathichudi> {
  @override
  Future<TodaysAathichudi> build() async {
    final list = await ref.watch(aathichudiProvider.future);
    final progress = ref.read(progressServiceProvider);

    final today = todayString();
    final last = progress.aathiLastNumber;
    final lastDate = progress.aathiLastDate;
    final endMode = progress.aathiEndMode;
    final count = list.length;

    // Already served today — idempotent re-show.
    if (lastDate == today && last != null) {
      return TodaysAathichudi(item: aathichudiByNumber(list, last));
    }

    int next;
    if (endMode == 'random') {
      // Date-seeded so it's stable for the whole day.
      final seed = int.parse(today.replaceAll('-', ''));
      next = Random(seed).nextInt(count) + 1;
    } else if (endMode == 'repeat') {
      next = (last == null || last >= count) ? 1 : last + 1;
    } else {
      // First pass through the set (no end mode chosen yet).
      if (last == null) {
        next = 1;
      } else if (last < count) {
        next = last + 1;
      } else {
        // Finished the set — ask the user what to do next.
        return const TodaysAathichudi(needsEndChoice: true);
      }
    }

    await progress.saveAathiServed(number: next, date: today);
    return TodaysAathichudi(item: aathichudiByNumber(list, next));
  }

  /// Called from the end-of-set prompt: 'repeat' or 'random'.
  Future<void> chooseEndMode(String mode) async {
    final progress = ref.read(progressServiceProvider);
    await progress.setAathiEndMode(mode);
    ref.invalidateSelf();
    await future;
  }
}

final todaysAathichudiProvider =
    AsyncNotifierProvider<TodaysAathichudiNotifier, TodaysAathichudi>(
  TodaysAathichudiNotifier.new,
);
