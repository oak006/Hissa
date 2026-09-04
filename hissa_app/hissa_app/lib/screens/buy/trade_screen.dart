import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/rate_lock.dart';
import 'processing_overlay.dart';

/// THE screen. Everything a first-time investor needs to see before they
/// commit — live price, the exact fraction they receive, the locked FX rate,
/// and every fee — visible simultaneously, updating as they type.
class TradeScreen extends StatefulWidget {
  final String ticker;
  final bool isBuy;

  const TradeScreen({super.key, required this.ticker, required this.isBuy});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  double _amount = 0;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // The field border reacts to focus, so the screen has to rebuild for it.
    _focus.addListener(() => setState(() {}));
  }

  void _onChanged() {
    final parsed =
        double.tryParse(_controller.text.replaceAll(',', '').trim()) ?? 0;
    if (parsed != _amount) setState(() => _amount = parsed);
  }

  void _setAmount(double v) {
    _controller.text = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _confirm(TradeQuote quote) async {
    FocusScope.of(context).unfocus();
    setState(() => _processing = true);
    await Future<void>.delayed(K.processingDelay);
    if (!mounted) return;
    context.read<PortfolioProvider>().execute(quote);
    setState(() => _processing = false);
    if (!mounted) return;
    context.pushReplacement('/trade-done', extra: quote);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final stock = market.byTicker(widget.ticker);

    if (stock == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(s.t('no_results'))),
      );
    }

    final quote = portfolio.quote(
      ticker: widget.ticker,
      amountEgp: _amount,
      isBuy: widget.isBuy,
    );
    final dayChange = market.dayChangePctOf(widget.ticker);
    final sellable = portfolio.sellableEgp(widget.ticker);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              s.f(widget.isBuy ? 'buy_title' : 'sell_title', [stock.ticker]),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: K.pagePad.add(const EdgeInsets.only(bottom: 20)),
              children: [
                _Header(
                  ticker: stock.ticker,
                  name: stock.name(s.isAr),
                  price: quote.sharePriceUsd,
                  dayChangePct: dayChange,
                ),
                const SizedBox(height: 20),
                _AmountField(
                  controller: _controller,
                  focusNode: _focus,
                  label: s.t(
                    widget.isBuy ? 'amount_to_invest' : 'amount_to_sell',
                  ),
                  hasError: quote.errorKey != null,
                ),
                const SizedBox(height: 12),
                _QuickChips(
                  onPick: _setAmount,
                  showSellAll: !widget.isBuy,
                  sellAllValue: sellable,
                ),
                const SizedBox(height: 10),
                _BalanceLine(
                  isBuy: widget.isBuy,
                  cashEgp: portfolio.cashEgp,
                  sellableEgp: sellable,
                ),
                if (quote.errorKey != null) ...[
                  const SizedBox(height: 12),
                  _ErrorLine(
                    text: s.f(quote.errorKey!, [
                      for (final a in quote.errorArgs)
                        a is double ? Fmt.egp(context, a, whole: true) : a,
                    ]),
                  ),
                ],
                const SizedBox(height: 18),
                _Breakdown(quote: quote, ticker: stock.ticker),
                const SizedBox(height: 14),
                const _TransparencyNote(),
                DemoDataNote(market.asOf),
              ],
            ),
          ),
          bottomNavigationBar: _ConfirmBar(
            quote: quote,
            onConfirm: quote.valid ? () => _confirm(quote) : null,
          ),
        ),
        if (_processing)
          ProcessingOverlay(
            title: context.s.t('processing'),
            subtitle: context.s.t('processing_sub'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- sections

class _Header extends StatelessWidget {
  final String ticker;
  final String name;
  final double price;
  final double dayChangePct;

  const _Header({
    required this.ticker,
    required this.name,
    required this.price,
    required this.dayChangePct,
  });

  @override
  Widget build(BuildContext context) {
    return HissaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          TickerLogo(ticker: ticker, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker,
                  textDirection: TextDirection.ltr,
                  style: context.tt.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Ticks every 5s — the number visibly breathes during the pitch.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '\$${Fmt.price(price)}',
                  key: ValueKey(price),
                  textDirection: TextDirection.ltr,
                  style: context.tt.titleMedium,
                ),
              ),
              const SizedBox(height: 3),
              DeltaText(dayChangePct, fontSize: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool hasError;

  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final border = hasError ? K.loss : context.cs.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.tt.titleSmall),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: BorderRadius.circular(K.radiusCard),
            border: Border.all(
              color: focusNode.hasFocus || hasError
                  ? border
                  : context.cs.outlineVariant,
              width: focusNode.hasFocus || hasError ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                context.s.t('egp'),
                style: context.tt.titleMedium?.copyWith(color: context.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textDirection: TextDirection.ltr,
                  textAlign: context.s.isAr ? TextAlign.right : TextAlign.left,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    // one decimal point, at most two decimals
                    TextInputFormatter.withFunction((old, now) {
                      final t = now.text;
                      if (t.isEmpty) return now;
                      if ('.'.allMatches(t).length > 1) return old;
                      final dot = t.indexOf('.');
                      if (dot >= 0 && t.length - dot > 3) return old;
                      if (t.length > 9) return old;
                      return now;
                    }),
                  ],
                  style: context.tt.displaySmall?.copyWith(fontSize: 34),
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintStyle: context.tt.displaySmall?.copyWith(
                      fontSize: 34,
                      color: context.muted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChips extends StatelessWidget {
  final ValueChanged<double> onPick;
  final bool showSellAll;
  final double sellAllValue;

  const _QuickChips({
    required this.onPick,
    required this.showSellAll,
    required this.sellAllValue,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in K.quickAmountsEgp)
          _Chip(
            label: Fmt.egp(context, v, whole: true),
            onTap: () => onPick(v),
          ),
        if (showSellAll)
          _Chip(
            label: context.s.t('sell_all'),
            accent: true,
            onTap: () => onPick(sellAllValue),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _Chip({required this.label, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent
          ? context.cs.primary.withValues(alpha: 0.12)
          : context.cs.surface,
      borderRadius: BorderRadius.circular(K.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(K.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(K.radiusChip),
            border: Border.all(
              color: accent
                  ? context.cs.primary.withValues(alpha: 0.35)
                  : context.cs.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: context.tt.labelLarge?.copyWith(
              fontSize: 13,
              color: accent ? context.cs.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final bool isBuy;
  final double cashEgp;
  final double sellableEgp;

  const _BalanceLine({
    required this.isBuy,
    required this.cashEgp,
    required this.sellableEgp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isBuy
              ? Icons.account_balance_wallet_outlined
              : Icons.pie_chart_outline_rounded,
          size: 14,
          color: context.muted,
        ),
        const SizedBox(width: 6),
        Text(
          '${context.s.t(isBuy ? 'available' : 'available_to_sell')}: '
          '${Fmt.egp(context, isBuy ? cashEgp : sellableEgp)}',
          style: context.tt.labelSmall?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  final String text;
  const _ErrorLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: K.loss.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: K.loss),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.tt.bodySmall?.copyWith(
                color: K.loss,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The transparency argument, made visible. Every number the user is agreeing
/// to, in one card, before they confirm.
class _Breakdown extends StatelessWidget {
  final TradeQuote quote;
  final String ticker;

  const _Breakdown({required this.quote, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final muted = !quote.hasAmount;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: muted ? 0.55 : 1,
      child: HissaCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('order_summary'), style: context.tt.titleSmall),
            const SizedBox(height: 8),
            KeyValueRow(
              label: s.t('share_price'),
              value: '\$${Fmt.price(quote.sharePriceUsd)}',
            ),
            KeyValueRow(
              label: s.t('fx_applied'),
              value: '1 USD = ${quote.fx.toStringAsFixed(2)}',
              labelSuffix: const RateLockBadge(compact: true),
            ),
            KeyValueRow(
              label: s.t('amount_usd'),
              value: '\$${Fmt.price(quote.amountUsd)}',
            ),
            const SizedBox(height: 10),
            _FractionHero(quote: quote, ticker: ticker),
            const SizedBox(height: 10),
            KeyValueRow(
              label: s.t('commission'),
              value: Fmt.egp(context, quote.commissionEgp),
            ),
            KeyValueRow(
              label: s.t('flat_fee'),
              value: Fmt.egp(context, quote.flatFeeEgp),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(color: context.cs.outlineVariant),
            ),
            KeyValueRow(
              label: s.t(quote.isBuy ? 'total_debit' : 'total_credit'),
              value: Fmt.egp(context, quote.totalEgp.clamp(0, double.infinity)),
              emphasise: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// The product, rendered as large as it deserves.
class _FractionHero extends StatelessWidget {
  final TradeQuote quote;
  final String ticker;

  const _FractionHero({required this.quote, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: context.isDark
              ? [
                  K.royal.withValues(alpha: 0.30),
                  K.navy.withValues(alpha: 0.22),
                ]
              : [
                  K.royal.withValues(alpha: 0.11),
                  K.navy.withValues(alpha: 0.07),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cs.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                size: 15,
                color: context.cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                s.t(quote.isBuy ? 'you_receive_frac' : 'you_sell_frac'),
                style: context.tt.labelLarge?.copyWith(
                  color: context.cs.primary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(quote.fraction.toStringAsFixed(4)),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.fraction(quote.fraction),
                  textDirection: TextDirection.ltr,
                  style: context.tt.displaySmall?.copyWith(
                    fontSize: 38,
                    height: 1.05,
                    color: context.cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    s.f('of_one_share', [ticker]),
                    style: context.tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparencyNote extends StatelessWidget {
  const _TransparencyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 15, color: K.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.s.t('transparent_note'),
            style: context.tt.bodySmall?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Sticky footer: the total restated next to the button, so the figure the
/// user confirms is never scrolled off screen.
class _ConfirmBar extends StatelessWidget {
  final TradeQuote quote;
  final VoidCallback? onConfirm;

  const _ConfirmBar({required this.quote, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surface,
        border: Border(top: BorderSide(color: context.cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    s.t(quote.isBuy ? 'total_debit' : 'total_credit'),
                    style: context.tt.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    Fmt.egp(context, quote.totalEgp.clamp(0, double.infinity)),
                    style: context.tt.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onConfirm,
                style: quote.isBuy
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB4541C),
                      ),
                child: Text(s.t(quote.isBuy ? 'confirm_buy' : 'confirm_sell')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
