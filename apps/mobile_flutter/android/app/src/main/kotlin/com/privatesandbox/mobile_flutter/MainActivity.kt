package com.privatesandbox.mobile_flutter

import android.app.RecoverableSecurityException
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val MEDIA_STORE_CHANNEL = "privatesandbox.app/media_store"

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth's
// biometric prompt, which relies on FragmentActivity/FragmentManager.
class MainActivity : FlutterFragmentActivity() {
    private var pendingDeleteResult: MethodChannel.Result? = null
    private lateinit var deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest>

    override fun onCreate(savedInstanceState: Bundle?) {
        // Must be registered before the activity reaches STARTED, so this
        // has to happen here rather than lazily in configureFlutterEngine.
        deleteRequestLauncher =
            registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { activityResult ->
                pendingDeleteResult?.success(activityResult.resultCode == RESULT_OK)
                pendingDeleteResult = null
            }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_STORE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deleteContentUri" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString.isNullOrEmpty()) {
                            result.error("invalid_argument", "uri is required", null)
                        } else {
                            deleteContentUri(Uri.parse(uriString), result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Deletes the file the user originally picked from outside the vault
     * (gallery, downloads, etc.) so it stops showing up there once its
     * encrypted copy has been verified inside the sandbox.
     *
     * Scoped storage means this can't just be a filesystem delete: the URI
     * file_picker hands back is either a SAF *document* URI (from
     * ACTION_OPEN_DOCUMENT, which already grants persistent write access —
     * deletable directly) or a raw MediaStore URI (from ACTION_GET_CONTENT
     * on an image/audio/video-typed pick, read-only by default — deleting it
     * requires the system's one-time consent flow).
     */
    private fun deleteContentUri(uri: Uri, result: MethodChannel.Result) {
        try {
            if (DocumentsContract.isDocumentUri(this, uri)) {
                result.success(DocumentsContract.deleteDocument(contentResolver, uri))
                return
            }
        } catch (_: Exception) {
            // Not deletable as a document URI; fall through to the
            // MediaStore-specific path below.
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                pendingDeleteResult = result
                deleteRequestLauncher.launch(IntentSenderRequest.Builder(pendingIntent.intentSender).build())
            } catch (_: Exception) {
                result.success(false)
            }
            return
        }

        try {
            val rows = contentResolver.delete(uri, null, null)
            result.success(rows > 0)
        } catch (e: RecoverableSecurityException) {
            pendingDeleteResult = result
            deleteRequestLauncher.launch(
                IntentSenderRequest.Builder(e.userAction.actionIntent.intentSender).build(),
            )
        } catch (_: Exception) {
            result.success(false)
        }
    }
}
