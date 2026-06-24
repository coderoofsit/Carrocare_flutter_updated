import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/daily_wash/data/models/service_price_model.dart';
import 'package:carrocare_flutter/features/door_step/data/datasources/door_step_form_remote_data_source.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/confirm_form_args.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Matches Android [CarPolishActivity].
class CarPolishPage extends StatefulWidget {
  const CarPolishPage({super.key});

  @override
  State<CarPolishPage> createState() => _CarPolishPageState();
}

class _CarPolishPageState extends State<CarPolishPage> {
  final _remote = DoorStepFormRemoteDataSource(sl<ApiClient>());

  bool _loading = true;
  String? _error;
  String _description = '';
  List<DailyServiceModel> _services = <DailyServiceModel>[];

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
    try {
      final model = await _remote.getServicePrice('doorstep car machine polish');
      if ((model.code).toString() != '200') {
        throw Exception('Failed to load services');
      }
      if (!mounted) return;
      setState(() {
        _description = model.description;
        _services = model.services;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showInfo() {
    if (_description.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Doorstep Car Machine Polish'),
        content: SingleChildScrollView(
          child: Text(_stripHtml(_description)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Doorstep Car Machine Polish',
      onBack: () => context.pop(),
      actions: <Widget>[
        GestureDetector(
          onTap: _description.isEmpty ? null : _showInfo,
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: Opacity(
              opacity: _description.isEmpty ? 0.45 : 1,
              child: Image.asset('assets/images/info.png'),
            ),
          ),
        ),
      ],
      body: _loading
          ? const CarroCareLoadingOverlay()
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return _ServiceCard(service: service);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.push(
                            '/confirm-form',
                            extra: const ConfirmFormArgs(
                              mode: ConfirmFormMode.machinePolish,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          child: const Text('PROCEED'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final DailyServiceModel service;

  String get _displayPrice => service.prices;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/car-details',
            extra: CarDetailsArgs(
              carName: normalizeVehicleCategory(service.type),
              carPrice: service.prices,
              carDesc: service.description,
              carImage: service.image,
              carId: service.id,
              header: 'doorstep car machine polish',
              displayPrice: _displayPrice,
            ),
          );
        },
        child: SizedBox(
          height: 130,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 140,
                child: Image.network(
                  service.image,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        service.type.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          _stripHtml(service.description),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹ $_displayPrice',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
