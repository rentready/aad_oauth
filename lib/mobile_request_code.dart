import 'dart:async';

import 'package:aad_oauth/model/config.dart';
import 'package:aad_oauth/request/authorization_request.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileRequestCode {
  final Config _config;
  final AuthorizationRequest _authorizationRequest;
  final String _redirectUriHost;
  late NavigationDelegate _navigationDelegate;
  String? _code;
  late WebViewController _controller;

  MobileRequestCode(Config config)
      : _config = config,
        _authorizationRequest = AuthorizationRequest(config),
        _redirectUriHost = Uri.parse(config.redirectUri).host {
    _navigationDelegate = NavigationDelegate(
      onNavigationRequest: _onNavigationRequest,
    );
  }

  Future<String?> requestCode() async {
    _code = null;

    final urlParams = _constructUrlParams();
    final launchUri = Uri.parse('${_authorizationRequest.url}?$urlParams');

    _controller = WebViewController();

    await _controller.setNavigationDelegate(_navigationDelegate);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setUserAgent(_config.userAgent);
    await _controller.loadRequest(launchUri);
    // initialize js channel
    await _controller.addJavaScriptChannel('AadChannel', onMessageReceived: _onJavascriptMessageReceived);

    if (_config.onPageFinished != null) {
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _config.onPageFinished,
        ),
      );
    }

    final webView = WebViewWidget(controller: _controller);

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
        builder: (context) => Scaffold(
          appBar: _config.appBar,
          body: PopScope(
            canPop: false,
            onPopInvoked: (bool didPop) async {
              if (didPop) return;
              if (await _controller.canGoBack()) {
                await _controller.goBack();
                return;
              }
              final NavigatorState navigator = Navigator.of(context);
              navigator.pop();
            },
            child: SafeArea(
              child: Stack(
                children: [_config.loader, webView],
              ),
            ),
          ),
        ),
      ),
    );
    return _code;
  }

  Future<void> clearCookies() async {
    await WebViewCookieManager().clearCookies();
  }

  Future<NavigationDecision> _onNavigationRequest(NavigationRequest request) async {
    try {
      var uri = Uri.parse(request.url);

      if (uri.queryParameters['error'] != null) {
        _config.navigatorKey.currentState!.pop();
      }

      var checkHost = uri.host == _redirectUriHost;

      if (uri.queryParameters['code'] != null && checkHost) {
        _code = uri.queryParameters['code'];
        _config.navigatorKey.currentState!.pop();
      }
    } catch (_) {}
    return NavigationDecision.navigate;
  }

  String _constructUrlParams() => _mapToQueryParams(_authorizationRequest.parameters, _config.customParameters);

  String _mapToQueryParams(Map<String, String> params, Map<String, String> customParams) {
    final queryParams = <String>[];

    params.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));

    customParams.forEach((String key, String value) => queryParams.add('$key=${Uri.encodeQueryComponent(value)}'));
    return queryParams.join('&');
  }

  void _onJavascriptMessageReceived(JavaScriptMessage jsMessage) {
    if (_config.onJavascriptMessage != null) {
      _config.onJavascriptMessage!(jsMessage.message);
    }
  }
}
