import 'package:flutter/material.dart';

/// 사람을 나타내는 동그란 이미지.
///
/// 프로필 사진이 있으면 그것을, 없거나 못 불러오면 닉네임 첫 글자를 보여준다.
/// 소셜 로그인으로 받아오는 사진은 언제든 빠지거나 깨질 수 있어서 대체 표시가
/// 늘 필요하다.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
    this.background,
    this.foreground,
  });

  final String name;
  final double size;

  /// 프로필 사진. 없으면 이니셜로 대신한다.
  final String? imageUrl;

  final Color? background;
  final Color? foreground;

  /// 닉네임에서 뽑은 한 글자.
  ///
  /// 한글은 첫 글자를 그대로 쓰고, 라틴 문자는 대문자로 올린다.
  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ?? theme.colorScheme.surfaceContainerHighest;
    final fg = foreground ?? theme.colorScheme.onSurface;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: bg,
          child: imageUrl == null
              ? _Initial(text: _initial, size: size, color: fg)
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  // 사진을 못 가져와도 자리가 비지 않게 이니셜로 되돌린다.
                  errorBuilder: (context, _, _) =>
                      _Initial(text: _initial, size: size, color: fg),
                ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.text, required this.size, required this.color});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          // 원 안에 들어가도록 지름에 비례해 잡는다.
          fontSize: size * 0.46,
          height: 1,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
