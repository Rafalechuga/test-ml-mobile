#!/bin/bash

echo "=== INSTALACION DE PRERREQUISITOS PARA APPIUM LOCAL ==="

# Funcion para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funcion para imprimir estado
print_status() {
    if [ $? -eq 0 ]; then
        echo "OK: $1"
    else
        echo "ERROR: $1"
        exit 1
    fi
}

echo "Verificando y instalando dependencias base..."

# 1. Actualizar sistema
echo "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y
print_status "Sistema actualizado"

# 2. Instalar Java 8
echo "Instalando Java JDK 8..."
sudo apt install openjdk-8-jdk -y
print_status "Java JDK 8 instalado"

# Verificar Java
/usr/lib/jvm/java-8-openjdk-amd64/bin/java -version
print_status "Java verificado"

# 3. Instalar herramientas esenciales
echo "Instalando herramientas esenciales..."
sudo apt install git curl wget unzip -y
print_status "Herramientas esenciales instaladas"

# 4. Instalar ADB
echo "Instalando ADB..."
sudo apt install adb -y
print_status "ADB instalado"

# 5. Instalar Ruby y Bundler
echo "Instalando Ruby y Bundler..."
sudo apt install ruby-full -y

# Instalar version MUY antigua de Bundler compatible con Ruby 2.7.0
echo "Instalando Bundler version compatible con Ruby 2.7.0..."
sudo gem install bundler -v 2.1.4

print_status "Ruby y Bundler instalados"

# Verificar Ruby y Bundler
ruby --version
bundle _2.1.4_ --version
print_status "Ruby y Bundler verificados"

# 6. Instalar Node.js 18
echo "Instalando Node.js 18..."
sudo apt remove --purge nodejs npm -y
sudo apt autoremove -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
print_status "Node.js 18 instalado"

# Verificar Node.js
node --version
npm --version
print_status "Node.js verificado"

# El resto del script permanece igual...
# [las otras secciones del script]

# 7. Configurar variables de entorno
echo "Configurando variables de entorno..."

# Crear backup del .bashrc
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# Agregar configuraciones al .bashrc
cat >> ~/.bashrc << 'EOF'

# Appium Local Development Configuration
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk

export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/build-tools

# npm global installations without sudo
export NPM_GLOBAL=$HOME/.npm-global
export PATH=$NPM_GLOBAL/bin:$PATH
EOF

# Aplicar cambios inmediatamente
source ~/.bashrc

# Configurar npm para instalaciones globales sin sudo
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

print_status "Variables de entorno configuradas"

# 8. Instalar Android SDK (versión simplificada)
echo "Instalando Android SDK..."

# Crear directorio Android
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk

# Descargar Command Line Tools
echo "Descargando Android Command Line Tools..."
wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
print_status "Command Line Tools descargados"

# Extraer en ubicación directa
echo "Extrayendo herramientas..."
mkdir -p cmdline-tools/latest
unzip -q -o -d cmdline-tools/latest commandlinetools-linux-*.zip
rm commandlinetools-linux-*.zip

print_status "Android SDK extraido y organizado"

# 9. Aceptar licencias e instalar componentes
echo "Aceptando licencias de Android..."

# Forzar el uso de Java 8 para SDK Manager
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

yes | ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --licenses
print_status "Licencias aceptadas"

echo "Instalando componentes de Android..."
~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-33" \
    "build-tools;33.0.0" \
    "emulator"
print_status "Componentes base de Android instalados"

# Listar system images disponibles e instalar uno
echo "Buscando system images disponibles..."
~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --list | grep "system-images" | head -10

# Instalar system image específico
echo "Instalando system image de Android 33..."
~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-33;google_apis;x86_64"
print_status "System image instalado"

# 10. Crear AVD (solo si no existe)
echo "Verificando si el AVD ya existe..."
if ~/Android/Sdk/emulator/emulator -list-avds | grep -q "pixel_android_33"; then
    echo "OK: AVD pixel_android_33 ya existe"
else
    echo "Creando Android Virtual Device..."
    echo "no" | ~/Android/Sdk/cmdline-tools/latest/bin/avdmanager create avd \
    -n pixel_android_33 \
    -k "system-images;android-33;google_apis;x86_64" \
    -d 9
    print_status "AVD creado: pixel_android_33"
fi

# 11. Instalar Appium
echo "Instalando Appium..."
npm install -g appium
npm install -g appium-doctor
npm install -g appium-uiautomator2-driver
print_status "Appium instalado"

# Verificar Appium
appium --version
print_status "Appium verificado"

# 12. Verificar aceleracion de hardware
echo "Verificando aceleracion de hardware..."
KVM_COUNT=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
if [ $KVM_COUNT -gt 0 ]; then
    echo "OK: KVM disponible: $KVM_COUNT cores"
else
    echo "ADVERTENCIA: KVM no disponible. El emulador puede ser lento."
fi

# 13. Instalar gemas del proyecto
echo "Instalando gemas Ruby del proyecto..."
cd - > /dev/null

# Configurar instalación local de gemas
export GEM_HOME="$HOME/.gems"
export PATH="$GEM_HOME/bin:$PATH"
mkdir -p $GEM_HOME

# Configurar bundle para usar path local
bundle _2.1.4_ config set path 'vendor/bundle'

if [ -f "Gemfile" ]; then
    # Limpiar cache y lock file existente
    rm -f Gemfile.lock
    
    # Instalar gemas con versiones compatibles con RubyGems 3.1.2
    bundle _2.1.4_ install
    print_status "Gemas Ruby instaladas"
else
    echo "ADVERTENCIA: Gemfile no encontrado en el directorio actual"
fi


echo ""
echo "COMPLETADO: Instalacion finalizada"
echo ""
echo "Resumen de lo instalado:"
echo "   - Java JDK 8"
echo "   - Herramientas esenciales (git, curl, wget, unzip)"
echo "   - ADB"
echo "   - Ruby y Bundler"
echo "   - Node.js 18"
echo "   - Android SDK"
echo "   - Appium y drivers"
echo "   - AVD: pixel_android_33"
echo ""
echo "Para ejecutar las pruebas, usa: ./scripts/run-local-tests.sh"
echo ""
echo "No olvides cerrar y reabrir la terminal o ejecutar:"
echo "   source ~/.bashrc"