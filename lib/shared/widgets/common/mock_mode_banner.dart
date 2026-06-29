import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purple_tomato/core/providers/upstox_auth_provider.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';

/// A dismissible banner shown at the top of the home screen when the app is
/// running in demo/mock mode (no Upstox access token present).
///
/// Informs the user that live market data is unavailable and guides them to
/// connect their Upstox account for real-time prices.
class MockModeBanner extends ConsumerStatefulWidget {
  const MockModeBanner({super.key});

  @override
  ConsumerState<MockModeBanner> createState() => _MockModeBannerState();
}

class _MockModeBannerState extends ConsumerState<MockModeBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMock = ref.watch(isMockModeProvider);

    if (!isMock || _dismissed) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
        decoration: BoxDecoration(
          color: AppTheme.warningSubtle,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppTheme.warningDefault.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.warningDefault,
              size: 18,
            ),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: AppTheme.warningDefault,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'Demo mode — ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: 'Using simulated prices. Connect Upstox for live market data.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            GestureDetector(
              onTap: _dismiss,
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.warningDefault,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
