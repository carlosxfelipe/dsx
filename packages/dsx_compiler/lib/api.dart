import 'dart:io';
import 'package:path/path.dart' as p;
import 'dsx_compiler.dart';
import 'emit.dart';

String compileDsx(String source, {String fnName = 'View'}) {
  final parser = Parser(source);
  final program = parser.parseProgram();
  return emitDart(program, fnName: fnName);
}

void compileFile(String inputPath, String outDir) {
  final src = File(inputPath).readAsStringSync();
  final code = compileDsx(src, fnName: 'View');
  final outPath = p.join(outDir, '${p.basenameWithoutExtension(inputPath)}.dart');
  File(outPath).createSync(recursive: true);
  File(outPath).writeAsStringSync(code);
  stdout.writeln('✔ Compiled $inputPath → $outPath');
}
