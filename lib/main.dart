import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linkpilot/app/router.dart';
import 'package:linkpilot/app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: LinkPilotApp(),
    ),
  );
}

class LinkPilotApp extends StatelessWidget {
  const LinkPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'LinkPilot',
          theme: LinkPilotTheme.lightTheme(lightDynamic),
          darkTheme: LinkPilotTheme.darkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
