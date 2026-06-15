import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:dio/dio.dart';

part 'my_orders_event.dart';
part 'my_orders_state.dart';

class MyOrdersBloc extends Bloc<MyOrdersEvent, MyOrdersState> {
  MyOrdersBloc(this._repository) : super(const MyOrdersInitial()) {
    on<MyOrdersStarted>((_, emit) => emit(const MyOrdersLoading()));
    on<MyOrdersRequested>(_onRequested);
  }

  final OrdersRepository _repository;

  Future<void> _onRequested(
    MyOrdersRequested event,
    Emitter<MyOrdersState> emit,
  ) async {
    emit(const MyOrdersLoading());
    try {
      final orders = await _repository.getOrders(
        token: event.token,
        customerId: event.customerId,
      );
      emit(MyOrdersLoaded(orders));
    } on DioException catch (e) {
      final root = e.error;
      if (root is FormatException) {
        emit(const MyOrdersFailure(
          'Could not read orders from server. Please try again.',
        ));
        return;
      }
      final message = e.message ?? '';
      final isConnectivity = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      emit(
        MyOrdersFailure(
          isConnectivity
              ? 'Network error. Please check your connection.'
              : (message.isEmpty
                  ? 'Failed to load orders. Please try again.'
                  : message),
        ),
      );
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Session expired')) {
        emit(const MyOrdersFailure('Session expired. Please login again.'));
        return;
      }
      emit(MyOrdersFailure(
        message.isEmpty ? 'Failed to load orders' : message,
      ));
    } on Object catch (e) {
      emit(MyOrdersFailure(
        e is Error ? e.toString() : 'Failed to load orders. Please try again.',
      ));
    }
  }
}
