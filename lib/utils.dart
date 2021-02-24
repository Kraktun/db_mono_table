import 'package:flutter/material.dart';

void showLoadingScreen(BuildContext contextO) {
  showDialog(
    context: contextO,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white.withOpacity(0.45),
        insetPadding: EdgeInsets.zero, // remove edges
        child: new SizedBox.expand( // fullscreen
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center, // center
            mainAxisAlignment: MainAxisAlignment.center, // center
            children: <Widget>[
              new Center(
                child: new SizedBox(
                  height: 75.0,
                  width: 75.0,
                  child: new CircularProgressIndicator(
                    value: null,
                    strokeWidth: 9.0,
                  ),
                ),
              ),
              new Container(
                margin: const EdgeInsets.only(top: 25.0),
                child: new Center(
                  child: new Text(
                    "Loading...",
                    style: new TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

int compareCells(DataCell a, DataCell b, {bool tryNumber = false}) {
  var valA = (a.child as Text).data;
  var valB = (b.child as Text).data;
  if (!tryNumber)
    return valA.compareTo(valB);
  try {
    return double.parse(valA).compareTo(double.parse(valB));
  } on FormatException {
    return valA.compareTo(valB);
  }
}

int tryCompareAsNumber(String a, String b) {
  try {
    return double.parse(a).compareTo(double.parse(b));
  } on Exception {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}

void showCustomDialog(BuildContext contextO, String title, String s) {
  showDialog<void>(
    context: contextO,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(s),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}