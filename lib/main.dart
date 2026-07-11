import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/kural_providers.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _AppBootstrap()));
}

/// Runs one-time async init (Hive box, notification scheduling) before
/// showing the real UI. Kept as a tiny wrapper so main() stays sync-clean.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    await ref.read(progressServiceProvider).init();

    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    await notifications.scheduleDailyReminder();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // In-app splash — bridges the native splash and the home screen.
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: kBrandBlue,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(28)),
                      child: Image(
                        image: AssetImage('assets/icon/kural_icon.png'),
                        width: 132,
                        height: 132,
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const ThirukkuralApp();
      },
    );
  }
}

class ThirukkuralApp extends StatelessWidget {
  const ThirukkuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kural',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBrandBlue,
        colorSchemeSeed: kBrandBlue,
        brightness: Brightness.dark,
        useMaterial3: true,
        // Keep popovers/sheets on-brand instead of the default dark surface.
        popupMenuTheme: PopupMenuThemeData(
          color: kBrandBlue,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          textStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.18)),
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: kBrandBlue,
          modalBackgroundColor: kBrandBlue,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: Colors.white.withOpacity(0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
