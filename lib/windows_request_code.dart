import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'model/config.dart';
import 'request/authorization_request.dart';

class WindowsRequestCode {
  static String className = 'RequestCodeWindows';

  final Config _config;
  final AuthorizationRequest _authorizationRequest;
  final String _redirectUriHost;
  String? _code;
  final WebviewController _controller;
  bool _isInitialized = false;
  StreamSubscription? _$onUrlChange;

  WindowsRequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config),
        _redirectUriHost = Uri.parse(config.redirectUri).host,
        _controller = WebviewController();

  String _constructUrlParams() => _mapToQueryParams(_authorizationRequest.parameters, _config.customParameters);

  String _mapToQueryParams(Map<String, String> params, Map<String, String> customParams) {
    final queryParams = <String>[];

    params.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    customParams.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));

    return queryParams.join('&');
  }

  void _onUrlChangeListener(String url) {
    try {
      var uri = Uri.parse(url);

      if (uri.queryParameters['error'] != null) {
        _config.navigatorKey.currentState!.pop();
      }

      var checkHost = uri.host == _redirectUriHost;

      if (uri.queryParameters['code'] != null && checkHost) {
        _code = uri.queryParameters['code'];
        _config.navigatorKey.currentState!.pop();
      }
    } catch (err) {
      print('$className: _onUrlChangeListener: err: $err');
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) await _controller.initialize();
    _isInitialized = true;
  }

  void dispose() {
    _$onUrlChange?.cancel();
    _controller.dispose();
  }

  Future<void> clearCookies() async {
    await initialize();
    await _controller.clearCookies();
  }

  Future<String?> requestCode() async {
    _code = null;

    final urlParams = _constructUrlParams();
    final launchUrl = '${_authorizationRequest.url}?$urlParams';

    await initialize();
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await _controller.loadUrl(launchUrl);

    _$onUrlChange ??= _controller.url.listen(_onUrlChangeListener);

    if (_config.navigatorKey.currentState == null) {
      throw Exception(
        'Could not push new route using provided navigatorKey, Because '
        'NavigatorState returned from provided navigatorKey is null. Please Make sure '
        'provided navigatorKey is passed to WidgetApp. This can also happen if at the time of this method call '
        'WidgetApp is not part of the flutter widget tree',
      );
    }

    await _config.navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          final webView = Webview(_controller);

          return Scaffold(
            appBar: _config.appBar,
            body: PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) async {
                if (didPop) return;

                final NavigatorState navigator = Navigator.of(context);
                navigator.pop();
              },
              child: SafeArea(
                child: Stack(
                  children: [_config.loader, webView],
                ),
              ),
            ),
          );
        },
      ),
    );
    return _code;
  }
}
