package com.sphereon.musap;

import android.view.View
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ReactShadowNode
import com.facebook.react.uimanager.ViewManager
import kotlinx.coroutines.ExperimentalCoroutinesApi

class MusapPackage: ReactPackage {

    @OptIn(ExperimentalCoroutinesApi::class)
    override fun createNativeModules(reactApplicationContext: ReactApplicationContext): MutableList<NativeModule> =
        mutableListOf(MusapBridgeAndroid(reactApplicationContext))

    override fun createViewManagers(reactApplicationContext: ReactApplicationContext): MutableList<ViewManager<View, ReactShadowNode<*>>> =
        mutableListOf()
}
