# ================================================================
# 🚀 Flutter Development Environment Setup Automation
# ================================================================
# Autor: [Seu Nome]
# GitHub: [Seu GitHub]
# Versão: 1.0
# Descrição: Script automatizado para configurar ambiente Flutter completo
# ================================================================

param(
    [string]$InstallPath = "C:\DevPrograms",
    [string]$JavaVersion = "11",
    [switch]$SkipChocolatey,
    [switch]$SkipJava,
    [switch]$SkipAndroid,
    [switch]$SkipFlutter,
    [switch]$Verbose
)

# ================================================================
# CONFIGURAÇÕES E VARIÁVEIS
# ================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# URLs e versões
$CHOCOLATEY_URL = "https://community.chocolatey.org/install.ps1"
$JDK8_URL = "https://builds.openlogic.com/downloadJDK/openlogic-openjdk/8u392-b08/openlogic-openjdk-8u392-b08-windows-x64.msi"
$JDK11_URL = "https://builds.openlogic.com/downloadJDK/openlogic-openjdk/11.0.21+9/openlogic-openjdk-11.0.21+9-windows-x64.msi"
$ANDROID_STUDIO_URL = "https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.1.12/android-studio-2024.1.1.12-windows.exe"

# Cores para output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

# ================================================================
# FUNÇÕES UTILITÁRIAS
# ================================================================

function Write-ColorMessage {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorMessage "=" * 60 "Header"
    Write-ColorMessage "🔧 $Title" "Header"
    Write-ColorMessage "=" * 60 "Header"
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [int]$Current, [int]$Total)
    Write-ColorMessage "[$Current/$Total] $Step" "Info"
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://www.google.com" -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Add-ToPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = "$currentPath;$PathToAdd"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-ColorMessage "✅ Adicionado ao PATH: $PathToAdd" "Success"
    } else {
        Write-ColorMessage "ℹ️ Já existe no PATH: $PathToAdd" "Info"
    }
}

function Set-EnvironmentVariable {
    param([string]$Name, [string]$Value)
    
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Write-ColorMessage "✅ Variável de ambiente definida: $Name = $Value" "Success"
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForKeyPress {
    param([string]$Message = "Pressione qualquer tecla para continuar...")
    Write-ColorMessage $Message "Info"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ================================================================
# VERIFICAÇÕES PRÉ-INSTALAÇÃO
# ================================================================

function Test-Prerequisites {
    Write-Header "VERIFICANDO PRÉ-REQUISITOS"
    
    # Verificar direitos de administrador
    if (-not (Test-AdminRights)) {
        Write-ColorMessage "❌ Este script precisa ser executado como Administrador!" "Error"
        Write-ColorMessage "   Clique com botão direito no PowerShell e selecione 'Executar como administrador'" "Warning"
        exit 1
    }
    Write-ColorMessage "✅ Direitos de administrador confirmados" "Success"
    
    # Verificar conexão com internet
    Write-ColorMessage "🌐 Testando conexão com internet..." "Info"
    if (-not (Test-InternetConnection)) {
        Write-ColorMessage "❌ Sem conexão com internet! Verifique sua conexão." "Error"
        exit 1
    }
    Write-ColorMessage "✅ Conexão com internet funcionando" "Success"
    
    # Verificar espaço em disco
    $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 10) {
        Write-ColorMessage "❌ Espaço insuficiente! Necessário pelo menos 10GB, disponível: ${freeSpaceGB}GB" "Error"
        exit 1
    }
    Write-ColorMessage "✅ Espaço em disco suficiente: ${freeSpaceGB}GB disponível" "Success"
    
    # Verificar política de execução
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-ColorMessage "⚠️ Política de execução restritiva detectada. Ajustando..." "Warning"
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    }
    Write-ColorMessage "✅ Política de execução adequada" "Success"
    
    Write-ColorMessage "🎉 Todos os pré-requisitos atendidos!" "Success"
}

# ================================================================
# INSTALAÇÃO DO CHOCOLATEY E GIT
# ================================================================

function Install-ChocolateyAndGit {
    if ($SkipChocolatey) {
        Write-ColorMessage "⏭️ Pulando instalação do Chocolatey (parâmetro -SkipChocolatey)" "Warning"
        return
    }
    
    Write-Header "INSTALANDO CHOCOLATEY E GIT"
    
    # Verificar se Chocolatey já está instalado
    if (Test-Command "choco") {
        Write-ColorMessage "✅ Chocolatey já está instalado" "Success"
    } else {
        Write-Step "Instalando Chocolatey" 1 2
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($CHOCOLATEY_URL))
            Write-ColorMessage "✅ Chocolatey instalado com sucesso!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao instalar Chocolatey: $_" "Error"
            exit 1
        }
    }
    
    # Verificar se Git já está instalado
    if (Test-Command "git") {
        Write-ColorMessage "✅ Git já está instalado" "Success"
    } else {
        Write-Step "Instalando Git" 2 2
        try {
            choco install git -y
            Write-ColorMessage "✅ Git instalado com sucesso!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao instalar Git: $_" "Error"
            exit 1
        }
    }
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ================================================================
# INSTALAÇÃO E CONFIGURAÇÃO DO JAVA
# ================================================================

function Install-JavaVersions {
    if ($SkipJava) {
        Write-ColorMessage "⏭️ Pulando instalação do Java (parâmetro -SkipJava)" "Warning"
        return
    }
    
    Write-Header "INSTALANDO E CONFIGURANDO JAVA"
    
    # Criar estrutura de pastas
    $javaPath = Join-Path $InstallPath "java"
    if (-not (Test-Path $javaPath)) {
        New-Item -ItemType Directory -Path $javaPath -Force | Out-Null
        Write-ColorMessage "✅ Pasta Java criada: $javaPath" "Success"
    }
    
    # Instalar JDK 8
    Write-Step "Instalando OpenJDK 8" 1 4
    $jdk8Path = Join-Path $javaPath "jdk8"
    if (-not (Test-Path $jdk8Path)) {
        try {
            $jdk8Installer = Join-Path $env:TEMP "openjdk8.msi"
            Write-ColorMessage "📥 Baixando OpenJDK 8..." "Info"
            Invoke-WebRequest -Uri $JDK8_URL -OutFile $jdk8Installer
            
            Write-ColorMessage "🔧 Instalando OpenJDK 8..." "Info"
            Start-Process msiexec.exe -ArgumentList "/i `"$jdk8Installer`" /quiet INSTALLDIR=`"$jdk8Path`"" -Wait
            Remove-Item $jdk8Installer -Force
            Write-ColorMessage "✅ OpenJDK 8 instalado!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao instalar JDK 8: $_" "Error"
            exit 1
        }
    } else {
        Write-ColorMessage "✅ JDK 8 já está instalado" "Success"
    }
    
    # Instalar JDK 11
    Write-Step "Instalando OpenJDK 11" 2 4
    $jdk11Path = Join-Path $javaPath "jdk11"
    if (-not (Test-Path $jdk11Path)) {
        try {
            $jdk11Installer = Join-Path $env:TEMP "openjdk11.msi"
            Write-ColorMessage "📥 Baixando OpenJDK 11..." "Info"
            Invoke-WebRequest -Uri $JDK11_URL -OutFile $jdk11Installer
            
            Write-ColorMessage "🔧 Instalando OpenJDK 11..." "Info"
            Start-Process msiexec.exe -ArgumentList "/i `"$jdk11Installer`" /quiet INSTALLDIR=`"$jdk11Path`"" -Wait
            Remove-Item $jdk11Installer -Force
            Write-ColorMessage "✅ OpenJDK 11 instalado!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao instalar JDK 11: $_" "Error"
            exit 1
        }
    } else {
        Write-ColorMessage "✅ JDK 11 já está instalado" "Success"
    }
    
    # Criar link simbólico
    Write-Step "Configurando link simbólico" 3 4
    $currentPath = Join-Path $javaPath "current"
    $targetPath = if ($JavaVersion -eq "8") { $jdk8Path } else { $jdk11Path }
    
    if (Test-Path $currentPath) {
        Remove-Item $currentPath -Force
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $currentPath -Target $targetPath -Force | Out-Null
        Write-ColorMessage "✅ Link simbólico criado para JDK $JavaVersion" "Success"
    }
    catch {
        Write-ColorMessage "❌ Erro ao criar link simbólico: $_" "Error"
        exit 1
    }
    
    # Configurar variáveis de ambiente
    Write-Step "Configurando variáveis de ambiente" 4 4
    Set-EnvironmentVariable "JAVA_HOME" $currentPath
    Add-ToPath "%JAVA_HOME%\bin"
    
    # Criar funções de chaveamento no PowerShell Profile
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath -Parent
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    $javaFunctions = @"

# ================================================================
# FUNÇÕES DE CHAVEAMENTO JAVA - Gerado automaticamente
# ================================================================
function jdk8() {
    New-Item -ItemType SymbolicLink -Path "$currentPath" -Target "$jdk8Path" -Force | Out-Null
    Write-Host "✅ Switched to JDK 8" -ForegroundColor Green
    java -version
}

function jdk11() {
    New-Item -ItemType SymbolicLink -Path "$currentPath" -Target "$jdk11Path" -Force | Out-Null
    Write-Host "✅ Switched to JDK 11" -ForegroundColor Green
    java -version
}

function java-version() {
    Write-Host "📋 Current Java Configuration:" -ForegroundColor Cyan
    Write-Host "JAVA_HOME: " -NoNewline
    Write-Host "$env:JAVA_HOME" -ForegroundColor Yellow
    java -version
}

"@
    
    # Verificar se as funções já existem no profile
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -notlike "*jdk8()*") {
            Add-Content $profilePath $javaFunctions
            Write-ColorMessage "✅ Funções de chaveamento adicionadas ao PowerShell Profile" "Success"
        }
    } else {
        Set-Content $profilePath $javaFunctions
        Write-ColorMessage "✅ PowerShell Profile criado com funções de chaveamento" "Success"
    }
}

# ================================================================
# INSTALAÇÃO E CONFIGURAÇÃO DO ANDROID STUDIO
# ================================================================

function Install-AndroidStudio {
    if ($SkipAndroid) {
        Write-ColorMessage "⏭️ Pulando instalação do Android Studio (parâmetro -SkipAndroid)" "Warning"
        return
    }
    
    Write-Header "INSTALANDO ANDROID STUDIO"
    
    # Verificar se Android Studio já está instalado
    $androidStudioPath = "${env:ProgramFiles}\Android\Android Studio"
    if (Test-Path $androidStudioPath) {
        Write-ColorMessage "✅ Android Studio já está instalado" "Success"
    } else {
        Write-Step "Baixando e instalando Android Studio" 1 3
        try {
            $androidInstaller = Join-Path $env:TEMP "android-studio.exe"
            Write-ColorMessage "📥 Baixando Android Studio (pode demorar alguns minutos)..." "Info"
            Invoke-WebRequest -Uri $ANDROID_STUDIO_URL -OutFile $androidInstaller
            
            Write-ColorMessage "🔧 Instalando Android Studio..." "Info"
            Start-Process $androidInstaller -ArgumentList "/S" -Wait
            Remove-Item $androidInstaller -Force
            Write-ColorMessage "✅ Android Studio instalado!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao instalar Android Studio: $_" "Error"
            Write-ColorMessage "ℹ️ Você pode instalar manualmente em: https://developer.android.com/studio" "Info"
        }
    }
    
    # Configurar variáveis de ambiente do Android SDK
    Write-Step "Configurando Android SDK" 2 3
    $androidSdkPath = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    
    if (-not (Test-Path $androidSdkPath)) {
        Write-ColorMessage "⚠️ Android SDK não encontrado no local padrão" "Warning"
        Write-ColorMessage "   Execute o Android Studio e configure o SDK manualmente" "Info"
        Write-ColorMessage "   Local padrão: $androidSdkPath" "Info"
    } else {
        Set-EnvironmentVariable "ANDROID_HOME" $androidSdkPath
        Set-EnvironmentVariable "ANDROID_SDK_ROOT" $androidSdkPath
        Add-ToPath "%ANDROID_HOME%\tools"
        Add-ToPath "%ANDROID_HOME%\platform-tools"
        Write-ColorMessage "✅ Variáveis Android SDK configuradas" "Success"
    }
    
    Write-Step "Verificando instalação" 3 3
    Write-ColorMessage "ℹ️ Após configurar o Android Studio:" "Info"
    Write-ColorMessage "   1. Abra o Android Studio" "Info"
    Write-ColorMessage "   2. Complete a configuração inicial" "Info"
    Write-ColorMessage "   3. Instale o Android SDK mais recente" "Info"
    Write-ColorMessage "   4. Execute: flutter doctor --android-licenses" "Info"
}

# ================================================================
# INSTALAÇÃO E CONFIGURAÇÃO DO FLUTTER
# ================================================================

function Install-Flutter {
    if ($SkipFlutter) {
        Write-ColorMessage "⏭️ Pulando instalação do Flutter (parâmetro -SkipFlutter)" "Warning"
        return
    }
    
    Write-Header "INSTALANDO FLUTTER E FVM"
    
    # Instalar Flutter
    Write-Step "Clonando Flutter SDK" 1 4
    $flutterPath = Join-Path $InstallPath "flutter"
    
    if (Test-Path $flutterPath) {
        Write-ColorMessage "✅ Flutter já está instalado em: $flutterPath" "Success"
    } else {
        try {
            Write-ColorMessage "📥 Clonando Flutter SDK (pode demorar alguns minutos)..." "Info"
            Set-Location $InstallPath
            git clone https://github.com/flutter/flutter.git -b stable
            Write-ColorMessage "✅ Flutter SDK clonado!" "Success"
        }
        catch {
            Write-ColorMessage "❌ Erro ao clonar Flutter: $_" "Error"
            exit 1
        }
    }
    
    # Configurar variáveis de ambiente do Flutter
    Write-Step "Configurando Flutter" 2 4
    Set-EnvironmentVariable "FLUTTER_HOME" $flutterPath
    Add-ToPath "%FLUTTER_HOME%\bin"
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Instalar FVM
    Write-Step "Instalando FVM" 3 4
    try {
        $flutterBin = Join-Path $flutterPath "bin\flutter.bat"
        & $flutterBin pub global activate fvm
        
        # Configurar FVM cache path
        & fvm config --cache-path $InstallPath
        
        Write-ColorMessage "✅ FVM instalado e configurado!" "Success"
        
        # Adicionar FVM ao PATH
        $dartGlobalPath = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
        Add-ToPath $dartGlobalPath
        
    }
    catch {
        Write-ColorMessage "⚠️ Erro ao instalar FVM: $_" "Warning"
        Write-ColorMessage "   Você pode instalar manualmente depois com: flutter pub global activate fvm" "Info"
    }
    
    # Executar flutter doctor
    Write-Step "Executando diagnóstico inicial" 4 4
    try {
        Write-ColorMessage "🔍 Executando flutter doctor..." "Info"
        & $flutterBin doctor
    }
    catch {
        Write-ColorMessage "⚠️ Erro ao executar flutter doctor" "Warning"
        Write-ColorMessage "   Execute manualmente: flutter doctor" "Info"
    }
}

# ================================================================
# VERIFICAÇÃO FINAL E RELATÓRIO
# ================================================================

function Show-FinalReport {
    Write-Header "RELATÓRIO DE INSTALAÇÃO"
    
    Write-ColorMessage "🎉 Instalação concluída!" "Success"
    Write-Host ""
    
    # Verificar cada componente
    Write-ColorMessage "📋 Status dos Componentes:" "Info"
    
    # Chocolatey
    if (Test-Command "choco") {
        Write-ColorMessage "✅ Chocolatey: Instalado" "Success"
    } else {
        Write-ColorMessage "❌ Chocolatey: Não encontrado" "Error"
    }
    
    # Git
    if (Test-Command "git") {
        Write-ColorMessage "✅ Git: Instalado" "Success"
    } else {
        Write-ColorMessage "❌ Git: Não encontrado" "Error"
    }
    
    # Java
    $javaPath = Join-Path $InstallPath "java\current"
    if (Test-Path $javaPath) {
        Write-ColorMessage "✅ Java: Configurado ($javaPath)" "Success"
    } else {
        Write-ColorMessage "❌ Java: Não configurado" "Error"
    }
    
    # Android Studio
    $androidStudioPath = "${env:ProgramFiles}\Android\Android Studio"
    if (Test-Path $androidStudioPath) {
        Write-ColorMessage "✅ Android Studio: Instalado" "Success"
    } else {
        Write-ColorMessage "❌ Android Studio: Não encontrado" "Error"
    }
    
    # Flutter
    $flutterPath = Join-Path $InstallPath "flutter"
    if (Test-Path $flutterPath) {
        Write-ColorMessage "✅ Flutter: Instalado ($flutterPath)" "Success"
    } else {
        Write-ColorMessage "❌ Flutter: Não encontrado" "Error"
    }
    
    Write-Host ""
    Write-ColorMessage "📝 Próximos Passos:" "Info"
    Write-ColorMessage "1. Reinicie o PowerShell para carregar as novas variáveis" "Info"
    Write-ColorMessage "2. Execute: flutter doctor" "Info"
    Write-ColorMessage "3. Aceite as licenças Android: flutter doctor --android-licenses" "Info"
    Write-ColorMessage "4. Configure um emulador no Android Studio" "Info"
    Write-ColorMessage "5. Teste criando um projeto: flutter create teste_app" "Info"
    
    Write-Host ""
    Write-ColorMessage "🔧 Comandos Úteis:" "Info"
    Write-ColorMessage "• Trocar para JDK 8: jdk8" "Info"
    Write-ColorMessage "• Trocar para JDK 11: jdk11" "Info"
    Write-ColorMessage "• Ver versão Java atual: java-version" "Info"
    Write-ColorMessage "• Verificar Flutter: flutter doctor" "Info"
    Write-ColorMessage "• Usar versão específica Flutter em projeto: fvm use [versão]" "Info"
    
    Write-Host ""
    Write-ColorMessage "🆘 Suporte e Feedback:" "Info"
    Write-ColorMessage "• GitHub: [SEU_GITHUB]" "Info"
    Write-ColorMessage "• LinkedIn: [SEU_LINKEDIN]" "Info"
    Write-ColorMessage "• Email: [SEU_EMAIL]" "Info"
    
    Write-Host ""
}

# ================================================================
# FUNÇÃO PRINCIPAL
# ================================================================

function Main {
    try {
        # Banner de boas-vindas
        Clear-Host
        Write-ColorMessage @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    🚀 FLUTTER DEVELOPMENT ENVIRONMENT SETUP AUTOMATION      ║
║                                                              ║
║    📱 Configuração Completa para Desenvolvimento Flutter    ║
║    🔧 Java Multi-Versão + Android Studio + FVM              ║
║    💡 Criado por: [SEU NOME]                                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ "Header"
        
        Write-Host ""
        Write-ColorMessage "📁 Pasta de instalação: $InstallPath" "Info"
        Write-ColorMessage "☕ Versão Java padrão: $JavaVersion" "Info"
        
        if ($Verbose) {
            Write-ColorMessage "🔍 Modo verbose ativado" "Info"
        }
        
        Write-Host ""
        Write-ColorMessage "⚠️ Este script irá:" "Warning"
        Write-ColorMessage "• Instalar Chocolatey e Git" "Warning"
        Write-ColorMessage "• Instalar OpenJDK 8 e 11 com chaveamento automático" "Warning"
        Write-ColorMessage "• Instalar Android Studio" "Warning"
        Write-ColorMessage "• Instalar Flutter SDK e FVM" "Warning"
        Write-ColorMessage "• Configurar todas as variáveis de ambiente necessárias" "Warning"
        
        Write-Host ""
        $continue = Read-Host "Deseja continuar? (s/N)"
        if ($continue -notlike "s*" -and $continue -notlike "y*") {
            Write-ColorMessage "❌ Instalação cancelada pelo usuário" "Warning"
            exit 0
        }
        
        # Executar instalação
        $startTime = Get-Date
        
        Test-Prerequisites
        Install-ChocolateyAndGit
        Install-JavaVersions
        Install-AndroidStudio
        Install-Flutter
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host ""
        Write-ColorMessage "⏱️ Tempo total de instalação: $($duration.Minutes) minutos e $($duration.Seconds) segundos" "Info"
        
        Show-FinalReport
        
        Write-Host ""
        Write-ColorMessage "🎉 Instalação concluída com sucesso!" "Success"
        Write-ColorMessage "💡 Não se esqueça de reiniciar o PowerShell!" "Warning"
        
    }
    catch {
        Write-ColorMessage "❌ Erro durante a instalação: $_" "Error"
        Write-ColorMessage "📧 Reporte este erro para: [SEU_EMAIL]" "Info"
        exit 1
    }
}

# ================================================================
# EXECUÇÃO
# ================================================================

# Verificar se está sendo executado diretamente
if ($MyInvocation.InvocationName -ne ".") {
    Main
}