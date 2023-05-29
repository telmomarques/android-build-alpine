FROM alpine:3.18
WORKDIR /home/root

# Install JDK (needed by android sdk)
RUN apk add --update --no-cache openjdk17-jdk

# Get Gradle Build Tool
ARG GRADLE_HASH=e111cb9948407e26351227dabce49822fb88c37ee72f1d1582a69c68af2e702f
ARG GRADLE_FILE=gradle-8.1.1-bin.zip
RUN wget https://services.gradle.org/distributions/${GRADLE_FILE}
RUN set -e -u && echo "${GRADLE_HASH} ${GRADLE_FILE}" | sha256sum -c -
RUN unzip -d /opt/gradle ${GRADLE_FILE}

# Get Android SDK Manager
ARG CMDLINE_TOOLS_HASH=bd1aa17c7ef10066949c88dc6c9c8d536be27f992a1f3b5a584f9bd2ba5646a0
ARG CMDLINE_TOOLS_FILE=commandlinetools-linux-9477386_latest.zip
RUN wget https://dl.google.com/android/repository/${CMDLINE_TOOLS_FILE}
RUN set -e -u && echo "${CMDLINE_TOOLS_HASH} ${CMDLINE_TOOLS_FILE}" | sha256sum -c -
RUN unzip -d /home/root/android ${CMDLINE_TOOLS_FILE}
ENV PATH="${PATH}:/home/root/android/cmdline-tools/bin"

# Install Android Build Tools
RUN yes | sdkmanager --sdk_root=/home/root/android "build-tools;30.0.3"

# Second stage, remove clutter
FROM alpine:3.18
WORKDIR /home/root

# Get Gradle & Android tools from previous stage
COPY --from=0 /opt/gradle /opt/gradle
COPY --from=0 /home/root/android/build-tools /home/root/android/build-tools
COPY --from=0 /home/root/android/cmdline-tools /home/root/android/cmdline-tools

# Install JDK, glibc compatibility layer, libgcc and bash (needed by android tools)
RUN apk add --update --no-cache openjdk17-jdk gcompat libgcc bash

# Add Gradle and Android tools to PATH
ENV PATH="${PATH}:/opt/gradle/gradle-8.1.1/bin:/home/root/android/cmdline-tools/bin:/home/root/android/build-tools/30.0.3"
ENV ANDROID_HOME=/home/root/android

# Pre-accepting licenses is needed in order for builds not to fail waiting for user input
RUN yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
WORKDIR /home/root/project
