import 'dart:io';
import 'package:flutter/material.dart';

import 'download_service.dart';
import 'pdf_view_page.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final list = await DownloadService.getAllPdfFiles();
    setState(() {
      _files = list.whereType<File>().toList();
      _loading = false;
    });
  }

  void _openPdf(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewPage(
          file.path, // ⚠️ 这里用 path 直接打开
          file.uri.pathSegments.last,
        ),
      ),
    );
  }

  Future<void> _delete(File file) async {
    await file.delete();
    _loadFiles();
  }

  // ⭐ 新增：全部删除
  Future<void> _deleteAll() async {
    for (final file in _files) {
      await file.delete();
    }
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已下载图纸'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loadFiles,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: '全部删除',
            onPressed: _files.isEmpty
                ? null
                : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('确认删除'),
                  content:
                  const Text('是否要删除所有已下载文件？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _deleteAll();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text('暂无下载文件'))
          : ListView.builder(
        itemCount: _files.length,
        itemBuilder: (_, i) {
          final file = _files[i];
          final name = file.uri.pathSegments.last;

          return Card(
            child: ListTile(
              leading:
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(name),
              subtitle: Text(file.parent.path),
              onTap: () => _openPdf(file),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _delete(file),
              ),
            ),
          );
        },
      ),
    );
  }
}
