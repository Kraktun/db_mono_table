import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:db_mono_table/table_page.dart';
import 'package:db_mono_table/utils.dart';
import 'package:db_mono_table/consts.dart';


// Original from https://github.com/putraxor/flutter-login-ui under public domain


class LoginPage extends StatefulWidget {
  static const String ROUTE = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final passController = TextEditingController();
  final userController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    passController.dispose();
    userController.dispose();
    super.dispose();
  }

  Future<void> navigateAlreadyLogged() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_ID) ?? "";
    if (token.length > 0) {
      Navigator.of(context).pushNamed(TablePage.ROUTE);
    }
  }

  @override
  void initState() {
    super.initState();
    navigateAlreadyLogged();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 80.0,
        child: Image.asset('logo.png'),
      ),
    );

    final username = TextFormField(
      keyboardType: TextInputType.name,
      autofocus: false,
      controller: userController,
      decoration: InputDecoration(
        hintText: 'Username',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      validator: (value) {
        return value.isEmpty ? 'You must provide a username' : null;
      },
    );

    final password = TextFormField(
      autofocus: false,
      obscureText: true,
      controller: passController,
      decoration: InputDecoration(
        hintText: 'Password',
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      validator: (value) {
        return value.isEmpty ? 'You must provide a password' : null;
      },
    );

    Future<void> _login() async {
      try {
        final http.Response response = await http.post(
          '$SERVER_FULL_URL/login',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'user': userController.text,
            'password': passController.text,
          }),
        );
        if (response.statusCode == 202) {
          setState(() {
            passController.text = "";
          });
          Map<String, dynamic> l = json.decode(response.body);
          if (l.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            prefs.setString(TOKEN_ID, l["token"]);
          }
          Navigator.pop(context); // remove loading screen
          Navigator.of(context).pushNamed(TablePage.ROUTE);
        } else if (response.statusCode == 401) {
          Navigator.pop(context);
          showCustomDialog(context, "INVALID CREDENTIALS", "Invalid username/password");
        } else {
          Navigator.pop(context);
          showCustomDialog(context, "ERROR", "Server error");
        }
      } catch (e) {
        Navigator.pop(context);
        showCustomDialog(context, "ERROR", "Unknown error");
      }
    }

    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      onPrimary: Colors.lightBlueAccent,
      primary: Colors.lightBlueAccent,
      minimumSize: Size(88, 36),
      padding: EdgeInsets.all(12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        style: raisedButtonStyle,
        onPressed: () {
          if (_formKey.currentState.validate()) {
            showLoadingScreen(context);
            _login();
          }
        },
        child: Text('Log In', style: TextStyle(color: Colors.white)),
      ),
    );

    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                logo,
                SizedBox(height: 48.0),
                ConstrainedBox(
                  constraints: BoxConstraints(
                  minWidth: 100,
                  maxWidth: 500,
                  ),
                  child : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 24.0, right: 24.0),
                    children: <Widget>[
                      username,
                      SizedBox(height: 8.0),
                      password,
                      SizedBox(height: 24.0),
                      loginButton,
                      //forgotLabel,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}