import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/form_field_block.dart';

import '../../member/presentation/member_provider.dart';
import '../../place/domain/place.dart';
import '../../place/presentation/place_picker_field.dart';
import '../domain/event.dart';
import '../domain/poster.dart';
import 'widgets/poster_picker_field.dart';
import 'event_provider.dart';

/// 행사 올리기.
///
/// 바로 목록에 서지 않는다. 아무나 열 수 있게 두면 홍보 글이 행사로 올라온다.
/// 운영진이 확인한 뒤에 등록된다.
class EventCreateScreen extends ConsumerStatefulWidget {
  const EventCreateScreen({super.key});

  @override
  ConsumerState<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends ConsumerState<EventCreateScreen> {
  final _title = TextEditingController();
  final _summary = TextEditingController();

  EventKind _kind = EventKind.seminar;
  Place? _place;
  Poster? _poster;
  DateTime? _day;

  /// 시작 시각. 저녁 7시가 가장 흔하다.
  int _hour = 19;

  int _capacity = 30;

  /// 참가비. 대부분 무료라 기본은 0이다.
  final _fee = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _fee.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _title.text.trim().isNotEmpty &&
      _summary.text.trim().isNotEmpty &&
      _place != null &&
      _day != null;

  /// 고를 수 있는 날. 오늘부터 8주.
  ///
  /// 모각코와 달리 이번 주로 좁히지 않는다. 공간을 빌리고 사람을 모으는 데
  /// 시간이 걸려서 대개 한 달쯤 앞을 잡는다.
  List<DateTime> _days(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [for (var i = 7; i < 56; i++) today.add(Duration(days: i))];
  }

  Future<void> _pickDay(DateTime now) async {
    final days = _days(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? days.first,
      firstDate: days.first,
      lastDate: days.last,
      helpText: '행사 날짜',
    );
    if (picked == null) return;
    setState(() => _day = picked);
  }

  void _submit() {
    final now = ref.read(nowProvider);
    final place = _place!;
    final day = _day!.copyWith(hour: _hour);
    final id = '${EventList.localPrefix}${now.microsecondsSinceEpoch}';

    ref
        .read(eventListProvider.notifier)
        .propose(
          Event(
            id: id,
            chapter: ref.read(currentChapterProvider),
            kind: _kind,
            title: _title.text.trim(),
            summary: _summary.text.trim(),
            venue: place.name,
            startsAt: day,
            // 끝나는 시각은 따로 받지 않는다. 대부분 두세 시간이고, 한 칸 더
            // 두면 채우다 지쳐 올리기를 그만둔다.
            endsAt: day.add(const Duration(hours: 3)),
            // 신청 마감은 하루 전. 자리와 다과를 미리 잡아야 한다.
            applyBy: DateTime(day.year, day.month, day.day - 1, 23, 59),
            capacity: _capacity,
            applicantCount: 0,
            fee: int.tryParse(_fee.text.trim()) ?? 0,
            poster: _poster,
            status: EventStatus.pending,
            proposedBy: ref.read(myIdProvider),
          ),
        );

    Haptics.decide();
    // 목록으로 보내면 방금 올린 것이 없다. 검토 중이라 거기 서지 않는다.
    context.pushReplacement(AppRoute.myEvents);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final day = _day;

    return DetailScaffold(
      title: '행사 올리기',
      bottomAction: FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: const Text('검토 요청'),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            // 올리기 전에 알려준다. 눌러놓고 목록에 없으면 안 올라간 줄 안다.
            child: Text(
              '올리면 운영진 검토를 거쳐 등록됩니다. 보통 하루 안에 끝나요.',
              style: context.texts.labelSmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text(
            '종류',
            style: context.texts.labelMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilterBar<EventKind>(
          options: EventKind.values,
          selected: _kind,
          labelOf: (kind) => kind.label,
          onSelect: (kind) => setState(() => _kind = kind),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormFieldBlock(
                label: '이름',
                child: TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  maxLength: 40,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '예) Flutter 렌더링 파이프라인 뜯어보기',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '소개',
                child: TextField(
                  controller: _summary,
                  onChanged: (_) => setState(() {}),
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '무엇을 하는 자리인지, 누가 오면 좋을지 적어주세요',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PlacePickerField(
                value: _place,
                label: '장소',
                hint: '빌린 공간 이름으로 검색하세요',
                onChanged: (place) => setState(() => _place = place),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '날짜',
                hint: '공간을 빌리고 사람을 모을 시간이 필요해 일주일 뒤부터 고를 수 있어요',
                child: _DayButton(
                  day: day,
                  hour: _hour,
                  onTap: () => _pickDay(now),
                  onHour: (hour) => setState(() => _hour = hour),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '정원',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CountStepper(
                    value: _capacity,
                    min: 5,
                    max: 200,
                    onChanged: (value) => setState(() => _capacity = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PosterPickerField(
                poster: _poster,
                onChanged: (poster) => setState(() => _poster = poster),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '참가비',
                optional: true,
                hint: '비워두면 무료로 올라갑니다',
                child: TextField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 날짜와 시각을 한 줄에 세운 버튼.
class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.hour,
    required this.onTap,
    required this.onHour,
  });

  final DateTime? day;
  final int hour;
  final VoidCallback onTap;
  final ValueChanged<int> onHour;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final day = this.day;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSize.inputHeight),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              foregroundColor: day == null
                  ? colors.textTertiary
                  : colors.textPrimary,
            ),
            child: Text(
              day == null
                  ? '날짜 고르기'
                  : '${day.year}. ${day.month}. ${day.day}.',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // 시각은 정시 단위로만 받는다. 행사는 30분 단위로 시작하는 일이 드물고,
        // 칸이 늘어날수록 올리다 지친다.
        CountStepper(value: hour, min: 8, max: 22, onChanged: onHour),
        const SizedBox(width: AppSpacing.xs),
        Text('시', style: context.texts.labelSmall),
      ],
    );
  }
}
