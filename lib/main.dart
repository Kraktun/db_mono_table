import 'package:flutter/material.dart';
import 'package:db_mono_table/login_page.dart';
import 'package:db_mono_table/table_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final routes = <String, WidgetBuilder>{
    LoginPage.ROUTE: (context) => LoginPage(),
    TablePage.ROUTE: (context) => TablePage(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShowRoom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        fontFamily: 'Nunito',
      ),
      home: LoginPage(),
      routes: routes,
    );
  }
}