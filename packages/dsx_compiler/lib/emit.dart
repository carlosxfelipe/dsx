import 'dsx_compiler.dart';

String emitDart(Program prog, {String fnName = 'View'}) {
  final b = StringBuffer();
  for (final line in prog.prelude) {
    b.writeln(line.trimRight());
  }
  if (!prog.prelude
      .any((l) => l.contains("package:dsx_runtime/runtime.dart"))) {
    b.writeln("import 'package:dsx_runtime/runtime.dart';");
  }
  b.writeln('');
  b.writeln('NodeLike $fnName() {');

  final uiNodes = <Node>[];
  for (final n in prog.body) {
    if (n is Interp) {
      final expr = n.expr.trim();
      final isMultiline = expr.contains('\n');
      final hasSemicolon = expr.contains(';');
      final isHoist = isMultiline || hasSemicolon || expr.startsWith('!');
      if (isHoist) {
        final code = expr.startsWith('!') ? expr.substring(1).trimLeft() : expr;
        b.writeln('  $code');
        continue;
      }
    }
    uiNodes.add(n);
  }

  if (uiNodes.isEmpty) {
    b.writeln("  return text('');");
  } else if (uiNodes.length == 1) {
    b.writeln('  return ${_emitNode(uiNodes.first)};');
  } else {
    b.writeln("  return h('div', {}, [");
    for (final n in uiNodes) {
      b.writeln('    ${_emitNode(n)},');
    }
    b.writeln('  ]);');
  }

  b.writeln('}');
  return b.toString();
}

String _emitNode(Node n) {
  if (n is Text) {
    final t = n.text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return "text('$t')";
  } else if (n is Interp) {
    final expr = n.expr.replaceAll('\n', ' ').trim();
    return "dyn(() => (${expr}).toString())";
  } else if (n is Element) {
    final props = <String>[];
    for (final a in n.attrs) {
      if (a.expr != null) {
        if (a.isEvent) {
          props.add("'${a.name}': (e) => ((${a.expr})())");
        } else {
          props.add("'${a.name}': (${a.expr})");
        }
      } else {
        final v = (a.value ?? 'true')
            .replaceAll(r'\', r'\\')
            .replaceAll("'", r"\'")
            .replaceAll('\n', r'\n')
            .replaceAll('\r', r'\r')
            .replaceAll('\t', r'\t');
        props.add("'${a.name}': '$v'");
      }
    }
    final children = n.children.map(_emitNode).join(', ');
    return "h('${n.name}', {${props.join(', ')}}, [${children}])";
  }
  throw StateError('Unknown node $n');
}
