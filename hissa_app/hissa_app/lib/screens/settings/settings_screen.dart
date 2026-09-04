import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/hissa_mark.dart';
import '../../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final market = context.watch<MarketProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(top: 8, bottom: 28)),
          children: [
            Text(s.t('settings_title'), style: context.tt.headlineSmall),
            const SizedBox(height: 18),
            _ProfileCard(
              name: app.user.name(s.isAr),
              phone: app.user.phone,
              verified: app.user.verified,
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('language')),
            const SizedBox(height: 8),
            _SegmentCard(
              options: [
                (
                  s.t('arabic'),
                  app.isAr,
                  () => app.setLocale(const Locale('ar')),
                ),
                (
                  s.t('english'),
                  !app.isAr,
                  () => app.setLocale(const Locale('en')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('theme')),
            const SizedBox(height: 8),
            _SegmentCard(
              options: [
                (
                  s.t('theme_light'),
                  app.themeMode == ThemeMode.light,
                  () => app.setThemeMode(ThemeMode.light),
                ),
                (
                  s.t('theme_dark'),
                  app.themeMode == ThemeMode.dark,
                  () => app.setThemeMode(ThemeMode.dark),
                ),
                (
                  s.t('theme_system'),
                  app.themeMode == ThemeMode.system,
                  () => app.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('plan_status')),
            const SizedBox(height: 8),
            HissaCard(
              onTap: () => context.go('/plans'),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sub.isPaid
                          ? K.amber.withValues(alpha: 0.14)
                          : context.cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      sub.isPaid
                          ? Icons.workspace_premium_rounded
                          : Icons.card_membership_outlined,
                      size: 20,
                      color: sub.isPaid ? K.amber : context.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t(sub.plan.nameKey),
                          style: context.tt.titleSmall,
                        ),
                        if (sub.onTrial)
                          Text(
                            s.t('trial_active'),
                            style: context.tt.labelSmall?.copyWith(
                              color: K.gain,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.muted),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('demo_section')),
            const SizedBox(height: 8),
            HissaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('reset_demo'), style: context.tt.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    s.t('reset_demo_sub'),
                    style: context.tt.bodySmall?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt_rounded, size: 19),
                    label: Text(s.t('reset_demo')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('about_app')),
            const SizedBox(height: 8),
            HissaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [K.royal, K.navy],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: HissaMark(size: 17)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${s.t('app_name')} · ${s.t('tagline')}',
                        style: context.tt.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.t('about_body'),
                    style: context.tt.bodySmall?.copyWith(height: 1.7),
                  ),
                ],
              ),
            ),
            DemoDataNote(market.asOf),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.t('reset_demo')),
        content: Text(s.t('reset_confirm'), style: context.tt.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            child: Text(s.t('confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    context.read<PortfolioProvider>().reset();
    context.read<SubscriptionProvider>().reset();
    context.read<ChatProvider>().reset();
    context.read<MarketProvider>().reset();
    context.read<AppProvider>().reset();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.t('reset_done'))));
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final bool verified;

  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return HissaCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              name.characters.first,
              style: context.tt.headlineSmall?.copyWith(
                color: context.cs.primary,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: context.tt.titleMedium),
                    const SizedBox(width: 8),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: K.gain.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 11,
                              color: K.gain,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.s.t('verified_badge'),
                              style: context.tt.labelSmall?.copyWith(
                                color: K.gain,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: context.tt.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two- or three-way segmented control used for language and theme.
class _SegmentCard extends StatelessWidget {
  final List<(String, bool, VoidCallback)> options;
  const _SegmentCard({required this.options});

  @override
  Widget build(BuildContext context) {
    return HissaCard(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final (label, selected, onTap) in options)
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: selected ? context.cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.tt.labelLarge?.copyWith(
                      fontSize: 14,
                      color: selected ? Colors.white : context.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
