import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/brands.dart';
import '../app/constants.dart';
import '../app/formatters.dart';
import '../app/strings.dart';
import '../app/theme.dart';

/// The app's one card shape. Everything sits on one of these.
class HissaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool outlined;

  const HissaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(K.radiusCard);
    return Material(
      color: color ?? context.cs.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: outlined
                ? Border.all(color: context.cs.outlineVariant)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Company logo tile.
///
/// Real brand mark on the company's real brand colour where one is bundled;
/// the ticker on that same brand colour where it is not. The hairline border
/// keeps the near-black brands (Apple, Nike, Palantir) from disappearing into
/// a dark background.
class TickerLogo extends StatelessWidget {
  final String ticker;
  final double size;

  const TickerLogo({super.key, required this.ticker, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final brand = Brand.of(ticker);
    final path = brand.assetPath;
    final label = ticker.length <= 4 ? ticker : ticker.substring(0, 4);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.color,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: path == null
          ? Text(
              label,
              textDirection: TextDirection.ltr,
              style: context.tt.labelLarge?.copyWith(
                color: Colors.white,
                fontSize: size * (label.length > 3 ? 0.235 : 0.30),
                letterSpacing: -0.2,
              ),
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.24),
              child: SvgPicture.asset(
                path,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                // The tile is already the brand colour; a missing asset should
                // never punch a hole in a list mid-demo.
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
    );
  }
}

/// Signed percentage with a directional arrow. Green up, red down — always.
class DeltaText extends StatelessWidget {
  final double pct;
  final double? fontSize;
  final bool showArrow;
  final FontWeight weight;

  const DeltaText(
    this.pct, {
    super.key,
    this.fontSize,
    this.showArrow = true,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.deltaColor(pct);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrow && pct != 0)
          Icon(
            pct > 0
                ? Icons.arrow_drop_up_rounded
                : Icons.arrow_drop_down_rounded,
            color: color,
            size: (fontSize ?? 14) + 8,
          ),
        Text(
          Fmt.pct(pct),
          textDirection: TextDirection.ltr,
          style: context.tt.labelLarge?.copyWith(
            color: color,
            fontSize: fontSize ?? 13,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }
}

/// Filled pill version, for the top of a detail screen.
class DeltaChip extends StatelessWidget {
  final double pct;
  const DeltaChip(this.pct, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.deltaColor(pct);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DeltaText(pct, fontSize: 13),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.tt.titleMedium)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// One line of a breakdown: label on one side, value on the other.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasise;
  final Widget? trailing;
  final Widget? labelSuffix;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasise = false,
    this.trailing,
    this.labelSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: emphasise
                  ? context.tt.titleSmall
                  : context.tt.bodyMedium?.copyWith(color: context.muted),
            ),
          ),
          if (labelSuffix != null) ...[const SizedBox(width: 8), labelSuffix!],
          const Spacer(),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: (emphasise ? context.tt.titleMedium : context.tt.bodyMedium)
                ?.copyWith(
                  color: valueColor,
                  fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

/// The unobtrusive honesty line. Shown on every screen that quotes a price.
class DemoDataNote extends StatelessWidget {
  final String asOf;
  final EdgeInsetsGeometry padding;

  const DemoDataNote(
    this.asOf, {
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: context.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.s.f('prices_disclaimer', [asOf]),
              textAlign: TextAlign.center,
              style: context.tt.labelSmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: context.cs.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.cs.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.tt.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.tt.bodySmall,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 200,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A short-lived tick that drives every countdown in the app.
class CountdownBuilder extends StatefulWidget {
  final int seconds;
  final VoidCallback? onFinished;
  final Widget Function(BuildContext context, int remaining) builder;

  const CountdownBuilder({
    super.key,
    required this.seconds,
    required this.builder,
    this.onFinished,
  });

  @override
  State<CountdownBuilder> createState() => CountdownBuilderState();
}

class CountdownBuilderState extends State<CountdownBuilder> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onFinished?.call();
      }
    });
  }

  /// Called by parents to re-arm the countdown (e.g. "refresh rate").
  void restart([int? seconds]) {
    setState(() => _remaining = seconds ?? widget.seconds);
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}
