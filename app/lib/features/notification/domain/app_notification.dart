import '../../../shared/domain/chapter.dart';

/// 알림의 종류.
///
/// 종류마다 아이콘과 색을 달리해서, 목록을 훑을 때 글자를 읽기 전에 무슨
/// 알림인지 먼저 걸러지게 한다.
enum NotificationKind {
  /// 내 글·모임·행사에 댓글이 달림
  comment('댓글', '내 글과 모임에 댓글이 달렸을 때'),

  /// 내 글에 좋아요
  like('좋아요', '내 글에 좋아요가 눌렸을 때'),

  /// 내가 연 모임에 누가 들어옴
  join('참여', '내가 연 모임에 누가 들어왔을 때'),

  /// 참여하기로 한 모임이 곧 시작
  upcoming('모임 임박', '참여하기로 한 모임이 다가왔을 때'),

  /// 운영진 공지
  notice('공지', '지부 운영진이 공지를 올렸을 때');

  const NotificationKind(this.label, this.description);

  final String label;

  /// 설정 화면에서 무엇을 끄고 켜는지 한 줄로 밝힌다.
  ///
  /// '댓글'만 적어두면 내가 단 댓글인지 내 글에 달린 댓글인지 알 수 없어,
  /// 끄기가 겁나서 그냥 다 켜두게 된다.
  final String description;
}

/// 알림 한 줄.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.chapter,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.body,
    this.route,
    this.isRead = false,
  });

  final String id;

  /// 알림이 난 지역. 지역을 바꾸면 그 지역 알림만 보인다.
  final Chapter chapter;

  final NotificationKind kind;

  /// 무슨 일이 났는지 한 줄. '오하이오님이 회원님의 글에 댓글을 달았어요'
  final String title;

  /// 댓글 내용처럼 딸려 오는 말. 없을 수 있다.
  ///
  /// 이게 있으면 열어보지 않고도 무슨 댓글인지 안다. 알림을 눌러 들어가는
  /// 횟수가 줄어드는 만큼 목록에서 값을 다 주는 편이 낫다.
  final String? body;

  /// 눌렀을 때 갈 곳. 없으면 읽음 표시만 된다.
  final String? route;

  final DateTime createdAt;

  final bool isRead;

  AppNotification markRead() => AppNotification(
    id: id,
    chapter: chapter,
    kind: kind,
    title: title,
    createdAt: createdAt,
    body: body,
    route: route,
    isRead: true,
  );
}
