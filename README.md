# DSX

MVP funcional com:
- **Hoisting** de blocos `{ ... }` top-level para dentro da função (útil para `signal()`).
- **Eventos corrigidos**: handlers `onClick={ () => ... }` executam o closure na hora do clique.
- CLI robusto (caminha o projeto + `Glob.matches`).

## 1) Instalar dependências
```bash
cd packages/dsx_compiler && dart pub get
cd ../example_app && dart pub get
```

## 2) DSX → Dart
```bash
# dentro de packages/example_app
dart run dsx_compiler:dsxc src/main.dsx -o gen
# (alternativa)
dart run dsx_compiler:dsxc "**/*.dsx" -o gen
```

## 3) Dart → JS
```bash
dart compile js -O4 -o web/app.js bin/bootstrap.dart
```

## 4) Servir `web/`
```bash
dart pub global activate dhttpd
~/.pub-cache/bin/dhttpd --path web --port 8080
# abra http://localhost:8080
```

### Dicas
- Se o botão não reagir, confirme que recompilou **após** trocar qualquer `.dsx`:
  ```bash
  dart run dsx_compiler:dsxc src/main.dsx -o gen
  dart compile js -O4 -o web/app.js bin/bootstrap.dart
  ```
- Se o glob não pegar arquivos, use o caminho direto `src/main.dsx` como acima.

Próximo passo sugerido (**Step 3**): componentes `<PascalCase />`, `--watch`, `className`/`style` (objeto), `value/checked` controlados.
