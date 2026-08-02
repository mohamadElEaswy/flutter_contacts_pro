package com.yourname.flutter_contacts_pro

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/** Thin Android bridge: permission requests + contact-change observation. */
class FlutterContactsProPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    EventChannel.StreamHandler {

    private lateinit var permissionsChannel: MethodChannel
    private lateinit var changesChannel: EventChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var permissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var contentObserver: ContentObserver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        permissionsChannel =
            MethodChannel(binding.binaryMessenger, "flutter_contacts_pro/permissions")
        permissionsChannel.setMethodCallHandler(this)

        changesChannel = EventChannel(binding.binaryMessenger, "flutter_contacts_pro/changes")
        changesChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        permissionsChannel.setMethodCallHandler(null)
        changesChannel.setStreamHandler(null)
        unregisterObserver()
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> {
                val write = call.argument<Boolean>("write") ?: false
                requestPermission(write, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun requestPermission(write: Boolean, result: MethodChannel.Result) {
        val act = activity
        val ctx = applicationContext
        if (act == null || ctx == null) {
            result.error("NO_ACTIVITY", "No foreground activity for permission request", null)
            return
        }

        val permissions =
            if (write) {
                arrayOf(Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS)
            } else {
                arrayOf(Manifest.permission.READ_CONTACTS)
            }

        val allGranted =
            permissions.all {
                ContextCompat.checkSelfPermission(ctx, it) == PackageManager.PERMISSION_GRANTED
            }
        if (allGranted) {
            result.success(statusMap(granted = true, permanentlyDenied = false))
            return
        }

        if (permissionResult != null) {
            result.error("IN_PROGRESS", "A permission request is already in progress", null)
            return
        }

        permissionResult = result
        ActivityCompat.requestPermissions(act, permissions, REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val pending = permissionResult ?: return false
        permissionResult = null

        val granted =
            grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        val act = activity
        val permanentlyDenied =
            !granted &&
                act != null &&
                permissions.any {
                    !ActivityCompat.shouldShowRequestPermissionRationale(act, it)
                }

        pending.success(
            statusMap(granted = granted, permanentlyDenied = permanentlyDenied),
        )
        return true
    }

    private fun statusMap(granted: Boolean, permanentlyDenied: Boolean): Map<String, Any> {
        val status =
            when {
                granted -> "granted"
                permanentlyDenied -> "permanentlyDenied"
                else -> "denied"
            }
        return mapOf("status" to status)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val ctx = applicationContext ?: return
        val observer =
            object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    onChange(selfChange, null)
                }

                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    eventSink?.success(
                        mapOf(
                            "type" to "unknown",
                            "contactId" to null,
                            "timestampMs" to System.currentTimeMillis(),
                        ),
                    )
                }
            }
        contentObserver = observer
        ctx.contentResolver.registerContentObserver(
            ContactsContract.Contacts.CONTENT_URI,
            true,
            observer,
        )
    }

    override fun onCancel(arguments: Any?) {
        unregisterObserver()
        eventSink = null
    }

    private fun unregisterObserver() {
        val observer = contentObserver ?: return
        applicationContext?.contentResolver?.unregisterContentObserver(observer)
        contentObserver = null
    }

    companion object {
        private const val REQUEST_CODE = 39174
    }
}
