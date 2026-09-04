import 'package:flutter/material.dart';

import '../app/constants.dart';
import '../app/formatters.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../models/holding.dart';
import '../models/stock.dart';
import '../models/transaction.dart';
import 'charts.dart';
import 'common.dart';

/// Invest-list row: logo, ticker + name, sparkline, price, day change.
class StockRow extends StatelessWidget {
  final Stock stock;
  final double price;
  final double dayChangePct;
  final VoidCallback onTap;

  const StockRow({
    super.key,
    required this.stock,
    required this.price,
    required this.dayChangePct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.s.isAr;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            TickerLogo(ticker: stock.ticker),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.ticker,
                    textDirection: TextDirection.ltr,
                    style: context.tt.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock.name(isAr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Sparkline(
              points: stock.history.sublist(stock.history.length - 24),
              color: context.deltaColor(dayChangePct),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${Fmt.price(price)}',
                  textDirection: TextDirection.ltr,
                  style: context.tt.titleSmall?.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                DeltaText(dayChangePct, fontSize: 12, showArrow: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-screen holding row — leads with the fraction owned, because that is
/// the thing the product is selling.
class HoldingRow extends StatelessWidget {
  final Stock stock;
  final Holding holding;
  final double price;
  final double dayChangePct;
  final VoidCallback onTap;

  /// Follows the Home currency toggle.
  final bool showEgp;

  const HoldingRow({
    super.key,
    required this.stock,
    required this.holding,
    required this.price,
    required this.dayChangePct,
    required this.onTap,
    this.showEgp = true,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.s.isAr;
    final valueUsd = holding.valueUsd(price);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: [
            TickerLogo(ticker: stock.ticker),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stock.ticker,
                        textDirection: TextDirection.ltr,
                        style: context.tt.titleSmall?.copyWith(fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.cs.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Fmt.fraction(holding.fraction),
                          textDirection: TextDirection.ltr,
                          style: context.tt.labelSmall?.copyWith(
                            color: context.cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock.name(isAr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  showEgp
                      ? Fmt.egp(context, valueUsd * K.fxEgpPerUsd)
                      : Fmt.usd(context, valueUsd),
                  style: context.tt.titleSmall?.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                DeltaText(dayChangePct, fontSize: 12, showArrow: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet activity row.
class TxnRow extends StatelessWidget {
  final Txn txn;
  const TxnRow({super.key, required this.txn});

  IconData get _icon => switch (txn.type) {
    TxType.deposit => Icons.south_west_rounded,
    TxType.convert => Icons.swap_horiz_rounded,
    TxType.buy => Icons.trending_up_rounded,
    TxType.sell => Icons.trending_down_rounded,
    TxType.dividend => Icons.savings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final credit = txn.isCredit;
    final tint = switch (txn.type) {
      TxType.deposit => const Color(0xFF11A66B),
      TxType.convert => context.cs.primary,
      TxType.buy => context.cs.primary,
      TxType.sell => const Color(0xFFB4541C),
      TxType.dividend => const Color(0xFFE8A317),
    };

    final title = txn.ticker == null
        ? context.s.t(txn.labelKey)
        : '${context.s.t(txn.labelKey)} · ${txn.ticker}';

    final amount = txn.amountEgp != null
        ? '${credit ? '+' : '−'} ${Fmt.egp(context, txn.amountEgp!)}'
        : (txn.amountUsd != null
              ? '+ ${Fmt.usd(context, txn.amountUsd!)}'
              : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: context.isDark ? 0.22 : 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, size: 19, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.tt.titleSmall?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      Fmt.dateTime(txn.at),
                      style: context.tt.labelSmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(txn.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: context.tt.titleSmall?.copyWith(
                  fontSize: 14,
                  color: credit ? const Color(0xFF11A66B) : null,
                ),
              ),
              if (txn.fraction != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${Fmt.fraction(txn.fraction!)} ${txn.ticker}',
                  textDirection: TextDirection.ltr,
                  style: context.tt.labelSmall?.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TxStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final done = status == TxStatus.completed;
    final color = done ? const Color(0xFF11A66B) : const Color(0xFFE8A317);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.s.t(done ? 'status_completed' : 'status_pending'),
        style: context.tt.labelSmall?.copyWith(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
