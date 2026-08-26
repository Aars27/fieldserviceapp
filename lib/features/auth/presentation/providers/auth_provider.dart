import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fieldserviceapp/core/errors/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

final _secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final _dioClientProvider = Provider<Dio>((ref) {
  return DioClient(ref.read(_secureStorageProvider)).dio;
});

final _connectivityProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final _authRemoteProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(_dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(_authRemoteProvider),
    ref.read(_secureStorageProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final secureStorageProvider = _secureStorageProvider;
final dioProvider = _dioClientProvider;
final connectivityServiceProvider = _connectivityProvider;

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final hasSession = await ref.read(authRepositoryProvider).hasSession;

    return hasSession
        ? const AuthUser(id: '', name: '', email: '', role: '')
        : null;
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUseCaseProvider).call(email, password);
    switch (result) {
      case Ok(:final value):
        state = AsyncData(value);
        return null;
      case Err(:final failure):
        state = const AsyncData(null);
        return failure.message;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
