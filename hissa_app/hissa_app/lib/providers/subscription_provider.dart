import 'package:flutter/foundation.dart';

import '../models/plan.dart';

/// In-memory entitlement flag. "Start demo trial" flips it instantly — there
/// is no payment flow anywhere in this build.
class SubscriptionProvider extends ChangeNotifier {
  PlanTier _tier = PlanTier.free;
  bool _onTrial = false;

  PlanTier get tier => _tier;
  Plan get plan => Plan.of(_tier);
  bool get onTrial => _onTrial;
  bool get isPaid => _tier != PlanTier.free;

  /// The one gated feature in the demo: the Arabic AI advisor.
  bool get canUseAdvisor => isPaid;

  /// Tier 3 additionally unlocks themed portfolios and screeners.
  bool get canUseScreeners => _tier == PlanTier.tier3;

  void startTrial(PlanTier tier) {
    _tier = tier;
    _onTrial = tier != PlanTier.free;
    notifyListeners();
  }

  void endTrial() {
    _tier = PlanTier.free;
    _onTrial = false;
    notifyListeners();
  }

  void reset() {
    _tier = PlanTier.free;
    _onTrial = false;
    notifyListeners();
  }
}
