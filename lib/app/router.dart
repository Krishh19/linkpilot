import 'package:go_router/go_router.dart';
import 'package:linkpilot/features/about/about_screen.dart';
import 'package:linkpilot/features/browsers/browsers_screen.dart';
import 'package:linkpilot/features/cleaner/cleaner_screen.dart';
import 'package:linkpilot/features/help/help_screen.dart';
import 'package:linkpilot/features/home/home_screen.dart';
import 'package:linkpilot/features/onboarding/onboarding_screen.dart';
import 'package:linkpilot/features/rules/rule_editor_screen.dart';
import 'package:linkpilot/features/rules/rules_screen.dart';
import 'package:linkpilot/features/test_url/test_url_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RulesScreen(),
    ),
    GoRoute(
      path: '/rules/new',
      builder: (context, state) => const RuleEditorScreen(),
    ),
    GoRoute(
      path: '/rules/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return RuleEditorScreen(ruleId: id);
      },
    ),
    GoRoute(
      path: '/browsers',
      builder: (context, state) => const BrowsersScreen(),
    ),
    GoRoute(
      path: '/cleaner',
      builder: (context, state) => const CleanerScreen(),
    ),
    GoRoute(
      path: '/test-url',
      builder: (context, state) => const TestUrlScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
