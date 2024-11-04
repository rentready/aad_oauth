import 'package:aad_oauth/helper/aad_oauth_platform_type.dart';
import 'package:aad_oauth/helper/core_oauth.dart';
import 'package:aad_oauth/helper/mobile_oauth.dart';
import 'package:aad_oauth/helper/windows_oauth.dart';
import 'package:aad_oauth/model/config.dart';

CoreOAuth getOAuthConfig(Config config, {AadOAuthPlatformType? platformType}) =>
    OtherOAuth(config, platformType: platformType);

class OtherOAuth extends CoreOAuth {
  factory OtherOAuth(Config config, {AadOAuthPlatformType? platformType}) {
    platformType ??= AadOAuthPlatformTypes.currentPlatform();

    switch (platformType) {
      case AadOAuthPlatformType.windows:
        return WindowsOAuth(config);
      case AadOAuthPlatformType.android:
      case AadOAuthPlatformType.ios:
        return MobileOAuth(config);
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
