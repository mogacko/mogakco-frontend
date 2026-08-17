import '../../../shared/domain/chapter.dart';

/// 모임 안의 하루.
///
/// 한 모임이 토·일처럼 여러 날에 걸쳐 열리고, 참여는 날마다 따로 정한다.
/// 토요일만 가고 일요일은 빠지는 식이 되므로 정원과 인원도 날짜별로 센다.
class MeetupSession {
  const MeetupSession({
    required this.id,
    required this.startsAt,
    required this.participants,
    required this.capacity,
    this.isJoined = false,
  });

  final String id;

  /// 이 날의 시작 시각
  final DateTime startsAt;

  /// 이 날 오기로 한 사람들. 앞에서부터 먼저 신청한 순서다.
  ///
  /// 숫자만 들고 있으면 '6명'이라고 적어놓고 정작 누가 오는지 물으면 답할
  /// 데가 없다. 목록이 원본이고 숫자는 거기서 나온다.
  final List<String> participants;

  final int capacity;

  int get participantCount => participants.length;

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

  MeetupSession copyWith({
    bool? isJoined,
    List<String>? participants,
    DateTime? startsAt,
    int? capacity,
  }) {
    return MeetupSession(
      id: id,
      startsAt: startsAt ?? this.startsAt,
      participants: participants ?? this.participants,
      capacity: capacity ?? this.capacity,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

/// 모임을 접는 이유.
///
/// 고르게 한다. 취소만 되고 이유가 없으면 기다리던 사람은 자기가 뭘 잘못했나
/// 싶어진다. 이유를 알면 다음 주에 다시 올지도 가늠이 된다.
enum CancelReason {
  personal('개인 사정', '모임장이 갈 수 없게 됐어요'),
  place('장소 문제', '자리를 못 잡았거나 카페가 문을 닫아요'),
  tooFew('인원 부족', '모이기로 한 사람이 너무 적어요'),
  weather('날씨', '비·눈으로 이동이 어려워요'),
  other('기타', '위에 없는 이유예요');

  const CancelReason(this.label, this.description);

  final String label;
  final String description;

  /// 직접 적어야 하는 이유인지. 기타만 받는다.
  bool get needsNote => this == CancelReason.other;
}

/// 취소된 모임에 붙는 표.
class Cancellation {
  const Cancellation({required this.reason, required this.at, this.note});

  final CancelReason reason;

  /// 직접 적은 말. 기타일 때만 채워진다.
  final String? note;

  final DateTime at;

  /// 화면에 그대로 세울 한 줄.
  String get label => note ?? reason.label;
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
    this.cancellation,
    this.banned = const [],
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

  /// 접힌 모임이면 그 표. 아니면 null.
  ///
  /// 취소한 모임을 목록에서 지우지 않는다. 오기로 했던 사람은 그 자리가 어떻게
  /// 됐는지 확인하러 오는데, 통째로 사라지면 자기가 잘못 본 건지 알 수 없다.
  final Cancellation? cancellation;

  bool get isCancelled => cancellation != null;

  /// 모임장이 내보낸 사람들.
  ///
  /// 내보내기만 하고 끝내면 그 사람이 곧바로 다시 신청한다. 내보낸 자리에
  /// 다시 들어오는 걸 막지 못하면 모임장이 할 수 있는 게 없다.
  ///
  /// 모임 안에서만 막는다. 앱 전체에서 안 보이게 하는 건 차단이고, 그건
  /// 내보내는 사람이 따로 고를 일이다.
  final List<String> banned;

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
  ///
  /// [me] 는 참여자 목록에 넣고 뺄 내 이름이다. 숫자만 올리고 내리면 아바타
  /// 줄에는 내가 없는데 '참여 중'이라고 적히는 상태가 된다.
  Meetup toggleSession(String sessionId, String me) {
    // 접힌 모임에는 신청할 것이 없다.
    if (isCancelled) return this;
    // 내보낸 사람은 다시 들어올 수 없다.
    if (banned.contains(me)) return this;

    return copyWith(
      sessions: [
        for (final session in sessions)
          if (session.id != sessionId)
            session
          else if (session.isJoined)
            session.copyWith(
              isJoined: false,
              participants: session.participants
                  .where((name) => name != me)
                  .toList(),
            )
          else if (!session.isFull)
            session.copyWith(
              isJoined: true,
              // 맨 뒤에 붙인다. 먼저 신청한 사람이 앞에 서는 순서다.
              participants: [...session.participants, me],
            )
          else
            session,
      ],
    );
  }

  /// 고친 모임을 만든다.
  ///
  /// 살아남은 날의 참여자는 그대로 둔다. 시각을 옮겼다고 오기로 한 사람을 다
  /// 풀어버리면 모임장이 오타 하나 고쳤을 때도 자리가 텅 빈다. 바뀐 것은
  /// 알려주고, 못 오게 된 사람이 스스로 뺀다.
  ///
  /// 이미 지난 날은 건드리지 않는다. 고칠 수 있는 것은 앞으로 열릴 자리뿐이고,
  /// 지난 날을 지우면 그날 왔던 사람의 기록까지 사라진다.
  Meetup edit({
    required DateTime now,
    required String placeName,
    required String address,
    required bool isRecurring,
    required Map<DateTime, ({int hour, int minute, int capacity})> days,
    double? latitude,
    double? longitude,
    String? description,
  }) {
    // 날짜만 남긴 열쇠로 견준다. 시각이 바뀌어도 '같은 날'이면 그날 오기로 한
    // 사람은 그대로다.
    final byDay = {
      for (final session in sessions)
        DateTime(
          session.startsAt.year,
          session.startsAt.month,
          session.startsAt.day,
        ): session,
    };

    final past = sessions.where((session) => session.daysFrom(now) < 0);

    final next = [
      for (final day in days.keys.toList()..sort())
        if (byDay[day] case final kept?)
          kept.copyWith(
            startsAt: day.copyWith(
              hour: days[day]!.hour,
              minute: days[day]!.minute,
            ),
            capacity: days[day]!.capacity,
          )
        else
          MeetupSession(
            id: '$id-${day.day}',
            startsAt: day.copyWith(
              hour: days[day]!.hour,
              minute: days[day]!.minute,
            ),
            // 연 사람은 가는 사람이다. 새로 더한 날도 만들 때와 같다.
            participants: [host],
            capacity: days[day]!.capacity,
            isJoined: true,
          ),
    ];

    return Meetup(
      id: id,
      chapter: chapter,
      placeName: placeName,
      address: address,
      host: host,
      hostAvatarUrl: hostAvatarUrl,
      sessions: [...past, ...next]
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      isRecurring: isRecurring,
      description: description,
      latitude: latitude,
      longitude: longitude,
      cancellation: cancellation,
      banned: banned,
    );
  }

  /// 모임장 이름만 바꾼 새 모임을 만든다.
  Meetup withHost(String host) => Meetup(
    cancellation: cancellation,
    banned: banned,
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

  /// 사유를 달아 모임을 접는다.
  Meetup cancel(Cancellation cancellation) =>
      copyWith(cancellation: cancellation);

  /// 한 사람을 모든 날짜에서 빼고 다시 못 들어오게 한다.
  ///
  /// 날짜별로 빼지 않는다. 이틀 다 오기로 한 사람을 내보내려고 두 번 눌러야
  /// 하면, 한 번만 누르고 끝난 줄 알았다가 다음 날 마주친다.
  Meetup kick(String memberId) {
    return copyWith(
      banned: [...banned, memberId],
      sessions: [
        for (final session in sessions)
          if (!session.participants.contains(memberId))
            session
          else
            session.copyWith(
              // 내보내는 건 남이다. 내 참여 여부는 그대로 둔다.
              participants: session.participants
                  .where((name) => name != memberId)
                  .toList(),
            ),
      ],
    );
  }

  /// 이 사람을 내보낼 수 있는지.
  ///
  /// 모임장 자신은 뺄 수 없다. 연 사람이 없는 모임은 모임이 아니고, 접으려면
  /// 접기가 따로 있다.
  bool canKick(String memberId) => memberId != host && !banned.contains(memberId);

  Meetup copyWith({
    List<MeetupSession>? sessions,
    Cancellation? cancellation,
    List<String>? banned,
  }) {
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
      cancellation: cancellation ?? this.cancellation,
      banned: banned ?? this.banned,
    );
  }
}
