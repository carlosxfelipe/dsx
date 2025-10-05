import 'dart:html';
import 'package:dsx_runtime/runtime.dart';
import '../gen/main.dart' as gen;

void main() {
  final root = document.getElementById('app') as HtmlElement;
  mount(gen.View(), root);
}
