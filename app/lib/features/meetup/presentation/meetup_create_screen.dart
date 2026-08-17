import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/navigation.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/form_field_block.dart';
import '../../auth/presentation/session_provider.dart';
import '../../place/domain/place.dart';
import '../../place/presentation/place_picker_field.dart';
import '../domain/edit_scope.dart';
import '../domain/meetup.dart';
import 'meetup_provider.dart';
import 'widgets/edit_scope_sheet.dart';

/// 한 주치 모각코를 연다.
///
/// 날짜를 자유롭게 고르는 대신 이번 주 이레에서 고른다. 이 앱의 모임은 주
/// 단위이고, 달력을 띄우면 다음 달까지 고를 수 있어 모델과 어긋난다.
///
/// 고른 날마다 시각과 정원을 따로 둔다. 토요일 오전과 일요일 저녁이 한 모임인
/// 경우가 흔해서, 하나로 묶으면 둘 중 하나가 거짓이 된다.
class MeetupCreateScreen extends ConsumerStatefulWidget {
  const MeetupCreateScreen({super.key, this.meetupId});

  /// 고칠 모임의 id. 없으면 새로 여는 것이다.
  ///
  /// 열기와 고치기를 한 화면으로 둔다. 나눠 두면 칸이 하나 늘 때마다 두 곳을
  /// 맞춰야 하고, 한쪽만 고쳐 두면 고칠 때만 없는 칸이 생긴다.
  final String? meetupId;

  @override
  ConsumerState<MeetupCreateScreen> createState() => _MeetupCreateScreenState();
}

/// 고른 하루에 딸린 값
typedef _Day = ({int hour, int minute, int capacity});

class _MeetupCreateScreenState extends ConsumerState<MeetupCreateScreen> {
  final _description = TextEditingController();

  /// 검색으로 고른 장소. 이름·주소·좌표가 함께 온다.
  Place? _place;

  /// 고른 날짜와 그 날의 시각·정원. 열쇠는 시:분을 뗀 날짜다.
  final _days = <DateTime, _Day>{};

  bool _recurring = false;

  bool get _isEditing => widget.meetupId != null;

  /// 고치기 전의 모임. 무엇이 바뀌었는지 견주는 데 쓴다.
  Meetup? _original;

  @override
  void initState() {
    super.initState();
    final id = widget.meetupId;
    if (id == null) return;

    // 지금 값으로 칸을 채워 연다. 빈 폼을 주면 안 고칠 것까지 다시 적어야 한다.
    final meetup = ref
        .read(meetupListProvider)
        .where((meetup) => meetup.id == id)
        .firstOrNull;
    if (meetup == null) return;

    _original = meetup;
    _description.text = meetup.description ?? '';
    _recurring = meetup.isRecurring;
    _place = Place(
      // 장소를 다시 고르지 않으면 그대로 쓴다. 검색으로 고른 것이 아니라
      // id 가 없으므로 모임 id 를 빌린다.
      id: meetup.id,
      name: meetup.placeName,
      address: meetup.address,
      latitude: meetup.latitude ?? 0,
      longitude: meetup.longitude ?? 0,
    );

    final now = ref.read(nowProvider);
    for (final session in meetup.sessions) {
      // 이미 지난 날은 고를 수 있는 이레 밖이라 칸에 세우지 않는다.
      // 도메인의 edit 이 손대지 않고 그대로 남긴다.
      if (session.daysFrom(now) < 0) continue;
      final start = session.startsAt;
      _days[DateTime(start.year, start.month, start.day)] = (
        hour: start.hour,
        minute: start.minute,
        capacity: session.capacity,
      );
    }
  }

  /// 처음 고르는 날에 채워 넣을 값.
  ///
  /// 다음 날짜부터는 직전에 정한 것을 이어받는다. 이틀을 여는 모임은 대개
  /// 시각과 정원이 같아서, 매번 같은 값을 다시 고르게 두지 않는다.
  static const _fallback = (hour: 19, minute: 0, capacity: 8);

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  /// 고를 수 있는 이레. 오늘부터 센다.
  List<DateTime> _week(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
  }

  bool get _canSubmit => _place != null && _days.isNotEmpty;

  void _toggleDay(DateTime day) {
    setState(() {
      if (_days.remove(day) != null) return;
      // 직전에 정한 값을 이어받는다.
      _days[day] = _days.values.lastOrNull ?? _fallback;
    });
  }

  Future<void> _pickTime(DateTime day) async {
    final current = _days[day]!;
    final now = ref.read(nowProvider);

    final picked = await showModalBottomSheet<_Day>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TimeSheet(
        initial: DateTime(
          now.year,
          now.month,
          now.day,
          current.hour,
          current.minute,
        ),
        onDone: (time) => Navigator.of(context).pop((
          hour: time.hour,
          minute: time.minute,
          capacity: current.capacity,
        )),
      ),
    );

    if (picked == null) return;
    setState(() => _days[day] = picked);
  }

  /// 다음 주에도 이어질 값이 바뀌었는지.
  ///
  /// 정기 모임은 요일·시각·정원·장소를 규칙으로 삼아 매주 새로 생긴다. 그
  /// 넷 중 하나라도 달라지면 다음 주까지 미칠지 물어야 한다. 소개글만 고쳤을
  /// 때는 묻지 않는다 — 이번 주만 다른 소개를 쓸 이유가 없고, 고칠 때마다
  /// 뜨면 안 읽고 누르게 된다.
  bool _propagates(Meetup original) {
    if (original.placeName != _place!.name) return true;
    if (original.address != _place!.address) return true;

    // 날짜가 아니라 '요일'로 견준다. 다음 주에 넘어가는 것은 이번 주 8월
    // 15일이 아니라 '토요일 19시 8명'이다.
    String shape(int weekday, int hour, int minute, int capacity) =>
        '$weekday $hour:$minute x$capacity';

    final now = ref.read(nowProvider);
    final before = {
      for (final session in original.sessions)
        if (session.daysFrom(now) >= 0)
          shape(
            session.startsAt.weekday,
            session.startsAt.hour,
            session.startsAt.minute,
            session.capacity,
          ),
    };
    final after = {
      for (final entry in _days.entries)
        shape(
          entry.key.weekday,
          entry.value.hour,
          entry.value.minute,
          entry.value.capacity,
        ),
    };

    return !setEquals(before, after);
  }

  Future<void> _save(Meetup original) async {
    // 정기 모임에서 다음 주까지 이어질 값이 바뀌었을 때만 묻는다.
    EditScope? scope;
    if (original.isRecurring && _recurring && _propagates(original)) {
      scope = await showEditScopeSheet(context, what: '바꾼 내용을 어디까지 적용할까요?');
      if (scope == null) return;
    }
    if (!mounted) return;

    final place = _place!;
    ref
        .read(meetupListProvider.notifier)
        .replace(
          original.edit(
            now: ref.read(nowProvider),
            placeName: place.name,
            address: place.address,
            isRecurring: _recurring,
            days: _days,
            latitude: place.latitude == 0 ? null : place.latitude,
            longitude: place.longitude == 0 ? null : place.longitude,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
          ),
        );

    Haptics.decide();
    if (!mounted) return;

    // 고른 범위는 서버가 붙으면 규칙을 함께 고칠지 가르는 값이 된다. 목업에는
    // 규칙이 없어 지금은 무엇을 골랐는지 알려주는 데까지만 쓴다.
    final message = switch (scope) {
      EditScope.forward => '앞으로 열릴 모각코도 함께 바꿨어요',
      EditScope.thisWeek => '이번 주 모각코만 바꿨어요',
      null => '고쳤어요',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    goBack(context);
  }

  Future<void> _submit() async {
    final original = _original;
    if (original != null) return _save(original);

    final now = ref.read(nowProvider);
    final session = ref.read(sessionProvider);
    final chapter = ref.read(currentChapterProvider);

    final days = _days.keys.toList()..sort();
    final id = '${MeetupList.localPrefix}${now.microsecondsSinceEpoch}';
    final place = _place!;

    ref
        .read(meetupListProvider.notifier)
        .add(
          Meetup(
            id: id,
            chapter: chapter,
            placeName: place.name,
            address: place.address,
            host: session?.nickname ?? '나',
            isRecurring: _recurring,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            // 검색으로 고른 곳이라 좌표가 딸려 온다. 상세에서 바로 지도가 뜬다.
            latitude: place.latitude,
            longitude: place.longitude,
            sessions: [
              for (final day in days)
                MeetupSession(
                  id: '$id-${day.day}',
                  startsAt: day.copyWith(
                    hour: _days[day]!.hour,
                    minute: _days[day]!.minute,
                  ),
                  // 연 사람은 가는 사람이다. 빈 목록으로 시작하면 방금 만든
                  // 자리가 아무도 안 오는 곳처럼 보인다.
                  participants: [session?.nickname ?? '나'],
                  capacity: _days[day]!.capacity,
                  isJoined: true,
                ),
            ],
          ),
        );

    Haptics.decide();
    // 목록으로 돌아가지 않고 만든 자리로 바로 들어간다. 방금 연 것을 목록에서
    // 다시 찾게 두지 않는다.
    context.pushReplacement(AppRoute.meetup(id));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final days = _days.keys.toList()..sort();

    return DetailScaffold(
      title: _isEditing ? '모각코 고치기' : '모각코 만들기',
      bottomAction: FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: Text(_isEditing ? '저장' : '만들기'),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlacePickerField(
                value: _place,
                onChanged: (place) => setState(() => _place = place),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '소개',
                optional: true,
                child: TextField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '어떻게 모이는 자리인지 적어주세요',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FormFieldBlock(
                label: '언제',
                hint: '이번 주에서 고릅니다. 여러 날을 한 모임으로 묶을 수 있어요',
                child: _WeekPicker(
                  week: _week(now),
                  now: now,
                  selected: _days.keys.toSet(),
                  onToggle: _toggleDay,
                ),
              ),
            ],
          ),
        ),
        if (days.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.border),
                  _DayRow(
                    day: days[i],
                    now: now,
                    value: _days[days[i]]!,
                    onTapTime: () => _pickTime(days[i]),
                    onCapacity: (capacity) => setState(() {
                      final current = _days[days[i]]!;
                      _days[days[i]] = (
                        hour: current.hour,
                        minute: current.minute,
                        capacity: capacity,
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: _RecurringToggle(
            value: _recurring,
            onChanged: (value) => setState(() => _recurring = value),
          ),
        ),
      ],
    );
  }
}

/// 이번 주 이레를 늘어놓고 고르게 한다.
class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
    required this.week,
    required this.now,
    required this.selected,
    required this.onToggle,
  });

  final List<DateTime> week;
  final DateTime now;
  final Set<DateTime> selected;
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: [
        for (final day in week)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _DayChip(
                // 날짜를 열쇠로 둔다. 알약 자리는 오늘이 며칠이냐에 따라
                // 매일 한 칸씩 밀리므로 순서로 가리키면 잡을 수 없다.
                key: ValueKey(day),
                weekday: weekdays[day.weekday - 1],
                dayOfMonth: day.day,
                // 토·일은 달력에서 하듯 색을 달리한다.
                weekend: day.weekday >= 6,
                selected: selected.contains(day),
                onTap: () => onToggle(day),
                colors: colors,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.weekday,
    required this.dayOfMonth,
    required this.weekend,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String weekday;
  final int dayOfMonth;
  final bool weekend;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  weekday,
                  style: context.texts.labelSmall?.copyWith(
                    color: selected
                        ? colors.primaryForeground
                        : (weekend ? colors.primary : colors.textTertiary),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  '$dayOfMonth',
                  style: context.texts.labelMedium?.copyWith(
                    color: selected
                        ? colors.primaryForeground
                        : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 고른 하루의 시각과 정원
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.now,
    required this.value,
    required this.onTapTime,
    required this.onCapacity,
  });

  final DateTime day;
  final DateTime now;
  final _Day value;
  final VoidCallback onTapTime;
  final ValueChanged<int> onCapacity;

  String get _label {
    final today = DateTime(now.year, now.month, now.day);
    final gap = day.difference(today).inDays;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return switch (gap) {
      0 => '오늘',
      1 => '내일',
      _ => '${day.month}/${day.day} (${weekdays[day.weekday - 1]})',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              _label,
              style: context.texts.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 시각은 눌러서 고친다. 값이 곧 버튼이라 따로 아이콘을 두지 않는다.
          Semantics(
            button: true,
            label: '시각 바꾸기',
            child: InkWell(
              onTap: onTapTime,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  time,
                  style: context.texts.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          CountStepper(value: value.capacity, onChanged: onCapacity),
        ],
      ),
    );
  }
}

/// 시각 고르는 시트.
///
/// 머티리얼 시계 대신 굴림판을 쓴다. 앱의 다른 고르기가 모두 시트라 여기만
/// 다이얼로그가 뜨면 결이 어긋난다.
class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.initial, required this.onDone});

  final DateTime initial;
  final ValueChanged<DateTime> onDone;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: widget.initial,
              // 5분 단위. 모임 시각을 1분 단위로 잡는 사람은 없다.
              minuteInterval: 5,
              use24hFormat: true,
              onDateTimeChanged: (value) => _value = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: FilledButton(
              onPressed: () => widget.onDone(_value),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringToggle extends StatelessWidget {
  const _RecurringToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 카드를 두르지 않는다. 묶을 줄도 고를 선택지도 없는 한 줄짜리 옵션인데
    // 요일 묶음과 같은 상자를 쓰면 같은 무게로 읽혀, 정작 골라야 할 요일이
    // 받을 시선을 나눠 갖는다. 위에 선 하나만 긋고 배경에 눕힌다.
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정기 모임',
                  style: context.texts.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text('매주 같은 자리에서 이어집니다', style: context.texts.labelSmall),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
