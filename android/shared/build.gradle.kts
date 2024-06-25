plugins {
     kotlin("multiplatform")
     id("com.android.library")
}

kotlin {
    androidTarget {
        compilations.all {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }

    sourceSets {
        androidMain.dependencies {
            implementation("com.facebook.react:react-android")
            implementation("fi.methics.musap:musap-android:1.0.0") {
                exclude(group = "com.yubico.yubikit", module = "core") // These are already jetified into musap-android.aar
                exclude(group = "com.yubico.yubikit", module = "android")
                exclude(group = "com.yubico.yubikit", module = "piv")
            }
            implementation (files("libs/nimbus-jose-jwt-9.21.jar"))
        }
    }
}

android {
    namespace = "com.sphereon.musap.shared"
    compileSdk = 34
    defaultConfig {
        minSdk = 26
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
