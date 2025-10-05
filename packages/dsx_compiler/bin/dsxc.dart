import 'dart:io';
import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:dsx_compiler/api.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('out-dir', abbr: 'o', help: 'Pasta de saída para os .dart gerados', defaultsTo: 'gen')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Mostrar ajuda');

  final results = parser.parse(args);
  if (results['help'] == true || results.rest.isEmpty) {
    stdout.writeln('dsxc <globs...> -o <outDir>');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final outDir = results['out-dir'] as String;
  final patterns = results.rest.map((s) => Glob(s, recursive: true)).toList();

  final files = <String>{};
  final root = Directory.current.path;
  for (final ent in Directory(root).listSync(recursive: true, followLinks: false)) {
    if (ent is! File) continue;
    final rel = p.relative(ent.path, from: root);
    if (!rel.endsWith('.dsx')) continue;
    if (patterns.any((g) => g.matches(rel))) {
      files.add(ent.path);
    }
  }

  if (files.isEmpty) {
    stderr.writeln('Nenhum arquivo .dsx encontrado.');
    exit(2);
  }

  for (final f in files) {
    try {
      compileFile(f, outDir);
    } catch (e, st) {
      stderr.writeln('Falha ao compilar $f:\n$e\n$st');
      exitCode = 1;
    }
  }
}
