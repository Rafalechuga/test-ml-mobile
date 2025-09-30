FROM ubuntu:22.04

# Evitar preguntas interactivas durante la instalación
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Mexico_City

# Variables de entorno para Android
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV PATH ${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}

# Instalar dependencias base
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    openjdk-8-jdk \
    git curl wget unzip \
    adb \
    ruby-full \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    sudo \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Configurar Java 8 como predeterminado
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

# Instalar Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Crear directorio para Android SDK
RUN mkdir -p ${ANDROID_HOME}

# Descargar e instalar Android Command Line Tools
RUN cd ${ANDROID_HOME} && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip -q commandlinetools-linux-*.zip && \
    rm commandlinetools-linux-*.zip && \
    mkdir -p cmdline-tools/latest && \
    mv tools/* cmdline-tools/latest/ && \
    rmdir tools

# Aceptar licencias y instalar componentes de Android
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-33" \
    "build-tools;33.0.0" \
    "emulator" \
    "system-images;android-33;google_apis;x86_64"

# Instalar Appium globalmente
RUN npm install -g appium@latest
RUN npm install -g appium-doctor
RUN npm install -g appium-uiautomator2-driver

# Instalar appium como dependencia local también
RUN npm init -y && \
    npm install appium --save-dev

# Crear AVD
RUN echo "no" | ${ANDROID_HOME}/cmdline-tools/latest/bin/avdmanager create avd \
    -n pixel_android_33 \
    -k "system-images;android-33;google_apis;x86_64" \
    -d 9

# Instalar bundler para Ruby
RUN gem install bundler

# Crear directorio de trabajo
WORKDIR /workspace

# Copiar archivos del proyecto
COPY Gemfile .
COPY features ./features
COPY scripts ./scripts

# Instalar gemas de Ruby
RUN bundle install

# Script de espera para el emulador
RUN chmod +x scripts/wait-for-emulator.sh
RUN chmod +x scripts/start-appium.sh

# Exponer puerto de Appium
EXPOSE 4723

# Comando por defecto
CMD ["bash", "-c", "scripts/start-appium.sh"]