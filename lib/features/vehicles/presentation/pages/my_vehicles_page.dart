import 'package:carrocare_flutter/core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'MY VEHICLES',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openAddVehicle,
                    child: Container(
                      width: 45,
                      height: 45,
                      margin: const EdgeInsets.only(right: 10),
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
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFEDEFF1),
                child: BlocBuilder<MyVehiclesBloc, MyVehiclesState>(
                  builder: (context, state) {
                    if (state is MyVehiclesLoading || state is MyVehiclesInitial) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
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
                      padding: const EdgeInsets.all(10),
                      itemCount: vehicles.length,
                      itemBuilder: (_, index) => _VehicleCard(item: vehicles[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.item});

  final VehicleItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 140,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${item.make}-${item.model}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const Divider(height: 10),
                  _kv('Vehicle No.', item.vehicleNo),
                  _kv('Parking Lot', item.parkingLotNo),
                  _kv('Vehicle Color', item.color),
                  _kv('Parking Area', item.parkingArea),
                  _kv('Pref. Schedule', item.preferredSchedule),
                  _kv('Pref. Time', item.preferredTime),
                  _kv('Apartment Name', item.apartmentName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        '$key : $value',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.black,
        ),
      ),
    );
  }
}
