# ================================================================
# 🔍 Flutter Environment Health Checker
# ================================================================
# Complemento do Flutter Setup Automation
# Autor: [Seu Nome]
# Versão: 1.0
# Descrição: Verifica e diagnostica problemas no ambiente Flutter
# ================================================================

param(
    [switch]$Fix,          # Tentar corrigir problemas automaticamente
    [switch]$Detailed,     # Relatório detalhado
    [switch]$Export,       # Exportar relatório para arquivo
    [string]$OutputPath = "flutter-health-report.txt"
)

# ================================================================
# CONFIGURAÇÕES
# ================================================================

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

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
    Write-ColorMessage "🔍 $Title" "Header"
    Write-ColorMessage "=" * 60 "Header"
    Write-Host ""
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

function Get-CommandVersion {
    param([string]$Command, [string]$VersionFlag = "--version")
    try {
        $output = & $Command $VersionFlag 2>&1
        return $output -join " "
    }
    catch {
        return "Não encontrado"
    }
}

function Test-Path {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        Write-ColorMessage "✅ $Description`: $Path" "Success"
        return $true
    } else {
        Write-ColorMessage "❌ $Description não encontrado: $Path" "Error"
        return $false
    }
}

function Test-EnvironmentVariable {
    param([string]$VarName, [string]$ExpectedPath = $null)
    $value = [Environment]::GetEnvironmentVariable($VarName, "User")
    
    if ([string]::IsNullOrEmpty($value)) {
        Write-ColorMessage "❌ Variável $VarName não definida" "Error"
        return $false
    }
    
    if ($ExpectedPath -and -not (Test-Path $value)) {
        Write-ColorMessage "❌ $VarName aponta para caminho inválido: $value" "Error"
        return $false
    }
    
    Write-ColorMessage "✅ $VarName`: $value" "Success"
    return $true
}

# ================================================================
# VERIFICAÇÕES ESPECÍFICAS
# ================================================================

function Test-JavaEnvironment {
    Write-Header "VERIFICANDO AMBIENTE JAVA"
    
    $javaIssues = @()
    
    # Verificar JAVA_HOME
    $javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
    if ([string]::IsNullOrEmpty($javaHome)) {
        $javaIssues += "JAVA_HOME não definido"
        Write-ColorMessage "❌ JAVA_HOME não definido" "Error"
    } elseif (-not (Test-Path $javaHome)) {
        $javaIssues += "JAVA_HOME aponta para caminho inválido: $javaHome"
        Write-ColorMessage "❌ JAVA_HOME inválido: $javaHome" "Error"
    } else {
        Write-ColorMessage "✅ JAVA_HOME: $javaHome" "Success"
    }
    
    # Verificar se Java está no PATH
    if (Test-Command "java") {
        $javaVersion = Get-CommandVersion "java"
        Write-ColorMessage "✅ Java encontrado: $javaVersion" "Success"
    } else {
        $javaIssues += "Java não encontrado no PATH"
        Write-ColorMessage "❌ Java não encontrado no PATH" "Error"
    }
    
    # Verificar estrutura de pastas Java
    $devPrograms = "C:\DevPrograms\java"
    if (Test-Path $devPrograms) {
        Write-ColorMessage "✅ Pasta Java encontrada: $devPrograms" "Success"
        
        # Verificar JDK 8
        $jdk8Path = Join-Path $devPrograms "jdk8"
        Test-Path $jdk8Path "JDK 8" | Out-Null
        
        # Verificar JDK 11
        $jdk11Path = Join-Path $devPrograms "jdk11"
        Test-Path $jdk11Path "JDK 11" | Out-Null
        
        # Verificar link current
        $currentPath = Join-Path $devPrograms "current"
        if (Test-Path $currentPath) {
            $target = (Get-Item $currentPath).Target
            Write-ColorMessage "✅ Link simbólico 'current' aponta para: $target" "Success"
        } else {
            $javaIssues += "Link simbólico 'current' não encontrado"
            Write-ColorMessage "❌ Link simbólico 'current' não encontrado" "Error"
        }
    } else {
        $javaIssues += "Estrutura de pastas Java não encontrada"
        Write-ColorMessage "❌ Estrutura Java não encontrada: $devPrograms" "Error"
    }
    
    # Verificar funções PowerShell
    try {
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        if ($profileContent -like "*jdk8()*") {
            Write-ColorMessage "✅ Funções de chaveamento Java encontradas no PowerShell Profile" "Success"
        } else {
            $javaIssues += "Funções de chaveamento não encontradas no PowerShell Profile"
            Write-ColorMessage "⚠️ Funções de chaveamento não encontradas" "Warning"
        }
    }
    catch {
        Write-ColorMessage "⚠️ Não foi possível verificar PowerShell Profile" "Warning"
    }
    
    return $javaIssues
}

function Test-AndroidEnvironment {
    Write-Header "VERIFICANDO AMBIENTE ANDROID"
    
    $androidIssues = @()
    
    # Verificar ANDROID_HOME
    if (-not (Test-EnvironmentVariable "ANDROID_HOME")) {
        $androidIssues += "ANDROID_HOME não definido"
    }
    
    # Verificar ANDROID_SDK_ROOT
    if (-not (Test-EnvironmentVariable "ANDROID_SDK_ROOT")) {
        $androidIssues += "ANDROID_SDK_ROOT não definido"
    }
    
    # Verificar Android Studio
    $androidStudioPath = "${env:ProgramFiles}\Android\Android Studio"
    if (-not (Test-Path $androidStudioPath "Android Studio")) {
        $androidIssues += "Android Studio não encontrado"
    }
    
    # Verificar ADB
    if (Test-Command "adb") {
        $adbVersion = Get-CommandVersion "adb"
        Write-ColorMessage "✅ ADB encontrado: $adbVersion" "Success"
    } else {
        $androidIssues += "ADB não encontrado no PATH"
        Write-ColorMessage "❌ ADB não encontrado" "Error"
    }
    
    # Verificar SDK Manager
    $androidHome = [Environment]::GetEnvironmentVariable("ANDROID_HOME", "User")
    if ($androidHome -and (Test-Path $androidHome)) {
        $platformTools = Join-Path $androidHome "platform-tools"
        $buildTools = Join-Path $androidHome "build-tools"
        $platforms = Join-Path $androidHome "platforms"
        
        Test-Path $platformTools "Platform Tools" | Out-Null
        Test-Path $buildTools "Build Tools" | Out-Null
        Test-Path $platforms "Android Platforms" | Out-Null
    }
    
    # Verificar emuladores
    if (Test-Command "emulator") {
        Write-ColorMessage "✅ Emulator encontrado" "Success"
    } else {
        Write-ColorMessage "⚠️ Emulator não encontrado no PATH" "Warning"
    }
    
    return $androidIssues
}

function Test-FlutterEnvironment {
    Write-Header "VERIFICANDO AMBIENTE FLUTTER"
    
    $flutterIssues = @()
    
    # Verificar FLUTTER_HOME
    if (-not (Test-EnvironmentVariable "FLUTTER_HOME")) {
        $flutterIssues += "FLUTTER_HOME não definido"
    }
    
    # Verificar Flutter no PATH
    if (Test-Command "flutter") {
        $flutterVersion = Get-CommandVersion "flutter"
        Write-ColorMessage "✅ Flutter encontrado: $flutterVersion" "Success"
    } else {
        $flutterIssues += "Flutter não encontrado no PATH"
        Write-ColorMessage "❌ Flutter não encontrado" "Error"
    }
    
    # Verificar Dart
    if (Test-Command "dart") {
        $dartVersion = Get-CommandVersion "dart"
        Write-ColorMessage "✅ Dart encontrado: $dartVersion" "Success"
    } else {
        $flutterIssues += "Dart não encontrado"
        Write-ColorMessage "❌ Dart não encontrado" "Error"
    }
    
    # Verificar FVM
    if (Test-Command "fvm") {
        $fvmVersion = Get-CommandVersion "fvm"
        Write-ColorMessage "✅ FVM encontrado: $fvmVersion" "Success"
    } else {
        Write-ColorMessage "⚠️ FVM não encontrado" "Warning"
    }
    
    # Executar flutter doctor se disponível
    if (Test-Command "flutter") {
        Write-ColorMessage "🔍 Executando flutter doctor..." "Info"
        try {
            $doctorOutput = flutter doctor 2>&1
            if ($doctorOutput -match "\[✓\]") {
                Write-ColorMessage "✅ Flutter doctor executado com sucesso" "Success"
                if ($Detailed) {
                    Write-Host ""
                    Write-ColorMessage "📋 Saída do flutter doctor:" "Info"
                    $doctorOutput | ForEach-Object { 
                        if ($_ -match "\[✓\]") {
                            Write-ColorMessage $_ "Success"
                        } elseif ($_ -match "\[✗\]") {
                            Write-ColorMessage $_ "Error"
                        } elseif ($_ -match "\[!\]") {
                            Write-ColorMessage $_ "Warning"
                        } else {
                            Write-Host $_
                        }
                    }
                }
            } else {
                $flutterIssues += "Flutter doctor encontrou problemas"
                Write-ColorMessage "⚠️ Flutter doctor encontrou problemas" "Warning"
            }
        }
        catch {
            $flutterIssues += "Erro ao executar flutter doctor"
            Write-ColorMessage "❌ Erro ao executar flutter doctor: $_" "Error"
        }
    }
    
    return $flutterIssues
}

function Test-GeneralEnvironment {
    Write-Header "VERIFICANDO AMBIENTE GERAL"
    
    $generalIssues = @()
    
    # Verificar Git
    if (Test-Command "git") {
        $gitVersion = Get-CommandVersion "git"
        Write-ColorMessage "✅ Git encontrado: $gitVersion" "Success"
    } else {
        $generalIssues += "Git não encontrado"
        Write-ColorMessage "❌ Git não encontrado" "Error"
    }
    
    # Verificar Chocolatey
    if (Test-Command "choco") {
        $chocoVersion = Get-CommandVersion "choco"
        Write-ColorMessage "✅ Chocolatey encontrado: $chocoVersion" "Success"
    } else {
        Write-ColorMessage "⚠️ Chocolatey não encontrado" "Warning"
    }
    
    # Verificar PowerShell Profile
    if (Test-Path $PROFILE) {
        Write-ColorMessage "✅ PowerShell Profile encontrado: $PROFILE" "Success"
    } else {
        Write-ColorMessage "⚠️ PowerShell Profile não encontrado" "Warning"
    }
    
    # Verificar espaço em disco
    $drive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 5) {
        $generalIssues += "Pouco espaço em disco: ${freeSpaceGB}GB"
        Write-ColorMessage "⚠️ Pouco espaço em disco: ${freeSpaceGB}GB" "Warning"
    } else {
        Write-ColorMessage "✅ Espaço em disco adequado: ${freeSpaceGB}GB" "Success"
    }
    
    return $generalIssues
}

# ================================================================
# CORREÇÕES AUTOMÁTICAS
# ================================================================

function Repair-Environment {
    param([array]$Issues)
    
    if (-not $Fix) {
        return
    }
    
    Write-Header "TENTANDO CORRIGIR PROBLEMAS"
    
    foreach ($issue in $Issues) {
        Write-ColorMessage "🔧 Tentando corrigir: $issue" "Info"
        
        switch -Wildcard ($issue) {
            "*JAVA_HOME*" {
                # Tentar encontrar e configurar JAVA_HOME
                $javaPath = "C:\DevPrograms\java\current"
                if (Test-Path $javaPath) {
                    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "User")
                    Write-ColorMessage "✅ JAVA_HOME configurado para: $javaPath" "Success"
                }
            }
            
            "*ANDROID_HOME*" {
                # Tentar encontrar e configurar ANDROID_HOME
                $possiblePaths = @(
                    "${env:LOCALAPPDATA}\Android\Sdk",
                    "${env:ProgramFiles}\Android\sdk",
                    "C:\Android\sdk"
                )
                
                foreach ($path in $possiblePaths) {
                    if (Test-Path $path) {
                        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $path, "User")
                        [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $path, "User")
                        Write-ColorMessage "✅ Android SDK configurado para: $path" "Success"
                        break
                    }
                }
            }
            
            "*Flutter não encontrado*" {
                # Verificar se Flutter existe mas não está no PATH
                $flutterPath = "C:\DevPrograms\flutter"
                if (Test-Path $flutterPath) {
                    [Environment]::SetEnvironmentVariable("FLUTTER_HOME", $flutterPath, "User")
                    
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                    $flutterBin = Join-Path $flutterPath "bin"
                    if ($currentPath -notlike "*$flutterBin*") {
                        $newPath = "$currentPath;$flutterBin"
                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                        Write-ColorMessage "✅ Flutter adicionado ao PATH" "Success"
                    }
                }
            }
            
            default {
                Write-ColorMessage "⚠️ Correção não implementada para: $issue" "Warning"
            }
        }
    }
    
    Write-ColorMessage "🔄 Reinicie o PowerShell para aplicar as correções" "Warning"
}

# ================================================================
# RELATÓRIO E EXPORTAÇÃO
# ================================================================

function Export-Report {
    param([array]$AllIssues)
    
    if (-not $Export) {
        return
    }
    
    $reportContent = @"
# Flutter Environment Health Report
# Generated: $(Get-Date)
# Computer: $env:COMPUTERNAME
# User: $env:USERNAME

## Summary
Total Issues Found: $($AllIssues.Count)

## Issues Details
"@
    
    foreach ($issue in $AllIssues) {
        $reportContent += "`n- $issue"
    }
    
    $reportContent += @"

## Environment Variables
JAVA_HOME: $([Environment]::GetEnvironmentVariable("JAVA_HOME", "User"))
ANDROID_HOME: $([Environment]::GetEnvironmentVariable("ANDROID_HOME", "User"))
ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT", "User"))
FLUTTER_HOME: $([Environment]::GetEnvironmentVariable("FLUTTER_HOME", "User"))

## Tool Versions
"@
    
    if (Test-Command "java") {
        $reportContent += "`nJava: $(Get-CommandVersion 'java')"
    }
    
    if (Test-Command "flutter") {
        $reportContent += "`nFlutter: $(Get-CommandVersion 'flutter')"
    }
    
    if (Test-Command "dart") {
        $reportContent += "`nDart: $(Get-CommandVersion 'dart')"
    }
    
    if (Test-Command "adb") {
        $reportContent += "`nADB: $(Get-CommandVersion 'adb')"
    }
    
    Set-Content -Path $OutputPath -Value $reportContent
    Write-ColorMessage "📄 Relatório exportado para: $OutputPath" "Success"
}

# ================================================================
# FUNÇÃO PRINCIPAL
# ================================================================

function Main {
    Clear-Host
    Write-ColorMessage @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║      🔍 FLUTTER ENVIRONMENT HEALTH CHECKER                  ║
║                                                              ║
║      Diagnóstico completo do ambiente de desenvolvimento    ║
║      Criado por: [SEU NOME]                                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ "Header"
    
    Write-Host ""
    
    # Coletar todos os problemas
    $allIssues = @()
    
    # Executar verificações
    $allIssues += Test-GeneralEnvironment
    $allIssues += Test-JavaEnvironment
    $allIssues += Test-AndroidEnvironment
    $allIssues += Test-FlutterEnvironment
    
    # Remover itens vazios
    $allIssues = $allIssues | Where-Object { $_ -ne $null -and $_ -ne "" }
    
    # Mostrar resumo
    Write-Header "RESUMO FINAL"
    
    if ($allIssues.Count -eq 0) {
        Write-ColorMessage "🎉 Nenhum problema encontrado! Seu ambiente está saudável." "Success"
    } else {
        Write-ColorMessage "⚠️ Foram encontrados $($allIssues.Count) problema(s):" "Warning"
        foreach ($issue in $allIssues) {
            Write-ColorMessage "  • $issue" "Error"
        }
        
        if ($Fix) {
            Repair-Environment -Issues $allIssues
        } else {
            Write-Host ""
            Write-ColorMessage "💡 Para tentar corrigir automaticamente, execute:" "Info"
            Write-ColorMessage "   .\health-checker.ps1 -Fix" "Info"
        }
    }
    
    # Exportar relatório se solicitado
    Export-Report -AllIssues $allIssues
    
    Write-Host ""
    Write-ColorMessage "🔗 Precisa de ajuda? Visite: github.com/[SEU_USUARIO]/flutter-setup-automation" "Info"
    Write-ColorMessage "📧 Suporte: [SEU_EMAIL]" "Info"
}

# ================================================================
# EXECUÇÃO
# ================================================================

if ($MyInvocation.InvocationName -ne ".") {
    Main
}