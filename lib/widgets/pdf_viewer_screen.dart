import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  Uint8List? _bytes;
  bool _compartilhando = false;

  Future<void> _compartilhar() async {
    if (_bytes == null || _compartilhando) return;
    setState(() => _compartilhando = true);
    try {
      final dir = await getTemporaryDirectory();
      final nome = widget.title.isNotEmpty
          ? '${widget.title.replaceAll(RegExp(r'[^\w\- ]+'), '').trim()}.pdf'
          : 'documento.pdf';
      final file = File('${dir.path}/$nome');
      await file.writeAsBytes(_bytes!, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
          subject: widget.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao compartilhar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _compartilhando = false);
    }
  }

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

      _bytes = resp.bodyBytes;
      final docFuture = PdfDocument.openData(_bytes!);
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: _compartilhando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            tooltip: 'Enviar / baixar',
            onPressed: _compartilhar,
          ),
        ],
      ),
      body: PdfViewPinch(controller: _controller),
    );
  }
}