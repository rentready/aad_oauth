import 'package:aad_oauth/helper/aad_oauth_platform_type.dart';
import 'package:aad_oauth/helper/core_oauth.dart';
import 'package:aad_oauth/model/config.dart';

CoreOAuth getOAuthConfig(Config config, {AadOAuthPlatformType? platformType}) =>
    CoreOAuth.fromConfig(config, platformType: platformType);
