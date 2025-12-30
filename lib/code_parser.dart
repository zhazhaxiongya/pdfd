class CodeParser {
  // 底盘号 / 订单号 / VIN
  static bool isChassis(String code) {
    String c = code.replaceAll(" ", "");

    // 8位或12位纯数字（你系统最常见）
    if (RegExp(r'^\d{8}$').hasMatch(c)) return true;
    if (RegExp(r'^\d{12}$').hasMatch(c)) return true;

    // VIN（兜底）
    if (c.length >= 17 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(c)) {
      return true;
    }

    return false;
  }
}
