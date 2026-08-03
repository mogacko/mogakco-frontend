import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/navigation.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/form_field_block.dart';
import '../../../shared/widgets/tag_input_field.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../signup/domain/profile_options.dart';
import 'profile_provider.dart';

/// 프로필 수정.
///
/// 가입 때 받는 항목과 같다. 다만 지역은 없다 — 지부를 옮기는 건 프로필을
/// 고치는 일이 아니라 옮겨 가는 일이라, 슬쩍 바뀌면 안 되는 자리다.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  static const _minLength = 2;
  static const _maxLength = 12;

  late final TextEditingController _nickname;
  late final TextEditingController _bio;
  late final TextEditingController _affiliation;

  String? _field;
  late Set<String> _stacks;
  late Set<String> _interests;

  @override
  void initState() {
    super.initState();
    // 지금 값으로 칸을 채워 연다. 빈 폼을 주면 안 고칠 것까지 다시 적어야 한다.
    final profile = ref.read(profileProvider);
    _nickname = TextEditingController(text: profile.nickname);
    _bio = TextEditingController(text: profile.bio ?? '');
    _affiliation = TextEditingController(text: profile.affiliation ?? '');
    _field = profile.field;
    _stacks = profile.stacks.toSet();
    _interests = profile.interests.toSet();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    _affiliation.dispose();
    super.dispose();
  }

  String get _name => _nickname.text.trim();

  /// 유효하면 null, 아니면 사용자에게 보여줄 사유.
  ///
  /// 가입 때와 같은 규칙이다. 여기서만 느슨하면 가입은 막히고 수정으로는
  /// 되는 이름이 생긴다.
  String? get _nicknameError {
    if (_name.isEmpty) return null;
    if (_name.length < _minLength) return '$_minLength자 이상 입력해 주세요';
    if (!RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(_name)) {
      return '한글, 영문, 숫자, 밑줄만 사용할 수 있어요';
    }
    return null;
  }

  /// 분야는 비울 수 있지만 비운 채로 저장할 수는 없다. 가입 때 받는 필수
  /// 항목이라, 수정으로 지워지면 가입으로는 만들 수 없는 프로필이 생긴다.
  bool get _canSave =>
      _name.length >= _minLength && _nicknameError == null && _field != null;

  void _save() {
    ref
        .read(profileProvider.notifier)
        .save(
          ref
              .read(profileProvider)
              .copyWith(
                nickname: _name,
                field: _field!,
                bio: _bio.text,
                affiliation: _affiliation.text,
                stacks: _stacks.toList(),
                interests: _interests.toList(),
              ),
        );

    Haptics.decide();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('프로필을 저장했어요'),
          duration: Duration(seconds: 2),
        ),
      );
    goBack(context);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return DetailScaffold(
      title: '프로필 수정',
      bottomAction: FilledButton(
        onPressed: _canSave ? _save : null,
        child: const Text('저장'),
      ),
      children: [
        Center(
          child: UserAvatar(
            name: _name.isEmpty ? profile.nickname : _name,
            imageUrl: profile.avatarUrl,
            size: 80,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormFieldBlock(
                label: '닉네임',
                child: TextField(
                  key: const Key('nickname-input'),
                  controller: _nickname,
                  onChanged: (_) => setState(() {}),
                  maxLength: _maxLength,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '$_minLength~$_maxLength자로 입력해 주세요',
                    errorText: _nicknameError,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FormFieldBlock(
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
              FormFieldBlock(
                label: '자기소개',
                optional: true,
                child: TextField(
                  key: const Key('bio-input'),
                  controller: _bio,
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
              FormFieldBlock(
                label: '소속',
                optional: true,
                child: TextField(
                  key: const Key('affiliation-input'),
                  controller: _affiliation,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '예) 부산대학교 / 프리랜서',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FormFieldBlock(
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
              FormFieldBlock(
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
            ],
          ),
        ),
      ],
    );
  }
}
