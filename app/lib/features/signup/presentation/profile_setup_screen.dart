import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_height_scroll_view.dart';
import '../../../shared/widgets/tag_input_field.dart';
import '../domain/profile_options.dart';
import 'widgets/signup_progress.dart';

/// 프로필 입력.
///
/// 필수는 닉네임과 분야다. 이 둘은 모임에서 상대를 알아보는 최소 정보라
/// 받아두고, 나머지는 나중에 채우게 한다.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _minLength = 2;
  static const _maxLength = 12;

  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _affiliationController = TextEditingController();

  final _stacks = <String>{};
  final _interests = <String>{};

  /// 분야는 하나만 담는다. 목록에 없으면 직접 적을 수 있다.
  String? _field;

  /// 입력을 시작하기 전에는 오류를 띄우지 않는다.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController
      ..removeListener(_onNicknameChanged)
      ..dispose();
    _bioController.dispose();
    _affiliationController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() => setState(() => _touched = true);

  String get _nickname => _nicknameController.text.trim();

  /// 유효하면 null, 아니면 사용자에게 보여줄 사유.
  String? get _nicknameError {
    if (!_touched || _nickname.isEmpty) return null;
    if (_nickname.length < _minLength) return '$_minLength자 이상 입력해 주세요';
    if (!RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(_nickname)) {
      return '한글, 영문, 숫자, 밑줄만 사용할 수 있어요';
    }
    return null;
  }

  /// 닉네임과 분야가 채워져야 가입할 수 있다. 지역은 앞 단계에서 이미 받는다.
  bool get _canProceed =>
      _nickname.length >= _minLength &&
      _nicknameError == null &&
      _field != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: FullHeightScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SignupProgress(step: 3),
              const SizedBox(height: AppSpacing.xxl),
              Text('프로필을 알려주세요', style: context.texts.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                '닉네임과 분야만 정하면 시작할 수 있어요',
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              const Center(child: _AvatarPicker()),
              const SizedBox(height: AppSpacing.xxxl),
              _Field(
                label: '닉네임',
                child: TextField(
                  controller: _nicknameController,
                  maxLength: _maxLength,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '2~12자로 입력해 주세요',
                    errorText: _nicknameError,
                    counterText: '',
                    suffixIcon: _canProceed
                        ? Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: colors.primary,
                            size: AppSize.iconMd,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                label: '분야',
                hint: '하나만',
                child: TagInputField(
                  key: const Key('field-input'),
                  suggestions: ProfileOptions.fields,
                  selected: _field == null ? const {} : {_field!},
                  hintText: '예) 백엔드 — 개발이 아니어도 괜찮아요',
                  maxTags: 1,
                  onAdd: (value) => setState(() => _field = value),
                  onRemove: (_) => setState(() => _field = null),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                label: '자기소개',
                child: TextField(
                  controller: _bioController,
                  maxLength: 60,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '예) 백엔드 공부 중이고 사이드 프로젝트 같이 할 사람 찾아요',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                label: '소속',
                optional: true,
                child: TextField(
                  controller: _affiliationController,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '예) 부산대학교 / 프리랜서',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                label: '스택',
                optional: true,
                child: TagInputField(
                  key: const Key('stack-input'),
                  suggestions: ProfileOptions.stacks,
                  selected: _stacks,
                  hintText: '예) Spring — 입력하면 추천이 떠요',
                  onAdd: (value) => setState(() => _stacks.add(value)),
                  onRemove: (value) => setState(() => _stacks.remove(value)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Field(
                label: '관심분야',
                optional: true,
                child: TagInputField(
                  key: const Key('interest-input'),
                  suggestions: ProfileOptions.interests,
                  selected: _interests,
                  hintText: '예) 사이드 프로젝트',
                  maxTags: 6,
                  onAdd: (value) => setState(() => _interests.add(value)),
                  onRemove: (value) => setState(() => _interests.remove(value)),
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              FilledButton(
                onPressed: _canProceed
                    ? () => context.push(AppRoute.signupComplete)
                    : null,
                child: const Text('가입 완료'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 라벨 + 입력 요소 묶음.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.optional = false,
    this.hint,
  });

  final String label;
  final Widget child;
  final bool optional;

  /// 라벨 옆에 덧붙일 짧은 안내. 선택 규칙이 자명하지 않을 때만 쓴다.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: context.texts.labelMedium),
            if (optional) ...[
              const SizedBox(width: AppSpacing.xs),
              Text('선택', style: context.texts.labelSmall),
            ],
            if (hint != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(hint!, style: context.texts.labelSmall),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// 프로필 이미지 선택 자리.
///
/// image_picker 연동은 다음 스프린트 범위라 지금은 기본 아바타만 보여준다.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              CupertinoIcons.person,
              size: 44,
              color: colors.textTertiary,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 2),
              ),
              child: Icon(
                CupertinoIcons.camera_fill,
                size: AppSize.iconSm,
                color: colors.primaryForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
