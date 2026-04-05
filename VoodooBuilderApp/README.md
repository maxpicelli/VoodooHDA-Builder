# VoodooHDA Builder

App SwiftUI para macOS que automatiza o pipeline do projeto VoodooHDA:

- clonar ou reutilizar o repositorio VoodooHDA
- clonar ou reutilizar o MacKernelSDK
- criar o link simbolico `VoodooHDA/MacKernelSDK`
- compilar `VoodooHDA.prefPane`
- compilar `VoodooHDA.kext` via `tranc/VoodooHDA_BS.xcodeproj`
- copiar para a pasta do instalador exatamente os artefatos `Release` compilados no clone local
- executar `makeInstall.sh` para gerar `VoodooHDA.pkg`
- copiar o `VoodooHDA.pkg` final para a Mesa
- aplicar ao `.pkg` o mesmo icone do `VoodooHDA.prefPane`
- abrir o instalador automaticamente no macOS

## Quick Start

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git && cd VoodooHDA-Builder
cd VoodooBuilderApp
swift run
```

Se `VoodooHDA` ou `MacKernelSDK` nao existirem no workspace escolhido, o app baixa essas dependencias automaticamente.

O clone `VoodooHDA/` nao faz parte do repositório do builder. Ele continua sendo uma dependencia local de build, mas o proprio app pode clonar ou atualizar `VoodooHDA` e `MacKernelSDK` automaticamente.

## Abrir no Xcode

Abra o workspace raiz `VoodooHDA-Builder.xcworkspace` no Xcode:

```bash
open ../VoodooHDA-Builder.xcworkspace
```

Ou abra [Open VoodooHDA Builder in Xcode.command](../Open%20VoodooHDA%20Builder%20in%20Xcode.command) com duplo clique no Finder para abrir direto o workspace no Xcode.

No VS Code, tambem da para usar `Run Task` e executar `Open VoodooHDA Builder in Xcode`.

## Rodar pelo terminal

```bash
cd VoodooBuilderApp
swift run
```

## Capturas de tela

### App

![Janela principal do VoodooHDA Builder](../docs/images/Builder.png)

### Instalador

![Tela de introducao do instalador VoodooHDA](../docs/images/VoodooHDA-pkg.png)

## Paths padrao

Os valores padrao assumem este layout dentro do workspace atual:

- `VoodooHDA/`
- `VodooHDA-Installer-VoodooHDA-3.1.3-Tahoe-Raptor-LAKE/`
- `MacKernelSDK/`

Se quiser usar outro clone ou outro diretório, ajuste os campos na interface.