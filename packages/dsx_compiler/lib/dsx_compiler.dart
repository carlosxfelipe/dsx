library dsx_compiler;

sealed class Node {}

class Program {
  final List<String> prelude;
  final List<Node> body;
  Program(this.prelude, this.body);
}

class Element extends Node {
  final String name;
  final List<Attr> attrs;
  final List<Node> children;
  Element(this.name, this.attrs, this.children);
}

class Text extends Node {
  final String text;
  Text(this.text);
}

class Interp extends Node {
  final String expr;
  Interp(this.expr);
}

class Attr {
  final String name;
  final String? value;
  final String? expr;
  Attr(this.name, {this.value, this.expr});
  bool get isEvent =>
      name.startsWith('on') &&
      name.length > 2 &&
      name[2].toUpperCase() == name[2];
}

class Parser {
  final String src;
  int i = 0;
  Parser(this.src);

  bool get isEnd => i >= src.length;
  String get cur => src[i];
  String peek(int n) => src.substring(i, (i + n).clamp(0, src.length));

  void skipWs() {
    while (!isEnd && RegExp(r'\s').hasMatch(cur)) i++;
  }

  Program parseProgram() {
    final prelude = <String>[];
    while (true) {
      final line = _readLinePreview();
      if (line == null) break;
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
        prelude.add(line);
        _consumeLine();
      } else {
        break;
      }
    }
    final nodes = <Node>[];
    while (!isEnd) {
      skipWs();
      if (isEnd) break;
      if (peek(2) == '</') break;
      if (cur == '<')
        nodes.add(_parseElement());
      else if (cur == '{')
        nodes.add(_parseInterp());
      else
        nodes.add(_parseText());
    }
    return Program(prelude, nodes);
  }

  String? _readLinePreview() {
    if (isEnd) return null;
    final nl = src.indexOf('\n', i);
    if (nl == -1) return src.substring(i);
    return src.substring(i, nl + 1);
  }

  void _consumeLine() {
    final nl = src.indexOf('\n', i);
    if (nl == -1) {
      i = src.length;
    } else {
      i = nl + 1;
    }
  }

  Element _parseElement() {
    i++;
    final name = _readIdent(allowDash: true);
    final attrs = <Attr>[];
    while (true) {
      skipWs();
      if (isEnd) break;
      if (peek(2) == '/>') {
        i += 2;
        return Element(name, attrs, []);
      }
      if (cur == '>') {
        i++;
        break;
      }
      attrs.add(_parseAttr());
    }
    final kids = <Node>[];
    while (!isEnd) {
      if (peek(2) == '</') {
        i += 2;
        final close = _readIdent();
        _consumeChar('>');
        if (close != name) {
          throw FormatException(
              'Tag fechando não corresponde: esperado </$name>, encontrou </$close>');
        }
        break;
      }
      if (cur == '<')
        kids.add(_parseElement());
      else if (cur == '{')
        kids.add(_parseInterp());
      else
        kids.add(_parseText());
    }
    return Element(name, attrs, kids);
  }

  void _consumeChar(String ch) {
    skipWs();
    if (isEnd || cur != ch) {
      throw FormatException('Esperado \"%s\" em %d'
          .replaceFirst('%s', ch)
          .replaceFirst('%d', '$i'));
    }
    i++;
  }

  Attr _parseAttr() {
    skipWs();
    final name = _readIdent(allowDash: true);
    skipWs();
    if (!isEnd && cur == '=') {
      i++;
      skipWs();
    }
    if (!isEnd && cur == '{') {
      i++;
      final sb = StringBuffer();
      int depth = 1;
      while (!isEnd && depth > 0) {
        final ch = cur;
        if (ch == '{')
          depth += 1;
        else if (ch == '}') depth -= 1;
        if (depth == 0) {
          i++;
          break;
        }
        sb.write(ch);
        i++;
      }
      return Attr(name, expr: sb.toString().trim());
    }
    if (!isEnd && (cur == '"' || cur == "'")) {}
    if (!isEnd && (cur == '"' || cur == "'")) {
      final quote = cur;
      i++;
      final sb = StringBuffer();
      while (!isEnd && cur != quote) {
        sb.write(cur);
        i++;
      }
      if (isEnd) throw FormatException('String de atributo não fechada');
      i++;
      return Attr(name, value: sb.toString());
    }
    final val = _readUntil([' ', '\t', '\n', '>', '/']);
    if (val.isEmpty) return Attr(name, value: 'true');
    return Attr(name, value: val);
  }

  Node _parseText() {
    final start = i;
    while (!isEnd) {
      final ch = cur;
      if (ch == '<' || ch == '{') break;
      i++;
    }
    final t = src.substring(start, i);
    return Text(t);
  }

  Interp _parseInterp() {
    i++;
    final sb = StringBuffer();
    int depth = 1;
    while (!isEnd && depth > 0) {
      final ch = cur;
      if (ch == '{')
        depth += 1;
      else if (ch == '}') depth -= 1;
      if (depth == 0) {
        i++;
        break;
      }
      sb.write(ch);
      i++;
    }
    return Interp(sb.toString().trim());
  }

  String _readIdent({bool allowDash = false}) {
    final sb = StringBuffer();
    while (!isEnd) {
      final ch = cur;
      final ok =
          RegExp(r'[A-Za-z0-9_]').hasMatch(ch) || (allowDash && ch == '-');
      if (!ok) break;
      sb.write(ch);
      i++;
    }
    return sb.toString();
  }

  String _readUntil(List<String> stops) {
    final sb = StringBuffer();
    while (!isEnd && !stops.contains(cur)) {
      sb.write(cur);
      i++;
    }
    return sb.toString();
  }
}
