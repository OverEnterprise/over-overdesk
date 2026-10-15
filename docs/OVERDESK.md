# OverDesk para Windows x64

O perfil `overdesk` usa `rustdesk.overenterprise.com.br` para ID e relay,
oculta Login/Conta (incluindo agenda e dispositivos vinculados a conta),
oculta as abas Rede e Seguranca e fixa o modo de acesso completo.
As permissoes da janela de aceitacao nao podem ser alteradas.
O modo de aprovacao e `click`, como no JSON do RdGen. Nenhuma senha permanente
e incorporada ao executavel. O Sobre omite website, privacidade e slogan;
seu rodape mostra somente `Copyright © 2026 Over Enterprise LTDA.`.
A identificacao na tela principal e `Desenvolvido por Over Enterprise LTDA.`,
sem link para o website do RustDesk.
Os avisos de autoria do upstream e a licenca acompanham o pacote em arquivos.

As cores seguem `over-design/packages/theme/theme.css`: vermelho da marca
`#C72826` em botoes e destaques, `#F26B66` para textos e selecoes no tema
escuro, e superficies neutras claras/escuras. O indicador de conexao e os
estados de sucesso, aviso e erro mantem suas funcoes. O script passa
`--dart-define=OVERDESK=true` ao Flutter nos dois modos de compilacao;
sem essa definicao, os tokens e temas originais continuam em uso.

O servidor continua sendo o RustDesk Server OSS. Nao ha API de contas:
o perfil desativa registro na API e nao usa `apiServer` do JSON do RdGen.
As portas nativas padrao sao 21115/TCP, 21116/TCP+UDP e 21117/TCP.
O perfil usa TCP/UDP nativos, limpa proxy anteriormente salvo e desativa
WebSocket. Mantem TCP punch habilitado; os recursos opcionais UDP punch,
IPv6 punch e WebRTC ficam desabilitados, como no padrao de servidor proprio
do cliente. Isso nao desativa o UDP nativo da porta 21116.
Os controles de TCP punch, UDP punch, IPv6 P2P e WebRTC P2P tambem ficam
ocultos em Geral > Outro, pois seus valores ja estao fixos no perfil.
As demais preferencias locais de sessao, captura e renderizacao permanecem.

## Primeira compilacao pelo GitHub Actions

1. A chave publica do servidor ja esta em `res/overdesk/server_key.pub` e e
   incorporada ao executavel. Nao e necessario configurar secrets de Actions.
   Para trocar a chave, atualize esse arquivo com o conteudo de
   `/root/id_ed25519.pub` do container **hbbs** e recompile.
   Esse arquivo pertence ao RustDesk, nao ao SSH. O script valida Base64 de 32 bytes.
2. Execute o workflow **OverDesk Windows x64** manualmente.
3. Baixe o artefato `OverDesk-windows-x64` e extraia `OverDesk.exe`.
   Distribua somente esse EXE.

O workflow produz um EXE portatil autoextrator sem assinatura, nao um MSI.
Ao abrir, o empacotador original do RustDesk extrai as DLLs e os dados para
`%LOCALAPPDATA%/overdesk` e inicia o aplicativo. Nao e necessario distribuir
arquivos auxiliares ao lado do EXE. A instalacao continua disponivel no app.
Ele aproveita o gerador de bridge existente no CI e os caches
de Rust, Flutter/Pub e vcpkg. Nao publica release e nao exige credenciais Pro.
O bundle inicial nao inclui os drivers opcionais de impressora, monitor USB
nem o helper de privacidade que o workflow completo do upstream acrescenta.

## Compilacao local incremental

Requisitos iguais aos do build Windows upstream:

- Windows x64 e Visual Studio 2022 com Desktop development with C++, CMake
  e Windows SDK.
- Git, Python, Rust 1.75 e Flutter 3.24.5 no PATH.
- Dependencia Python do empacotador: `python -m pip install -r libs/portable/requirements.txt`.
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

Saida para distribuir: `target/OverDesk.exe`.
A pasta intermediaria `flutter/build/windows/x64/runner/Release` continua
existindo para desenvolvimento; seu EXE exige as DLLs e os dados dessa pasta.
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

Os logos e icones aprovados ficam em `res/overdesk` e sao copiados para os
assets Flutter durante o build. O EXE portatil tambem recebe icone e metadados
OverDesk. O empacotador usa Brotli nivel 5 para reduzir o tempo de recompacote.
O JSON do RdGen nao e um arquivo de configuracao nativo deste fork.

## Superficie de regressao

Sem a feature `overdesk`, o carregamento de configuracao e a interpretacao do
nome do EXE seguem o codigo original. Com a feature, `src/common.rs` e
`src/flutter_ffi.rs` inicializam o perfil fixo em cada processo, e
`src/platform/windows.rs` usa esse perfil em vez de configuracao no nome do EXE.
Isso evita mudar de servidor ao renomear o executavel. A tela desktop Sobre
omite links, licenca textual e slogan do rodape quando o nome do aplicativo e
OverDesk, exibindo o copyright da Over Enterprise.
`flutter/lib/desktop/pages/desktop_setting_page.dart` tambem omite os quatro
controles de rede em Geral > Outro no OverDesk. `flutter/lib/common.dart` muda
a autoria nas telas principal e mobile apenas no OverDesk, preservando o texto
e link originais nos demais clientes. `src/overdesk.rs` fixa as permissoes e a
rede e limpa proxy salvo, necessario porque a aba foi removida.
O tema opcional em `flutter/lib/common/overdesk_theme.dart` e aplicado por
`common.dart`; seus tokens tambem atendem as janelas de sessao e arquivos.
As cores desenhadas diretamente em `desktop_home_page.dart`,
`desktop_setting_page.dart`, `tabbar_widget.dart` e `update_progress.dart`
recebem a mesma paleta. Cada caminho preserva as cores anteriores sem
`OVERDESK=true`. `res/overdesk/build.ps1` passa essa definicao nos dois modos
e executa os passos Flutter/copia do helper que antes delegava a `build.py`.
`libs/portable/Cargo.toml`, `build.rs` e `src/ui.rs` habilitam os recursos visuais
do empacotador somente com sua feature `overdesk`. O fluxo de extracao original
nao foi alterado. Nenhum protocolo,
submodulo ou arquivo de traducao foi alterado. O job Windows x64 de testes em
`flutter-build.yml` tambem executa o teste do perfil com a chave publica
incorporada, sem conectar ao servidor.
