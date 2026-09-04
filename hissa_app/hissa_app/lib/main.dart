import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'app/strings.dart';
import 'app/theme.dart';
import 'providers/app_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/market_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/subscription_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cairo is bundled in assets/fonts, so google_fonts must never reach for
  // the network. This build makes zero HTTP requests of any kind.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const HissaApp());
}

class HissaApp extends StatelessWidget {
  const HissaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()..load()),
        // Portfolio needs live prices, so it hangs off the market provider and
        // hydrates itself once the static snapshot has loaded.
        ChangeNotifierProxyProvider<MarketProvider, PortfolioProvider>(
          create: (_) => PortfolioProvider(),
          update: (_, market, portfolio) =>
              (portfolio ?? PortfolioProvider())..attach(market),
        ),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) {
          return MaterialApp.router(
            title: 'Hissa',
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: app.themeMode,

            // Arabic + RTL is the default; the settings toggle flips the whole
            // tree through this one value.
            locale: app.locale,
            supportedLocales: AppStrings.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
