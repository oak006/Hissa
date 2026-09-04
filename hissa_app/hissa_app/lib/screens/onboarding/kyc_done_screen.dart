import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common.dart';
import '../buy/processing_overlay.dart';

/// "Verified in under 5 minutes" — the claim the KYC flow exists to make.
class KycDoneScreen extends StatelessWidget {
  const KycDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: K.pagePad,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const SuccessCheck(size: 100),
                    const SizedBox(height: 24),
                    Text(
                      s.t('kyc_done_title'),
                      style: context.tt.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: K.amber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.t('kyc_done_sub'),
                          style: context.tt.titleSmall?.copyWith(
                            color: K.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    HissaCard(
                      child: Column(
                        children: [
                          for (final key in const [
                            'kyc_step_phone',
                            'kyc_step_id',
                            'kyc_step_risk',
                          ])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: K.gain.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: K.gain,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.t(key),
                                      style: context.tt.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    s.t('verified_badge'),
                                    style: context.tt.labelSmall?.copyWith(
                                      color: K.gain,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                    FilledButton(
                      onPressed: () {
                        context.read<AppProvider>().completeOnboarding();
                        context.go('/home');
                      },
                      child: Text(s.t('start_investing')),
                    ),
                    const SizedBox(height: 18),
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
