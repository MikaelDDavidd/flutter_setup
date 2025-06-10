# ================================================================
# Android SDK Configuration Fix
# ================================================================
# Execute este script APOS configurar o Android Studio pela primeira vez
# Autor: Mikael David
# GitHub: https://github.com/MikaelDDavidd
# ================================================================

function Write-StatusMessage {
    param([string]$Message, [string]$Type = "Info")
    
    $color = "White"
    $prefix = "[INFO]"
    
    switch ($Type) {
        "Success" { $color = "Green"; $prefix = "[OK]" }
        "Warning" { $color = "Yellow"; $prefix = "[WARN]" }
        "Error" { $color = "Red"; $prefix = "[ERROR]" }
        "Header" { $color = "Magenta"; $prefix = "[FIX]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-AndroidStudioSetup {
    Write-StatusMessage "Verificando se Android Studio foi configurado..." "Header"
    
    # Locais possiveis do Android SDK
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:USERPROFILE\AppData\Local\Android\Sdk",
        "${env:ProgramFiles}\Android\sdk",
        "C:\Android\sdk",
        "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-StatusMessage "Android SDK encontrado em: $path" "Success"
            
            # Verificar se tem platform-tools
            $platformTools = Join-Path $path "platform-tools"
            if (Test-Path $platformTools) {
                Write-StatusMessage "Platform-tools encontrado: $platformTools" "Success"
                return $path
            } else {
                Write-StatusMessage "Platform-tools nao encontrado em: $platformTools" "Warning"
            }
        }
    }
    
    Write-StatusMessage "Android SDK nao encontrado!" "Error"
    Write-StatusMessage "Voce precisa executar o Android Studio primeiro!" "Warning"
    return $null
}

function Configure-AndroidEnvironment {
    param([string]$AndroidSdkPath)
    
    Write-StatusMessage "Configurando variaveis de ambiente do Android..." "Header"
    
    # Configurar ANDROID_HOME
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $AndroidSdkPath, "User")
    Write-StatusMessage "ANDROID_HOME configurado: $AndroidSdkPath" "Success"
    
    # Configurar ANDROID_SDK_ROOT
    [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $AndroidSdkPath, "User")
    Write-StatusMessage "ANDROID_SDK_ROOT configurado: $AndroidSdkPath" "Success"
    
    # Atualizar PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $platformTools = Join-Path $AndroidSdkPath "platform-tools"
    $tools = Join-Path $AndroidSdkPath "tools"
    $cmdlineTools = Join-Path $AndroidSdkPath "cmdline-tools\latest\bin"
    
    # Adicionar platform-tools ao PATH
    if ($currentPath -notlike "*$platformTools*") {
        $newPath = "$currentPath;$platformTools"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-StatusMessage "Platform-tools adicionado ao PATH" "Success"
    } else {
        Write-StatusMessage "Platform-tools ja esta no PATH" "Info"
    }
    
    # Adicionar tools ao PATH (se existir)
    if (Test-Path $tools) {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$tools*") {
            $newPath = "$currentPath;$tools"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            Write-StatusMessage "Tools adicionado ao PATH" "Success"
        } else {
            Write-StatusMessage "Tools ja esta no PATH" "Info"
        }
    }
    
    # Adicionar cmdline-tools ao PATH (se existir)
    if (Test-Path $cmdlineTools) {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$cmdlineTools*") {
            $newPath = "$currentPath;$cmdlineTools"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            Write-StatusMessage "Cmdline-tools adicionado ao PATH" "Success"
        } else {
            Write-StatusMessage "Cmdline-tools ja esta no PATH" "Info"
        }
    }
}

function Test-AndroidConfiguration {
    Write-StatusMessage "Testando configuracao do Android..." "Header"
    
    # Recarregar variaveis de ambiente
    $env:ANDROID_HOME = [Environment]::GetEnvironmentVariable("ANDROID_HOME", "User")
    $env:ANDROID_SDK_ROOT = [Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT", "User")
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-StatusMessage "ANDROID_HOME: $env:ANDROID_HOME" "Info"
    Write-StatusMessage "ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT" "Info"
    
    # Testar ADB
    try {
        $adbVersion = adb --version 2>&1
        if ($adbVersion) {
            Write-StatusMessage "ADB funcionando: $($adbVersion[0])" "Success"
        } else {
            Write-StatusMessage "ADB nao retornou versao" "Warning"
        }
    }
    catch {
        Write-StatusMessage "ADB nao encontrado no PATH" "Error"
        Write-StatusMessage "Tente reiniciar o PowerShell" "Warning"
        return $false
    }
    
    # Testar sdkmanager (se disponivel)
    try {
        $sdkmanager = Get-Command sdkmanager -ErrorAction SilentlyContinue
        if ($sdkmanager) {
            Write-StatusMessage "SDKManager encontrado" "Success"
        }
    }
    catch {
        Write-StatusMessage "SDKManager nao encontrado (normal em algumas instalacoes)" "Info"
    }
    
    return $true
}

function Test-FlutterDoctor {
    Write-StatusMessage "Testando Flutter Doctor..." "Header"
    
    try {
        # Verificar se Flutter esta disponivel
        $flutterVersion = flutter --version 2>&1
        if ($flutterVersion) {
            Write-StatusMessage "Flutter encontrado" "Success"
        }
        
        Write-StatusMessage "Executando flutter doctor..." "Info"
        Write-Host ""
        flutter doctor
        Write-Host ""
        
        return $true
    }
    catch {
        Write-StatusMessage "Flutter nao encontrado ou erro ao executar flutter doctor" "Error"
        Write-StatusMessage "Verifique se o Flutter foi instalado corretamente" "Warning"
        return $false
    }
}

function Show-AndroidStudioInstructions {
    Write-StatusMessage "INSTRUCOES PARA CONFIGURAR ANDROID STUDIO" "Header"
    Write-Host ""
    Write-StatusMessage "1. Abra o Android Studio" "Info"
    Write-StatusMessage "2. Complete o setup wizard inicial" "Info"
    Write-StatusMessage "3. Aceite todas as licencas" "Info"
    Write-StatusMessage "4. Aguarde o download do Android SDK (~3-4GB)" "Info"
    Write-StatusMessage "5. Verifique o caminho em: File > Settings > Android SDK" "Info"
    Write-StatusMessage "6. Execute este script novamente" "Info"
    Write-Host ""
    Write-StatusMessage "Para abrir o Android Studio execute:" "Warning"
    Write-Host "& '${env:ProgramFiles}\\Android\\Android Studio\\bin\\studio64.exe'" -ForegroundColor Yellow
    Write-Host ""
}

function Show-NextSteps {
    Write-StatusMessage "PROXIMOS PASSOS RECOMENDADOS:" "Header"
    Write-Host ""
    Write-StatusMessage "1. Reinicie o PowerShell para aplicar as mudancas" "Info"
    Write-StatusMessage "2. Execute: flutter doctor --android-licenses" "Info"
    Write-StatusMessage "3. Execute: flutter doctor" "Info"
    Write-StatusMessage "4. Configure um emulador no Android Studio:" "Info"
    Write-StatusMessage "   - Tools > AVD Manager > Create Virtual Device" "Info"
    Write-StatusMessage "5. Teste criando um projeto Flutter:" "Info"
    Write-StatusMessage "   - flutter create teste_app" "Info"
    Write-StatusMessage "   - cd teste_app" "Info"
    Write-StatusMessage "   - flutter run" "Info"
    Write-Host ""
}

function Main {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "          ANDROID SDK CONFIGURATION FIX" -ForegroundColor Magenta
    Write-Host "          Corrige variaveis de ambiente Android" -ForegroundColor Cyan
    Write-Host "          Criado por: Mikael David" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Verificar se Android SDK existe
    $androidSdkPath = Test-AndroidStudioSetup
    
    if (-not $androidSdkPath) {
        Show-AndroidStudioInstructions
        
        Write-Host ""
        $openAndroidStudio = Read-Host "Deseja abrir o Android Studio agora? (s/N)"
        if ($openAndroidStudio -like "s*" -or $openAndroidStudio -like "y*") {
            try {
                Start-Process "${env:ProgramFiles}\Android\Android Studio\bin\studio64.exe"
                Write-StatusMessage "Android Studio sendo iniciado..." "Success"
                Write-StatusMessage "Execute este script novamente apos o setup!" "Warning"
            }
            catch {
                Write-StatusMessage "Erro ao abrir Android Studio: $_" "Error"
                Write-StatusMessage "Abra manualmente e execute este script depois" "Info"
            }
        }
        
        Write-Host ""
        Write-StatusMessage "Script finalizado. Execute novamente apos configurar o Android Studio." "Info"
        return
    }
    
    # Configurar variaveis de ambiente
    Configure-AndroidEnvironment -AndroidSdkPath $androidSdkPath
    
    Write-Host ""
    Write-StatusMessage "Configuracao das variaveis concluida!" "Success"
    Write-StatusMessage "IMPORTANTE: Reinicie o PowerShell para aplicar as mudancas" "Warning"
    
    # Testar configuracao atual
    Write-Host ""
    $testNow = Read-Host "Deseja testar a configuracao agora? (s/N)"
    if ($testNow -like "s*" -or $testNow -like "y*") {
        Write-Host ""
        $androidSuccess = Test-AndroidConfiguration
        
        if ($androidSuccess) {
            Write-Host ""
            $testFlutter = Read-Host "Deseja testar o Flutter Doctor? (s/N)"
            if ($testFlutter -like "s*" -or $testFlutter -like "y*") {
                Test-FlutterDoctor
            }
        }
    }
    
    # Mostrar proximos passos
    Write-Host ""
    Show-NextSteps
    
    Write-Host ""
    Write-StatusMessage "ANDROID SDK CONFIGURADO COM SUCESSO!" "Success"
    Write-Host ""
    Write-StatusMessage "Suporte:" "Info"
    Write-StatusMessage "GitHub: https://github.com/MikaelDDavidd" "Info"
    Write-StatusMessage "Email: mikaeldavi111@gmail.com" "Info"
}

# Executar script principal
Main