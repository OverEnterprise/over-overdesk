# OverDesk para Windows x64

O perfil `overdesk` usa `rustdesk.overenterprise.com.br` para ID e relay,
oculta Login/Conta (incluindo agenda e dispositivos vinculados a conta),
oculta a edicao de servidor e remove o slogan da tela Sobre.
Proxy e demais configuracoes continuam disponiveis.
O modo de aprovacao e `click`, como no JSON do RdGen. Nenhuma senha permanente
e incorporada ao executavel. Creditos e licenca permanecem no Sobre.

O servidor continua sendo o RustDesk Server OSS. Nao ha API de contas:
o perfil desativa registro na API e nao usa `apiServer` do JSON do RdGen.
As portas nativas padrao sao 21115/TCP, 21116/TCP+UDP e 21117/TCP.

## Primeira compilacao pelo GitHub Actions

1. A chave publica do servidor ja esta em `res/overdesk/server_key.pub` e e
   incorporada ao executavel. Nao e necessario configurar secrets de Actions.
   Para trocar a chave, atualize esse arquivo com o conteudo de
   `/root/id_ed25519.pub` do container **hbbs** e recompile.
   Esse arquivo pertence ao RustDesk, nao ao SSH. O script valida Base64 de 32 bytes.
2. Execute o workflow **OverDesk Windows x64** manualmente.
3. Baixe o artefato `OverDesk-windows-x64`, extraia a pasta completa e execute
   `OverDesk.exe`. As DLLs e a pasta `data` precisam acompanhar o EXE.

O workflow produz um bundle sem assinatura, nao um instalador MSI nem um EXE
autoextrator. Ele aproveita o gerador de bridge existente no CI e os caches
de Rust, Flutter/Pub e vcpkg. Nao publica release e nao exige credenciais Pro.
O bundle inicial nao inclui os drivers opcionais de impressora, monitor USB
nem o helper de privacidade que o workflow completo do upstream acrescenta.

## Compilacao local incremental

Requisitos iguais aos do build Windows upstream:

- Windows x64 e Visual Studio 2022 com Desktop development with C++, CMake
  e Windows SDK.
- Git, Python, Rust 1.75 e Flutter 3.24.5 no PATH.
- LLVM/Clang 15.0.6 e `LIBCLANG_PATH` configurado.
- vcpkg no commit `9e593bb18ea69cc5095e012465dcd675a822ed0d`,
  `VCPKG_ROOT` configurado e dependencias instaladas via
  `vcpkg install --triplet x64-windows-static --host-triplet x64-windows-static --x-install-root=<VCPKG_ROOT>/installed`.
- Engine Windows customizado e patch de dropdown do upstream, conforme os
  passos no workflow `overdesk-windows.yml`.
- Arquivos gerados de bridge: baixe `bridge-artifact` da mesma execucao do CI
  e extraia na raiz do repositorio. Nao execute codegen localmente.

Na raiz do repositorio, em PowerShell de 64 bits:

```powershell
git submodule update --init --recursive
./res/overdesk/build.ps1
```

Saida: `flutter/build/windows/x64/runner/Release/OverDesk.exe`.
Nao execute `cargo clean` nem `flutter clean` entre builds normais:
Rust e Flutter reutilizam seus resultados anteriores.

Se **somente Dart/UI** mudou e o Rust ja foi compilado com o perfil OverDesk:

```powershell
./res/overdesk/build.ps1 -UiOnly
```

Depois de mudar Rust, servidor ou chave, execute novamente sem `-UiOnly`.
Para validar apenas a chave, use `./res/overdesk/build.ps1 -Check`.
O primeiro build ainda baixa e compila dependencias; nao ha promessa de tempo.
O ganho esperado vem da reutilizacao dos caches e do caminho apenas de UI.

Este perfil ainda usa os assets visuais do upstream. O icone e o logo do RdGen
nao sao importados automaticamente. O JSON do RdGen nao e um arquivo de
configuracao nativo deste fork.

## Superficie de regressao

Sem a feature `overdesk`, o carregamento de configuracao e a interpretacao do
nome do EXE seguem o codigo original. Com a feature, `src/common.rs` e
`src/flutter_ffi.rs` inicializam o perfil fixo em cada processo, e
`src/platform/windows.rs` usa esse perfil em vez de configuracao no nome do EXE.
Isso evita mudar de servidor ao renomear o executavel. A tela desktop Sobre
omite o slogan quando o nome do aplicativo e OverDesk. Nenhum protocolo,
submodulo ou arquivo de traducao foi alterado. O job Windows x64 de testes em
`flutter-build.yml` tambem executa o teste do perfil com a chave publica
incorporada, sem conectar ao servidor.
