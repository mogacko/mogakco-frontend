import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import 'meetup_create_screen.dart';
import 'meetup_provider.dart';

/// 모각코 고치기.
///
/// 모임을 먼저 찾아 없으면 여기서 끊는다. 만들기 화면에 그대로 넘기면 빈 폼이
/// 열려, 고치러 들어온 사람이 새로 여는 화면을 보게 된다.
class MeetupEditScreen extends ConsumerWidget {
  const MeetupEditScreen({super.key, required this.meetupId});

  final String meetupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetup = ref
        .watch(meetupListProvider)
        .where((meetup) => meetup.id == meetupId)
        .firstOrNull;

    if (meetup == null) {
      return const DetailScaffold(
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.person_2,
              title: '모각코를 찾을 수 없어요',
              description: '닫혔거나 지워진 모임일 수 있어요',
            ),
          ),
        ],
      );
    }

    return MeetupCreateScreen(meetupId: meetupId);
  }
}
