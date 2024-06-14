package com.sphereon.musaprn;

import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.List;
import java.util.stream.Collectors;

import fi.methics.musap.sdk.api.MusapClient;
import fi.methics.musap.sdk.internal.util.MusapSscd;

public class MusapModule extends ReactContextBaseJavaModule {

    public MusapModule(ReactApplicationContext context) {
        super(context);
    }
    @NonNull
    @Override
    public String getName() {
        return "MusapModule";
    }

    @ReactMethod
    public List<MusapSscd> listSscds() {
        var sscds = MusapClient.listActiveSscds();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Log.d("MusapModule", sscds.stream().map(MusapSscd::getSscdId).collect(Collectors.joining(", ")));
        }
        return sscds;
    }
}
