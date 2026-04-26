import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;

  AuthBloc(this._apiService) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.login(event.identifier, event.password);
      
      if (response['success'] == true) {
        emit(AuthAuthenticated(user: response['user']));
      } else {
        emit(AuthError(message: response['error'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Network error. Please check your connection.'));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _apiService.register(
        name: event.name,
        phone: event.phone,
        email: event.email,
        password: event.password,
      );

      if (response['success'] == true) {
        emit(AuthAuthenticated(user: response['user']));
      } else {
        emit(AuthError(message: response['error'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Network error. Please check your connection.'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _apiService.logout();
    emit(AuthUnauthenticated());
  }
}
