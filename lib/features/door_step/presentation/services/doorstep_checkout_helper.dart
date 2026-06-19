import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/checkout_navigation.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/razorpay_price_summary_sheet.dart';
import 'package:carrocare_flutter/features/door_step/core/doorstep_service_type_mapper.dart';
import 'package:carrocare_flutter/features/door_step/data/datasources/door_step_remote_data_source.dart';
import 'package:carrocare_flutter/features/door_step/presentation/widgets/doorstep_payment_sheet.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoorstepCheckoutHelper {
  DoorstepCheckoutHelper({
    DoorStepRemoteDataSource? remote,
    CheckoutRepository? checkoutRepository,
  })  : _remote = remote ?? DoorStepRemoteDataSource(sl<ApiClient>()),
        _checkoutRepository = checkoutRepository ?? sl<CheckoutRepository>();

  final DoorStepRemoteDataSource _remote;
  final CheckoutRepository _checkoutRepository;

  Future<void> completeBooking({
    required BuildContext context,
    required String action,
    required String packType,
    required String packAmount,
    required String serviceLabel,
    required VehicleItem vehicle,
    required String address,
    required String latitude,
    required String longitude,
    required String scheduleDate,
    required String scheduleTime,
    required int gstPercent,
  }) async {
    final price = int.tryParse(packAmount) ?? 0;
    final gstAmount = (price * gstPercent) ~/ 100;
    final total = price + gstAmount;
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    final method = await showDoorstepPaymentSheet(
      context: context,
      serviceLabel: serviceLabel,
      totalAmount: total,
    );
    if (method == null || !context.mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final customerId = prefs.getString('customer_id') ?? '';
    final token = prefs.getString('token') ?? '';
    final serviceType = DoorstepServiceTypeMapper.serviceTypeForAction(action);
    final orderParams = <String, String>{
      'customerId': customerId,
      'token': token,
      'packType': packType,
      'packAmount': packAmount,
      'vehicleId': vehicle.id,
      'serviceType': serviceType,
      'subTotal': '$price',
      'gst': '$gstPercent',
      'gstAmount': '$gstAmount',
      'totalAmount': '$total',
      'scheduleDate': scheduleDate,
      'scheduleTime': scheduleTime,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (method == DoorstepPaymentMethod.cod) {
      if (!context.mounted) return;
      await _placeCodOrder(context, orderParams, router: router);
      return;
    }
    if (!context.mounted) return;
    await _placeOnlineOrder(
      router: router,
      context: context,
      orderParams: orderParams,
      serviceLabel: serviceLabel,
      total: total,
      gstPercent: gstPercent,
      email: prefs.getString('email') ??
          prefs.getString('useremail') ??
          '',
      mobile: prefs.getString('mobile') ??
          prefs.getString('usermobile') ??
          '',
    );
  }

  Future<void> _placeCodOrder(
    BuildContext context,
    Map<String, String> params, {
    required GoRouter router,
  }) async {
    try {
      final data = await _remote.saveDoorstepCodOrder(
        customerId: params['customerId']!,
        token: params['token']!,
        packType: params['packType']!,
        packAmount: params['packAmount']!,
        vehicleId: params['vehicleId']!,
        serviceType: params['serviceType']!,
        subTotal: params['subTotal']!,
        gst: params['gst']!,
        gstAmount: params['gstAmount']!,
        totalAmount: params['totalAmount']!,
        scheduleDate: params['scheduleDate']!,
        scheduleTime: params['scheduleTime']!,
        address: params['address']!,
        latitude: params['latitude']!,
        longitude: params['longitude']!,
      );
      if (!context.mounted) return;
      final code = (data['code'] ?? '').toString();
      final message = (data['result'] ?? data['message'] ?? 'Order placed')
          .toString();
      if (code != '200') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isEmpty ? 'Order failed' : message)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      goToMyOrders(router);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _placeOnlineOrder({
    required GoRouter router,
    required BuildContext context,
    required Map<String, String> orderParams,
    required String serviceLabel,
    required int total,
    required int gstPercent,
    required String email,
    required String mobile,
  }) async {
    final priceSummary = RazorpayPriceSummary.fromInclusive(
      serviceLabel: serviceLabel,
      inclusiveTotal: total,
      gstPercent: gstPercent,
    );
    final razorpay = RazorpayCheckoutService();
    try {
      if (!context.mounted) return;
      final confirmed = await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
        onConfirmPay: () async {
          final keys = await _checkoutRepository.getRazorpayKeys();
          final paymentId = await razorpay.openAndWait(
            keyId: keys.keyId,
            amountPaise: total * 100,
            description: serviceLabel,
            email: email,
            contact: mobile,
            priceSummary: priceSummary,
          );
          final data = await _remote.saveDoorstepOnlineOrder(
            paymentId: paymentId,
            customerId: orderParams['customerId']!,
            token: orderParams['token']!,
            packType: orderParams['packType']!,
            packAmount: orderParams['packAmount']!,
            vehicleId: orderParams['vehicleId']!,
            serviceType: orderParams['serviceType']!,
            subTotal: orderParams['subTotal']!,
            gst: orderParams['gst']!,
            gstAmount: orderParams['gstAmount']!,
            totalAmount: orderParams['totalAmount']!,
            scheduleDate: orderParams['scheduleDate']!,
            scheduleTime: orderParams['scheduleTime']!,
            address: orderParams['address']!,
            latitude: orderParams['latitude']!,
            longitude: orderParams['longitude']!,
          );
          if ((data['code'] ?? '').toString() != '200') {
            throw Exception(
              (data['result'] ?? data['message'] ?? 'Order failed').toString(),
            );
          }
        },
      );
      if (!confirmed) return;
      goToPaymentSuccess(router);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Timeout') ||
                    e.toString().contains('cancelled')
                ? 'Payment cancelled'
                : e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      razorpay.dispose();
    }
  }
}
