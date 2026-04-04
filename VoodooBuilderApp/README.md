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
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git
cd VoodooHDA-Builder
git clone https://github.com/CloverHackyColor/VoodooHDA.git
git clone https://github.com/acidanthera/MacKernelSDK.git
cd VoodooBuilderApp
swift run
```

## Clonar este projeto

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git
cd VoodooHDA-Builder
```

## Dependencias locais

O clone `VoodooHDA/` nao faz parte do repositório do builder. Ele deve existir localmente como base de compilacao.

```bash
git clone https://github.com/CloverHackyColor/VoodooHDA.git
git clone https://github.com/acidanthera/MacKernelSDK.git
```

## Abrir no Xcode

Abra `Package.swift` no Xcode:

```bash
cd VoodooBuilderApp
open Package.swift
```

## Rodar pelo terminal

```bash
cd VoodooBuilderApp
swift run
```

## Capturas de tela

- Janela principal do `VoodooHDA Builder` com o status final `3/3 VoodooHDA.pkg pronto`.
- Janela do instalador `Instalar VoodooHDA Installer` na etapa de introducao.

Observacao: para embutir as imagens reais no README, os arquivos dos prints precisam existir dentro do repositório.

## Paths padrao

Os valores padrao assumem este layout dentro do workspace atual:

- `VoodooHDA/`
- `VodooHDA-Installer-VoodooHDA-3.1.3-Tahoe-Raptor-LAKE/`
- `MacKernelSDK/`

Se quiser usar outro clone ou outro diretório, ajuste os campos na interface.