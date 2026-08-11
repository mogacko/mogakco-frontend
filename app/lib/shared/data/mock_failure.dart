import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 목업이 실패하는 척할지.
///
/// 서버가 붙기 전에는 실패가 나지 않아서 실패 화면을 확인할 길이 없다.
/// 시험대에서 켜서 본다. 서버가 붙으면 이 파일은 지운다.
class MockFailure extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final mockFailureProvider = NotifierProvider<MockFailure, bool>(
  MockFailure.new,
);

/// 목업이 던지는 실패.
class MockNetworkFailure implements Exception {
  const MockNetworkFailure();

  @override
  String toString() => '목업이 실패하는 척했다';
}
