import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/portfolio_provider.dart';
import '../screens/buy/trade_screen.dart';
import '../screens/buy/trade_success_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/invest/invest_screen.dart';
import '../screens/invest/stock_detail_screen.dart';
import '../screens/onboarding/id_screen.dart';
import '../screens/onboarding/kyc_done_screen.dart';
import '../screens/onboarding/otp_screen.dart';
import '../screens/onboarding/phone_screen.dart';
import '../screens/onboarding/risk_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell.dart';
import '../screens/wallet/wallet_screen.dart';

/// Five tabs in a stateful shell, with the onboarding flow and the
/// full-screen routes (stock detail, trade, chat) living outside it.
class AppRouter {
  AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/phone',
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/onboarding/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/onboarding/id',
        builder: (context, state) => const IdScreen(),
      ),
      GoRoute(
        path: '/onboarding/risk',
        builder: (context, state) => const RiskScreen(),
      ),
      GoRoute(
        path: '/onboarding/done',
        builder: (context, state) => const KycDoneScreen(),
      ),

      // Pushed above the shell so the bottom bar gets out of the way for the
      // screens that need the full height.
      GoRoute(
        path: '/stock/:ticker',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            StockDetailScreen(ticker: state.pathParameters['ticker']!),
      ),
      GoRoute(
        path: '/trade/:ticker',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => TradeScreen(
          ticker: state.pathParameters['ticker']!,
          isBuy: state.uri.queryParameters['mode'] != 'sell',
        ),
      ),
      GoRoute(
        path: '/trade-done',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final quote = state.extra as TradeQuote?;
          // Reachable only from a completed trade; a stray deep link falls
          // back to Home rather than crashing on stage.
          if (quote == null) return const HomeScreen();
          return TradeSuccessScreen(quote: quote);
        },
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ChatScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invest',
                builder: (context, state) => const InvestScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                builder: (context, state) => const PlansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
}
