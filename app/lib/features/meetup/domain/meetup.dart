import '../../../shared/domain/chapter.dart';

/// 모임 안의 하루.
///
/// 한 모임이 토·일처럼 여러 날에 걸쳐 열리고, 참여는 날마다 따로 정한다.
/// 토요일만 가고 일요일은 빠지는 식이 되므로 정원과 인원도 날짜별로 센다.
class MeetupSession {
  const MeetupSession({
    required this.id,
    required this.startsAt,
    required this.participantCount,
    required this.capacity,
    this.isJoined = false,
  });

  final String id;

  /// 이 날의 시작 시각
  final DateTime startsAt;

  final int participantCount;
  final int capacity;

  /// 내가 이 날에 참여하기로 했는지
  final bool isJoined;

  bool get isFull => participantCount >= capacity;

  /// 남은 자리
  int get remaining => (capacity - participantCount).clamp(0, capacity);

  /// 오늘부터 며칠 뒤인지. 오늘이면 0, 지난 날이면 음수.
  ///
  /// 시:분을 떼고 날짜만 견준다. 오늘 저녁 모임을 '내일'로 세지 않기 위해서다.
  int daysFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
    return day.difference(today).inDays;
  }

  /// 'HH:mm'
  String get timeLabel =>
      '${startsAt.hour.toString().padLeft(2, '0')}:'
      '${startsAt.minute.toString().padLeft(2, '0')}';

  /// 요일 한 글자
  String get weekdayLabel =>
      const ['월', '화', '수', '목', '금', '토', '일'][startsAt.weekday - 1];

  /// 화면에 보여줄 시점. '오늘 19:00'처럼 읽힌다.
  ///
  /// 요일 대신 남은 날로 적는다. 며칠 뒤인지가 참여를 정하는 데 더 직접적이고,
  /// '수요일'은 오늘이 무슨 요일인지 먼저 떠올려야 한다.
  ///
  /// 하루만 따로 세울 때 쓴다. 한 주를 한꺼번에 늘어놓는 자리에서는
  /// [dayLabel] 쪽이 맞다.
  String whenLabel(DateTime now) {
    final days = daysFrom(now);

    return switch (days) {
      0 => '오늘 $timeLabel',
      1 => '내일 $timeLabel',
      _ => '$days일 뒤 $timeLabel',
    };
  }

  /// 날짜만. '오늘', '내일', '8/2 (일)'처럼 읽힌다.
  ///
  /// 한 모임의 여러 날을 세로로 늘어놓을 때 쓴다. 그 자리에서는 '3일 뒤',
  /// '5일 뒤'가 나란히 놓이는데, 며칠씩 떨어져 있는지를 머릿속에서 다시
  /// 날짜로 옮겨야 해서 오히려 고르기 어렵다. 가까운 이틀만 말로 두고
  /// 나머지는 날짜로 적는다.
  String dayLabel(DateTime now) {
    return switch (daysFrom(now)) {
      0 => '오늘',
      1 => '내일',
      _ => '${startsAt.month}/${startsAt.day} ($weekdayLabel)',
    };
  }

  MeetupSession copyWith({bool? isJoined, int? participantCount}) {
    return MeetupSession(
      id: id,
      startsAt: startsAt,
      participantCount: participantCount ?? this.participantCount,
      capacity: capacity,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

/// 한 주 단위로 여는 모각코 모임.
///
/// 장소는 모임이 정하고 날짜는 [sessions]가 나눠 갖는다. 같은 카페에서
/// 토·일 이틀을 여는 주가 있고 하루만 여는 주가 있어서, 모임을 날짜마다
/// 따로 만들지 않고 주 단위로 묶는다.
class Meetup {
  const Meetup({
    required this.id,
    required this.chapter,
    required this.placeName,
    required this.address,
    required this.host,
    required this.sessions,
    this.hostAvatarUrl,
    this.isRecurring = false,
    this.description,
    this.latitude,
    this.longitude,
  });

  final String id;
  final Chapter chapter;

  /// 카페 등 모이는 장소 이름
  final String placeName;

  /// 시·도를 포함한 전체 주소
  final String address;

  /// 모임을 연 사람의 닉네임.
  ///
  /// 누가 모으는지가 참여를 정하는 데 꽤 크게 작용한다. 아는 사람이면
  /// 마음이 놓이고, 모르는 사람이라도 익명 모임보다는 덜 낯설다.
  final String host;

  /// 모임장 프로필 사진. 없으면 닉네임 첫 글자로 대신한다.
  final String? hostAvatarUrl;

  /// 이 주에 열리는 날들. 이른 날부터 담는다.
  final List<MeetupSession> sessions;

  /// 매주 되풀이되는 정기 모임인지
  final bool isRecurring;

  /// 모임장이 적은 소개. 목록에는 안 보이고 상세에서만 읽는다.
  ///
  /// 없는 모임이 흔하다. 자리만 잡고 별말 없이 여는 경우가 많다.
  final String? description;

  /// 장소의 위도·경도.
  ///
  /// 주소 문자열만으로는 지도를 그릴 수 없다. 주소를 좌표로 바꾸는 건 지오코딩
  /// API 가 하는 일이라 서버가 저장해 내려줘야 한다. 없으면 상세에서 지도를
  /// 빼고 주소만 둔다.
  final double? latitude;
  final double? longitude;

  /// 지도를 그릴 수 있는지
  bool get hasLocation => latitude != null && longitude != null;

  /// 시·도를 뗀 주소.
  ///
  /// 지금 보고 있는 지역의 모임만 나열되므로 '부산광역시'를 매번 반복할 이유가 없다.
  /// 앞자리가 해당 지역을 가리키면 잘라내고 구·동만 남긴다.
  String get shortAddress {
    final parts = address.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts.first.startsWith(chapter.label)) {
      return parts.skip(1).join(' ');
    }
    return address;
  }

  /// 가장 먼저 열리는 날. 정렬 기준으로 쓴다.
  DateTime get firstStartsAt => sessions
      .map((session) => session.startsAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  /// 오늘 열리는 날. 없으면 null.
  MeetupSession? sessionToday(DateTime now) {
    for (final session in sessions) {
      if (session.daysFrom(now) == 0) return session;
    }
    return null;
  }

  /// 아직 지나지 않은 날 중 가장 가까운 것. 다 지났으면 null.
  MeetupSession? nextSession(DateTime now) {
    MeetupSession? nearest;
    for (final session in sessions) {
      if (session.daysFrom(now) < 0) continue;
      if (nearest == null || session.startsAt.isBefore(nearest.startsAt)) {
        nearest = session;
      }
    }
    return nearest;
  }

  /// 이번 주에 열리는 날이 하나라도 있는지.
  bool isThisWeek(DateTime now, {int withinDays = 7}) {
    return sessions.any((session) {
      final days = session.daysFrom(now);
      return days >= 0 && days <= withinDays;
    });
  }

  /// 내가 하루라도 참여하기로 한 모임인지
  bool get isJoinedAny => sessions.any((session) => session.isJoined);

  /// 모든 날이 다 찼는지
  bool get isFull => sessions.every((session) => session.isFull);

  /// 이 주에 모인 사람 수. 같은 사람이 이틀 다 오면 두 번 센다.
  int get totalParticipants =>
      sessions.fold(0, (sum, session) => sum + session.participantCount);

  /// 전체 자리 수
  int get totalCapacity =>
      sessions.fold(0, (sum, session) => sum + session.capacity);

  /// 얼마나 찼는지. 0이면 빈 모임, 1이면 자리가 다 찬 모임.
  ///
  /// 진짜 '급상승'은 시간당 참여 증가율이라 서버 집계가 있어야 한다.
  /// 그 전까지는 채워진 비율로 인기를 가늠한다.
  double get fillRate =>
      totalCapacity == 0 ? 0 : totalParticipants / totalCapacity;

  /// 특정 날의 참여를 뒤집은 새 모임을 만든다.
  ///
  /// 자리가 찬 날은 새로 신청할 수 없지만, 이미 신청했다면 언제든 뺄 수 있다.
  Meetup toggleSession(String sessionId) {
    return copyWith(
      sessions: [
        for (final session in sessions)
          if (session.id != sessionId)
            session
          else if (session.isJoined)
            session.copyWith(
              isJoined: false,
              participantCount: session.participantCount - 1,
            )
          else if (!session.isFull)
            session.copyWith(
              isJoined: true,
              participantCount: session.participantCount + 1,
            )
          else
            session,
      ],
    );
  }

  /// 모임장 이름만 바꾼 새 모임을 만든다.
  Meetup withHost(String host) => Meetup(
    id: id,
    chapter: chapter,
    placeName: placeName,
    address: address,
    host: host,
    hostAvatarUrl: hostAvatarUrl,
    sessions: sessions,
    isRecurring: isRecurring,
    description: description,
    latitude: latitude,
    longitude: longitude,
  );

  Meetup copyWith({List<MeetupSession>? sessions}) {
    return Meetup(
      id: id,
      chapter: chapter,
      placeName: placeName,
      address: address,
      host: host,
      hostAvatarUrl: hostAvatarUrl,
      sessions: sessions ?? this.sessions,
      isRecurring: isRecurring,
      description: description,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
