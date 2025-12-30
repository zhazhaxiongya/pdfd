import 'package:flutter/material.dart';
import 'api.dart';
import 'pdf_view_page.dart';
import 'download_service.dart';
import 'download_page.dart';
import 'scan_page.dart'; // 扫码页

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController codeCtrl = TextEditingController(); // 底盘号
  final TextEditingController partCtrl = TextEditingController(); // 图号

  List<Map<String, dynamic>> list = [];
  bool loading = false;
  int pageIndex = 0;

  /* ================= Toast ================= */
  void showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  /* ================= 搜索 ================= */
  Future<void> search(String value) async {
    final v = value.trim();
    if (v.isEmpty) {
      showToast("请输入查询条件");
      return;
    }

    setState(() {
      loading = true;
      list.clear();
    });

    try {
      final r = await Api.queryDrawings(v);

      if (!mounted) return;
      setState(() {
        list = r;
      });

      if (r.isEmpty) {
        showToast("未查到图纸");
      }
    } catch (e) {
      if (mounted) {
        showToast("网络异常");
      }
    } finally {
      // ⭐⭐⭐ 关键：无论成功/失败/跳转，都必须关闭遮罩
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  /* ================= 打开扫码 ================= */
  void openScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanPage(
          onScan: (code) {
            // ⭐ 只填到底盘号
            codeCtrl.text = code;
            partCtrl.clear();
            search(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: pageIndex,
            children: [
              _buildSearchPage(),
              const DownloadPage(),
            ],
          ),

          // Loading 遮罩
          if (loading) ...[
            const ModalBarrier(
              dismissible: false,
              color: Colors.black45,
            ),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (i) => setState(() => pageIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "搜索"),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: "下载"),
        ],
      ),
    );
  }

  /* ================= 搜索页 ================= */
  Widget _buildSearchPage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              "图纸查询系统",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ===== 底盘号（扫码） =====
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          hintText: "底盘号 / 订单号",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: openScan,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        partCtrl.clear();
                        search(codeCtrl.text);
                      },
                      child: const Text("搜索"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== 图号搜索 =====
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.tag),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: partCtrl,
                        decoration: const InputDecoration(
                          hintText: "图号",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        codeCtrl.clear();
                        search(partCtrl.text);
                      },
                      child: const Text("搜索"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// ===== 搜索结果 =====
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text("暂无数据"))
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final item = list[i];

                  final indexNo = i + 1;
                  final paperId = item["PaperId"]?.toString() ?? "";
                  final partName = item["PartName"]?.toString() ?? "";
                  final paperName = item["PaperName"]?.toString() ?? "图纸";
                  final partNo = item["PartNo"]?.toString() ?? "";

                  final subDir = codeCtrl.text.isNotEmpty
                      ? codeCtrl.text
                      : partCtrl.text;

                  // 下载文件名：{part_name}_{paper_name}
                  final downloadName = "${partName}_${paperName}";

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),

                      // ✅ 显示名称
                      title: Text(
                        "$indexNo | $partName | $paperName",
                      ),

                      subtitle: Text("图号：$partNo"),

                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          // 👁 查看
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewPage(
                                    paperId,
                                    paperName,
                                    subDir: subDir,
                                  ),
                                ),
                              );
                            },
                          ),

                          // ⬇️ 下载
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () async {
                              await DownloadService.downloadPdf(
                                paperId,
                                downloadName, // ✅ 新命名规则
                                Api.token,
                                subDir: subDir,
                              );
                              showToast("下载完成");
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),


            const SizedBox(height: 6),

            // ===== 登录状态 =====
            Chip(
              label: Text(Api.logged ? "已登录" : "未登录"),
              avatar: Icon(
                Api.logged ? Icons.check_circle : Icons.error,
                color: Api.logged ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
