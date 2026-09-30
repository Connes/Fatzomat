package com.example.food_app_mvp

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val chatChannelName = "together/chatgpt"
    private val locationChannelName = "schmackofatz/location"
    private val chatGptPackage = "com.openai.chatgpt"
    private val locationPermissionRequestCode = 4312

    private var pendingLocationResult: MethodChannel.Result? = null
    private var locationListener: LocationListener? = null
    private var locationManager: LocationManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, chatChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openApp" -> result.success(openChatGptApp())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentLocation" -> getCurrentLocation(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun openChatGptApp(): Boolean {
        val launchIntent = packageManager.getLaunchIntentForPackage(chatGptPackage)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            return true
        }
        return false
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (!isLocationServiceEnabled()) {
            result.error("LOCATION_DISABLED", "Die Standortdienste sind deaktiviert. Bitte aktiviere den Standort und versuche es erneut.", null)
            return
        }

        if (!hasLocationPermission()) {
            if (pendingLocationResult != null) {
                result.error("LOCATION_BUSY", "Eine Standortanfrage läuft bereits.", null)
                return
            }
            pendingLocationResult = result
            requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                locationPermissionRequestCode,
            )
            return
        }

        requestSingleLocation(result)
    }

    private fun requestSingleLocation(result: MethodChannel.Result) {
        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        locationManager = manager

        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { manager.isProviderEnabled(it) }
        if (providers.isEmpty()) {
            result.error("LOCATION_DISABLED", "Der Standortdienst ist nicht verfügbar. Bitte aktiviere den Standort und versuche es erneut.", null)
            return
        }

        // Prefer an existing OS-cached position. This avoids making the user
        // wait for a fresh GPS fix when Android already knows a usable location.
        val now = System.currentTimeMillis()
        val lastKnown = providers
            .mapNotNull { provider ->
                try {
                    manager.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                }
            }
            .filter { location ->
                location.latitude.isFinite() &&
                    location.longitude.isFinite() &&
                    location.time > 0L &&
                    now - location.time <= 15 * 60 * 1000L
            }
            .maxByOrNull { it.time }

        if (lastKnown != null) {
            locationListener?.let { listener ->
                try { manager.removeUpdates(listener) } catch (_: Exception) { }
                locationListener = null
            }
            result.success(mapOf("latitude" to lastKnown.latitude, "longitude" to lastKnown.longitude))
            return
        }

        locationListener?.let { listener ->
            try { manager.removeUpdates(listener) } catch (_: Exception) { }
        }

        val listener = object : LocationListener {
            private var delivered = false

            private fun deliver(location: Location) {
                if (delivered) return
                if (!location.latitude.isFinite() || !location.longitude.isFinite()) return
                delivered = true
                providers.forEach { provider ->
                    try { manager.removeUpdates(this) } catch (_: Exception) { }
                }
                locationListener = null
                result.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
            }

            override fun onLocationChanged(location: Location) {
                deliver(location)
            }

            override fun onProviderDisabled(providerName: String) {
                if (providers.all { !manager.isProviderEnabled(it) }) {
                    locationListener = null
                    result.error("LOCATION_DISABLED", "Der Standortdienst wurde deaktiviert.", null)
                }
            }
        }
        locationListener = listener

        try {
            @Suppress("MissingPermission")
            providers.forEach { provider ->
                manager.requestLocationUpdates(provider, 1000L, 0f, listener, mainLooper)
            }
        } catch (_: SecurityException) {
            locationListener = null
            result.error("LOCATION_PERMISSION", "Die Standortberechtigung wurde nicht erteilt.", null)
        } catch (_: Exception) {
            locationListener = null
            result.error("LOCATION_UNAVAILABLE", "Der aktuelle Standort konnte nicht ermittelt werden.", null)
        }
    }

    private fun hasLocationPermission(): Boolean =
        checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun isLocationServiceEnabled(): Boolean {
        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        return manager.isProviderEnabled(LocationManager.GPS_PROVIDER) || manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationPermissionRequestCode) return

        val result = pendingLocationResult ?: return
        pendingLocationResult = null
        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            requestSingleLocation(result)
        } else {
            result.error("LOCATION_PERMISSION", "Die Standortberechtigung wurde abgelehnt. Ohne Standort kann Schmackofatz keine Restaurants im Umkreis von 20 km suchen.", null)
        }
    }

    override fun onDestroy() {
        locationListener?.let { listener ->
            locationManager?.let { manager ->
                try { manager.removeUpdates(listener) } catch (_: Exception) { }
            }
        }
        locationListener = null
        pendingLocationResult?.error("LOCATION_CANCELLED", "Die Standortanfrage wurde beendet.", null)
        pendingLocationResult = null
        super.onDestroy()
    }
}
