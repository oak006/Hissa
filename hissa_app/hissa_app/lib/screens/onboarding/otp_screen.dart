import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/fake_notification.dart';
import 'onboarding_scaffold.dart';

/// Six boxes, any six digits. The resend timer genuinely counts down.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  int _remaining = K.otpResendSeconds;
  Timer? _timer;
  bool _submitting = false;

  /// The code "sent" to the device. Any six digits are accepted, so this only
  /// exists so the mock notification has something real to show and autofill.
  late String _sentCode = _newCode();

  /// Bumped on resend to rebuild the banner, so a new one slides in.
  int _notificationRound = 0;

  String _newCode() {
    final rnd = Random();
    return List.generate(_length, (_) => rnd.nextInt(10)).join();
  }

  String get _code => _controller.text;
  bool get _complete => _code.length == _length;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _resend() {
    setState(() {
      _sentCode = _newCode();
      _notificationRound++;
    });
    _startTimer();
  }

  void _autofill() {
    _controller.text = _sentCode;
    _focus.unfocus();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = K.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    context.push('/onboarding/id');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final phone = context.watch<AppProvider>().user.phone;

    final scaffold = OnboardingScaffold(
      step: 1,
      title: s.t('otp_title'),
      subtitle: s.f('otp_sub', [phone]),
      actionLabel: s.t('verify'),
      loading: _submitting,
      onAction: _complete ? _verify : null,
      secondary: TextButton(
        onPressed: _remaining > 0
            ? null
            : () {
                _resend();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(s.t('otp_resent'))));
              },
        child: Text(
          _remaining > 0
              ? s.f('otp_resend_in', [Fmt.clock(_remaining)])
              : s.t('otp_resend'),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // The real field, invisible — the boxes below mirror its value.
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 60,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_length),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // Six fixed-width boxes just fit a 375pt phone and
                      // overflow anything narrower, so size them to the space.
                      const gap = 8.0;
                      final boxWidth =
                          ((box.maxWidth - gap * _length) / _length).clamp(
                            34.0,
                            48.0,
                          );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_length, (i) {
                          final filled = i < _code.length;
                          final active = i == _code.length && _focus.hasFocus;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: boxWidth,
                            height: boxWidth * 1.26,
                            margin: const EdgeInsets.symmetric(
                              horizontal: gap / 2,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active || filled
                                    ? context.cs.primary
                                    : context.cs.outlineVariant,
                                width: active ? 2 : 1.2,
                              ),
                            ),
                            child: Text(
                              filled ? _code[i] : '',
                              style: context.tt.headlineSmall?.copyWith(
                                fontSize: 24,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FieldHint(
            valid: _complete,
            validText: s.t('phone_ok'),
            invalidText: '${_code.length} / $_length',
            show: _code.isNotEmpty,
          ),
        ],
      ),
    );

    return Stack(
      children: [
        scaffold,
        // Rebuilt on each resend so a fresh banner slides in.
        FakeNotification(
          key: ValueKey(_notificationRound),
          title: s.t('app_name'),
          body: s.f('otp_notif_body', [_sentCode]),
          action: s.t('otp_tap_to_fill'),
          onTap: _autofill,
          delay: _notificationRound == 0
              ? const Duration(milliseconds: 1500)
              : const Duration(milliseconds: 600),
        ),
      ],
    );
  }
}
