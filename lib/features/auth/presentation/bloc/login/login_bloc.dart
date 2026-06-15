import 'package:carrocare_flutter/core/utils/validators.dart';
import 'package:carrocare_flutter/features/auth/domain/usecases/auth_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUseCase) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter all the details'));
      return;
    }
    if (!Validators.isValidEmail(event.email)) {
      emit(state.copyWith(errorMessage: 'Enter valid Email ID'));
      return;
    }
    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));
    try {
      final response = await _loginUseCase(
        email: event.email.trim(),
        password: event.password,
      );
      if (response.code == '200') {
        emit(
          state.copyWith(
            status: LoginStatus.success,
            userName: response.name,
            userMobile: response.mobile,
            userEmail: response.email ?? event.email.trim(),
            userToken: response.token,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            customerId: response.customerId,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Timeout.Try after sometime',
        ),
      );
    }
  }
}
