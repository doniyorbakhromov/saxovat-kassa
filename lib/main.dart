import "package:flutter/material.dart";

import "src/screens/home_screen.dart";
import "src/screens/link_screen.dart";
import "src/screens/login_screen.dart";
import "src/store.dart";
import "src/sync/sync_service.dart";
import "src/theme.dart";
import "src/widgets/auto_lock.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.init();
  await sync.init();
  runApp(const KassaApp());
}

class KassaApp extends StatelessWidget {
  const KassaApp({super.key});

  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Saxovat Kassa",
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      theme: buildAppTheme(),
      // AutoLock butun Navigator ustida turadi - shunda buyurtma ekrani
      // yoki oynalar ichidagi harakatlar ham hisobga olinadi.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            // Brauzer shrifti kattalashtirilsa ham kassa ekrani buzilmasin.
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.1,
            ),
          ),
          child: AutoLock(
            navigatorKey: _navKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: ListenableBuilder(
        listenable: Listenable.merge([store, sync]),
        builder: (context, _) {
          if (sync.needsLink) return const LinkScreen(key: ValueKey("link"));
          return store.unlocked
              ? const HomeScreen(key: ValueKey("home"))
              : const LoginScreen(key: ValueKey("login"));
        },
      ),
    );
  }
}
