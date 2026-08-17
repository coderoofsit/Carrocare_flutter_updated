import 'package:carrocare_flutter/features/checkout/core/checkout_constants.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/vehicle_list/domain/entities/vehicle_list_args.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';

class RenewCheckoutMapper {
  static ({VehicleListArgs booking, VehicleItem vehicle}) fromOrder(
    OrderItem order,
  ) {
    final header = _resolveHeader(order);
    return (
      booking: VehicleListArgs(
        header: header,
        carName: order.plan.isNotEmpty ? order.plan : order.packageType,
        carPrice: '',
        carDesc: order.serviceType,
        carImage: order.vehicleImage,
        carId: order.vehicleId,
        displayPrice: '',
      ),
      vehicle: VehicleItem(
        id: order.vehicleId,
        vehicleType: order.packageType,
        make: order.vehicleMake,
        model: order.vehicleModel,
        category: order.packageType,
        vehicleNo: order.vehicleNo,
        color: '',
        apartmentName: '',
        parkingLotNo: '',
        parkingArea: '',
        preferredSchedule: '',
        preferredTime: '',
        image: order.vehicleImage,
      ),
    );
  }

  static String _resolveHeader(OrderItem order) {
    final service = order.serviceType.toLowerCase();
    final plan = order.plan.toLowerCase();
    final packageType = order.packageType.toLowerCase();

    if (service == 'wash') {
      if (plan.contains('bike') || packageType.contains('bike')) {
        return CheckoutConstants.serviceBikeWash;
      }
      return CheckoutConstants.serviceWash;
    }
    if ((service.contains('addon') || service.contains('extra')) &&
        (plan.contains('extrainterior') ||
            plan.contains('extra interior') ||
            packageType.contains('extrainterior') ||
            packageType.contains('extra interior'))) {
      return CheckoutConstants.serviceExtraInterior;
    }
    if (service.contains('disinfection') ||
        service.contains('disinsfection') ||
        packageType.contains('disinfection') ||
        packageType.contains('disinsfection')) {
      return CheckoutConstants.serviceDisinfection;
    }
    if (service.contains('addon') || service.contains('wax')) {
      return CheckoutConstants.serviceAddon;
    }
    return order.serviceType;
  }
}
