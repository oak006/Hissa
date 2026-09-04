import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/rate_lock.dart';
import '../../widgets/rows.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _convertController = TextEditingController();
  double _convertEgp = 0;

  @override
  void initState() {
    super.initState();
    _convertController.addListener(() {
      final v =
          double.tryParse(_convertController.text.replaceAll(',', '')) ?? 0;
      if (v != _convertEgp) setState(() => _convertEgp = v);
    });
  }

  @override
  void dispose() {
    _convertController.dispose();
    super.dispose();
  }

  void _convert() {
    final portfolio = context.read<PortfolioProvider>();
    if (portfolio.convert(_convertEgp)) {
      _convertController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.s.t('converted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();

    if (!portfolio.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canConvert =
        _convertEgp > 0 && _convertEgp <= portfolio.cashEgp + 0.001;
    final txns = portfolio.transactions;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(top: 8, bottom: 28)),
          children: [
            Text(s.t('wallet_title'), style: context.tt.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    label: s.t('egp_balance'),
                    value: Fmt.egp(context, portfolio.cashEgp),
                    icon: Icons.account_balance_wallet_rounded,
                    primary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BalanceCard(
                    label: s.t('usd_balance'),
                    value: Fmt.usd(context, portfolio.cashUsd),
                    icon: Icons.attach_money_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Outlined rather than tonal: a faint tonal fill reads as disabled
            // next to the genuinely-disabled convert button below it.
            OutlinedButton.icon(
              onPressed: () {
                context.read<PortfolioProvider>().deposit(1000);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(s.t('deposit_demo'))));
              },
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(s.t('deposit')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: context.cs.primary,
                backgroundColor: context.cs.primary.withValues(alpha: 0.06),
                side: BorderSide(
                  color: context.cs.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(s.t('convert_title')),
            const SizedBox(height: 8),
            _ConvertCard(
              controller: _convertController,
              amountEgp: _convertEgp,
              canConvert: canConvert,
              onConvert: canConvert ? _convert : null,
            ),
            const SizedBox(height: 24),
            SectionHeader(s.t('recent_activity')),
            const SizedBox(height: 4),
            if (txns.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: s.t('no_activity'),
              )
            else
              HissaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < txns.length; i++) ...[
                      if (i > 0) Divider(color: context.cs.outlineVariant),
                      TxnRow(txn: txns[i]),
                    ],
                  ],
                ),
              ),
            DemoDataNote(market.asOf),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool primary;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return HissaCard(
      color: primary ? context.cs.primary : context.cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: primary
                ? Colors.white.withValues(alpha: 0.9)
                : context.cs.primary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: context.tt.labelSmall?.copyWith(
              fontSize: 11.5,
              color: primary ? Colors.white.withValues(alpha: 0.85) : null,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: context.tt.titleLarge?.copyWith(
                fontSize: 20,
                color: primary ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EGP in, USD out, at a rate that is locked and visibly counting down.
class _ConvertCard extends StatelessWidget {
  final TextEditingController controller;
  final double amountEgp;
  final bool canConvert;
  final VoidCallback? onConvert;

  const _ConvertCard({
    required this.controller,
    required this.amountEgp,
    required this.canConvert,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final usd = amountEgp / K.fxEgpPerUsd;

    return HissaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('you_pay'), style: context.tt.bodySmall),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            textAlign: s.isAr ? TextAlign.right : TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: context.tt.titleLarge?.copyWith(fontSize: 22),
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                child: Text(
                  s.t('egp'),
                  style: context.tt.titleMedium?.copyWith(color: context.muted),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: context.cs.outlineVariant)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.south_rounded,
                  size: 15,
                  color: context.cs.primary,
                ),
              ),
              Expanded(child: Divider(color: context.cs.outlineVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.t('you_get'), style: context.tt.bodySmall),
          const SizedBox(height: 6),
          Text(
            '\$${Fmt.price(usd)}',
            textDirection: TextDirection.ltr,
            style: context.tt.displaySmall?.copyWith(
              fontSize: 30,
              color: context.cs.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(s.t('fx_rate'), style: context.tt.bodySmall),
              const SizedBox(width: 8),
              Text(
                '1 USD = ${K.fxEgpPerUsd.toStringAsFixed(2)}',
                textDirection: TextDirection.ltr,
                style: context.tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const RateLockBadge(compact: true),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onConvert, child: Text(s.t('convert_now'))),
        ],
      ),
    );
  }
}
