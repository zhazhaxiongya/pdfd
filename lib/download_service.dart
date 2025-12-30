import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Dio dio = Dio();

  // ===== 文件名安全处理 =====
  static String safeName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<File> downloadPdf(String paperId, String paperName, String token,
      {String? subDir, String? partNo}) async {
    try {
      Directory base = await getApplicationDocumentsDirectory();
      Directory dir = subDir == null || subDir.isEmpty
          ? base
          : Directory("${base.path}/$subDir");

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      String safePaperName = safeName(paperName);
      String fileName;

      if (safePaperName.toLowerCase().endsWith('.pdf')) {
        fileName = safePaperName;
      } else {
        fileName = "$safePaperName.pdf";
      }

      File file = File("${dir.path}/$fileName");

      if (file.existsSync()) {
        return file;
      }

      var r = await dio.post(
        "http://qmscloud.sinotruk.com:8102/api/qms-biz-iqc/taskm/getDrawing",
        data: {
          "paperId": paperId,
          "type": "tz",
          "userInfo": ""
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            "Blade-Auth": "bearer $token",
            "Tenant-Id": "985735",
          },
        ),
      );

      await file.writeAsBytes(r.data);

      return file;
    } catch (e) {
      rethrow;
    }
  }

  // 新增：获取所有PDF文件（包括子目录）
  static Future<List<FileSystemEntity>> getAllPdfFiles() async {
    Directory base = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> allFiles = [];

    void scanDirectory(Directory dir) {
      if (dir.existsSync()) {
        var files = dir.listSync(recursive: false);
        for (var entity in files) {
          if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
            allFiles.add(entity);
          } else if (entity is Directory) {
            scanDirectory(entity);
          }
        }
      }
    }

    scanDirectory(base);
    return allFiles;
  }

  // 新增：获取文件下载路径
  static Future<String> getDownloadPath(String paperName, {String? subDir}) async {
    Directory base = await getApplicationDocumentsDirectory();

    if (subDir == null || subDir.isEmpty) {
      return "${base.path}/${safeName(paperName)}.pdf";
    } else {
      Directory dir = Directory("${base.path}/$subDir");
      return "${dir.path}/${safeName(paperName)}.pdf";
    }
  }
}