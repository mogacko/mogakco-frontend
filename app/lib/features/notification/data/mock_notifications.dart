import '../../../core/router/app_router.dart';
import '../../../shared/domain/chapter.dart';
import '../domain/app_notification.dart';

/// 알림 목업.
///
/// 실제로는 서버가 밀어 준다. 여기서는 목업 글·모임·행사를 가리키게 해서
/// 눌렀을 때 진짜 상세로 들어가는지까지 확인할 수 있게 둔다.
abstract final class MockNotifications {
  static List<AppNotification> from(DateTime now) => [
    AppNotification(
      id: 'busan-n1',
      chapter: Chapter.busan,
      kind: NotificationKind.comment,
      title: '해달님이 회원님의 글에 댓글을 달았어요',
      body: '저도 그 부분에서 막혔었는데 이렇게 푸셨군요',
      route: AppRoute.post('busan-t1'),
      createdAt: now.subtract(const Duration(minutes: 14)),
    ),
    AppNotification(
      id: 'busan-n2',
      chapter: Chapter.busan,
      kind: NotificationKind.upcoming,
      title: '내일 모모스커피 온천장 모각코가 열려요',
      body: '19:00 시작 · 8명 중 6명',
      route: AppRoute.meetup('busan-1'),
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'busan-n6',
      chapter: Chapter.busan,
      kind: NotificationKind.cancelled,
      title: '초량1941 모각코가 취소됐어요',
      body: '장소 문제 — 자리를 못 잡았거나 카페가 문을 닫아요',
      route: AppRoute.meetup('busan-4'),
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
    AppNotification(
      id: 'busan-n3',
      chapter: Chapter.busan,
      kind: NotificationKind.like,
      title: '회원님의 글을 3명이 좋아합니다',
      route: AppRoute.post('busan-t2'),
      createdAt: now.subtract(const Duration(hours: 9)),
    ),
    AppNotification(
      id: 'busan-n4',
      chapter: Chapter.busan,
      kind: NotificationKind.notice,
      title: '8월 정기 모임 일정이 올라왔어요',
      body: '이번 달은 매주 토요일 오후에 모입니다',
      route: AppRoute.post('busan-n1'),
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'busan-n5',
      chapter: Chapter.busan,
      kind: NotificationKind.join,
      title: '회원님이 연 모각코에 두부님이 참여했어요',
      route: AppRoute.meetup('busan-3'),
      createdAt: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 'seoul-n1',
      chapter: Chapter.seoul,
      kind: NotificationKind.comment,
      title: '민트님이 회원님의 글에 댓글을 달았어요',
      body: '이번 주에 시간 되시면 같이 가요',
      route: AppRoute.post('seoul-t1'),
      createdAt: now.subtract(const Duration(minutes: 42)),
    ),
    AppNotification(
      id: 'seoul-n2',
      chapter: Chapter.seoul,
      kind: NotificationKind.upcoming,
      title: '오늘 스터디홀 합정 모각코가 열려요',
      body: '14:00 시작 · 10명 중 7명',
      route: AppRoute.meetup('seoul-2'),
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 'seoul-n3',
      chapter: Chapter.seoul,
      kind: NotificationKind.notice,
      title: '서울 지부 오픈 안내',
      body: '이제 서울에서도 모각코가 열립니다',
      route: AppRoute.post('seoul-n1'),
      createdAt: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}
