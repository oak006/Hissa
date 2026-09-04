import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/market_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/rows.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  final _search = TextEditingController();
  String _category = 'all';

  static const _categories = <(String, String)>[
    ('all', 'cat_all'),
    ('tech', 'cat_tech'),
    ('etf', 'cat_etf'),
    ('popular', 'cat_popular'),
    ('movers', 'cat_movers'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final market = context.watch<MarketProvider>();

    if (market.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final results = market.query(search: _search.text, category: _category);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: K.pagePad.add(const EdgeInsets.only(top: 8, bottom: 10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('invest_title'), style: context.tt.headlineSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: s.t('search_hint'),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: context.muted,
                      ),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: K.pagePad,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (id, key) = _categories[i];
                  final selected = id == _category;
                  return _CategoryChip(
                    label: s.t(key),
                    selected: selected,
                    onTap: () => setState(() => _category = id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: s.t('no_results'),
                      subtitle: s.t('no_results_sub'),
                    )
                  : ListView(
                      padding: K.pagePad.add(
                        const EdgeInsets.only(bottom: 24, top: 4),
                      ),
                      children: [
                        HissaCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < results.length; i++) ...[
                                if (i > 0)
                                  Divider(color: context.cs.outlineVariant),
                                StockRow(
                                  stock: results[i],
                                  price: market.priceOf(results[i].ticker),
                                  dayChangePct: market.dayChangePctOf(
                                    results[i].ticker,
                                  ),
                                  onTap: () => context.push(
                                    '/stock/${results[i].ticker}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DemoDataNote(market.asOf),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.cs.primary : context.cs.surface,
      borderRadius: BorderRadius.circular(K.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(K.radiusChip),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(K.radiusChip),
            border: Border.all(
              color: selected ? context.cs.primary : context.cs.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: context.tt.labelLarge?.copyWith(
              fontSize: 13,
              color: selected ? Colors.white : context.cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
