FROM alpine:3.18
WORKDIR /home/root

# Install JDK
RUN apk add --update --no-cache openjdk17-jdk

# Get Gradle Build Tool
RUN wget https://services.gradle.org/distributions/gradle-8.1.1-bin.zip
RUN unzip -d /opt/gradle gradle-8.1.1-bin.zip

# Get Android SDK Manager
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
RUN unzip -d /home/root/android commandlinetools-linux-9477386_latest.zip
ENV PATH="${PATH}:/home/root/android/cmdline-tools/bin"

# Install Android Build Tools
RUN yes | sdkmanager --sdk_root=/home/root/android "build-tools;30.0.3"

# Second stage, build slimmer image
FROM alpine:3.18
WORKDIR /home/root

# Get Gradle & Android tools from previous stage
COPY --from=0 /opt/gradle /opt/gradle
COPY --from=0 /home/root/android/build-tools /home/root/android/build-tools
COPY --from=0 /home/root/android/cmdline-tools /home/root/android/cmdline-tools

# Install JDK, glibc compatibility layer, and libgcc (needed by some android build tools)
RUN apk add --update --no-cache openjdk17-jdk gcompat libgcc

# Add Gradle and Android tools to PATH
ENV PATH="${PATH}:/opt/gradle/gradle-8.1.1/bin:/home/root/android/cmdline-tools/bin:/home/root/android/build-tools/30.0.3"
ENV ANDROID_HOME=/home/root/android

# Pre-accepting licenses is needed in order for builds not to fail waiting for user input
RUN yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
WORKDIR /home/root/project
