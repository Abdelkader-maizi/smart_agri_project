import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  LoginRequested({required this.identifier, required this.password});

  @override
  List<Object?> get props => [identifier, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String email;
  final String password;

  RegisterRequested({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, phone, email, password];
}

class LogoutRequested extends AuthEvent {}
