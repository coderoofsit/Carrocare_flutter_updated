import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/core/utils/session_debug.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:carrocare_flutter/features/vehicles/presentation/bloc/my_vehicles_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  String _token = '';
  String _customerId = '';

  @override
  void initState() {
    super.initState();
    _loadSessionAndFetch();
  }

  Future<void> _loadSessionAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    await SessionDebug.logCustomerId(tag: 'MyVehicles');
    if (!mounted) return;
    context.read<MyVehiclesBloc>().add(
      MyVehiclesRequested(customerId: _customerId, token: _token),
    );
  }

  Future<void> _openAddVehicle() async {
    await context.push('/add-vehicle');
    if (!mounted) return;
    context.read<MyVehiclesBloc>().add(
      MyVehiclesRequested(customerId: _customerId, token: _token),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'My Vehicles',
      onBack: () => context.pop(),
      actions: <Widget>[
        GestureDetector(
          onTap: _openAddVehicle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/vectors/ic_add_circle.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ],
      body: BlocBuilder<MyVehiclesBloc, MyVehiclesState>(
        builder: (context, state) {
          if (state is MyVehiclesLoading || state is MyVehiclesInitial) {
            return const CarroCareLoadingOverlay();
          }
          if (state is MyVehiclesFailure) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.black),
              ),
            );
          }
          final vehicles = (state as MyVehiclesLoaded).vehicles;
          if (vehicles.isEmpty) {
            return SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 24),
                    Image.asset('assets/images/tyre.png', height: 200),
                    const SizedBox(height: 12),
                    const Text(
                      'No vehicles added yet',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: vehicles.length,
            itemBuilder: (_, index) => _VehicleCard(item: vehicles[index]),
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.item});

  final VehicleItem item;

  @override
  Widget build(BuildContext context) {
    final title = '${item.make}-${item.model}'.trim();
    final displayTitle = title == '-' || title.isEmpty ? 'Vehicle' : title;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: _VehicleChip(
                  label: _displayValue(item.vehicleNo),
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              if (item.color.trim().isNotEmpty)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _VehicleChip(
                    label: _displayValue(item.color),
                    icon: Icons.palette_outlined,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayTitle,
                  style: AppTypography.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                if (item.category.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    _displayValue(item.category),
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const _SectionLabel(title: 'Parking details'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _InfoBlock(
                        label: 'Parking lot',
                        value: _displayValue(item.parkingLotNo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBlock(
                        label: 'Parking area',
                        value: _displayValue(item.parkingArea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionLabel(title: 'Wash preferences'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _InfoBlock(
                        label: 'Preferred schedule',
                        value: _displayValue(item.preferredSchedule),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBlock(
                        label: 'Preferred time',
                        value: _displayValue(item.preferredTime),
                      ),
                    ),
                  ],
                ),
                if (item.apartmentName.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  const _SectionLabel(title: 'Apartment'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.apartmentName.trim(),
                            style: AppTypography.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _displayValue(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.quicksand(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}
