import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({required this.status, this.uid, this.errorMessage});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(String uid)
      : this._(status: AuthStatus.authenticated, uid: uid);

  const AuthState.unauthenticated([String? errorMessage])
      : this._(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;
  final String? uid;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, uid, errorMessage];
}
