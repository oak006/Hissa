import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/common.dart';
import 'processing_overlay.dart';

/// Closes the loop: the fraction they now own, stated plainly.
class TradeSuccessScreen extends StatelessWidget {
  final TradeQuote quote;

  const TradeSuccessScreen({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final portfolio = context.watch<PortfolioProvider>();
    final ownedNow = portfolio.fractionOf(quote.ticker);
    final accent = quote.isBuy ? K.gain : const Color(0xFFB4541C);

    return Scaffold(
      body: SafeArea(
        // Spacers give the layout air on a tall phone; the scroll view keeps
        // it from overflowing on a short one.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: K.pagePad,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    SuccessCheck(color: accent),
                    const SizedBox(height: 22),
                    Text(
                      s.t(quote.isBuy ? 'bought_title' : 'sold_title'),
                      style: context.tt.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Fmt.egp(context, quote.totalEgp),
                      style: context.tt.bodyMedium?.copyWith(
                        color: context.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    HissaCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.t(quote.isBuy ? 'you_now_own' : 'sold_amount'),
                            style: context.tt.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Fmt.fraction(
                                  quote.isBuy ? ownedNow : quote.fraction,
                                ),
                                textDirection: TextDirection.ltr,
                                style: context.tt.displaySmall?.copyWith(
                                  fontSize: 42,
                                  color: context.cs.primary,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Text(
                                  s.f('of_one_share', [quote.ticker]),
                                  style: context.tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: context.cs.outlineVariant),
                          const SizedBox(height: 8),
                          KeyValueRow(
                            label: s.t('share_price'),
                            value: '\$${Fmt.price(quote.sharePriceUsd)}',
                          ),
                          KeyValueRow(
                            label: s.t('fx_applied'),
                            value: '1 USD = ${quote.fx.toStringAsFixed(2)}',
                          ),
                          KeyValueRow(
                            label: s.t('commission'),
                            value: Fmt.egp(context, quote.commissionEgp),
                          ),
                          KeyValueRow(
                            label: s.t('flat_fee'),
                            value: Fmt.egp(context, quote.flatFeeEgp),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    FilledButton(
                      onPressed: () => context.go('/home'),
                      child: Text(s.t('back_home')),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.pushReplacement(
                        '/trade/${quote.ticker}?mode=${quote.isBuy ? 'buy' : 'sell'}',
                      ),
                      child: Text(s.t(quote.isBuy ? 'buy_more' : 'sell')),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
