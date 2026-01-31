import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/web_login_screen.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'features/dashboard/overview_screen.dart';
import 'features/assets/asset_list_screen.dart';
import 'features/people/people_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // In a real app, listen to auth state to redirect
  final isLoggedIn = false; // TODO: Connect to AuthProvider

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const WebLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetListScreen(),
          ),
          GoRoute(
            path: '/people',
            builder: (context, state) => const PeopleScreen(),
          ),
        ],
      ),
    ],
  );
});
