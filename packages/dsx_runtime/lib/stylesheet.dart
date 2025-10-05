import 'dart:html';

class StyleSheet {
  static final _rules = <String>{};
  final Map<String, String> classes;
  final Map<String, Map<String, dynamic>> raw;
  StyleSheet._(this.classes, this.raw);

  Map<String, dynamic> style(String key) => raw[key] ?? const {};
  String className(String key) => classes[key] ?? '';
  dynamic operator [](String key) => raw[key];

  Map<String, dynamic> get button => raw['button'] ?? const {};
  Map<String, dynamic> get card => raw['card'] ?? const {};

  static StyleElement _styleEl() {
    const id = '__dsx_styles__';
    var el = document.getElementById(id) as StyleElement?;
    if (el == null) {
      el = StyleElement()..id = id;
      document.head!.append(el);
    }
    return el;
  }

  static String _toCss(Map<String, dynamic> style) {
    final b = StringBuffer();
    style.forEach((k, v) {
      if (v is Map) return;
      if (v == null) return;
      if (v is num) {
        b.writeln('$k:${v}px;');
      } else {
        b.writeln('$k:$v;');
      }
    });
    return b.toString();
  }

  static String _hash(String input) {
    var h = 0x811C9DC5;
    for (final c in input.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(36);
  }

  static void _emitRule(
      String selector, Map<String, dynamic> style, StyleElement el) {
    final body = _toCss(style);
    final key = '$selector{$body}';
    if (_rules.add(key)) el.appendText('$selector{$body}');
    style.forEach((k, v) {
      if (v is Map && k.startsWith('&')) {
        _emitRule(selector + k.substring(1), v as Map<String, dynamic>, el);
      }
    });
  }

  static StyleSheet create(Map<String, dynamic> spec) {
    final classes = <String, String>{};
    final raw = <String, Map<String, dynamic>>{};
    final styleEl = _styleEl();
    spec.forEach((logical, block) {
      if (logical.startsWith('@media')) {
        final mq = logical;
        final inner = block as Map<String, dynamic>;
        final buf = StringBuffer('$mq{');
        inner.forEach((sel, st) {
          final selStr = sel.toString();
          final cls = selStr.startsWith('.') ? selStr : '.${selStr}';
          buf.write('$cls{${_toCss(st as Map<String, dynamic>)}}');
        });
        buf.write('}');
        final key = buf.toString();
        if (_rules.add(key)) styleEl.appendText(key);
      } else {
        final style = Map<String, dynamic>.from(block as Map<String, dynamic>);
        raw[logical] = style;
        final sig = '$logical|${style.toString()}';
        final cls = 'c${_hash(sig)}';
        classes[logical] = cls;
        _emitRule('.$cls', style, styleEl);
      }
    });
    return StyleSheet._(classes, raw);
  }
}
