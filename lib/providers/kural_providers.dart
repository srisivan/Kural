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

/// Notifier that decides which kural to show today, advancing sequentially
/// through the selected chapter and picking a random interpretation type
/// deterministically for the day (stable across rebuilds).
class TodaysKuralNotifier extends AsyncNotifier<TodaysKural> {
  @override
  Future<TodaysKural> build() async {
    final kurals = await ref.watch(kuralsProvider.future);
    final chapters = await ref.watch(chaptersProvider.future);
    final progress = ref.read(progressServiceProvider);

    final chapterNumber = progress.selectedChapter ?? chapters.first.number;
    final chapter = chapters.firstWhere((c) => c.number == chapterNumber);

    final todayStr = _todayString();
    final lastDate = progress.lastServedDate;
    final lastKuralNum = progress.lastServedKuralNumber;

    int nextKuralNumber;
    String interpretationKey;

    if (lastDate == todayStr && lastKuralNum != null) {
      // Already served today — show the same one again (idempotent).
      nextKuralNumber = lastKuralNum;
      interpretationKey = progress.lastInterpretation ?? 'mv';
    } else {
      if (lastKuralNum == null || lastKuralNum >= chapter.end) {
        // First run, or chapter just finished -> loop back to chapter start.
        nextKuralNumber = chapter.start;
      } else {
        nextKuralNumber = lastKuralNum + 1;
      }
      interpretationKey = _pickInterpretationForDate(todayStr);
      await progress.saveServed(
        kuralNumber: nextKuralNumber,
        date: todayStr,
        interpretationKey: interpretationKey,
      );
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
