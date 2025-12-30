import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

import 'download_service.dart';
import 'api.dart';

class PdfViewPage extends StatefulWidget {
  final String idOrPath;
  final String paperName;
  final String? subDir;

  const PdfViewPage(
      this.idOrPath,
      this.paperName, {
        this.subDir,
        super.key,
      });

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  PdfControllerPinch? _controller;

  int _currentPage = 1;
  int _totalPages = 0;
  bool _loading = true;

  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    File file;

    if (widget.idOrPath.toLowerCase().endsWith('.pdf')) {
      file = File(widget.idOrPath);
    } else {
      file = await DownloadService.downloadPdf(
        widget.idOrPath,
        widget.paperName,
        Api.token,
        subDir: widget.subDir,
      );
    }

    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(file.path),
    );

    setState(() => _loading = false);
  }

  /// 切换横屏（= 全屏）
  void _enterLandscape() {
    setState(() => _isLandscape = true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitLandscape() {
    setState(() => _isLandscape = false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _toggleLandscape() {
    _isLandscape ? _exitLandscape() : _enterLandscape();
  }

  /// Android 返回键：横屏时先退回竖屏
  Future<bool> _onWillPop() async {
    if (_isLandscape) {
      _exitLandscape();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller?.dispose();

    // 恢复默认竖屏，防止污染其他页面
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return Scaffold(
            backgroundColor: Colors.black,

            /// 竖屏才显示 AppBar
            appBar: isLandscape
                ? null
                : AppBar(
              title: Text(widget.paperName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.screen_rotation),
                  onPressed: _enterLandscape,
                ),
              ],
            ),

            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                /// PDF 本体
                PdfViewPinch(
                  controller: _controller!,
                  minScale: 0.8,
                  maxScale: 20.0,
                  onDocumentLoaded: (doc) {
                    setState(() => _totalPages = doc.pagesCount);
                  },
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                ),

                /// 页码（竖屏）
                if (!isLandscape)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _PageIndicator(
                        current: _currentPage,
                        total: _totalPages,
                      ),
                    ),
                  ),

                /// 横屏退出按钮（悬浮）
                if (isLandscape)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black54,
                      onPressed: _exitLandscape,
                      child:
                      const Icon(Icons.screen_lock_rotation),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 页码组件（复用 & 干净）
class _PageIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _PageIndicator({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
