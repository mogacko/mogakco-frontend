import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_height_scroll_view.dart';
import '../../../shared/widgets/mogacko_logo.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// 애플 로그인도 함께 세운다.
  ///
  /// iOS 가 아직 PWA 라도 안드로이드·웹에서 쓸 수 있다. 애플은 이때 앱 안에서
  /// 바로 뜨지 않고 Services ID 로 애플 사이트를 거쳐 돌아오는데, 그 돌아올
  /// 주소가 서버에 있어야 한다.
  ///
  /// 나중에 iOS 를 네이티브로 돌릴 때는 선택이 아니다 — 다른 소셜 로그인을
  /// 두고 애플만 빼면 앱스토어 심사에서 걸린다.
  static const _showAppleLogin = true;

  void _onSocialTap(BuildContext context, SocialProvider provider) {
    // 실제 OAuth 연동은 다음 스프린트 범위다.
    // 지금은 신규 가입자 흐름을 그대로 태워 화면 전환만 확인한다.
    context.push(AppRoute.signupTerms);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FullHeightScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const _Header(),
              const Spacer(flex: 3),
              _SocialButtons(
                showApple: _showAppleLogin,
                onTap: (provider) => _onSocialTap(context, provider),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _TermsNotice(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MogackoLogo.horizontal(size: 40),
        const SizedBox(height: AppSpacing.xxl),
        Text('혼자 하면 미루던 일도\n같이 앉으면 됩니다', style: context.texts.headlineLarge),
        const SizedBox(height: AppSpacing.md),
        Text(
          '모각코와 함께 오늘 자리를 잡아보세요',
          style: context.texts.bodyLarge?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.showApple, required this.onTap});

  final bool showApple;
  final ValueChanged<SocialProvider> onTap;

  @override
  Widget build(BuildContext context) {
    final providers = [
      SocialProvider.kakao,
      SocialProvider.google,
      if (showApple) SocialProvider.apple,
    ];

    return Column(
      // 버튼이 화면 폭을 채우도록 강제한다. 빠뜨리면 라벨 크기로 줄어든다.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final provider in providers) ...[
          SocialLoginButton(
            provider: provider,
            onPressed: () => onTap(provider),
          ),
          if (provider != providers.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.texts.labelSmall;
    final link = base?.copyWith(
      color: colors.textSecondary,
      decoration: TextDecoration.underline,
      decorationColor: colors.textTertiary,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '이용약관', style: link),
          const TextSpan(text: ' 및 '),
          TextSpan(text: '개인정보 처리방침', style: link),
          const TextSpan(text: '에 동의합니다'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
