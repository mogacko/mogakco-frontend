import '../../../shared/domain/chapter.dart';
import '../domain/event.dart';
import '../domain/poster.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
///
/// 포스터는 자리를 채우려고 가져다 쓰는 임의 이미지다. 실제 포스터는
/// 지부가 올린 것을 서버가 내려준다. 일부러 하나(busan-e4)는 비워 두어
/// 포스터 없는 행사의 표시도 함께 확인한다.
abstract final class MockEvents {
  /// [now]를 기준으로 다가오는 행사를 만든다.
  ///
  /// 날짜를 박아두면 하루만 지나도 전부 지난 행사가 되어 화면이 빈다.
  /// 오늘로부터 상대로 잡고 시각만 고정한다.
  static List<Event> from(DateTime now) {
    DateTime at(int afterDays, int hour) {
      final base = DateTime(now.year, now.month, now.day);
      return base.add(Duration(days: afterDays)).copyWith(hour: hour);
    }

    return [
      Event(
        id: 'busan-e1',
        chapter: Chapter.busan,
        kind: EventKind.seminar,
        title: 'Flutter 렌더링 파이프라인 뜯어보기',
        summary: '위젯이 화면에 그려지기까지 무슨 일이 일어나는지 코드로 따라갑니다. 노트북을 가져오세요.',
        venue: '부산 이노베이션 아카데미 세미나실',
        startsAt: at(5, 14),
        endsAt: at(5, 17),
        applyBy: at(3, 23),
        poster: const RemotePoster('https://picsum.photos/seed/seminar-flutter/240/240'),
        capacity: 40,
        applicantCount: 27,
      ),
      Event(
        id: 'busan-e2',
        chapter: Chapter.busan,
        kind: EventKind.networking,
        title: '7월 모각코 번개 — 광안리 야간 산책',
        summary: '코딩은 잠시 접고 걷습니다. 처음 오신 분도 편하게 오세요.',
        venue: '광안리 해수욕장 입구',
        startsAt: at(2, 19),
        endsAt: at(2, 21),
        applyBy: at(1, 18),
        poster: const RemotePoster('https://picsum.photos/seed/gwangalli-night/240/240'),
        capacity: 20,
        applicantCount: 18,
        isApplied: true,
      ),
      Event(
        id: 'busan-e3',
        chapter: Chapter.busan,
        kind: EventKind.hackathon,
        title: '부산 모각코 여름 해커톤',
        summary: '무박 2일로 팀을 짜서 하나를 끝까지 만듭니다. 식사와 간식이 제공됩니다.',
        venue: '센텀 스페이스',
        startsAt: at(21, 10),
        endsAt: at(22, 16),
        applyBy: at(14, 23),
        poster: const RemotePoster('https://picsum.photos/seed/summer-hackathon/240/240'),
        capacity: 60,
        applicantCount: 31,
        fee: 15000,
      ),
      Event(
        id: 'busan-e4',
        chapter: Chapter.busan,
        kind: EventKind.retrospective,
        title: '상반기 회고 모임',
        summary: '올해 절반을 어떻게 보냈는지 각자 정리하고 나눕니다.',
        venue: '동래 공유오피스 라운지',
        startsAt: at(9, 15),
        endsAt: at(9, 18),
        applyBy: at(7, 23),
        capacity: 16,
        applicantCount: 16,
      ),
      Event(
        id: 'busan-e5',
        chapter: Chapter.busan,
        kind: EventKind.seminar,
        title: 'PostgreSQL 실행 계획 읽는 법',
        summary: 'EXPLAIN 결과를 보고 어디가 느린지 짚어냅니다. SQL을 써본 적 있으면 충분합니다.',
        venue: '센텀 스페이스',
        startsAt: at(12, 19),
        endsAt: at(12, 21),
        applyBy: at(10, 23),
        capacity: 30,
        applicantCount: 11,
      ),
      Event(
        id: 'busan-e6',
        chapter: Chapter.busan,
        kind: EventKind.networking,
        title: '이직 이야기 나누는 자리',
        summary: '최근 옮긴 분들이 어떻게 준비했는지 짧게 말하고 나머지는 자유롭게 묻습니다.',
        venue: '동래 공유오피스 라운지',
        startsAt: at(9, 19),
        endsAt: at(9, 21),
        applyBy: at(8, 23),
        capacity: 24,
        applicantCount: 19,
      ),
      Event(
        id: 'busan-e7',
        chapter: Chapter.busan,
        kind: EventKind.retrospective,
        title: '상반기 회고 모임',
        summary: '올해 절반을 어떻게 보냈는지 각자 정리해 오고 서로 질문합니다.',
        venue: '토즈 스터디센터 서면점',
        startsAt: at(16, 14),
        endsAt: at(16, 17),
        applyBy: at(14, 23),
        poster: const RemotePoster('https://picsum.photos/seed/retro-half/240/240'),
        capacity: 20,
        applicantCount: 6,
      ),
      Event(
        id: 'busan-e8',
        chapter: Chapter.busan,
        kind: EventKind.other,
        title: '개발자 사진 촬영회',
        summary: '프로필 사진 한 장씩 찍습니다. 이력서에 쓸 만한 걸로요.',
        venue: '광안리 해수욕장 입구',
        startsAt: at(20, 15),
        endsAt: at(20, 18),
        applyBy: at(18, 23),
        capacity: 15,
        applicantCount: 4,
        fee: 15000,
      ),
      Event(
        id: 'seoul-e1',
        chapter: Chapter.seoul,
        kind: EventKind.seminar,
        title: '실전 이력서 클리닉',
        summary: '현직 채용 담당자와 함께 이력서를 한 줄씩 고칩니다. 초안을 미리 준비해 오세요.',
        venue: '성수 코워킹 스페이스 3층',
        startsAt: at(4, 19),
        endsAt: at(4, 22),
        applyBy: at(2, 23),
        poster: const RemotePoster('https://picsum.photos/seed/resume-clinic/240/240'),
        capacity: 24,
        applicantCount: 22,
      ),
      Event(
        id: 'seoul-e2',
        chapter: Chapter.seoul,
        kind: EventKind.networking,
        title: '사이드 프로젝트 팀 빌딩 데이',
        summary: '만들고 싶은 걸 3분씩 소개하고 팀을 짜는 자리입니다.',
        venue: '합정 스터디홀 대강의실',
        startsAt: at(11, 14),
        endsAt: at(11, 18),
        applyBy: at(9, 23),
        poster: const RemotePoster('https://picsum.photos/seed/team-building/240/240'),
        capacity: 50,
        applicantCount: 12,
      ),
      Event(
        id: 'seoul-e3',
        chapter: Chapter.seoul,
        kind: EventKind.hackathon,
        title: '주말 미니 해커톤 — 하루 만에 배포까지',
        summary: '아침에 시작해 저녁에 배포합니다. 규모보다 완성이 목표입니다.',
        venue: '역삼 디캠프',
        startsAt: at(17, 9),
        endsAt: at(17, 21),
        applyBy: at(12, 23),
        poster: const RemotePoster('https://picsum.photos/seed/mini-hackathon/240/240'),
        capacity: 30,
        applicantCount: 8,
        fee: 10000,
      ),
    ];
  }
}
