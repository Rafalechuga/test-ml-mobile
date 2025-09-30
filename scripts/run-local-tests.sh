#!/bin/bash

echo "=== EJECUCION LOCAL DE PRUEBAS APPIUM ==="

# ===============================
# Inicializar rbenv y Ruby 3.2.5
# ===============================
export PATH="$HOME/.rbenv/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - bash)"
    rbenv global 3.2.5
    rbenv rehash
fi

# ===============================
# Verificar e instalar gemas necesarias
# ===============================
install_gem_if_missing() {
    local gem_name=$1
    if ! gem list -i "$gem_name" >/dev/null 2>&1; then
        echo "Instalando $gem_name..."
        gem install "$gem_name"
        rbenv rehash
    else
        echo "OK: $gem_name ya instalado"
    fi
}

install_gem_if_missing "cucumber"
install_gem_if_missing "rspec"
install_gem_if_missing "appium_lib"

# ===============================
# Función de limpieza
# ===============================
cleanup() {
    echo "Limpiando procesos..."
    pkill -f "appium" || true
    pkill -f "emulator" || true
    sleep 3
    echo "Limpieza completada"
    exit 0
}
trap cleanup SIGINT

# ===============================
# Verificar prerrequisitos
# ===============================
check_prerequisites() {
    echo "Verificando prerrequisitos..."
    local missing=0

    command -v java >/dev/null 2>&1 && echo "OK: Java encontrado" || { echo "ERROR: Java no encontrado"; missing=1; }
    command -v adb >/dev/null 2>&1 && echo "OK: ADB encontrado" || { echo "ERROR: ADB no encontrado"; missing=1; }
    command -v appium >/dev/null 2>&1 && echo "OK: Appium encontrado (versión: $(appium --version))" || { echo "ERROR: Appium no encontrado"; missing=1; }
    command -v ruby >/dev/null 2>&1 && echo "OK: Ruby encontrado (versión: $(ruby -v | cut -d' ' -f2))" || { echo "ERROR: Ruby no encontrado"; missing=1; }
    
    # AVD
    if ~/Android/Sdk/emulator/emulator -list-avds | grep -q "pixel_android_33"; then
        echo "OK: AVD encontrado"
    else
        echo "ERROR: AVD 'pixel_android_33' no encontrado"
        missing=1
    fi

    [ -f "mercadolibre.apk" ] && echo "OK: APK disponible" || echo "ADVERTENCIA: APK no encontrado"

    [ $missing -ne 0 ] && { echo "ERROR: Faltan prerrequisitos esenciales."; exit 1; }
}

# ===============================
# Descargar APK si no existe
# ===============================
download_test_app() {
    if [ ! -f "mercadolibre.apk" ]; then
        echo "Descargando APK de prueba..."
        wget -O mercadolibre.apk "https://github.com/appium/appium/raw/master/packages/appium/sample-code/apps/ApiDemos-debug.apk" || { echo "ERROR: No se pudo descargar APK"; exit 1; }
        echo "OK: APK descargado"
    fi
}

# ===============================
# Iniciar emulador
# ===============================
start_emulator() {
    echo "Iniciando emulador Android..."
    pkill -f "emulator" || true
    sleep 2
    ~/Android/Sdk/emulator/emulator -avd pixel_android_33 -memory 2048 -cores 2 -gpu swiftshader_indirect -no-audio -no-snapshot -accel on -qemu -enable-kvm &
    EMULATOR_PID=$!
    echo "OK: Emulador iniciado (PID: $EMULATOR_PID)"

    echo "Esperando a que el emulador este listo..."
    adb wait-for-device

    local counter=0
    local max_wait=300
    while [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" != "1" ]; do
        echo "Boot no completado... ($counter/$max_wait segundos)"
        sleep 10
        counter=$((counter + 10))
        [ $counter -ge $max_wait ] && { echo "ERROR: Emulador no arranco"; kill $EMULATOR_PID; exit 1; }
    done
    echo "OK: Emulador listo"

    echo "Instalando aplicacion..."
    adb install -r mercadolibre.apk || { echo "Intentando forzar instalacion..."; adb uninstall io.appium.android.apis 2>/dev/null || true; adb install mercadolibre.apk; }
    echo "OK: Aplicacion instalada"
}

# ===============================
# Iniciar Appium
# ===============================
start_appium() {
    echo "Iniciando Appium Server..."
    pkill -f "appium" || true
    sleep 2
    appium --log-level info --allow-insecure=adb_shell --relaxed-security --base-path /wd/hub --port 4723 &
    APPIUM_PID=$!
    echo "OK: Appium iniciado (PID: $APPIUM_PID)"

    echo "Esperando a que Appium este listo..."
    local counter=0
    local max_attempts=12
    until curl -s http://localhost:4723/wd/hub/status >/dev/null || [ $counter -ge $max_attempts ]; do
        echo "Intento $((counter + 1))/$max_attempts: Appium no responde aún..."
        sleep 10
        counter=$((counter + 1))
    done
    [ $counter -ge $max_attempts ] && { echo "ERROR: Appium Server no responde"; exit 1; }
    echo "OK: Appium Server respondiendo"
}

# ===============================
# Crear prueba simple
# ===============================
create_simple_test() {
    cat > simple_test.rb << 'EOF'
#!/usr/bin/env ruby
begin
  require 'appium_lib'
  puts "appium_lib cargado correctamente"
rescue LoadError => e
  puts "No se pudo cargar appium_lib: #{e.message}"
  exit 1
end

caps = {
  platformName: 'Android',
  deviceName: 'emulator-5554',
  automationName: 'UiAutomator2',
  appPackage: 'io.appium.android.apis',
  appActivity: '.ApiDemos'
}

driver = Appium::Driver.new({ caps: caps }, true)
driver.start_driver
puts "Conectado al emulador"
sleep 2
driver.driver_quit
puts "Driver cerrado"
EOF
    chmod +x simple_test.rb
}

# ===============================
# Ejecutar pruebas
# ===============================
run_tests() {
    echo "Ejecutando pruebas..."
    if command -v cucumber >/dev/null 2>&1; then
        cucumber features/search.feature
        TEST_RESULT=$?
    else
        echo "Cucumber no disponible - ejecutando prueba simple..."
        create_simple_test
        ruby simple_test.rb
        TEST_RESULT=$?
        rm -f simple_test.rb
    fi

    [ $TEST_RESULT -eq 0 ] && echo "Todas las pruebas pasaron" || echo "❌ Algunas pruebas fallaron"
    return $TEST_RESULT
}

# ===============================
# Función principal
# ===============================
main() {
    echo "=== APPIUM LOCAL TEST RUNNER ==="

    check_prerequisites
    download_test_app
    start_emulator
    start_appium
    run_tests

    local result=$?

    echo ""
    echo "=== LIMPIEZA ==="
    cleanup

    exit $result
}

# Ejecutar principal
main
