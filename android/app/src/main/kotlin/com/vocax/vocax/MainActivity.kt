package com.vocax.vocax

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.AlarmClock
import android.provider.ContactsContract
import android.provider.MediaStore
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Lets the Dart side of Vocax control the phone: open apps, call, text,
 * flashlight, volume, media keys, alarms, settings and more.
 */
class MainActivity : FlutterActivity() {

    private var pendingPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    handle(call, result)
                } catch (e: Exception) {
                    result.error("device_error", e.message, null)
                }
            }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listApps" -> result.success(listApps())
            "launchApp" -> result.success(launchApp(call.argument<String>("package")))
            "openUrl" -> result.success(openUrl(call.argument<String>("url")))
            "dial" -> result.success(
                startIntent(Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", call.argument<String>("number") ?: "", null)))
            )
            "call" -> result.success(placeCall(call.argument<String>("number")))
            "sms" -> result.success(composeSms(call.argument<String>("number"), call.argument<String>("body")))
            "listContacts" -> result.success(listContacts())
            "requestPermissions" -> requestAppPermissions(call.argument<List<String>>("names") ?: emptyList(), result)
            "flashlight" -> result.success(setTorch(call.argument<Boolean>("on") ?: false))
            "volume" -> result.success(adjustVolume(call.argument<String>("action") ?: "up", call.argument<Int>("percent")))
            "media" -> result.success(sendMedia(call.argument<String>("action") ?: ""))
            "openSettings" -> result.success(openSettings(call.argument<String>("target") ?: "settings"))
            "alarm" -> result.success(
                setAlarm(call.argument<Int>("hour") ?: 0, call.argument<Int>("minute") ?: 0, call.argument<String>("label"))
            )
            "timer" -> result.success(setTimer(call.argument<Int>("seconds") ?: 0))
            "camera" -> result.success(openCamera(call.argument<Boolean>("video") ?: false))
            "battery" -> result.success(batteryLevel())
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private fun startIntent(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    // ---------------------------------------------------------------------
    // Apps and links
    // ---------------------------------------------------------------------

    private fun listApps(): List<Map<String, String>> {
        val pm = packageManager
        val main = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(main, 0)
            .map { mapOf("name" to it.loadLabel(pm).toString(), "package" to it.activityInfo.packageName) }
            .distinctBy { it["package"] }
            .sortedBy { it["name"]!!.lowercase() }
    }

    private fun launchApp(packageName: String?): Boolean {
        if (packageName == null) return false
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        return startIntent(intent)
    }

    private fun openUrl(url: String?): Boolean {
        if (url == null) return false
        return startIntent(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    // ---------------------------------------------------------------------
    // Calls, messages, contacts
    // ---------------------------------------------------------------------

    private fun placeCall(number: String?): Boolean {
        if (number == null) return false
        if (!hasPermission(Manifest.permission.CALL_PHONE)) return false
        return startIntent(Intent(Intent.ACTION_CALL, Uri.fromParts("tel", number, null)))
    }

    private fun composeSms(number: String?, body: String?): Boolean {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", number ?: "", null))
        intent.putExtra("sms_body", body ?: "")
        return startIntent(intent)
    }

    private fun listContacts(): List<Map<String, String>> {
        if (!hasPermission(Manifest.permission.READ_CONTACTS)) return emptyList()

        val contacts = mutableListOf<Map<String, String>>()
        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            ),
            null,
            null,
            null
        )

        cursor?.use { c ->
            val nameIndex = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIndex = c.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (c.moveToNext()) {
                val name = c.getString(nameIndex)
                val number = c.getString(numberIndex)
                if (name != null && number != null) {
                    contacts.add(mapOf("name" to name, "number" to number.replace(" ", "")))
                }
            }
        }
        return contacts
    }

    private fun requestAppPermissions(names: List<String>, result: MethodChannel.Result) {
        // Before Android 6 permissions are granted at install time.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }

        val wanted = names.mapNotNull {
            when (it) {
                "contacts" -> Manifest.permission.READ_CONTACTS
                "phone" -> Manifest.permission.CALL_PHONE
                else -> null
            }
        }
        val missing = wanted.filter { !hasPermission(it) }

        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        if (pendingPermission != null) {
            result.success(false)
            return
        }
        pendingPermission = result
        requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermission?.success(granted)
            pendingPermission = null
        }
    }

    // ---------------------------------------------------------------------
    // Flashlight, volume, media
    // ---------------------------------------------------------------------

    private fun setTorch(on: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        for (id in manager.cameraIdList) {
            val characteristics = manager.getCameraCharacteristics(id)
            if (characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true) {
                manager.setTorchMode(id, on)
                return true
            }
        }
        return false
    }

    private fun adjustVolume(action: String, percent: Int?): Int {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val stream = AudioManager.STREAM_MUSIC
        val max = audio.getStreamMaxVolume(stream)

        when (action) {
            "up" -> audio.adjustStreamVolume(stream, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI)
            "down" -> audio.adjustStreamVolume(stream, AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI)
            "mute" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    audio.adjustStreamVolume(stream, AudioManager.ADJUST_MUTE, AudioManager.FLAG_SHOW_UI)
                } else {
                    audio.setStreamVolume(stream, 0, AudioManager.FLAG_SHOW_UI)
                }
            }
            "unmute" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    audio.adjustStreamVolume(stream, AudioManager.ADJUST_UNMUTE, AudioManager.FLAG_SHOW_UI)
                }
            }
            "max" -> audio.setStreamVolume(stream, max, AudioManager.FLAG_SHOW_UI)
            "set" -> {
                val p = (percent ?: 50).coerceIn(0, 100)
                audio.setStreamVolume(stream, Math.round(max * p / 100f), AudioManager.FLAG_SHOW_UI)
            }
        }

        val now = audio.getStreamVolume(stream)
        return if (max == 0) 0 else Math.round(now * 100f / max)
    }

    private fun sendMedia(action: String): Boolean {
        val keyCode = when (action) {
            "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
            "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
            "toggle" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            "stop" -> KeyEvent.KEYCODE_MEDIA_STOP
            else -> return false
        }
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
        return true
    }

    // ---------------------------------------------------------------------
    // Settings, alarms, camera, battery
    // ---------------------------------------------------------------------

    private fun openSettings(target: String): Boolean {
        val action = when (target) {
            "wifi" -> "android.settings.WIFI_SETTINGS"
            "bluetooth" -> "android.settings.BLUETOOTH_SETTINGS"
            "airplane" -> "android.settings.AIRPLANE_MODE_SETTINGS"
            "location" -> "android.settings.LOCATION_SOURCE_SETTINGS"
            "display" -> "android.settings.DISPLAY_SETTINGS"
            "sound" -> "android.settings.SOUND_SETTINGS"
            "battery_saver" -> "android.settings.BATTERY_SAVER_SETTINGS"
            "data" -> "android.settings.DATA_ROAMING_SETTINGS"
            "nfc" -> "android.settings.NFC_SETTINGS"
            "accessibility" -> "android.settings.ACCESSIBILITY_SETTINGS"
            "apps" -> "android.settings.APPLICATION_SETTINGS"
            else -> "android.settings.SETTINGS"
        }
        return startIntent(Intent(action))
    }

    private fun setAlarm(hour: Int, minute: Int, label: String?): Boolean {
        val intent = Intent(AlarmClock.ACTION_SET_ALARM)
            .putExtra(AlarmClock.EXTRA_HOUR, hour)
            .putExtra(AlarmClock.EXTRA_MINUTES, minute)
            .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
        if (label != null) intent.putExtra(AlarmClock.EXTRA_MESSAGE, label)
        return startIntent(intent)
    }

    private fun setTimer(seconds: Int): Boolean {
        val intent = Intent("android.intent.action.SET_TIMER")
            .putExtra(AlarmClock.EXTRA_LENGTH, seconds)
            .putExtra(AlarmClock.EXTRA_SKIP_UI, true)
        return startIntent(intent)
    }

    private fun openCamera(video: Boolean): Boolean {
        val action = if (video) MediaStore.INTENT_ACTION_VIDEO_CAMERA else MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA
        return startIntent(Intent(action))
    }

    private fun batteryLevel(): Int {
        val battery = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    companion object {
        private const val CHANNEL = "vocax/device"
        private const val PERMISSION_REQUEST = 4101
    }
}
