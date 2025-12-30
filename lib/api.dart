import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static String baseUrl = "http://qmscloud.sinotruk.com:8102";
  static String tenantId = "985735";

  static String token = "";
  static bool logged = false;
  static String currentUser = "";

  // 统一管理用户列表
  static List<String> users = [
    "080681",
    "053262",
    "058200",
    "052202",
    "068238",
    "076200",
    "077046",
  ];

  static String password = "4de1fac35e8caff5e19b01bee60c9652";

  static Map<String, String> baseHeaders() {
    return {
      "Authorization": "Basic c2FiZXI6c2FiZXJfc2VjcmV0",
      "Tenant-Id": tenantId,
    };
  }

  static Map<String, String> authHeaders() {
    return {
      "Tenant-Id": tenantId,
      "Blade-Auth": "bearer $token",
      "Content-Type": "application/json",
    };
  }

  /// 统一随机登录入口
  static Future<void> loginRandom() async {
    if (logged && token.isNotEmpty) return;

    // 清理空用户名
    List<String> validUsers =
    users.where((u) => u.trim().isNotEmpty).toList();
    if (validUsers.isEmpty) {
      throw Exception("用户列表为空！");
    }

    // 随机选择用户名
    currentUser = validUsers[Random().nextInt(validUsers.length)];

    await login(currentUser, password);
    print("登录成功，当前用户名: $currentUser");
  }

  /// 登录函数
  static Future<void> login(String user, String pwd) async {
    var r = await http.post(
      Uri.parse("$baseUrl/api/blade-auth/oauth/token"),
      headers: baseHeaders(),
      body: {
        "tenantId": tenantId,
        "username": user,
        "password": pwd,
        "grant_type": "password",
      },
    );

    var data = json.decode(r.body);
    token = data["access_token"] ?? "";
    logged = token.isNotEmpty;
    if (!logged) {
      throw Exception("登录失败: ${r.body}");
    }
  }

  /// 以下方法保持原逻辑，可查询图号、图纸等
  static Future<List<String>> getPartNos(String input) async {
    await loginRandom();

    int flag = input.length == 8 ? 1 : 2;

    var r = await http.get(
      Uri.parse(
        "$baseUrl/api/qms-biz-iqc/taskm/getPartNo?flag=$flag&carOrOrderNo=$input",
      ),
      headers: authHeaders(),
    );

    var jsonData = json.decode(r.body);
    var data = jsonData["data"]?["data"] ?? {};

    List<String> partNos = [];

    String r2 = data["remark2"]?.toString().trim() ?? "";
    String r3 = data["remark3"]?.toString().trim() ?? "";

    if (r2.isNotEmpty) partNos.add(r2);
    if (r3.isNotEmpty) partNos.add(r3);
    if (partNos.isEmpty) partNos.add(input);

    return partNos;
  }

  static Future<List<Map<String, dynamic>>> getDrawingsByPartNo(String partNo) async {
    var r = await http.post(
      Uri.parse("$baseUrl/api/qms-biz-iqc/taskm/getDrawingInfo"),
      headers: authHeaders(),
      body: json.encode({
        "PartNo": partNo,
        "FactoryName": "卡车",
        "Remark1": "1",
      }),
    );

    var jsonData = json.decode(r.body);
    if (jsonData["success"] == true && jsonData["data"] != null) {
      return List<Map<String, dynamic>>.from(jsonData["data"]);
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> queryDrawings(String input) async {
    List<Map<String, dynamic>> all = [];

    List<String> partNos = await getPartNos(input);
    for (var p in partNos) {
      var list = await getDrawingsByPartNo(p);
      all.addAll(list);
    }

    final Map<String, Map<String, dynamic>> unique = {};
    for (var item in all) {
      var id = item["PaperId"];
      if (id != null) unique[id.toString()] = item;
    }

    return unique.values.toList();
  }
}
