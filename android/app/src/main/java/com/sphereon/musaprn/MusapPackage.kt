package com.sphereon.musaprn;

import android.view.View
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.facebook.react.uimanager.ReactShadowNode;

import kotlin.collections.MutableList;

class MusapPackage: ReactPackage {

    override public fun createNativeModules(reactApplicationContext: ReactApplicationContext): MutableList<NativeModule> = mutableListOf(MusapModule(reactApplicationContext))

    override public fun createViewManagers(reactApplicationContext: ReactApplicationContext): MutableList<ViewManager<View, ReactShadowNode<*>>> = mutableListOf()
}
