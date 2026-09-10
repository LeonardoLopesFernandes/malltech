import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/session.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String path;
  const WebViewScreen({super.key, required this.title, required this.path});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final isAbsolute = widget.path.startsWith('http');
    final uri = isAbsolute
        ? Uri.parse(widget.path)
        : Uri.parse(ApiConfig.v3 + widget.path);
    final params = <String, String>{};
    if (!isAbsolute && Session.token.value != null) {
      params['token'] = Session.token.value!;
    }
    if (!isAbsolute) params['integrated'] = 'true';
    final url = uri.replace(queryParameters: params).toString();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      );
    final sessid = Api.phpsessid;
    if (sessid.isNotEmpty) {
      for (final domain in ['v3.madnezz.com.br', 'sal.madnezz.com.br']) {
        WebViewCookieManager().setCookie(
          WebViewCookie(
            name: 'PHPSESSID',
            value: sessid,
            domain: domain,
            path: '/',
          ),
        );
      }
    }
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
