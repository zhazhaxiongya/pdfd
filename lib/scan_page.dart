import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  final ValueChanged<String> onScan;

  const ScanPage({super.key, required this.onScan});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late MobileScannerController controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: false, // ⭐ 重要，减少 Surface 压力
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleResult(String code) async {
    if (_handled) return;
    _handled = true;

    await controller.stop();

    if (!mounted) return;

    // ⭐ 将扫码结果通过回调传回 HomePage
    widget.onScan(code);

    // 返回上一页，而不是新建 HomePage
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫码')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code == null || code.isEmpty) return;
          _handleResult(code);
        },
      ),
    );
  }
}
