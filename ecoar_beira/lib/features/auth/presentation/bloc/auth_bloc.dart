import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  AuthLoginRequested({required this.email, required this.password});
  
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [name, email, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthGoogleLoginRequested extends AuthEvent {}

class AuthFacebookLoginRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  
  AuthAuthenticated({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class AuthRegistrationSuccess extends AuthState {
  final Map<String, dynamic> user;
  
  AuthRegistrationSuccess({required this.user});
  
  @override
  List<Object?> get props => [user];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthFacebookLoginRequested>(_onFacebookLoginRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock authentication
      if (event.email.isNotEmpty && event.password.length >= 6) {
        final user = {
          'id': 'user_123',
          'name': 'João Silva',
          'email': event.email,
          'level': 'Explorador',
          'points': 1250,
          'joinDate': DateTime.now().toIso8601String(),
        };
        
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Email ou senha inválidos'));
      }
    } catch (e) {
      emit(AuthError(message: 'Erro ao fazer login: ${e.toString()}'));
    }
  }
  
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock registration
      if (event.email.isNotEmpty && 
          event.password.length >= 6 && 
          event.name.isNotEmpty) {
        final user = {
          'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'name': event.name,
          'email': event.email,
          'level': 'Iniciante',
          'points': 0,
          'joinDate': DateTime.now().toIso8601String(),
        };
        
        emit(AuthRegistrationSuccess(user: user));
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Dados inválidos para registro'));
      }
    } catch (e) {
      emit(AuthError(message: 'Erro ao criar conta: ${e.toString()}'));
    }
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate logout process
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Erro ao fazer logout: ${e.toString()}'));
    }
  }
  
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Check if user is already logged in (SharedPreferences/Hive)
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock check - in real app, check stored token/session
      final hasValidSession = false; // Replace with actual check
      
      if (hasValidSession) {
        final user = {
          'id': 'user_123',
          'name': 'João Silva',
          'email': 'joao@email.com',
          'level': 'Explorador',
          'points': 1250,
        };
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate Google authentication
      await Future.delayed(const Duration(seconds: 2));
      
      final user = {
        'id': 'google_user_123',
        'name': 'Usuário Google',
        'email': 'usuario@gmail.com',
        'level': 'Iniciante',
        'points': 0,
        'provider': 'google',
      };
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Erro no login com Google: ${e.toString()}'));
    }
  }
  
  Future<void> _onFacebookLoginRequested(
    AuthFacebookLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Simulate Facebook authentication
      await Future.delayed(const Duration(seconds: 2));
      
      final user = {
        'id': 'fb_user_123',
        'name': 'Usuário Facebook',
        'email': 'usuario@facebook.com',
        'level': 'Iniciante',
        'points': 0,
        'provider': 'facebook',
      };
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: 'Erro no login com Facebook: ${e.toString()}'));
    }
  }
}
