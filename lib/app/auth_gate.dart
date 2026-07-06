import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_bloc.dart';
import '../auth/auth_screen.dart';
import '../auth/auth_state.dart';
import '../map/map_screen.dart';
import '../profile/profile_cubit.dart';
import '../profile/profile_repository.dart';
import '../profile/profile_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return const AuthScreen();
          case AuthStatus.authenticated:
            return _ProfileGate(uid: state.uid!);
        }
      },
    );
  }
}

class _ProfileGate extends StatelessWidget {
  const _ProfileGate({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        final name = data?['name'] as String?;
        final avatarBase64 = data?['avatarBase64'] as String?;

        if (name == null || avatarBase64 == null) {
          return BlocProvider(
            create: (_) => ProfileCubit(repository: ProfileRepository(), uid: uid),
            child: Builder(
              builder: (routeContext) => ProfileSetupScreen(
                onComplete: () {
                  final profileState = routeContext.read<ProfileCubit>().state;
                  Navigator.of(routeContext).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => MapScreen(
                        uid: uid,
                        currentName: profileState.name,
                        currentAvatarBase64: profileState.existingAvatarBase64!,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        return MapScreen(
          uid: uid,
          currentName: name,
          currentAvatarBase64: avatarBase64,
        );
      },
    );
  }
}
