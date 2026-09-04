import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import 'onboarding_scaffold.dart';

enum _IdStage { framing, scanning, verified }

/// Mock ID capture: a camera-frame placeholder, a capture button, two seconds
/// of scanning theatre, then a green verified state.
class IdScreen extends StatefulWidget {
  const IdScreen({super.key});

  @override
  State<IdScreen> createState() => _IdScreenState();
}

class _IdScreenState extends State<IdScreen> {
  _IdStage _stage = _IdStage.framing;

  Future<void> _capture() async {
    setState(() => _stage = _IdStage.scanning);
    await Future<void>.delayed(K.scanDelay);
    if (!mounted) return;
    setState(() => _stage = _IdStage.verified);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return OnboardingScaffold(
      step: 2,
      title: s.t('id_title'),
      subtitle: s.t('id_sub'),
      actionLabel: switch (_stage) {
        _IdStage.framing => s.t('id_capture'),
        _IdStage.scanning => s.t('id_scanning'),
        _IdStage.verified => s.t('continue'),
      },
      loading: _stage == _IdStage.scanning,
      onAction: switch (_stage) {
        _IdStage.framing => _capture,
        _IdStage.scanning => null,
        _IdStage.verified => () => context.push('/onboarding/risk'),
      },
      child: Column(
        children: [
          _CameraFrame(stage: _stage),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_stage) {
              _IdStage.framing => Text(
                s.t('id_frame_hint'),
                key: const ValueKey('framing'),
                style: context.tt.bodySmall,
              ),
              _IdStage.scanning => Row(
                key: const ValueKey('scanning'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(s.t('id_scanning'), style: context.tt.bodySmall),
                ],
              ),
              _IdStage.verified => Row(
                key: const ValueKey('verified'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: K.gain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.t('id_verified'),
                    style: context.tt.titleSmall?.copyWith(color: K.gain),
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _CameraFrame extends StatefulWidget {
  final _IdStage stage;
  const _CameraFrame({required this.stage});

  @override
  State<_CameraFrame> createState() => _CameraFrameState();
}

class _CameraFrameState extends State<_CameraFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.stage == _IdStage.verified;
    final scanning = widget.stage == _IdStage.scanning;
    final accent = verified ? K.gain : context.cs.primary;

    return AspectRatio(
      aspectRatio: 1.58, // ID-card proportions
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFFE7ECF6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Placeholder card artwork.
            Center(
              child: Opacity(
                opacity: verified ? 0.35 : 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 42, color: context.muted),
                    const SizedBox(height: 10),
                    Container(
                      width: 130,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.muted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: 92,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.muted.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (scanning)
              AnimatedBuilder(
                animation: _scan,
                builder: (context, _) => Align(
                  alignment: Alignment(0, _scan.value * 2 - 1),
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0),
                          accent,
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (verified)
              Container(
                color: K.gain.withValues(alpha: 0.10),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 54,
                    color: K.gain,
                  ),
                ),
              ),
            // Corner brackets.
            for (final a in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: a,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _Corner(alignment: a, color: accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  const _Corner({required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    final top = alignment.y < 0;
    final left = alignment.x < 0;
    final side = BorderSide(color: color, width: 2.5);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}
