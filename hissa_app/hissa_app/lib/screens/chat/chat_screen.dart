import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    context.read<ChatProvider>().send(text, isAr: context.s.isAr);
    _input.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sub = context.watch<SubscriptionProvider>();
    final chat = context.watch<ChatProvider>();

    // Rebuild after the bot answers so the view follows the new bubble.
    if (!chat.typing && chat.messages.isNotEmpty) _scrollToEnd();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [K.royal, K.navy]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.t('advisor'),
                    style: context.tt.titleSmall?.copyWith(fontSize: 15),
                  ),
                  Text(
                    s.t('advisor_disclaimer'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tt.labelSmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (sub.canUseAdvisor && !chat.isEmpty)
            IconButton(
              onPressed: chat.clear,
              icon: const Icon(Icons.delete_outline_rounded, size: 21),
              tooltip: s.t('clear_chat'),
            ),
        ],
      ),
      body: sub.canUseAdvisor
          ? _ChatBody(chat: chat, scroll: _scroll, input: _input, onSend: _send)
          : const _LockedState(),
    );
  }
}

class _ChatBody extends StatelessWidget {
  final ChatProvider chat;
  final ScrollController scroll;
  final TextEditingController input;
  final void Function([String?]) onSend;

  const _ChatBody({
    required this.chat,
    required this.scroll,
    required this.input,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: chat.isEmpty
              ? _EmptyChat(onPick: onSend)
              : ListView.builder(
                  controller: scroll,
                  padding: K.pagePad.add(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  itemCount: chat.messages.length + (chat.typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == chat.messages.length) return const _TypingBubble();
                    return _Bubble(message: chat.messages[i]);
                  },
                ),
        ),
        _InputBar(
          controller: input,
          enabled: !chat.typing,
          onSend: () => onSend(),
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function([String?]) onPick;
  const _EmptyChat({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final isAr = context.s.isAr;
    return ListView(
      padding: K.pagePad.add(const EdgeInsets.symmetric(vertical: 26)),
      children: [
        Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [K.royal, K.navy]),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.s.t('chat_empty'),
          textAlign: TextAlign.center,
          style: context.tt.titleSmall,
        ),
        const SizedBox(height: 22),
        for (final (ar, en) in ChatService.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _SuggestionChip(
              label: isAr ? ar : en,
              onTap: () => onPick(isAr ? ar : en),
            ),
          ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.cs.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: context.cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    final bg = fromUser
        ? context.cs.primary
        : (context.isDark ? K.darkSurface : Colors.white);
    final fg = fromUser ? Colors.white : context.cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: fromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [K.royal, K.navy]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: fromUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: const Radius.circular(16),
                      topEnd: const Radius.circular(16),
                      bottomStart: Radius.circular(fromUser ? 16 : 4),
                      bottomEnd: Radius.circular(fromUser ? 4 : 16),
                    ),
                    border: fromUser
                        ? null
                        : Border.all(color: context.cs.outlineVariant),
                  ),
                  child: Text(
                    message.text,
                    style: context.tt.bodyMedium?.copyWith(
                      color: fg,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    Fmt.dateTime(message.at),
                    style: context.tt.labelSmall?.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [K.royal, K.navy]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.isDark ? K.darkSurface : Colors.white,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(16),
                topEnd: Radius.circular(16),
                bottomStart: Radius.circular(4),
                bottomEnd: Radius.circular(16),
              ),
              border: Border.all(color: context.cs.outlineVariant),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = ((_c.value + i * 0.22) % 1.0);
                    final lift = (t < 0.5 ? t : 1 - t) * 2;
                    return Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                      child: Transform.translate(
                        offset: Offset(0, -lift * 3),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: context.muted.withValues(
                              alpha: 0.4 + lift * 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surface,
        border: Border(top: BorderSide(color: context.cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.s.t(enabled ? 'type_message' : 'typing'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: enabled ? context.cs.primary : context.cs.outlineVariant,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: enabled ? onSend : null,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The paywall, made demoable: on Free the advisor is visible but locked.
class _LockedState extends StatelessWidget {
  const _LockedState();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Center(
      child: SingleChildScrollView(
        padding: K.pagePad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: K.amber.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 33, color: K.amber),
            ),
            const SizedBox(height: 22),
            Text(
              s.t('chat_locked_title'),
              textAlign: TextAlign.center,
              style: context.tt.titleLarge?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              s.t('chat_locked_body'),
              textAlign: TextAlign.center,
              style: context.tt.bodyMedium?.copyWith(
                color: context.muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 26),
            HissaCard(
              outlined: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (ar, en) in ChatService.suggestions.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: context.muted,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              s.isAr ? ar : en,
                              style: context.tt.bodySmall?.copyWith(
                                fontSize: 12.5,
                                color: context.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/plans'),
                style: FilledButton.styleFrom(
                  backgroundColor: K.amber,
                  foregroundColor: const Color(0xFF3A2604),
                ),
                child: Text(s.t('see_plans')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
