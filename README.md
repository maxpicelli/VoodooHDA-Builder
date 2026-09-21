# VoodooHDA Builder

Projeto do app macOS que automatiza o build e o empacotamento do VoodooHDA.

O repositório publicado deve conter apenas os arquivos do builder. O clone local de `VoodooHDA/` nao entra aqui, porque ele e baixado separadamente do repositório original e usado apenas como base de build.

Na raiz do repositório existe um workspace `VoodooHDA-Builder.xcworkspace` que aponta para o projeto real do app em `VoodooBuilderApp/VoodooBuilderApp.xcodeproj`.

## Requisitos

- macOS 13 ou mais recente
- Processadores intel (não funciona com a séria M Apple Silicom arm64)
- Xcode instalado
- Xcode Command Line Tools instaladas com `xcode-select --install`
- Git disponível no sistema
- conexão com a internet para o clone automático de `VoodooHDA` e `MacKernelSDK`

Python nao e necessario para o app rodar nem para o pipeline principal.

## Quick Start

Clone este projeto e abra a pasta no Finder:

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git && cd VoodooHDA-Builder && open .
```

Ou clone e abra direto no Xcode:

```bash
git clone https://github.com/maxpicelli/VoodooHDA-Builder.git && cd VoodooHDA-Builder && open VoodooHDA-Builder.xcworkspace
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
open VoodooHDA-Builder.xcworkspace
```

Ou abra [Open VoodooHDA Builder in Xcode.command](Open%20VoodooHDA%20Builder%20in%20Xcode.command) com duplo clique no Finder para abrir direto o workspace no Xcode.

No VS Code, tambem da para usar `Run Task` e executar `Open VoodooHDA Builder in Xcode`.

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

O app tem duas abas.

### Aba `Compilar`

- reutiliza ou baixa o clone local de `VoodooHDA`
- reutiliza ou baixa o `MacKernelSDK`
- cria o link simbolico `VoodooHDA/MacKernelSDK`
- compila `VoodooHDA.prefPane`
- compila `VoodooHDA.kext`
- copia os artefatos `Release` para a pasta do instalador
- gera o `VoodooHDA.pkg` em `~/VoodooHDA-Installer-Work`
- aplica o icone do pref pane ao pacote final
- botao `Remover VoodooHDA` apaga a kext, o pref pane e os arquivos relacionados do sistema

### Aba `Kext propria`

Empacota uma `VoodooHDA.kext` que voce ja tem, sem compilar nada.

- escolha a `.kext` pelo botao `Escolher...` ou arraste o bundle do Finder para o campo
- opcionalmente escolha ou arraste uma `.prefPane` propria; se deixar vazio, usa a do template
- a versao e lida do `Info.plist` da kext e usada para nomear a pasta de saida
- gera `Kext.pkg`, `prefpane.pkg`, `getdump.pkg` e `VoodooHDA.pkg` em `~/VoodooHDA-<versao>`, separado do fluxo principal
- ajusta automaticamente os `version=` do `dist.xml` conforme os bundles escolhidos

### Versao instalada

O cartao de status mostra a versao do VoodooHDA instalado neste Mac, lida de:

- `/Library/Extensions/VoodooHDA.kext` (ou `/System/Library/Extensions`)
- `~/Library/PreferencePanes/VoodooHDA.prefPane` (ou `/Library/PreferencePanes`)

## Notas

- `VoodooHDA/` e uma dependencia local e fica fora deste repositório.
- o app clona ou atualiza automaticamente `VoodooHDA/` e `MacKernelSDK/` quando necessario.
- a aba `Kext propria` nao precisa do clone do `VoodooHDA` nem do `MacKernelSDK`.
- artefatos de build do Xcode e do SwiftPM tambem ficam ignorados.
