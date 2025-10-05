import 'dart:html';

typedef EffectFn = void Function();

class Signal<T> {
  T _value;
  final _listeners = <void Function()>{};
  Signal(this._value);
  T call() {
    _track(this);
    return _value;
  }

  void set(T v) {
    if (v == _value) return;
    _value = v;
    for (final l in List.of(_listeners)) {
      l();
    }
  }
}

Signal<T> signal<T>(T v) => Signal<T>(v);

final _stack = <_Computation>[];
void _track(Signal s) {
  if (_stack.isNotEmpty) {
    final c = _stack.last;
    if (c._sources.add(s)) s._listeners.add(c._run);
  }
}

class _Computation {
  final void Function() _run;
  final _sources = <Signal>{};
  _Computation(this._run);
}

void effect(EffectFn fn) {
  late _Computation c;
  void runner() {
    fn();
  }

  c = _Computation(runner);
  _stack.add(c);
  try {
    runner();
  } finally {
    _stack.removeLast();
  }
}

abstract class NodeLike {}

class TextNode extends NodeLike {
  final String text;
  TextNode(this.text);
}

class ElementNode extends NodeLike {
  final String tag;
  final Map<String, dynamic> props;
  final List<NodeLike> children;
  ElementNode(this.tag, this.props, this.children);
}

class DynNode extends NodeLike {
  final String Function() getter;
  DynNode(this.getter);
}

NodeLike text(String t) => TextNode(t);
NodeLike dyn(String Function() getter) => DynNode(getter);
NodeLike h(String tag,
        [Map<String, dynamic>? props, List<NodeLike>? children]) =>
    ElementNode(tag, props ?? <String, dynamic>{}, children ?? <NodeLike>[]);

void mount(NodeLike node, HtmlElement container) {
  container.children.clear();
  _render(node, container);
}

void _render(NodeLike n, Node parent) {
  if (n is TextNode) {
    parent.append(Text(n.text));
  } else if (n is ElementNode) {
    final el = Element.tag(n.tag);
    n.props.forEach((key, value) {
      if (key.startsWith('on') && value is Function) {
        final eventName = key.substring(2).toLowerCase();
        el.addEventListener(eventName, (Event e) => value(e));
      } else if (key == 'className') {
        el.setAttribute('class', '$value');
      } else if (key == 'style') {
        dynamic v = value;
        if (v is List) {
          final merged = <String, dynamic>{};
          for (final part in v) {
            if (part is Map) merged.addAll(Map<String, dynamic>.from(part));
          }
          v = merged;
        }
        if (v is Map) {
          final css = StringBuffer();
          v.forEach((k, v2) {
            if (v2 == null) return;
            if (v2 is num) {
              css.write('$k:${v2}px;');
            } else {
              css.write('$k:$v2;');
            }
          });
          el.setAttribute('style', css.toString());
        } else if (v != null) {
          el.setAttribute('style', '$v');
        }
      } else {
        el.setAttribute(key, '$value');
      }
    });
    for (final c in n.children) {
      _render(c, el);
    }
    parent.append(el);
  } else if (n is DynNode) {
    final anchor = Comment('dyn');
    parent.append(anchor);
    Text? lastText;
    void patch() {
      final content = n.getter();
      if (lastText == null) {
        lastText = Text(content);
        anchor.parent?.insertBefore(lastText!, anchor.nextNode);
      } else {
        lastText!.text = content;
      }
    }

    effect(patch);
  }
}

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
