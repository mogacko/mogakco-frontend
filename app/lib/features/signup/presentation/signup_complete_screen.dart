import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mogacko_logo.dart';

class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({super.key});

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final scale = Tween(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              Center(
                child: ScaleTransition(
                  scale: scale,
                  child: const MogackoLogo.square(size: 96),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                '환영합니다',
                style: context.texts.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '이제 모각코를 둘러보고 참여할 수 있어요',
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              FilledButton(
                onPressed: () => context.go(AppRoute.home),
                child: const Text('시작하기'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
