import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/app_providers.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/backend_connect_screen.dart';
import '../../presentation/screens/onboarding/api_key_screen.dart';
import '../../presentation/screens/onboarding/github_connect_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/projects/all_projects_screen.dart';
import '../../presentation/screens/projects/file_explorer_screen.dart';
import '../../presentation/screens/editor/code_editor_screen.dart';
import '../../presentation/screens/chat/planning_chat_screen.dart';
import '../../presentation/screens/chat/project_chat_screen.dart';
import '../../presentation/screens/deploy/deploy_screen.dart';
import '../../presentation/screens/qr/qr_scanner_screen.dart';
import '../../presentation/screens/projects/import_repo_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/backend-connect',
        builder: (_, __) => const BackendConnectScreen(),
      ),
      GoRoute(
        path: '/api-keys',
        builder: (_, __) => const ApiKeyScreen(),
      ),
      GoRoute(
        path: '/github-connect',
        builder: (_, __) => const GitHubConnectScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        pageBuilder: (_, __) => CustomTransitionPage(
          child: const QRScannerScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      // Main app routes
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (_, __) => const AllProjectsScreen(),
      ),
      GoRoute(
        path: '/projects/:projectId/files',
        builder: (_, state) => FileExplorerScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
      GoRoute(
        path: '/editor',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CodeEditorScreen(
            filePath: extra['filePath'] as String,
            projectId: extra['projectId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/planning-chat',
        builder: (_, __) => const PlanningChatScreen(),
      ),
      GoRoute(
        path: '/project-chat/:projectId',
        builder: (_, state) => ProjectChatScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
      GoRoute(
        path: '/import-repo',
        builder: (_, __) => const ImportRepoScreen(),
      ),
      GoRoute(
        path: '/deploy',
        builder: (_, __) => const DeployScreen(),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/splash') return null;
      if (!onboardingDone &&
          path != '/backend-connect' &&
          path != '/api-keys' &&
          path != '/github-connect' &&
          path != '/qr-scanner') {
        return '/backend-connect';
      }
      return null;
    },
  );
});
