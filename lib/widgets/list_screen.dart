import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  final String title;
  final Future<List<dynamic>> Function() loader;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? emptyText;

  const ListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.itemBuilder,
    this.actions,
    this.floatingActionButton,
    this.emptyText,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
      ),
      floatingActionButton: widget.floatingActionButton,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Erro: ${snap.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Text(widget.emptyText ?? 'Nenhum item encontrado.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) =>
                  widget.itemBuilder(context, items[i], i),
            );
          },
        ),
      ),
    );
  }
}
