import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linkpilot/app/router.dart';
import 'package:linkpilot/app/theme.dart';
import 'package:linkpilot/data/linkpilot_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  var startAtOnboarding = false;
  try {
    final repository = container.read(linkPilotRepositoryProvider);
    startAtOnboarding = !await repository.isOnboardingCompleted();
  } catch (_) {
    // If the native bridge is unavailable, fall back to the home screen.
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: LinkPilotApp(
        initialLocation: startAtOnboarding ? '/onboarding' : '/',
      ),
    ),
  );
}

class LinkPilotApp extends StatefulWidget {
  const LinkPilotApp({super.key, this.initialLocation = '/'});

  final String initialLocation;

  @override
  State<LinkPilotApp> createState() => _LinkPilotAppState();
}

class _LinkPilotAppState extends State<LinkPilotApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'LinkPilot',
          theme: LinkPilotTheme.lightTheme(lightDynamic),
          darkTheme: LinkPilotTheme.darkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
