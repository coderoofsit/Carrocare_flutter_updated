import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/constants/preferred_time_slots.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/wash_calendar_models.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class WashCalendarArgs {
  const WashCalendarArgs({
    required this.vehicleId,
    required this.orderId,
    required this.type,
  });

  final String vehicleId;
  final String orderId;
  final String type;
}

class WashCalendarPage extends StatefulWidget {
  const WashCalendarPage({super.key, required this.args});

  final WashCalendarArgs args;

  @override
  State<WashCalendarPage> createState() => _WashCalendarPageState();
}

class _WashCalendarPageState extends State<WashCalendarPage> {
  final OrdersRepository _repository = sl<OrdersRepository>();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;
  List<CalendarMarkedDay> _events = <CalendarMarkedDay>[];
  WashCalendarData? _washData;
  bool _showAddInternal = false;
  bool _scheduleSheetOpen = false;
  bool _showTimePicker = false;
  List<String> _activeTimeSlots = kCalendarPreferredTimes;

  String _token = '';
  String _customerId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    try {
      if (widget.args.type == 'extra') {
        final data = await _repository.getExtraInteriorCalendar(
          token: _token,
          customerId: _customerId,
          vehicleId: widget.args.vehicleId,
        );
        _events = data.days;
        _showAddInternal = false;
      } else {
        final data = await _repository.getWashCalendar(
          token: _token,
          customerId: _customerId,
          vehicleId: widget.args.vehicleId,
          orderId: widget.args.orderId,
        );
        _washData = data;
        _events = <CalendarMarkedDay>[
          ...data.washDays,
          ...data.internalDays,
        ];
        _showAddInternal =
            data.canScheduleDate1 || data.canScheduleDate2;
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<CalendarMarkedDay> _eventsOnDay(DateTime day) {
    return _events.where((event) => _isSameDay(event.date, day)).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Wash Calendar',
      onBack: () => context.pop(),
      actions: <Widget>[
        if (_showAddInternal && widget.args.type != 'extra')
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: AppColors.primary,
              elevation: 5,
              borderRadius: BorderRadius.circular(7),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => setState(() => _scheduleSheetOpen = true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '+ ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
      body: _loading
          ? const CarroCareLoadingOverlay()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TableCalendar<CalendarMarkedDay>(
                                    firstDay: DateTime.utc(2018),
                                    lastDay: DateTime.utc(2035, 12, 31),
                                    focusedDay: _focusedDay,
                                    selectedDayPredicate: (day) =>
                                        _selectedDay != null &&
                                        _isSameDay(_selectedDay!, day),
                                    eventLoader: _eventsOnDay,
                                    calendarStyle: const CalendarStyle(
                                      markerDecoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      todayDecoration: BoxDecoration(
                                        color: Color(0xFFFF5722),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedDecoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    headerStyle: const HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                      titleTextStyle: TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      leftChevronIcon: Icon(
                                        Icons.chevron_left,
                                        color: AppColors.white,
                                      ),
                                      rightChevronIcon: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.white,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                    onDaySelected: (selected, focused) {
                                      setState(() {
                                        _selectedDay = selected;
                                        _focusedDay = focused;
                                      });
                                      final dayEvents = _eventsOnDay(selected);
                                      if (dayEvents.isNotEmpty) {
                                        _showEventPopup(dayEvents.first);
                                      }
                                    },
                                    onPageChanged: (focused) {
                                      _focusedDay = focused;
                                    },
                                    calendarBuilders: CalendarBuilders(
                                      markerBuilder: (context, day, events) {
                                        if (events.isEmpty) {
                                          return null;
                                        }
                                        final hasWash = events.any(
                                          (e) =>
                                              e.kind == CalendarEventKind.wash,
                                        );
                                        final hasInternal = events.any(
                                          (e) =>
                                              e.kind !=
                                              CalendarEventKind.wash,
                                        );
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            if (hasWash)
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(
                                                  top: 34,
                                                  right: 2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            if (hasInternal)
                                              Container(
                                                width: 6,
                                                height: 6,
                                                margin: const EdgeInsets.only(
                                                  top: 34,
                                                  left: 2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.grey500,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (_scheduleSheetOpen)
                                _InternalScheduleSheet(
                                  dateType: _washData!.canScheduleDate1
                                      ? '1'
                                      : '2',
                                  internalId:
                                      _washData!.pendingInternalId ?? '',
                                  vehicleId: widget.args.vehicleId,
                                  orderId: widget.args.orderId,
                                  preferredTimes: kCalendarPreferredTimes,
                                  onClose: () => setState(
                                    () => _scheduleSheetOpen = false,
                                  ),
                                  onScheduled: () async {
                                    setState(() => _scheduleSheetOpen = false);
                                    await _load();
                                  },
                                ),
                  ],
                ),
    );
  }

  void _showEventPopup(CalendarMarkedDay event) {
    final status = event.status.toLowerCase();
    final noData = status == 'no' && event.imageUrl.isEmpty;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                noData ? 'No Data Found' : event.subtitle,
                textAlign: TextAlign.center,
              ),
              if (!noData && event.imageUrl.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Image.network(
                  event.imageUrl,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/placeholder.png',
                    height: 180,
                  ),
                ),
                if (event.status.isNotEmpty &&
                    event.status.toLowerCase() != 'no')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Washed Status: Cleaned',
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalScheduleSheet extends StatefulWidget {
  const _InternalScheduleSheet({
    required this.dateType,
    required this.internalId,
    required this.vehicleId,
    required this.orderId,
    required this.preferredTimes,
    required this.onClose,
    required this.onScheduled,
  });

  final String dateType;
  final String internalId;
  final String vehicleId;
  final String orderId;
  final List<String> preferredTimes;
  final VoidCallback onClose;
  final Future<void> Function() onScheduled;

  @override
  State<_InternalScheduleSheet> createState() => _InternalScheduleSheetState();
}

class _InternalScheduleSheetState extends State<_InternalScheduleSheet> {
  final OrdersRepository _repository = sl<OrdersRepository>();
  String? _scheduleDate;
  String? _scheduleTime;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;
  bool _showTimes = false;

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduleDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_scheduleDate == null || _scheduleTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose Date and Time')),
      );
      return;
    }
    setState(() => _submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final customerId = prefs.getString('customer_id') ?? '';
    try {
      final message = await _repository.scheduleInternalClean(
        token: token,
        customerId: customerId,
        vehicleId: widget.vehicleId,
        orderId: widget.orderId,
        scheduleDate: _scheduleDate!,
        scheduleTime: _scheduleTime!,
        comment: _commentController.text.trim(),
        dateType: widget.dateType,
        id: widget.internalId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await widget.onScheduled();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Schedule Internal Clean',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        _scheduleDate ?? 'Preferred Date',
                        style: TextStyle(
                          color: _scheduleDate == null
                              ? Colors.grey
                              : AppColors.black,
                        ),
                      ),
                      trailing: Image.asset(
                        'assets/images/down_arrow.png',
                        width: 16,
                        height: 16,
                      ),
                      onTap: _pickDate,
                    ),
                    ListTile(
                      title: Text(
                        _scheduleTime ?? 'Preferred Time',
                        style: TextStyle(
                          color: _scheduleTime == null
                              ? Colors.grey
                              : AppColors.black,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () {
                        if (_scheduleDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Choose Preferred Schedule'),
                            ),
                          );
                          return;
                        }
                        setState(() => _showTimes = !_showTimes);
                      },
                    ),
                    if (_showTimes)
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          itemCount: widget.preferredTimes.length,
                          itemBuilder: (context, index) {
                            final time = widget.preferredTimes[index];
                            return ListTile(
                              title: Text(time),
                              onTap: () {
                                setState(() {
                                  _scheduleTime = time;
                                  _showTimes = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Comments',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
