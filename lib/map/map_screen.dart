import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../profile/profile_cubit.dart';
import '../profile/profile_repository.dart';
import '../profile/profile_setup_screen.dart';
import 'map_user.dart';
import 'placemark_icon_cache.dart';
import 'users_map_cubit.dart';
import 'users_map_repository.dart';
import 'users_map_state.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.uid,
    required this.currentName,
    required this.currentAvatarBase64,
  });

  final String uid;
  final String currentName;
  final String currentAvatarBase64;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersMapCubit(repository: UsersMapRepository(), uid: uid)
        ..start(),
      child: _MapView(
        uid: uid,
        currentName: currentName,
        currentAvatarBase64: currentAvatarBase64,
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView({
    required this.uid,
    required this.currentName,
    required this.currentAvatarBase64,
  });

  final String uid;
  final String currentName;
  final String currentAvatarBase64;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final _iconCache = PlacemarkIconCache();
  YandexMapController? _controller;
  bool _hasCenteredCamera = false;
  List<PlacemarkMapObject> _placemarks = [];
  late String _currentName = widget.currentName;
  late String _currentAvatarBase64 = widget.currentAvatarBase64;

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => ProfileCubit(
            repository: ProfileRepository(),
            uid: widget.uid,
            initialName: _currentName,
            initialAvatarBase64: _currentAvatarBase64,
          ),
          child: Builder(
            builder: (routeContext) => ProfileSetupScreen(
              onComplete: () {
                final profileState = routeContext.read<ProfileCubit>().state;
                setState(() {
                  _currentName = profileState.name;
                  _currentAvatarBase64 =
                      profileState.existingAvatarBase64 ?? _currentAvatarBase64;
                });
                Navigator.of(routeContext).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onUsersChanged(List<MapUser> users) async {
    final placemarks = <PlacemarkMapObject>[];
    for (final user in users) {
      try {
        final icon = _iconCache.iconFor(user.avatarBase64);
        placemarks.add(
          PlacemarkMapObject(
            mapId: MapObjectId(user.uid),
            point: Point(latitude: user.latitude, longitude: user.longitude),
            icon: PlacemarkIcon.single(PlacemarkIconStyle(image: icon)),
            text: PlacemarkText(
              text: user.name,
              style: const PlacemarkTextStyle(
                size: 12,
                placement: TextStylePlacement.bottom,
              ),
            ),
          ),
        );
      } catch (error, stackTrace) {
        // Skip this user's marker for this build rather than letting one
        // bad avatar fetch (e.g. a deleted/expired URL) blank the whole map.
        if (kDebugMode) {
          debugPrint('Failed to build placemark for ${user.uid}: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }

    if (!mounted) return;
    setState(() => _placemarks = placemarks);

    if (!_hasCenteredCamera && _controller != null) {
      MapUser? self;
      for (final user in users) {
        if (user.uid == widget.uid) {
          self = user;
          break;
        }
      }
      if (self != null) {
        _hasCenteredCamera = true;
        await _controller!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(latitude: self.latitude, longitude: self.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find My Friend'),
        actions: [
          IconButton(
            key: const Key('editProfileButton'),
            icon: const Icon(Icons.person),
            onPressed: _openEditProfile,
          ),
          IconButton(
            key: const Key('signOutButton'),
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<UsersMapCubit, UsersMapState>(
        listenWhen: (previous, current) => previous.users != current.users,
        listener: (context, state) => _onUsersChanged(state.users),
        builder: (context, state) {
          return Stack(
            children: [
              YandexMap(
                mapObjects: _placemarks,
                onMapCreated: (controller) {
                  _controller = controller;
                  _onUsersChanged(context.read<UsersMapCubit>().state.users);
                },
              ),
              if (state.hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Center(
                            child: Text(
                              'Reconnecting…',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
