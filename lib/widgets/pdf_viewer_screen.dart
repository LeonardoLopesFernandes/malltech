import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final String? cookie;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.cookie,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfControllerPinch _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final headers = <String, String>{};
      if (widget.cookie != null && widget.cookie!.isNotEmpty) {
        headers['Cookie'] = widget.cookie!;
      }

      final resp = await http.get(Uri.parse(widget.url), headers: headers);
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final docFuture = PdfDocument.openData(resp.bodyBytes);
      _controller = PdfControllerPinch(
        document: docFuture,
        initialPage: 1,
      );
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erro ao carregar PDF: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PdfViewPinch(controller: _controller),
    );
  }
}