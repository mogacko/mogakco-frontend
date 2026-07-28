import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/mobile_frame.dart';

class MogackoApp extends StatelessWidget {
  const MogackoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '모각코',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 시스템 설정을 따른다. 앱 내 테마 전환은 설정 화면이 생길 때 붙인다.
      themeMode: ThemeMode.system,
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
