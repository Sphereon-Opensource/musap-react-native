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
    
//    listOf(
//        iosX64(),
//        iosArm64(),
//        iosSimulatorArm64()
//    ).forEach {
//        it.binaries.framework {
//            baseName = "shared"
//        }
//    }

//    js {
//        nodejs {
//
//        }
//        binaries.executable()
//    }

    sourceSets {

        commonMain.dependencies {
            implementation("com.facebook.react:react-android")
            implementation("com.squareup.okhttp3:okhttp:4.10.0")
            implementation("com.google.code.gson:gson:2.8.8")
            implementation ("org.slf4j:slf4j-api:2.0.7")
            implementation("org.bouncycastle:bcpkix-jdk15to18:1.71")
            implementation (files("libs/nimbus-jose-jwt-9.21.jar"))
            implementation(files("libs/app-release.aar"))
            implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
            implementation("com.google.firebase:firebase-messaging")
        }
    }
}

android {
    namespace = "com.sphereon.musap.shared"
    compileSdk = 34
    defaultConfig {
        minSdk = 24
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
