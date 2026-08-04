import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';

void main() {
  group('MeetupSession 날짜 표기', () {
    // 2026-07-27 은 월요일이다.
    final now = DateTime(2026, 7, 27, 9);

    MeetupSession at(int afterDays, int hour) => MeetupSession(
      id: 's',
      startsAt: DateTime(now.year, now.month, now.day + afterDays, hour),
      participants: ['p0'],
      capacity: 8,
    );

    test('가까운 이틀은 말로, 나머지는 날짜로 적는다', () {
      expect(at(0, 19).dayLabel(now), '오늘');
      expect(at(1, 9).dayLabel(now), '내일');
      // 2026-07-30 은 목요일이다.
      expect(at(3, 14).dayLabel(now), '7/30 (목)');
    });

    test('달을 넘겨도 날짜가 이어진다', () {
      // 2026-08-01 은 토요일이다.
      expect(at(5, 10).dayLabel(now), '8/1 (토)');
    });

    test('시각은 두 자리로 채운다', () {
      expect(at(0, 9).timeLabel, '09:00');
      expect(at(0, 19).timeLabel, '19:00');
    });

    test('요일을 한 글자로 적는다', () {
      expect(at(0, 9).weekdayLabel, '월');
      expect(at(5, 9).weekdayLabel, '토');
    });

    test('하루만 세울 때는 남은 날로 적는다', () {
      // whenLabel 과 dayLabel 은 쓰이는 자리가 달라 표기도 다르다.
      expect(at(3, 14).whenLabel(now), '3일 뒤 14:00');
      expect(at(3, 14).dayLabel(now), '7/30 (목)');
    });
  });
}
