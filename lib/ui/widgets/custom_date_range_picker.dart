import 'package:flutter/material.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';

// =================================================================
// CUSTOM DATE RANGE PICKER — Hadir.in Design System
// Usage: lihat di bawah file ini
// =================================================================

Future<DateTimeRange?> showCustomDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialDateRange,
}) async {
  return await showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _CustomDateRangePickerSheet(initialDateRange: initialDateRange),
  );
}

// =================================================================
// BOTTOM SHEET WRAPPER
// =================================================================
class _CustomDateRangePickerSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  const _CustomDateRangePickerSheet({this.initialDateRange});

  @override
  State<_CustomDateRangePickerSheet> createState() =>
      _CustomDateRangePickerSheetState();
}

class _CustomDateRangePickerSheetState
    extends State<_CustomDateRangePickerSheet>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingStart = true;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  static const List<String> _dayHeaders = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);

    if (widget.initialDateRange != null) {
      _startDate = widget.initialDateRange!.start;
      _endDate = widget.initialDateRange!.end;
      _selectingStart = false;
    }

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_focusedMonth.year == now.year && _focusedMonth.month == now.month) {
      return;
    }
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  bool get _isNextDisabled {
    final now = DateTime.now();
    return _focusedMonth.year == now.year && _focusedMonth.month == now.month;
  }

  void _onDayTap(DateTime day) {
    final today = DateTime.now();
    final d = DateTime(day.year, day.month, day.day);
    final todayClean = DateTime(today.year, today.month, today.day);
    if (d.isAfter(todayClean)) return;

    setState(() {
      if (_selectingStart || (_startDate != null && _endDate != null)) {
        _startDate = d;
        _endDate = null;
        _selectingStart = false;
      } else {
        if (d.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = d;
        } else {
          _endDate = d;
        }
        _selectingStart = true;
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    return d.isAfter(_startDate!) && d.isBefore(_endDate!);
  }

  bool _isStart(DateTime day) {
    if (_startDate == null) return false;
    return DateTime(day.year, day.month, day.day) == _startDate;
  }

  bool _isEnd(DateTime day) {
    if (_endDate == null) return false;
    return DateTime(day.year, day.month, day.day) == _endDate;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isFuture(DateTime day) {
    final today = DateTime.now();
    return day.isAfter(DateTime(today.year, today.month, today.day));
  }

  List<DateTime?> _buildCalendarDays() {
    final firstDay = _focusedMonth;
    // Flutter: Monday = 1, Sunday = 7
    int weekdayOffset = firstDay.weekday - 1; // Mon = 0
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final List<DateTime?> days = [];

    for (int i = 0; i < weekdayOffset; i++) {
      days.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    // Pad to full rows
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  String _formatSelectedRange() {
    if (_startDate == null) return "Pilih tanggal mulai";
    final f = DateFormat('d MMM yyyy', 'id_ID');
    if (_endDate == null) return "${f.format(_startDate!)} → ...";
    return "${f.format(_startDate!)}  –  ${f.format(_endDate!)}";
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── DRAG HANDLE ──
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: FluidColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: FluidColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Filter Tanggal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Pilih rentang tanggal absensi",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_startDate != null || _endDate != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectingStart = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Text(
                          "Reset",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── SELECTED RANGE BANNER ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: _startDate != null
                      ? LinearGradient(
                          colors: [
                            FluidColors.primary,
                            Color.lerp(
                              FluidColors.primary,
                              const Color(0xFF7C3AED),
                              0.6,
                            )!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _startDate == null ? Colors.white : null,
                  borderRadius: BorderRadius.circular(14),
                  border: _startDate == null
                      ? Border.all(color: Colors.grey.shade200)
                      : null,
                  boxShadow: _startDate != null
                      ? [
                          BoxShadow(
                            color: FluidColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _startDate == null
                          ? Icons.touch_app_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 15,
                      color: _startDate == null
                          ? Colors.grey.shade400
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatSelectedRange(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _startDate == null
                            ? Colors.grey.shade400
                            : Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── CALENDAR CARD ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: [
                      // Month Navigation
                      Row(
                        children: [
                          _NavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: _prevMonth,
                          ),
                          Expanded(
                            child: Text(
                              "${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          _NavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: _isNextDisabled ? null : _nextMonth,
                            disabled: _isNextDisabled,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Day-of-week headers
                      Row(
                        children: _dayHeaders
                            .map(
                              (h) => Expanded(
                                child: Text(
                                  h,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: h == 'Min'
                                        ? Colors.red.shade300
                                        : Colors.grey.shade400,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 10),

                      // Calendar grid
                      _buildGrid(days),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── FOOTER BUTTONS ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Batal",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_startDate != null && _endDate != null)
                          ? () => Navigator.pop(
                              context,
                              DateTimeRange(start: _startDate!, end: _endDate!),
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: FluidColors.primary,
                        disabledBackgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Terapkan Filter",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: (_startDate != null && _endDate != null)
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<DateTime?> days) {
    List<Widget> rows = [];
    for (int i = 0; i < days.length; i += 7) {
      rows.add(
        Row(
          children: List.generate(7, (j) {
            final day = days[i + j];
            return Expanded(child: _buildDayCell(day, j));
          }),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildDayCell(DateTime? day, int colIndex) {
    if (day == null) return const SizedBox(height: 44);

    final isStart = _isStart(day);
    final isEnd = _isEnd(day);
    final inRange = _isInRange(day);
    final isToday = _isToday(day);
    final future = _isFuture(day);
    final isSelected = isStart || isEnd;

    // Range highlight shape
    RangeSide? side;
    if (inRange) side = RangeSide.middle;
    if (isStart && _endDate != null) side = RangeSide.start;
    if (isEnd && _startDate != null) side = RangeSide.end;

    return GestureDetector(
      onTap: future ? null : () => _onDayTap(day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Range background strip
            if (side != null) Positioned.fill(child: _RangeStrip(side: side)),

            // Day circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          FluidColors.primary,
                          Color.lerp(
                            FluidColors.primary,
                            const Color(0xFF7C3AED),
                            0.6,
                          )!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FluidColors.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                  : isToday
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FluidColors.primary,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Center(
                child: Text(
                  "${day.day}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : future
                        ? Colors.grey.shade300
                        : inRange
                        ? FluidColors.primary
                        : colIndex == 6
                        ? Colors.red.shade300
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// HELPERS
// =================================================================

enum RangeSide { start, middle, end }

class _RangeStrip extends StatelessWidget {
  final RangeSide side;
  const _RangeStrip({required this.side});

  @override
  Widget build(BuildContext context) {
    final color = FluidColors.primary.withOpacity(0.1);
    return ClipRect(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: side == RangeSide.start
                ? const BorderRadius.horizontal(left: Radius.circular(18))
                : side == RangeSide.end
                ? const BorderRadius.horizontal(right: Radius.circular(18))
                : BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavButton({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled ? Colors.grey.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled ? Colors.grey.shade300 : const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// =================================================================
// PENGGUNAAN DI profile_screen.dart
// =================================================================
//
// 1. Import file ini:
//    import 'package:hadirin/ui/widgets/custom_date_range_picker.dart';
//
// 2. Ganti method _pickDateRange() dengan versi ini:
//
//  Future<void> _pickDateRange() async {
//    final DateTimeRange? picked = await showCustomDateRangePicker(
//      context: context,
//      initialDateRange: _selectedDateRange,
//    );
//    if (picked != null) {
//      setState(() => _selectedDateRange = picked);
//      _applyFilter();
//    }
//  }
//
// =================================================================
