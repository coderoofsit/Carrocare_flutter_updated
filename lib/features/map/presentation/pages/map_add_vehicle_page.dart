import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/storage/map_location_store.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/map/domain/entities/map_location_result.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Matches Android [MapAddVechileActivity] for door-step flow.
class MapAddVehiclePage extends StatefulWidget {
  const MapAddVehiclePage({super.key});

  @override
  State<MapAddVehiclePage> createState() => _MapAddVehiclePageState();
}

class _MapAddVehiclePageState extends State<MapAddVehiclePage> {
  final _repo = sl<VehiclesRepository>();
  final _store = MapLocationStore();

  final TextEditingController _vehicleNo = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _address = TextEditingController();

  String _category = '';
  String _makeModel = '';
  List<String> _makeModels = <String>[];
  bool _loading = false;
  bool _submitting = false;

  static const List<String> _categories = <String>['hatchback', 'sedan', 'suv'];
  static const Color _fieldBorder = Color(0xFF8F8F8F);
  static const Color _hintColor = Color(0xFF8F8F8F);

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final address = await _store.readAddress();
    if (address.isNotEmpty) {
      _address.text = address;
    }
  }

  @override
  void dispose() {
    _vehicleNo.dispose();
    _color.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadMakeModels() async {
    if (_category.isEmpty) return;
    setState(() => _loading = true);
    try {
      final list = await _repo.getMakeModels(_category);
      if (!mounted) return;
      setState(() {
        _makeModels = list;
        _makeModel = '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLocateMap() async {
    final result = await context.push<MapLocationResult>('/locate-on-map');
    if (result != null && mounted) {
      setState(() {
        _address.text = result.address;
      });
      await _store.savePick(
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
      );
    } else {
      await _loadAddress();
    }
  }

  Future<void> _submit() async {
    if (_makeModel.isEmpty ||
        _address.text.trim().isEmpty ||
        _vehicleNo.text.trim().isEmpty ||
        _color.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details')),
      );
      return;
    }

    final latitude = await _store.readLatitude();
    final longitude = await _store.readLongitude();
    if (!mounted) return;
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select address on map and tap Update location'),
        ),
      );
      return;
    }

    final parts = _makeModel.split('-');
    final make = parts.isNotEmpty ? parts.first : '';
    final model = parts.length > 1 ? parts.sublist(1).join('-') : '';

    final prefs = await SharedPreferences.getInstance();
    setState(() => _submitting = true);
    try {
      final message = await _repo.addDoorstepVehicle(
        category: _category,
        make: make,
        model: model,
        vehicleNo: _vehicleNo.text.trim(),
        color: _color.text.trim(),
        apartmentName: _address.text.trim(),
        latitude: latitude.toString(),
        longitude: longitude.toString(),
        customerId: prefs.getString('customer_id') ?? '',
        token: prefs.getString('token') ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.go('/door-step-service');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickCategory() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _categories
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (value == null) return;
    setState(() => _category = value);
    await _loadMakeModels();
  }

  Future<void> _pickMakeModel() async {
    if (_makeModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select vehicle category first')),
      );
      return;
    }
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _makeModels
              .map(
                (e) => ListTile(
                  title: Text(e),
                  onTap: () => Navigator.pop(context, e),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (value != null) setState(() => _makeModel = value);
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Add Vehicle',
      onBack: () => context.pop(),
      leadingWithContrastBackground: true,
      appBarElevation: 3,
      body: _loading
          ? const CarroCareLoadingOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                            _selectField(
                              label: _category.isEmpty
                                  ? 'Vehicle Category'
                                  : _category,
                              onTap: _pickCategory,
                            ),
                            _selectField(
                              label: _makeModel.isEmpty
                                  ? 'Make / Model'
                                  : _makeModel,
                              onTap: _pickMakeModel,
                            ),
                            _inputField(
                              controller: _vehicleNo,
                              hint: 'Vehicle Number',
                            ),
                            _inputField(
                              controller: _color,
                              hint: 'Vehicle Color',
                            ),
                            _selectField(
                              label: _address.text.isEmpty
                                  ? 'Tap to search and select address on map'
                                  : _address.text,
                              onTap: _openLocateMap,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('CANCEL'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('SUBMIT'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16, color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required VoidCallback onTap,
    int maxLines = 1,
  }) {
    final isPlaceholder = label == 'Vehicle Category' ||
        label == 'Make / Model' ||
        label == 'Address' ||
        label == 'Tap to search and select address on map';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _fieldBorder),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: isPlaceholder ? _hintColor : AppColors.black,
                ),
              ),
            ),
            Image.asset('assets/images/down_arrow.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}
