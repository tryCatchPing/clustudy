package com.trycatchping.clustudy

import android.os.Handler
import android.os.Looper
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val INSTALL_REFERRER_CHANNEL =
    "com.trycatchping.clustudy/install_referrer"

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INSTALL_REFERRER_CHANNEL,
        ).setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstallReferrer" -> fetchInstallReferrer(result)
            else -> result.notImplemented()
        }
    }

    private fun fetchInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()

        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    when (responseCode) {
                        InstallReferrerClient.InstallReferrerResponse.OK -> {
                            try {
                                val response = client.installReferrer
                                val payload = mapOf(
                                    "installReferrer" to response.installReferrer,
                                    "referrerClickTimestampSeconds" to response.referrerClickTimestampSeconds,
                                    "installBeginTimestampSeconds" to response.installBeginTimestampSeconds,
                                    "googlePlayInstantParam" to response.googlePlayInstantParam,
                                )
                                postSuccess(result, payload)
                            } catch (error: Exception) {
                                postError(
                                    result,
                                    "INSTALL_REFERRER_ERROR",
                                    error.localizedMessage ?: "Unknown error",
                                )
                            } finally {
                                client.endConnection()
                            }
                        }

                        InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
                            client.endConnection()
                            postSuccess(result, emptyMap())
                        }

                        InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
                            client.endConnection()
                            postError(
                                result,
                                "INSTALL_REFERRER_UNAVAILABLE",
                                "Google Play Install Referrer service unavailable",
                            )
                        }

                        else -> {
                            client.endConnection()
                            postError(
                                result,
                                "INSTALL_REFERRER_ERROR",
                                "Unhandled response code: $responseCode",
                            )
                        }
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    // The next invocation will establish a new connection.
                }
            })
        } catch (error: Exception) {
            client.endConnection()
            postError(
                result,
                "INSTALL_REFERRER_ERROR",
                error.localizedMessage ?: "Failed to start InstallReferrerClient",
            )
        }
    }

    private fun postSuccess(
        result: MethodChannel.Result,
        payload: Map<String, Any?>,
    ) {
        mainHandler.post { result.success(payload) }
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post { result.error(code, message, null) }
    }
}
