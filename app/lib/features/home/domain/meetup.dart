import '../../../shared/domain/chapter.dart';

/// 모집 중인 모각코 한 건.
class Meetup {
  const Meetup({
    required this.id,
    required this.chapter,
    required this.placeName,
    required this.address,
    required this.participantCount,
    required this.capacity,
    this.isJoined = false,
  });

  final String id;
  final Chapter chapter;

  /// 카페 등 모이는 장소 이름
  final String placeName;

  /// 시·도를 포함한 전체 주소
  final String address;

  final int participantCount;
  final int capacity;

  /// 내가 참여 신청한 모임인지
  final bool isJoined;

  /// 시·도를 뗀 주소.
  ///
  /// 지금 보고 있는 지역의 모임만 나열되므로 '서울특별시'를 매번 반복할 이유가 없다.
  /// 앞자리가 해당 지역을 가리키면 잘라내고 구·동만 남긴다.
  String get shortAddress {
    final parts = address.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts.first.startsWith(chapter.label)) {
      return parts.skip(1).join(' ');
    }
    return address;
  }

  bool get isFull => participantCount >= capacity;

  /// 남은 자리
  int get remaining => (capacity - participantCount).clamp(0, capacity);

  Meetup copyWith({bool? isJoined, int? participantCount}) {
    return Meetup(
      id: id,
      chapter: chapter,
      placeName: placeName,
      address: address,
      participantCount: participantCount ?? this.participantCount,
      capacity: capacity,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
