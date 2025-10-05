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

## 5) Editar a interface do exemplo DSX

Este passo explica como editar a interface do exemplo DSX e ver as mudanças no navegador.

## Estrutura do Projeto

```
packages/
├── dsx_compiler      # compilador DSX → Dart
├── dsx_runtime       # runtime (signals + renderizador DOM)
└── example_app       # aplicação de exemplo
    ├── src/main.dsx  # código DSX que define a UI
    ├── bin/bootstrap.dart
    └── web/index.html
```

### Passo 1: Editar o arquivo DSX

A UI principal está definida em:

```
packages/example_app/src/main.dsx
```

Por exemplo, para adicionar um parágrafo abaixo do contador:

```dsx
<div class="card">
  <h1>Contador</h1>
  <p>Valor: {count()}</p>
  <button onClick={() => count.set(count() - 1)}>-1</button>
  <button onClick={() => count.set(count() + 1)}>+1</button>
  <button onClick={() => count.set(0)}>reset</button>

  <p>Este é um parágrafo novo com informações adicionais.</p>
</div>
```

### Passo 2: Compilar DSX → Dart

No diretório `packages/example_app`, execute:

```bash
dart run dsx_compiler:dsxc src/main.dsx -o gen
```

Isso gera `packages/example_app/gen/main.dart`.

### Passo 3: Compilar Dart → JavaScript

Ainda no mesmo diretório:

```bash
dart compile js -O4 -o web/app.js bin/bootstrap.dart
```

### Passo 4: Servir a aplicação

Se necessário, instale e rode um servidor simples:

```bash
dart pub global activate dhttpd
~/.pub-cache/bin/dhttpd --path web --port 8080
```

Abra [http://localhost:8080](http://localhost:8080) no navegador.

#### Observações

- Sempre **recompile DSX** e **gere o JS** depois de modificar `main.dsx`.
- Se algo não atualizar, verifique se está usando o arquivo compilado mais recente.

