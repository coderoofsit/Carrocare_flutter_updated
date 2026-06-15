import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/billing/domain/entities/billing_item.dart';
import 'package:carrocare_flutter/features/billing/domain/repositories/billing_repository.dart';
import 'package:dio/dio.dart';

part 'my_billing_event.dart';
part 'my_billing_state.dart';

class MyBillingBloc extends Bloc<MyBillingEvent, MyBillingState> {
  MyBillingBloc(this._repository) : super(const MyBillingInitial()) {
    on<MyBillingRequested>(_onRequested);
  }

  final BillingRepository _repository;

  Future<void> _onRequested(
    MyBillingRequested event,
    Emitter<MyBillingState> emit,
  ) async {
    emit(const MyBillingLoading());
    try {
      final billings = await _repository.getBillings(
        token: event.token,
        customerId: event.customerId,
      );
      emit(MyBillingLoaded(billings));
    } on DioException catch (e) {
      final root = e.error;
      if (root is FormatException) {
        emit(const MyBillingFailure(
          'Could not read billings from server. Please try again.',
        ));
        return;
      }
      final isConnectivity = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      emit(
        MyBillingFailure(
          isConnectivity
              ? 'Network error. Please check your connection.'
              : (e.message?.isNotEmpty == true
                  ? e.message!
                  : 'Failed to load billings. Please try again.'),
        ),
      );
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Session expired')) {
        emit(const MyBillingFailure('Session expired. Please login again.'));
        return;
      }
      emit(MyBillingFailure(
        message.isEmpty ? 'Failed to load billings' : message,
      ));
    } catch (_) {
      emit(const MyBillingFailure('Timeout.Try after sometime'));
    }
  }
}
