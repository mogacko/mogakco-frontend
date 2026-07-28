import 'package:flutter/cupertino.dart';

import '../../domain/meetup.dart';

/// 참여를 정하기 전에 일정을 한 번 더 보여준다.
///
/// 버튼 한 번에 신청이 나가면 잘못 눌렀을 때 되돌릴 방법이 없다. 어디서
/// 언제 모이는지 확인하고 나서 결정하게 한다. 취소할 때도 마찬가지다.
///
/// 확인하면 true, 물러나면 false를 돌려준다.
Future<bool> confirmJoinChange(
  BuildContext context, {
  required Meetup meetup,
  required MeetupSession session,
  required DateTime now,
}) async {
  final leaving = session.isJoined;

  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => CupertinoAlertDialog(
      title: Text(leaving ? '참여를 취소할까요?' : '이 일정으로 참여할까요?'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Text(meetup.placeName),
            const SizedBox(height: 2),
            Text(meetup.shortAddress),
            const SizedBox(height: 6),
            Text(session.whenLabel(now)),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('닫기'),
        ),
        CupertinoDialogAction(
          // 취소는 되돌리기 어려운 쪽이라 빨갛게 둔다.
          isDestructiveAction: leaving,
          isDefaultAction: !leaving,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(leaving ? '참여 취소' : '참여하기'),
        ),
      ],
    ),
  );

  return result ?? false;
}
