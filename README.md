# 🚀 Flutter Setup Automation - Documentação

## 📖 Sobre

Este script automatiza completamente a configuração do ambiente de desenvolvimento Flutter no Windows, incluindo:

- ✅ **Chocolatey** e **Git**
- ✅ **OpenJDK 8 e 11** com sistema de chaveamento
- ✅ **Android Studio** e SDK
- ✅ **Flutter SDK** e **FVM** (Flutter Version Management)
- ✅ **Configuração automática** de todas as variáveis de ambiente
- ✅ **Funções PowerShell** para gerenciamento de versões

## 🚀 Uso Rápido

### Instalação Completa (Recomendado)
```powershell
# Execute como Administrador
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/[SEU_USUARIO]/flutter-setup/main/setup.ps1'))
```

### Download e Execução Local
```powershell
# 1. Baixe o script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/[SEU_USUARIO]/flutter-setup/main/setup.ps1" -OutFile "flutter-setup.ps1"

# 2. Execute como Administrador
.\flutter-setup.ps1
```

## ⚙️ Opções Avançadas

### Parâmetros Disponíveis

| Parâmetro | Descrição | Padrão |
|-----------|-----------|---------|
| `-InstallPath` | Pasta de instalação | `C:\DevPrograms` |
| `-JavaVersion` | Versão Java padrão (8 ou 11) | `11` |
| `-SkipChocolatey` | Pular instalação do Chocolatey | `false` |
| `-SkipJava` | Pular instalação do Java | `false` |
| `-SkipAndroid` | Pular instalação do Android Studio | `false` |
| `-SkipFlutter` | Pular instalação do Flutter | `false` |
| `-Verbose` | Modo detalhado | `false` |

### Exemplos de Uso

```powershell
# Instalação personalizada
.\flutter-setup.ps1 -InstallPath "D:\Development" -JavaVersion "8"

# Pular Android Studio (se já instalado)
.\flutter-setup.ps1 -SkipAndroid

# Apenas Java e Flutter
.\flutter-setup.ps1 -SkipChocolatey -SkipAndroid

# Modo verbose para debug
.\flutter-setup.ps1 -Verbose
```

## 🔧 Funcionalidades Incluídas

### Sistema de Chaveamento Java
Após a instalação, você terá disponível:

```powershell
# Trocar para JDK 8
jdk8

# Trocar para JDK 11  
jdk11

# Ver versão atual
java-version
```

### Gerenciamento de Versões Flutter (FVM)
```powershell
# Listar versões disponíveis
fvm releases

# Usar versão específica no projeto
fvm use 3.19.0

# Usar versão global
fvm global 3.24.0
```

## 📋 Pré-requisitos

- ✅ **Windows 10/11**
- ✅ **10GB+ espaço livre**
- ✅ **Conexão com internet**
- ✅ **Direitos de administrador**
- ✅ **PowerShell 5.1+**

## 🔍 Verificação Pós-Instalação

Execute estes comandos para verificar a instalação:

```powershell
# 1. Verificar Flutter
flutter doctor

# 2. Verificar Java
java -version

# 3. Verificar Android SDK
adb --version

# 4. Verificar FVM
fvm --version

# 5. Aceitar licenças Android
flutter doctor --android-licenses
```

## 🐛 Troubleshooting

### Problemas Comuns

**❌ Erro: "Execution Policy"**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

**❌ Erro: "Chocolatey não encontrado"**
```powershell
# Reinicie o PowerShell e tente novamente
refreshenv
```

**❌ Erro: "flutter doctor" falha**
```powershell
# Reinicie o PowerShell para carregar variáveis
# Execute novamente: flutter doctor
```

**❌ Android SDK não encontrado**
1. Abra o Android Studio
2. Vá em File → Settings → Android SDK
3. Instale a versão mais recente
4. Execute: `flutter doctor --android-licenses`

### Logs e Debug

O script gera logs detalhados. Para mais informações:
```powershell
.\flutter-setup.ps1 -Verbose
```

## 📦 Estrutura Final

Após a instalação, sua estrutura ficará assim:

```
C:\DevPrograms\
├── java\
│   ├── jdk8\           # OpenJDK 8
│   ├── jdk11\          # OpenJDK 11
│   └── current\        # Link simbólico para versão ativa
├── flutter\            # Flutter SDK
└── fvm\               # Versões Flutter gerenciadas pelo FVM
    └── versions\
```

## 🎯 Primeiros Passos Após Instalação

### 1. Criar Primeiro Projeto
```powershell
# Navegar para pasta de projetos
cd C:\DevPrograms

# Criar projeto Flutter
flutter create meu_primeiro_app
cd meu_primeiro_app

# Executar projeto
flutter run
```

### 2. Configurar IDE

**Visual Studio Code:**
```bash
# Instalar extensões
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
```

**Android Studio:**
1. Abrir Android Studio
2. Ir em Plugins
3. Instalar "Flutter" e "Dart"

### 3. Configurar Emulador Android
1. Abrir Android Studio
2. Tools → AVD Manager
3. Create Virtual Device
4. Escolher dispositivo e API level
5. Finish

## 📚 Recursos Adicionais

### Links Úteis
- 📖 [Documentação Flutter](https://flutter.dev/docs)
- 🎓 [Flutter Codelabs](https://codelabs.developers.google.com/?cat=Flutter)
- 💬 [Flutter Community](https://flutter.dev/community)
- 🐙 [Flutter GitHub](https://github.com/flutter/flutter)

### Comandos Flutter Essenciais
```powershell
# Verificar instalação
flutter doctor

# Criar projeto
flutter create nome_projeto

# Executar app
flutter run

# Build para produção
flutter build apk

# Análise de código
flutter analyze

# Formatar código
flutter format .

# Limpar build
flutter clean

# Atualizar dependências
flutter pub get
```

### Comandos FVM Úteis
```powershell
# Listar versões instaladas
fvm list

# Instalar versão específica
fvm install 3.19.0

# Remover versão
fvm remove 3.19.0

# Ver configuração
fvm config
```

## 🆘 Suporte

### Encontrou um problema?

1. **Verifique os pré-requisitos** listados acima
2. **Execute em modo verbose**: `.\flutter-setup.ps1 -Verbose`
3. **Consulte o troubleshooting** desta documentação
4. **Abra uma issue** no GitHub: [SEU_REPOSITORIO]/issues

### Contato

- 📧 **Email**: [seu.email@domain.com]
- 🐙 **GitHub**: [github.com/seu-usuario]
- 💼 **LinkedIn**: [linkedin.com/in/seu-perfil]
- 🐦 **Twitter**: [@seu_usuario]

### Contribuições

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- Flutter Team pela excelente documentação
- Comunidade Flutter brasileira
- Todos que contribuíram com feedback e melhorias

---

**⭐ Se este script te ajudou, considere dar uma star no repositório!**

**🔄 Mantenha-se atualizado seguindo o repositório para receber as últimas melhorias!**