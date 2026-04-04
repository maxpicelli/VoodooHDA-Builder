# VoodooHDA Builder

Projeto do app macOS que automatiza o build e o empacotamento do VoodooHDA.

O repositório publicado deve conter apenas os arquivos do builder. O clone local de `VoodooHDA/` nao entra aqui, porque ele e baixado separadamente do repositório original e usado apenas como base de build.

## Quick Start

Clone este projeto:

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git
cd VoodooHDA-Builder
```

Depois baixe as dependencias locais esperadas pelo builder:

```bash
git clone https://github.com/CloverHackyColor/VoodooHDA.git
git clone https://github.com/acidanthera/MacKernelSDK.git
```

## Clonar este projeto

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git
cd VoodooHDA-Builder
```

## Clonar as dependencias locais

```bash
git clone https://github.com/CloverHackyColor/VoodooHDA.git
git clone https://github.com/acidanthera/MacKernelSDK.git
```

## Estrutura esperada no workspace

```text
Voodoo-HDA-builder-compiler/
├── VoodooBuilderApp/
├── VoodooHDA/
└── MacKernelSDK/
```

## Abrir no Xcode

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

### App

![Janela principal do VoodooHDA Builder](docs/images/Builder.png)

### Instalador

![Tela de introducao do instalador VoodooHDA](docs/images/VoodooHDA-pkg.png)

## O que o app faz

- reutiliza ou baixa o clone local de `VoodooHDA`
- reutiliza ou baixa o `MacKernelSDK`
- cria o link simbolico `VoodooHDA/MacKernelSDK`
- compila `VoodooHDA.prefPane`
- compila `VoodooHDA.kext`
- copia os artefatos `Release` para a pasta do instalador
- gera o `VoodooHDA.pkg`
- copia o `.pkg` final para a Mesa
- aplica o icone do pref pane ao pacote final

## Notas

- `VoodooHDA/` e uma dependencia local e fica fora deste repositório.
- artefatos de build do Xcode e do SwiftPM tambem ficam ignorados.