import '../app/constants.dart';

enum PlanTier { free, tier2, tier3 }

/// Whether a feature is included, excluded, or included with a qualifier
/// (e.g. commission level).
class Cell {
  final bool? included;
  final String? valueKey;
  const Cell.yes() : included = true, valueKey = null;
  const Cell.no() : included = false, valueKey = null;
  const Cell.value(String key) : included = null, valueKey = key;
}

class Plan {
  final PlanTier tier;
  final String nameKey;
  final double priceEgp;
  final bool mostPopular;

  const Plan({
    required this.tier,
    required this.nameKey,
    required this.priceEgp,
    this.mostPopular = false,
  });

  bool get isPaid => tier != PlanTier.free;

  static const all = <Plan>[
    Plan(tier: PlanTier.free, nameKey: 'plan_free', priceEgp: K.tierFreeEgp),
    Plan(tier: PlanTier.tier2, nameKey: 'plan_t2', priceEgp: K.tier2Egp),
    Plan(
      tier: PlanTier.tier3,
      nameKey: 'plan_t3',
      priceEgp: K.tier3Egp,
      mostPopular: true,
    ),
  ];

  static Plan of(PlanTier t) => all.firstWhere((p) => p.tier == t);
}

/// One row of the comparison table.
class PlanFeature {
  final String labelKey;
  final Cell free;
  final Cell tier2;
  final Cell tier3;

  /// Rendered bold — the rows that carry the upgrade argument.
  final bool emphasised;

  const PlanFeature(
    this.labelKey,
    this.free,
    this.tier2,
    this.tier3, {
    this.emphasised = false,
  });

  Cell cell(PlanTier t) => switch (t) {
    PlanTier.free => free,
    PlanTier.tier2 => tier2,
    PlanTier.tier3 => tier3,
  };

  static const rows = <PlanFeature>[
    PlanFeature('f_fractional', Cell.yes(), Cell.yes(), Cell.yes()),
    PlanFeature('f_recurring', Cell.yes(), Cell.yes(), Cell.yes()),
    PlanFeature('f_edu_core', Cell.yes(), Cell.yes(), Cell.yes()),
    PlanFeature(
      'f_commission',
      Cell.value('v_standard'),
      Cell.value('v_reduced'),
      Cell.value('v_lowest'),
    ),
    PlanFeature('f_ai', Cell.no(), Cell.yes(), Cell.yes(), emphasised: true),
    PlanFeature('f_analytics', Cell.no(), Cell.yes(), Cell.yes()),
    PlanFeature('f_themed', Cell.no(), Cell.no(), Cell.yes()),
    PlanFeature('f_edu_adv', Cell.no(), Cell.no(), Cell.yes()),
    PlanFeature(
      'f_support',
      Cell.value('v_standard'),
      Cell.value('v_priority'),
      Cell.value('v_priority'),
    ),
  ];
}
