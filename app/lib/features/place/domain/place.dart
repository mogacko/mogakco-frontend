/// 검색으로 찾은 장소 한 곳.
///
/// 지점명과 주소를 따로 받아 적게 하지 않고 한 번에 고르게 하려고 둔다.
/// 사람이 적은 주소는 '동래구 온천동'과 '부산 동래구 온천동 123-4'가 섞이고,
/// 그 상태로는 지도를 그릴 좌표를 얻을 수 없다.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  final String id;

  /// 지점명. '모모스커피 온천장'처럼 가게 이름에 지점이 붙는다.
  final String name;

  /// 도로명 주소
  final String address;

  /// '카페', '스터디카페' 같은 업종. 없을 수 있다.
  ///
  /// 같은 이름의 가게가 여럿일 때 어느 쪽인지 가리는 데 쓴다.
  final String? category;

  final double latitude;
  final double longitude;

  /// 시·도를 뗀 주소.
  ///
  /// 목록에서 '부산광역시'가 열 줄 내리 반복되면 정작 다른 부분인 구·동이
  /// 뒤로 밀려 눈에 안 들어온다.
  String get shortAddress {
    final parts = address.trim().split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.skip(1).join(' ') : address;
  }
}
