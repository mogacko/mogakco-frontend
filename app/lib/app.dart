import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'shared/widgets/mobile_frame.dart';

class MogackoApp extends ConsumerWidget {
  const MogackoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '모각코',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 기본은 기기 설정을 따르고, 내 정보에서 바꿀 수 있다.
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
      // 웹에서 마우스로도 캐러셀을 넘길 수 있게 한다.
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        // 기기 글꼴 크기를 과하게 키워도 레이아웃이 깨지지 않도록 상한을 둔다.
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          // 넓은 화면에서도 폰 폭으로 잡아 둔다.
          child: MobileFrame(child: child!),
        );
      },
    );
  }
}
