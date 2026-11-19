package com.example.frontend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "congomedika/audio"
    private val eventChannelName = "congomedika/audio_events"

    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false

    // Notifie le Dart quand un casque filaire ou un Bluetooth est
    // branché/débranché pour re-router l'audio pendant un appel.
    private val headsetReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            eventSink?.success("routeChanged")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName,
        ).setMethodCallHandler { call, result ->
            val audioManager =
                getSystemService(Context.AUDIO_SERVICE) as AudioManager
            try {
                when (call.method) {
                    "isHeadsetConnected" ->
                        result.success(hasExternalAudioDevice(audioManager))
                    "setAudioRoute" -> {
                        val speaker = call.argument<Boolean>("speaker") ?: false
                        result.success(applyAudioRoute(audioManager, speaker))
                    }
                    "resetAudioRoute" -> {
                        applyAudioRoute(audioManager, false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("AUDIO_ROUTE", e.message, null)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerHeadsetReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterHeadsetReceiver()
                }
            },
        )
    }

    private fun registerHeadsetReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_HEADSET_PLUG)
            addAction("android.bluetooth.device.action.ACL_CONNECTED")
            addAction("android.bluetooth.device.action.ACL_DISCONNECTED")
            addAction(
                "android.bluetooth.a2dp.profile.action.CONNECTION_STATE_CHANGED",
            )
            addAction(
                "android.bluetooth.headset.profile.action.CONNECTION_STATE_CHANGED",
            )
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(
                    headsetReceiver,
                    filter,
                    Context.RECEIVER_NOT_EXPORTED,
                )
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(headsetReceiver, filter)
            }
            receiverRegistered = true
        } catch (_: Exception) {
        }
    }

    private fun unregisterHeadsetReceiver() {
        if (!receiverRegistered) return
        try {
            unregisterReceiver(headsetReceiver)
        } catch (_: Exception) {
        }
        receiverRegistered = false
    }

    private fun hasExternalAudioDevice(audioManager: AudioManager): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return audioManager.availableCommunicationDevices.any {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    it.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES
            }
        }
        @Suppress("DEPRECATION")
        val wired = audioManager.isWiredHeadsetOn
        @Suppress("DEPRECATION")
        val bluetooth =
            audioManager.isBluetoothScoOn || audioManager.isBluetoothA2dpOn
        return wired || bluetooth
    }

    // Retourne true si le haut-parleur est réellement actif.
    // speakerOn=false : casque Bluetooth > casque filaire > oreillette.
    private fun applyAudioRoute(
        audioManager: AudioManager,
        speakerOn: Boolean,
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager.availableCommunicationDevices
            val target = if (speakerOn) {
                devices.firstOrNull {
                    it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                }
            } else {
                devices.firstOrNull {
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                        it.type == AudioDeviceInfo.TYPE_BLE_HEADSET
                } ?: devices.firstOrNull {
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                        it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES
                } ?: devices.firstOrNull {
                    it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE
                }
            }
            if (target != null) {
                audioManager.setCommunicationDevice(target)
                return target.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
            return false
        }

        @Suppress("DEPRECATION")
        audioManager.isSpeakerphoneOn = speakerOn

        @Suppress("DEPRECATION")
        val hasBluetooth =
            audioManager.isBluetoothScoOn || audioManager.isBluetoothA2dpOn
        try {
            if (!speakerOn && hasBluetooth) {
                @Suppress("DEPRECATION")
                audioManager.startBluetoothSco()
                @Suppress("DEPRECATION")
                audioManager.isBluetoothScoOn = true
            } else {
                @Suppress("DEPRECATION")
                audioManager.isBluetoothScoOn = false
                @Suppress("DEPRECATION")
                audioManager.stopBluetoothSco()
            }
        } catch (_: Exception) {
        }

        @Suppress("DEPRECATION")
        return audioManager.isSpeakerphoneOn
    }
}
