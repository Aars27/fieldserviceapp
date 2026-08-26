import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._remote, this._secureStorage);

  @override
  Future<Result<AuthUser>> login(String email, String password) async {
    try {
      final result = await _remote.login(email, password);
      await _secureStorage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return Ok(result.user);
    } on AuthException catch (e) {
      return Err(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }

  @override
  Future<void> logout() => _secureStorage.clearTokens();

  @override
  Future<bool> get hasSession => _secureStorage.hasValidSession;
}
