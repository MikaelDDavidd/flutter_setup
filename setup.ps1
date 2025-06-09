# ================================================================
# Flutter Development Environment Setup Automation
# ================================================================
# Autor: Mikael David
# GitHub: https://github.com/MikaelDDavidd
# Versao: 1.0
# Descricao: Script automatizado para configurar ambiente Flutter completo
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
# CONFIGURACOES E VARIAVEIS
# ================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# URLs e versoes
$CHOCOLATEY_URL = "https://community.chocolatey.org/install.ps1"
$JDK8_URL = "https://builds.openlogic.com/downloadJDK/openlogic-openjdk/8u392-b08/openlogic-openjdk-8u392-b08-windows-x64.msi"
$JDK11_URL = "https://builds.openlogic.com/downloadJDK/openlogic-openjdk/11.0.21+9/openlogic-openjdk-11.0.21+9-windows-x64.msi"
$ANDROID_STUDIO_URL = "https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.1.12/android-studio-2024.1.1.12-windows.exe"

# ================================================================
# FUNCOES UTILITARIAS
# ================================================================

function Write-StatusMessage {
    param([string]$Message, [string]$Type = "Info")
    
    $color = "White"
    $prefix = "[INFO]"
    
    switch ($Type) {
        "Success" { $color = "Green"; $prefix = "[OK]" }
        "Warning" { $color = "Yellow"; $prefix = "[WARN]" }
        "Error" { $color = "Red"; $prefix = "[ERROR]" }
        "Header" { $color = "Magenta"; $prefix = "[SETUP]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-StatusMessage $Title "Header"
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-StepMessage {
    param([string]$Step, [int]$Current, [int]$Total)
    Write-StatusMessage "[$Current/$Total] $Step" "Info"
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

function Add-ToUserPath {
    param([string]$PathToAdd)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$PathToAdd*") {
        $newPath = $currentPath + ";" + $PathToAdd
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-StatusMessage "Adicionado ao PATH: $PathToAdd" "Success"
    } else {
        Write-StatusMessage "Ja existe no PATH: $PathToAdd" "Info"
    }
}

function Set-UserEnvironmentVariable {
    param([string]$Name, [string]$Value)
    
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Write-StatusMessage "Variavel de ambiente definida: $Name = $Value" "Success"
}

function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# ================================================================
# VERIFICACOES PRE-INSTALACAO
# ================================================================

function Test-Prerequisites {
    Write-SectionHeader "VERIFICANDO PRE-REQUISITOS"
    
    # Verificar direitos de administrador
    if (-not (Test-AdminRights)) {
        Write-StatusMessage "Este script precisa ser executado como Administrador!" "Error"
        Write-StatusMessage "Clique com botao direito no PowerShell e selecione 'Executar como administrador'" "Warning"
        exit 1
    }
    Write-StatusMessage "Direitos de administrador confirmados" "Success"
    
    # Verificar conexao com internet
    Write-StatusMessage "Testando conexao com internet..." "Info"
    if (-not (Test-InternetConnection)) {
        Write-StatusMessage "Sem conexao com internet! Verifique sua conexao." "Error"
        exit 1
    }
    Write-StatusMessage "Conexao com internet funcionando" "Success"
    
    # Verificar espaco em disco
    $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 10) {
        Write-StatusMessage "Espaco insuficiente! Necessario pelo menos 10GB, disponivel: ${freeSpaceGB}GB" "Error"
        exit 1
    }
    Write-StatusMessage "Espaco em disco suficiente: ${freeSpaceGB}GB disponivel" "Success"
    
    # Verificar politica de execucao
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-StatusMessage "Politica de execucao restritiva detectada. Ajustando..." "Warning"
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
    }
    Write-StatusMessage "Politica de execucao adequada" "Success"
    
    Write-StatusMessage "Todos os pre-requisitos atendidos!" "Success"
}

# ================================================================
# INSTALACAO DO CHOCOLATEY E GIT
# ================================================================

function Install-ChocolateyAndGit {
    if ($SkipChocolatey) {
        Write-StatusMessage "Pulando instalacao do Chocolatey (parametro -SkipChocolatey)" "Warning"
        return
    }
    
    Write-SectionHeader "INSTALANDO CHOCOLATEY E GIT"
    
    # Verificar se Chocolatey ja esta instalado
    if (Test-CommandExists "choco") {
        Write-StatusMessage "Chocolatey ja esta instalado" "Success"
    } else {
        Write-StepMessage "Instalando Chocolatey" 1 2
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($CHOCOLATEY_URL))
            Write-StatusMessage "Chocolatey instalado com sucesso!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao instalar Chocolatey: $_" "Error"
            exit 1
        }
    }
    
    # Verificar se Git ja esta instalado
    if (Test-CommandExists "git") {
        Write-StatusMessage "Git ja esta instalado" "Success"
    } else {
        Write-StepMessage "Instalando Git" 2 2
        try {
            choco install git -y
            Write-StatusMessage "Git instalado com sucesso!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao instalar Git: $_" "Error"
            exit 1
        }
    }
    
    # Atualizar variaveis de ambiente
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ================================================================
# INSTALACAO E CONFIGURACAO DO JAVA
# ================================================================

function Install-JavaVersions {
    if ($SkipJava) {
        Write-StatusMessage "Pulando instalacao do Java (parametro -SkipJava)" "Warning"
        return
    }
    
    Write-SectionHeader "INSTALANDO E CONFIGURANDO JAVA"
    
    # Criar estrutura de pastas
    $javaPath = Join-Path $InstallPath "java"
    if (-not (Test-Path $javaPath)) {
        New-Item -ItemType Directory -Path $javaPath -Force | Out-Null
        Write-StatusMessage "Pasta Java criada: $javaPath" "Success"
    }
    
    # Instalar JDK 8
    Write-StepMessage "Instalando OpenJDK 8" 1 4
    $jdk8Path = Join-Path $javaPath "jdk8"
    if (-not (Test-Path $jdk8Path)) {
        try {
            $jdk8Installer = Join-Path $env:TEMP "openjdk8.msi"
            Write-StatusMessage "Baixando OpenJDK 8..." "Info"
            Invoke-WebRequest -Uri $JDK8_URL -OutFile $jdk8Installer
            
            Write-StatusMessage "Instalando OpenJDK 8..." "Info"
            $installArgs = "/i `"$jdk8Installer`" /quiet INSTALLDIR=`"$jdk8Path`""
            Start-Process msiexec.exe -ArgumentList $installArgs -Wait
            Remove-Item $jdk8Installer -Force
            Write-StatusMessage "OpenJDK 8 instalado!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao instalar JDK 8: $_" "Error"
            exit 1
        }
    } else {
        Write-StatusMessage "JDK 8 ja esta instalado" "Success"
    }
    
    # Instalar JDK 11
    Write-StepMessage "Instalando OpenJDK 11" 2 4
    $jdk11Path = Join-Path $javaPath "jdk11"
    if (-not (Test-Path $jdk11Path)) {
        try {
            $jdk11Installer = Join-Path $env:TEMP "openjdk11.msi"
            Write-StatusMessage "Baixando OpenJDK 11..." "Info"
            Invoke-WebRequest -Uri $JDK11_URL -OutFile $jdk11Installer
            
            Write-StatusMessage "Instalando OpenJDK 11..." "Info"
            $installArgs = "/i `"$jdk11Installer`" /quiet INSTALLDIR=`"$jdk11Path`""
            Start-Process msiexec.exe -ArgumentList $installArgs -Wait
            Remove-Item $jdk11Installer -Force
            Write-StatusMessage "OpenJDK 11 instalado!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao instalar JDK 11: $_" "Error"
            exit 1
        }
    } else {
        Write-StatusMessage "JDK 11 ja esta instalado" "Success"
    }
    
    # Criar link simbolico
    Write-StepMessage "Configurando link simbolico" 3 4
    $currentPath = Join-Path $javaPath "current"
    $targetPath = if ($JavaVersion -eq "8") { $jdk8Path } else { $jdk11Path }
    
    if (Test-Path $currentPath) {
        Remove-Item $currentPath -Force
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $currentPath -Target $targetPath -Force | Out-Null
        Write-StatusMessage "Link simbolico criado para JDK $JavaVersion" "Success"
    }
    catch {
        Write-StatusMessage "Erro ao criar link simbolico: $_" "Error"
        exit 1
    }
    
    # Configurar variaveis de ambiente
    Write-StepMessage "Configurando variaveis de ambiente" 4 4
    Set-UserEnvironmentVariable "JAVA_HOME" $currentPath
    Add-ToUserPath "%JAVA_HOME%\bin"
    
    # Criar funcoes de chaveamento no PowerShell Profile
    $profilePath = $PROFILE
    $profileDir = Split-Path $profilePath -Parent
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    $javaFunctions = @"

# ================================================================
# FUNCOES DE CHAVEAMENTO JAVA - Gerado automaticamente
# ================================================================
function jdk8() {
    New-Item -ItemType SymbolicLink -Path "$currentPath" -Target "$jdk8Path" -Force | Out-Null
    Write-Host "Switched to JDK 8" -ForegroundColor Green
    java -version
}

function jdk11() {
    New-Item -ItemType SymbolicLink -Path "$currentPath" -Target "$jdk11Path" -Force | Out-Null
    Write-Host "Switched to JDK 11" -ForegroundColor Green
    java -version
}

function java-version() {
    Write-Host "Current Java Configuration:" -ForegroundColor Cyan
    Write-Host "JAVA_HOME: " -NoNewline
    Write-Host "`$env:JAVA_HOME" -ForegroundColor Yellow
    java -version
}

"@
    
    # Verificar se as funcoes ja existem no profile
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -notlike "*jdk8()*") {
            Add-Content $profilePath $javaFunctions
            Write-StatusMessage "Funcoes de chaveamento adicionadas ao PowerShell Profile" "Success"
        }
    } else {
        Set-Content $profilePath $javaFunctions
        Write-StatusMessage "PowerShell Profile criado com funcoes de chaveamento" "Success"
    }
}

# ================================================================
# INSTALACAO E CONFIGURACAO DO ANDROID STUDIO
# ================================================================

function Install-AndroidStudio {
    if ($SkipAndroid) {
        Write-StatusMessage "Pulando instalacao do Android Studio (parametro -SkipAndroid)" "Warning"
        return
    }
    
    Write-SectionHeader "INSTALANDO ANDROID STUDIO"
    
    # Verificar se Android Studio ja esta instalado
    $androidStudioPath = "${env:ProgramFiles}\Android\Android Studio"
    if (Test-Path $androidStudioPath) {
        Write-StatusMessage "Android Studio ja esta instalado" "Success"
    } else {
        Write-StepMessage "Baixando e instalando Android Studio" 1 3
        try {
            $androidInstaller = Join-Path $env:TEMP "android-studio.exe"
            Write-StatusMessage "Baixando Android Studio (pode demorar alguns minutos)..." "Info"
            Invoke-WebRequest -Uri $ANDROID_STUDIO_URL -OutFile $androidInstaller
            
            Write-StatusMessage "Instalando Android Studio..." "Info"
            Start-Process $androidInstaller -ArgumentList "/S" -Wait
            Remove-Item $androidInstaller -Force
            Write-StatusMessage "Android Studio instalado!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao instalar Android Studio: $_" "Error"
            Write-StatusMessage "Voce pode instalar manualmente em: https://developer.android.com/studio" "Info"
        }
    }
    
    # Configurar variaveis de ambiente do Android SDK
    Write-StepMessage "Configurando Android SDK" 2 3
    $androidSdkPath = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    
    if (-not (Test-Path $androidSdkPath)) {
        Write-StatusMessage "Android SDK nao encontrado no local padrao" "Warning"
        Write-StatusMessage "Execute o Android Studio e configure o SDK manualmente" "Info"
        Write-StatusMessage "Local padrao: $androidSdkPath" "Info"
    } else {
        Set-UserEnvironmentVariable "ANDROID_HOME" $androidSdkPath
        Set-UserEnvironmentVariable "ANDROID_SDK_ROOT" $androidSdkPath
        Add-ToUserPath "%ANDROID_HOME%\tools"
        Add-ToUserPath "%ANDROID_HOME%\platform-tools"
        Write-StatusMessage "Variaveis Android SDK configuradas" "Success"
    }
    
    Write-StepMessage "Verificando instalacao" 3 3
    Write-StatusMessage "Apos configurar o Android Studio:" "Info"
    Write-StatusMessage "1. Abra o Android Studio" "Info"
    Write-StatusMessage "2. Complete a configuracao inicial" "Info"
    Write-StatusMessage "3. Instale o Android SDK mais recente" "Info"
    Write-StatusMessage "4. Execute: flutter doctor --android-licenses" "Info"
}

# ================================================================
# INSTALACAO E CONFIGURACAO DO FLUTTER
# ================================================================

function Install-Flutter {
    if ($SkipFlutter) {
        Write-StatusMessage "Pulando instalacao do Flutter (parametro -SkipFlutter)" "Warning"
        return
    }
    
    Write-SectionHeader "INSTALANDO FLUTTER E FVM"
    
    # Instalar Flutter
    Write-StepMessage "Clonando Flutter SDK" 1 4
    $flutterPath = Join-Path $InstallPath "flutter"
    
    if (Test-Path $flutterPath) {
        Write-StatusMessage "Flutter ja esta instalado em: $flutterPath" "Success"
    } else {
        try {
            Write-StatusMessage "Clonando Flutter SDK (pode demorar alguns minutos)..." "Info"
            Set-Location $InstallPath
            git clone https://github.com/flutter/flutter.git -b stable
            Write-StatusMessage "Flutter SDK clonado!" "Success"
        }
        catch {
            Write-StatusMessage "Erro ao clonar Flutter: $_" "Error"
            exit 1
        }
    }
    
    # Configurar variaveis de ambiente do Flutter
    Write-StepMessage "Configurando Flutter" 2 4
    Set-UserEnvironmentVariable "FLUTTER_HOME" $flutterPath
    Add-ToUserPath "%FLUTTER_HOME%\bin"
    
    # Atualizar variaveis de ambiente
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Instalar FVM
    Write-StepMessage "Instalando FVM" 3 4
    try {
        $flutterBin = Join-Path $flutterPath "bin\flutter.bat"
        & $flutterBin pub global activate fvm
        
        # Configurar FVM cache path
        & fvm config --cache-path $InstallPath
        
        Write-StatusMessage "FVM instalado e configurado!" "Success"
        
        # Adicionar FVM ao PATH
        $dartGlobalPath = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
        Add-ToUserPath $dartGlobalPath
        
    }
    catch {
        Write-StatusMessage "Erro ao instalar FVM: $_" "Warning"
        Write-StatusMessage "Voce pode instalar manualmente depois com: flutter pub global activate fvm" "Info"
    }
    
    # Executar flutter doctor
    Write-StepMessage "Executando diagnostico inicial" 4 4
    try {
        Write-StatusMessage "Executando flutter doctor..." "Info"
        & $flutterBin doctor
    }
    catch {
        Write-StatusMessage "Erro ao executar flutter doctor" "Warning"
        Write-StatusMessage "Execute manualmente: flutter doctor" "Info"
    }
}

# ================================================================
# VERIFICACAO FINAL E RELATORIO
# ================================================================

function Show-FinalReport {
    Write-SectionHeader "RELATORIO DE INSTALACAO"
    
    Write-StatusMessage "Instalacao concluida!" "Success"
    Write-Host ""
    
    # Verificar cada componente
    Write-StatusMessage "Status dos Componentes:" "Info"
    
    # Chocolatey
    if (Test-CommandExists "choco") {
        Write-StatusMessage "Chocolatey: Instalado" "Success"
    } else {
        Write-StatusMessage "Chocolatey: Nao encontrado" "Error"
    }
    
    # Git
    if (Test-CommandExists "git") {
        Write-StatusMessage "Git: Instalado" "Success"
    } else {
        Write-StatusMessage "Git: Nao encontrado" "Error"
    }
    
    # Java
    $javaPath = Join-Path $InstallPath "java\current"
    if (Test-Path $javaPath) {
        Write-StatusMessage "Java: Configurado ($javaPath)" "Success"
    } else {
        Write-StatusMessage "Java: Nao configurado" "Error"
    }
    
    # Android Studio
    $androidStudioPath = "${env:ProgramFiles}\Android\Android Studio"
    if (Test-Path $androidStudioPath) {
        Write-StatusMessage "Android Studio: Instalado" "Success"
    } else {
        Write-StatusMessage "Android Studio: Nao encontrado" "Error"
    }
    
    # Flutter
    $flutterPath = Join-Path $InstallPath "flutter"
    if (Test-Path $flutterPath) {
        Write-StatusMessage "Flutter: Instalado ($flutterPath)" "Success"
    } else {
        Write-StatusMessage "Flutter: Nao encontrado" "Error"
    }
    
    Write-Host ""
    Write-StatusMessage "Proximos Passos:" "Info"
    Write-StatusMessage "1. Reinicie o PowerShell para carregar as novas variaveis" "Info"
    Write-StatusMessage "2. Execute: flutter doctor" "Info"
    Write-StatusMessage "3. Aceite as licencas Android: flutter doctor --android-licenses" "Info"
    Write-StatusMessage "4. Configure um emulador no Android Studio" "Info"
    Write-StatusMessage "5. Teste criando um projeto: flutter create teste_app" "Info"
    
    Write-Host ""
    Write-StatusMessage "Comandos Uteis:" "Info"
    Write-StatusMessage "• Trocar para JDK 8: jdk8" "Info"
    Write-StatusMessage "• Trocar para JDK 11: jdk11" "Info"
    Write-StatusMessage "• Ver versao Java atual: java-version" "Info"
    Write-StatusMessage "• Verificar Flutter: flutter doctor" "Info"
    Write-StatusMessage "• Usar versao especifica Flutter em projeto: fvm use [versao]" "Info"
    
    Write-Host ""
    Write-StatusMessage "Suporte e Feedback:" "Info"
    Write-StatusMessage "• GitHub: https://github.com/MikaelDDavidd" "Info"
    Write-StatusMessage "• Email: mikaeldavi111@gmail.com" "Info"
    
    Write-Host ""
}

# ================================================================
# FUNCAO PRINCIPAL
# ================================================================

function Main {
    try {
        # Banner de boas-vindas
        Clear-Host
        Write-Host "============================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "    FLUTTER DEVELOPMENT ENVIRONMENT SETUP AUTOMATION" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "    Configuracao Completa para Desenvolvimento Flutter" -ForegroundColor Cyan
        Write-Host "    Java Multi-Versao + Android Studio + FVM" -ForegroundColor Cyan
        Write-Host "    Criado por: Mikael David" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Magenta
        
        Write-Host ""
        Write-StatusMessage "Pasta de instalacao: $InstallPath" "Info"
        Write-StatusMessage "Versao Java padrao: $JavaVersion" "Info"
        
        if ($Verbose) {
            Write-StatusMessage "Modo verbose ativado" "Info"
        }
        
        Write-Host ""
        Write-StatusMessage "Este script ira:" "Warning"
        Write-StatusMessage "• Instalar Chocolatey e Git" "Warning"
        Write-StatusMessage "• Instalar OpenJDK 8 e 11 com chaveamento automatico" "Warning"
        Write-StatusMessage "• Instalar Android Studio" "Warning"
        Write-StatusMessage "• Instalar Flutter SDK e FVM" "Warning"
        Write-StatusMessage "• Configurar todas as variaveis de ambiente necessarias" "Warning"
        
        Write-Host ""
        $continue = Read-Host "Deseja continuar? (s/N)"
        if ($continue -notlike "s*" -and $continue -notlike "y*") {
            Write-StatusMessage "Instalacao cancelada pelo usuario" "Warning"
            exit 0
        }
        
        # Executar instalacao
        $startTime = Get-Date
        
        Test-Prerequisites
        Install-ChocolateyAndGit
        Install-JavaVersions
        Install-AndroidStudio
        Install-Flutter
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host ""
        Write-StatusMessage "Tempo total de instalacao: $($duration.Minutes) minutos e $($duration.Seconds) segundos" "Info"
        
        Show-FinalReport
        
        Write-Host ""
        Write-StatusMessage "Instalacao concluida com sucesso!" "Success"
        Write-StatusMessage "Nao se esqueca de reiniciar o PowerShell!" "Warning"
        
    }
    catch {
        Write-StatusMessage "Erro durante a instalacao: $_" "Error"
        Write-StatusMessage "Reporte este erro para: mikaeldavi111@gmail.com" "Info"
        exit 1
    }
}

# ================================================================
# EXECUCAO
# ================================================================

# Verificar se esta sendo executado diretamente
if ($MyInvocation.InvocationName -ne ".") {
    Main
}