import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/customer_full_schedule.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomerWashSchedulePage extends StatefulWidget {
  const CustomerWashSchedulePage({super.key});

  @override
  State<CustomerWashSchedulePage> createState() =>
      _CustomerWashSchedulePageState();
}

class _CustomerWashSchedulePageState extends State<CustomerWashSchedulePage>
    with SingleTickerProviderStateMixin {
  final OrdersRepository _repository = sl<OrdersRepository>();
  late final TabController _tabController;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  String? _error;
  String _selectedVehicleId = '';

  List<CustomerScheduleVehicle> _vehicles = const [];
  List<CustomerScheduleEvent> _subscriptionEvents = const [];
  List<CustomerScheduleEvent> _extraEvents = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final customerId = prefs.getString('customer_id') ?? '';
    try {
      final data = await _repository.getCustomerFullSchedule(
        token: token,
        customerId: customerId,
      );
      if (!mounted) return;
      setState(() {
        _vehicles = data.vehicles;
        _subscriptionEvents = data.subscriptionEvents;
        _extraEvents = data.extraInteriorEvents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<CustomerScheduleEvent> get _activeEvents {
    final source =
        _tabController.index == 0 ? _subscriptionEvents : _extraEvents;
    if (_selectedVehicleId.isEmpty) return source;
    return source
        .where((e) => e.vehicleId == _selectedVehicleId)
        .toList(growable: false);
  }

  List<CustomerScheduleEvent> _eventsOnDay(DateTime day) {
    return _activeEvents.where((e) => _isSameDay(e.date, day)).toList();
  }

  Color _dotColor(CustomerScheduleEvent event) {
    switch (event.eventType) {
      case 'internal_clean':
        return const Color(0xFF2F80ED);
      case 'addon':
        return const Color(0xFFF2994A);
      case 'extra_interior':
        return const Color(0xFF9B51E0);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Wash Details',
      onBack: () => context.pop(),
      actions: <Widget>[
        IconButton(
          tooltip: 'Raise a complaint',
          onPressed: () => context.push('/complaint'),
          icon: const Icon(
            Icons.report_gmailerrorred_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
      body: Column(
        children: <Widget>[
          Material(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const <Widget>[
                Tab(text: 'Subscriptions & Internal Cleans'),
                Tab(text: 'Extra Interiors & Add-Ons'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: DottedLoader());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_vehicles.isEmpty) {
      return const Center(
        child: Text('No vehicles found on your account.'),
      );
    }

    return Column(
      children: <Widget>[
        _VehicleChipBar(
          vehicles: _vehicles,
          selectedVehicleId: _selectedVehicleId,
          onSelected: (id) => setState(() => _selectedVehicleId = id),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _Legend(isSubscriptionTab: _tabController.index == 0),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TableCalendar<CustomerScheduleEvent>(
                firstDay: DateTime.utc(2018),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null && _isSameDay(_selectedDay!, day),
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
                    _showDaySheet(selected, dayEvents);
                  }
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final colors = <Color>{};
                    for (final event in events) {
                      colors.add(_dotColor(event));
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: colors
                            .take(3)
                            .map(
                              (color) => Container(
                                width: 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDaySheet(DateTime day, List<CustomerScheduleEvent> events) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: events.length > 1 ? 0.72 : 0.58,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          DateFormat('d MMM yyyy').format(day),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ReadOnlyEventCard(event: events[index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VehicleChipBar extends StatelessWidget {
  const _VehicleChipBar({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
  });

  final List<CustomerScheduleVehicle> vehicles;
  final String selectedVehicleId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        children: <Widget>[
          _chip(
            label: 'All Vehicles',
            selected: selectedVehicleId.isEmpty,
            onTap: () => onSelected(''),
          ),
          ...vehicles.map(
            (v) => _chip(
              label: v.label,
              selected: selectedVehicleId == v.vehicleId,
              onTap: () => onSelected(v.vehicleId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryTint,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.grey700,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.grey300,
        ),
        backgroundColor: AppColors.white,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.isSubscriptionTab});

  final bool isSubscriptionTab;

  @override
  Widget build(BuildContext context) {
    final items = isSubscriptionTab
        ? const <(Color, String)>[
            (AppColors.primary, 'External Wash'),
            (Color(0xFF2F80ED), 'Internal Clean'),
          ]
        : const <(Color, String)>[
            (Color(0xFFF2994A), 'Wax Polish'),
            (Color(0xFF9B51E0), 'Extra Interior'),
          ];
    return Row(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.$1,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReadOnlyEventCard extends StatelessWidget {
  const _ReadOnlyEventCard({required this.event});

  final CustomerScheduleEvent event;

  String get _statusLabel {
    if (event.isCompleted) return 'Cleaned';
    if (event.isReported) return 'Issue Reported';
    return 'Pending';
  }

  Color get _statusColor {
    if (event.isCompleted) return const Color(0xFF219653);
    if (event.isReported) return const Color(0xFFF2994A);
    return AppColors.grey500;
  }

  String? get _timestampLabel {
    final at = event.completedAt ?? event.reportedAt ?? event.startedAt;
    if (at == null) return null;
    final local = at.toLocal();
    final prefix = event.isCompleted
        ? 'Completed'
        : event.isReported
            ? 'Reported'
            : 'Started';
    return '$prefix: ${DateFormat('d MMM yyyy, hh:mm a').format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = event.vehicleNo.isNotEmpty
        ? event.vehicleNo
        : event.vehicleId;
    final remarks = event.notes.isNotEmpty
        ? event.notes
        : event.reportNote;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${event.title} - $vehicle',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (event.scheduleTime.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${event.scheduleTime}',
              style: const TextStyle(color: AppColors.grey600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (_timestampLabel != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _timestampLabel!,
              style: const TextStyle(
                color: AppColors.grey700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (remarks.isNotEmpty || event.reportType.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Labour notes & remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (event.reportType.isNotEmpty)
                    Text(
                      event.reportType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  if (remarks.isNotEmpty)
                    Text(
                      remarks,
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
          if (event.beforeImageUrls.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _PhotoGallery(
              title: 'Before Wash',
              urls: event.beforeImageUrls,
            ),
          ],
          if (event.washedImageUrls.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _PhotoGallery(
              title: 'After Wash',
              urls: event.washedImageUrls,
            ),
          ],
          if (event.reportImageUrls.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _PhotoGallery(
              title: 'Issue Photos',
              urls: event.reportImageUrls,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.title, required this.urls});

  final String title;
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '📸 $title',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final url = urls[index];
              return GestureDetector(
                onTap: () => _openZoom(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 84,
                      height: 84,
                      color: AppColors.grey200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
