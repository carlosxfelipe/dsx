import 'dart:html';
export 'stylesheet.dart';

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
