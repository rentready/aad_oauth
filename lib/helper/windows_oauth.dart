import 'package:aad_oauth/helper/auth_storage.dart';
import 'package:aad_oauth/helper/core_oauth.dart';
import 'package:aad_oauth/helper/other_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:aad_oauth/model/failure.dart';
import 'package:aad_oauth/model/token.dart';
import 'package:aad_oauth/request_token.dart';
import 'package:aad_oauth/windows_request_code.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

OtherOAuth getOAuthConfig(Config config) => WindowsOAuth(config);

class WindowsOAuth extends CoreOAuth implements OtherOAuth {
  final AuthStorage _authStorage;
  final WindowsRequestCode _requestCode;
  final RequestToken _requestToken;

  WindowsOAuth(Config config)
      : _authStorage = AuthStorage(
          tokenIdentifier: config.tokenIdentifier,
          aOptions: config.aOptions,
        ),
        _requestCode = WindowsRequestCode(config),
        _requestToken = RequestToken(config);

  Future<void> _removeOldTokenOnFirstLogin() async {
    var prefs = await SharedPreferences.getInstance();
    final keyFreshInstall = 'freshInstall';

    if (!prefs.getKeys().contains(keyFreshInstall)) {
      await logout();
      await prefs.setBool(keyFreshInstall, false);
    }
  }

  Future<Either<Failure, Token>> _performFullAuthFlow() async {
    var code = await _requestCode.requestCode();

    if (code == null) {
      return Left(AadOauthFailure(
        errorType: ErrorType.accessDeniedOrAuthenticationCanceled,
        message: 'Access denied or authentication canceled.',
      ));
    }

    return await _requestToken.requestToken(code);
  }

  Future<Either<Failure, Token>> _authorization({bool refreshIfAvailable = false}) async {
    var token = await _authStorage.loadTokenFromCache();

    if (!refreshIfAvailable) {
      if (token.hasValidAccessToken()) {
        return Right(token);
      }
    }

    if (token.hasRefreshToken()) {
      final result = await _requestToken.requestRefreshToken(token.refreshToken!);
      //If refresh token request throws an exception, we have to do
      //a fullAuthFlow.
      result.fold((l) => token.accessToken = null, (r) => token = r);
    }

    if (!token.hasValidAccessToken()) {
      final result = await _performFullAuthFlow();
      Failure? failure;
      result.fold((l) => failure = l, (r) => token = r);

      if (failure != null) {
        return Left(failure!);
      }
    }

    await _authStorage.saveTokenToCache(token);
    return Right(token);
  }

  @override
  Future<Either<Failure, Token>> login({bool refreshIfAvailable = false}) async {
    await _removeOldTokenOnFirstLogin();
    return await _authorization(refreshIfAvailable: refreshIfAvailable);
  }

  @override
  Future<void> logout({bool showPopup = true}) async {
    await _authStorage.clear();
    await _requestCode.clearCookies();
  }

  @override
  Future<String?> getIdToken() async => (await _authStorage.loadTokenFromCache()).idToken;
}
