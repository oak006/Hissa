import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/app_provider.dart';
import 'onboarding_scaffold.dart';

/// Egyptian mobile entry. Ten digits after +20 — validated for shape only,
/// and any ten digits are accepted.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length == 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final formatted =
        '+20 ${_digits.substring(0, 2)} ${_digits.substring(2, 6)} '
        '${_digits.substring(6)}';
    context.read<AppProvider>().setPhone(formatted);
    setState(() => _submitting = false);
    if (!mounted) return;
    context.push('/onboarding/otp');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return OnboardingScaffold(
      step: 1,
      title: s.t('phone_title'),
      subtitle: s.t('phone_sub'),
      actionLabel: s.t('send_code'),
      loading: _submitting,
      onAction: _valid ? _submit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('phone_label'), style: context.tt.titleSmall),
          const SizedBox(height: 10),
          Directionality(
            // The number itself always reads left to right, in both locales.
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: context.tt.titleLarge?.copyWith(
                fontSize: 22,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: s.t('phone_hint'),
                hintStyle: context.tt.titleLarge?.copyWith(
                  fontSize: 22,
                  letterSpacing: 1.5,
                  color: context.muted.withValues(alpha: 0.45),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇪🇬', style: TextStyle(fontSize: 19)),
                      const SizedBox(width: 8),
                      Text(
                        '+20',
                        style: context.tt.titleLarge?.copyWith(
                          fontSize: 20,
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 24,
                        color: context.cs.outlineVariant,
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: _valid
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: K.gain,
                        size: 21,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FieldHint(
            valid: _valid,
            validText: s.t('phone_ok'),
            invalidText: s.t('phone_short'),
            show: _controller.text.isNotEmpty,
          ),
        ],
      ),
    );
  }
}
