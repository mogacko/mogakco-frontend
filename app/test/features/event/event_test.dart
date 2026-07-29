import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/event/domain/event.dart';
import 'package:mogacko/shared/domain/chapter.dart';

void main() {
  group('Event', () {
    final now = DateTime(2026, 7, 27, 9);

    Event make({
      int applyByAfterDays = 3,
      int startsAfterDays = 5,
      int capacity = 40,
      int applicantCount = 10,
      int fee = 0,
      bool isApplied = false,
    }) {
      DateTime at(int afterDays, int hour) =>
          DateTime(now.year, now.month, now.day + afterDays, hour);

      return Event(
        id: 'e',
        chapter: Chapter.busan,
        kind: EventKind.seminar,
        title: '세미나',
        summary: '요약',
        venue: '어딘가',
        startsAt: at(startsAfterDays, 14),
        endsAt: at(startsAfterDays, 17),
        applyBy: at(applyByAfterDays, 23),
        capacity: capacity,
        applicantCount: applicantCount,
        fee: fee,
        isApplied: isApplied,
      );
    }

    test('마감까지 남은 날을 D-N 으로 적는다', () {
      expect(make(applyByAfterDays: 3).ddayLabel(now), 'D-3');
      expect(make(applyByAfterDays: 0).ddayLabel(now), 'D-DAY');
    });

    test('마감 시각이 지나면 마감으로 적는다', () {
      expect(make(applyByAfterDays: -1).ddayLabel(now), '마감');
    });

    test('오늘 밤 마감을 D-1 로 세지 않는다', () {
      // 기준이 오전 9시여도 같은 날이면 D-DAY 다.
      expect(make(applyByAfterDays: 0).daysToApplyBy(now), 0);
    });

    test('자리가 다 차면 마감 전이어도 닫힌다', () {
      final full = make(capacity: 10, applicantCount: 10);

      expect(full.isFull, isTrue);
      expect(full.isClosed(now), isTrue);
    });

    test('행사가 이미 시작했으면 닫힌다', () {
      expect(make(startsAfterDays: -1).isClosed(now), isTrue);
    });

    test('참가비는 세 자리마다 끊어 적고 0원은 무료로 적는다', () {
      expect(make(fee: 0).feeLabel, '무료');
      expect(make(fee: 15000).feeLabel, '15,000원');
      expect(make(fee: 1500000).feeLabel, '1,500,000원');
    });

    test('신청하면 인원이 한 명 는다', () {
      final applied = make(applicantCount: 10).apply();

      expect(applied.isApplied, isTrue);
      expect(applied.applicantCount, 11);
    });

    test('두 번 신청해도 인원은 한 번만 는다', () {
      final twice = make(applicantCount: 10).apply().apply();

      expect(twice.applicantCount, 11);
    });

    test('취소하면 인원이 도로 준다', () {
      final back = make(applicantCount: 10).apply().cancel();

      expect(back.isApplied, isFalse);
      expect(back.applicantCount, 10);
    });

    test('마감이 사흘 안으로 들어와야 서두를 일이다', () {
      expect(make(applyByAfterDays: 3).isUrgent(now), isTrue);
      expect(make(applyByAfterDays: 4).isUrgent(now), isFalse);
      // 이미 지난 마감은 서두를 일이 아니라 끝난 일이다.
      expect(make(applyByAfterDays: -1).isUrgent(now), isFalse);
    });

    test('시각과 날짜를 사람이 읽는 꼴로 적는다', () {
      // 2026-08-01 은 토요일이다.
      final event = make(startsAfterDays: 5);

      expect(event.dateLabel, '8월 1일 (토)');
      expect(event.timeRangeLabel, '14:00 - 17:00');
    });
  });
}
