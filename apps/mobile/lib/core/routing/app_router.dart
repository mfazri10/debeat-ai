import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/lobby/lobby_screen.dart';
import '../../features/debate/arena_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/lobby',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/arena/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? 'default-session';
        final extra = state.extra as Map<String, dynamic>?;
        return ArenaScreen(
          sessionId: sessionId,
          initialData: extra,
        );
      },
    ),
    GoRoute(
      path: '/results/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? 'default-session';
        return ResultsScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
