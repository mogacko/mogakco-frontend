import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 화면 모드에 붙일 이름.
///
/// [ThemeMode] 는 프레임워크 것이라 한국어 이름을 여기서 얹는다.
extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => '시스템 설정',
    ThemeMode.light => '라이트',
    ThemeMode.dark => '다크',
  };

  /// 고르는 자리에서 왜 그런지 한 줄.
  String get description => switch (this) {
    ThemeMode.system => '기기 설정을 따라갑니다',
    ThemeMode.light => '항상 밝게',
    ThemeMode.dark => '항상 어둡게',
  };
}

/// 앱이 쓸 화면 모드.
///
/// 기본은 기기 설정을 따른다. 대부분은 기기에서 한 번 정하고 앱마다 다시
/// 정하지 않는다.
///
/// 아직 기억하지 않는다. 앱을 다시 켜면 시스템 설정으로 돌아간다. 저장하려면
/// 기기에 값을 남기는 의존성이 하나 더 필요하다.
class AppThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(
  AppThemeMode.new,
);
