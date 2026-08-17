import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';
import 'package:mogacko/shared/domain/chapter.dart';

/// 고칠 때 참여자를 어떻게 다루는지 본다.
///
/// 화면보다 여기가 중요하다. 잘못 고치면 오기로 한 사람이 조용히 사라지는데,
/// 모임장은 저장하고 나가버려서 알아차릴 자리가 없다.
void main() {
  final now = DateTime(2026, 8, 17, 10);
  DateTime day(int add) => DateTime(2026, 8, 17 + add);

  Meetup build({
    required List<MeetupSession> sessions,
    bool isRecurring = true,
  }) {
    return Meetup(
      id: 'm1',
      chapter: Chapter.busan,
      placeName: '모모스커피 온천장',
      address: '부산광역시 동래구 금강공원로 73번길 1',
      host: 'evan',
      isRecurring: isRecurring,
      sessions: sessions,
    );
  }

  MeetupSession session(
    int addDays, {
    int hour = 19,
    int capacity = 8,
    List<String> participants = const ['evan', '수민'],
  }) {
    return MeetupSession(
      id: 'm1-${17 + addDays}',
      startsAt: DateTime(2026, 8, 17 + addDays, hour),
      participants: participants,
      capacity: capacity,
      isJoined: true,
    );
  }

  ({int hour, int minute, int capacity}) at(int hour, {int capacity = 8}) =>
      (hour: hour, minute: 0, capacity: capacity);

  group('모각코 고치기', () {
    test('시각을 옮겨도 오기로 한 사람은 그대로 남는다', () {
      final before = build(sessions: [session(1)]);

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(1): at(21)},
      );

      expect(after.sessions, hasLength(1));
      expect(after.sessions.first.startsAt.hour, 21);
      // 오타 하나 고쳤다고 자리가 텅 비면 안 된다.
      expect(after.sessions.first.participants, ['evan', '수민']);
      expect(after.sessions.first.isJoined, isTrue);
    });

    test('같은 날이면 session id 를 유지한다', () {
      final before = build(sessions: [session(1)]);
      final id = before.sessions.first.id;

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(1): at(21)},
      );

      // id 가 바뀌면 그 날에 눌러둔 참여가 다른 것을 가리키게 된다.
      expect(after.sessions.first.id, id);
    });

    test('날을 더하면 모임장이 그 날의 첫 참여자가 된다', () {
      final before = build(sessions: [session(1)]);

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(1): at(19), day(2): at(14)},
      );

      expect(after.sessions, hasLength(2));
      final added = after.sessions.last;
      expect(added.participants, ['evan']);
      expect(added.isJoined, isTrue);
    });

    test('날을 빼면 그 날이 사라진다', () {
      final before = build(sessions: [session(1), session(2)]);

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(1): at(19)},
      );

      expect(after.sessions, hasLength(1));
      expect(after.sessions.first.startsAt.day, 18);
    });

    test('이미 지난 날은 손대지 않는다', () {
      // 어제 열린 자리. 고칠 수 있는 이레 밖이라 칸에도 안 선다.
      final before = build(sessions: [session(-1), session(1)]);

      final after = before.edit(
        now: now,
        placeName: '오지오커피',
        address: '부산광역시 금정구 어딘가 1',
        isRecurring: true,
        days: {day(1): at(21)},
      );

      // 지난 날을 지우면 그날 왔던 사람의 기록까지 사라진다.
      expect(after.sessions, hasLength(2));
      expect(after.sessions.first.startsAt.day, 16);
      expect(after.sessions.first.participants, ['evan', '수민']);
    });

    test('날짜가 바뀌면 이른 날부터 다시 세운다', () {
      final before = build(sessions: [session(3)]);

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(3): at(19), day(1): at(19)},
      );

      expect(
        after.sessions.map((session) => session.startsAt.day),
        [18, 20],
      );
    });

    test('정원을 줄여도 이미 온 사람을 빼지 않는다', () {
      final before = build(
        sessions: [
          session(1, capacity: 8, participants: ['evan', '수민', '지훈']),
        ],
      );

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: true,
        days: {day(1): at(19, capacity: 2)},
      );

      final only = after.sessions.first;
      expect(only.participants, hasLength(3));
      expect(only.capacity, 2);
      // 넘친 자리는 '남은 자리 0'으로 읽히지 음수가 되지 않는다.
      expect(only.remaining, 0);
      expect(only.isFull, isTrue);
    });

    test('정기를 끄면 표가 사라지고 이번 주 모임은 남는다', () {
      final before = build(sessions: [session(1)]);

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: false,
        days: {day(1): at(19)},
      );

      expect(after.isRecurring, isFalse);
      // 토글 하나로 이미 참여한 자리가 사라지면 안 된다.
      expect(after.sessions, hasLength(1));
      expect(after.sessions.first.participants, ['evan', '수민']);
    });

    test('접힌 표와 내보낸 사람은 그대로 따라온다', () {
      final before = Meetup(
        id: 'm1',
        chapter: Chapter.busan,
        placeName: '모모스커피 온천장',
        address: '부산광역시 동래구 금강공원로 73번길 1',
        host: 'evan',
        banned: ['말썽'],
        sessions: [session(1)],
      );

      final after = before.edit(
        now: now,
        placeName: before.placeName,
        address: before.address,
        isRecurring: false,
        days: {day(1): at(19)},
      );

      // 고치면서 내보낸 사람이 풀리면 모임장이 할 수 있는 게 없어진다.
      expect(after.banned, ['말썽']);
    });
  });
}
