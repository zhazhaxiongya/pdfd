import 'package:flutter/material.dart';
import 'api.dart';
import 'home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  bool logged = false;

  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  void autoLogin() async {
    await Api.loginRandom();
    setState(() {
      logged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: logged ? HomePage() : Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}