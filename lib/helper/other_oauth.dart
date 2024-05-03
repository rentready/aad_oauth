import 'dart:io' show Platform;

import 'package:aad_oauth/helper/core_oauth.dart';
import 'package:aad_oauth/helper/mobile_oauth.dart';
import 'package:aad_oauth/helper/windows_oauth.dart';
import 'package:aad_oauth/model/config.dart';

CoreOAuth getOAuthConfig(Config config) => OtherOAuth(config);

class OtherOAuth extends CoreOAuth {
  factory OtherOAuth(Config config) {
    if (Platform.isWindows) {
      return WindowsOAuth(config);
    } else if (Platform.isAndroid || Platform.isIOS) {
      return MobileOAuth(config);
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
