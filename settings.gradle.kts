rootProject.name = "cmp-app"

pluginManagement {
    repositories {
        // 腾讯云镜像：Gradle 插件门户代理
        maven("https://mirrors.cloud.tencent.com/nexus/repository/gradle-plugins/")
        // 腾讯云镜像：Maven Central / Google 等公共仓库代理
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

dependencyResolutionManagement {
    repositories {
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        google()
        mavenCentral()
    }
}

include(":composeApp")
include(":androidApp")
include(":desktopApp")
include(":webApp")
