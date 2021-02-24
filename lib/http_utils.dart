import 'package:flutter/material.dart';
import 'package:db_mono_table/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:db_mono_table/table_object.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:db_mono_table/consts.dart';
import 'dart:core';

Future<List<TableObject>> getTableData(BuildContext context, {String filterText = ""}) async {
  try { // TODO ADD FILTERING
    final queryParameters = filterText.isNotEmpty ? {
      'search': filterText,
    } : Map<String, String>();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_ID) ?? "";
    final http.Response response = await http.get(
      buildApiUri('/objects', queryParameters),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return  l.map((model) => TableObject.fromJson(model)).toList();
    } else if (response.statusCode == 401) {
      // Not authenticated
      prefs.remove(TOKEN_ID); // remove token to avoid loop
      Navigator.pop(context);
      Navigator.of(context).pushNamed(LoginPage.ROUTE);
    } else {
      return [TableObject(elements: List.filled(TableObject.COLUMNS.length, ""), boxTip: "")];
    }
  } catch (e) {
    return [TableObject(elements: List.filled(TableObject.COLUMNS.length, ""), boxTip: "")];
  }
  return [TableObject(elements: List.filled(TableObject.COLUMNS.length, ""), boxTip: "")];
}

Future<void> logout(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_ID) ?? "";
    final http.Response response = await http.post(
      '$SERVER_FULL_URL/logout',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove(TOKEN_ID);
      Navigator.pop(context); // remove loading screen
      Navigator.of(context).pushNamed(LoginPage.ROUTE);
    } else if (response.statusCode == 401) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(LoginPage.ROUTE);
    } else {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove(TOKEN_ID);
      Navigator.pop(context);
      Navigator.of(context).pushNamed(LoginPage.ROUTE);
    }
  } catch (e) {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(TOKEN_ID);
    Navigator.pop(context);
    Navigator.of(context).pushNamed(LoginPage.ROUTE);
  }
}

Uri buildApiUri(String endpoint, Map<String, String> queryParams) {
  return Uri.https("$SERVER_BARE_URL", '$SERVER_API_ENDPOINT$endpoint', queryParams);
}