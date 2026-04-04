# VoodooHDA Builder

Projeto do app macOS que automatiza o build e o empacotamento do VoodooHDA.

O repositório publicado deve conter apenas os arquivos do builder. O clone local de `VoodooHDA/` nao entra aqui, porque ele e baixado separadamente do repositório original e usado apenas como base de build.

## Quick Start

Clone este projeto:

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git
cd VoodooHDA-Builder
```

Depois abra o app. Se `VoodooHDA` ou `MacKernelSDK` nao existirem no workspace escolhido, o builder faz o clone automaticamente.

O builder tenta reutilizar clones locais existentes, mas tambem consegue baixar automaticamente o `VoodooHDA` e o `MacKernelSDK` quando eles ainda nao existem no workspace.

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
- o app clona ou atualiza automaticamente `VoodooHDA/` e `MacKernelSDK/` quando necessario.
- artefatos de build do Xcode e do SwiftPM tambem ficam ignorados.