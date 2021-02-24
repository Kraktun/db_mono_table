import 'package:flutter/material.dart';
import 'package:db_mono_table/data_table_rev.dart';

class TableObject {

  static const COLUMNS = ["Name", "Description", "Quantity", "TAG", "Place"];

  // This represents a single row
  final List<String> elements;
  final String boxTip;

  TableObject({
    @required this.elements,
    @required this.boxTip,
  });

  TableObject.fromJson(Map<String, dynamic> json)
      :
        elements = json.values.map((e) => e.toString()).toList().sublist(0, json.values.length - 1),
        boxTip = json.values.last.toString();

  Map<String, dynamic> toJson() {
    var m = Map<String, dynamic>();
    int index = 0;
    elements.forEach((element) {
      m[COLUMNS[index]] = element;
      ++index;
    });
    return m;
  }

  bool applyFilter(List<String> filter) {
    for (int i = 0; i < filter.length; i++) {
      // ignore case
      if (filter.isNotEmpty && !elements[i].toLowerCase().contains(filter[i].toLowerCase()))
        return false;
    }
    return true;
  }

  DataRowR toRow() {
    var d = DataRowR(
      cells: elements.map((e) => DataCellR(Text(e))).toList(),
    );
    d.cells.last = DataCellR(
      Tooltip(message: boxTip, child: new Text(elements.last)),
    );
    return d;
  }
}