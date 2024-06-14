package com.sphereon.musaprn;

import android.os.Build;
import android.util.Log;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import kotlin.collections.MutableList;

import fi.methics.musap.sdk.api.MusapClient;
import fi.methics.musap.sdk.internal.util.MusapSscd
import fi.methics.musap.sdk.sscd.android.AndroidKeystoreSscd

class MusapModule(val context: ReactApplicationContext): ReactContextBaseJavaModule(context) {

    init {
        MusapClient.init(context)
        MusapClient.enableSscd(AndroidKeystoreSscd(context), "ANDROID")
    }

    override fun getName(): String = "MusapModule"

    @ReactMethod
    fun listActiveSscds(): MutableList<MusapSscd>? {
        var sscds = MusapClient.listActiveSscds();
        Log.d("MusapModule", sscds.map{it.getSscdId()}.joinToString(", "));
        return sscds;
    }
}
