#!/usr/bin/env dart

import "dart:io";

main() {
  Process.run("dart2js", [
       "example/demo/demo.dart",
       "-oexample/demo/demo.js"
  ])..then((_) => print("dart2js demo.dart - DONE"))
    ..catchError((e) => print(e));
}