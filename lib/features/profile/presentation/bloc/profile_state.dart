part of 'profile_bloc.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    required this.apartments,
    required this.userType,
    this.errorMessage,
  });

  final UserProfile profile;
  final List<String> apartments;
  final String userType;
  final String? errorMessage;
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating(this.previous);

  final ProfileLoaded previous;
}

class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess(this.message);

  final String message;
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;
}
