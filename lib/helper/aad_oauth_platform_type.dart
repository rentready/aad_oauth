import 'dart:io';

enum AadOAuthPlatformType { windows, android, ios, unsupported }

extension AadOAuthPlatformTypes on AadOAuthPlatformType {
  static AadOAuthPlatformType currentPlatform() {
    if (Platform.isWindows) return AadOAuthPlatformType.windows;
    if (Platform.isAndroid) return AadOAuthPlatformType.android;
    if (Platform.isIOS) return AadOAuthPlatformType.ios;
    return AadOAuthPlatformType.unsupported;
  }
}
