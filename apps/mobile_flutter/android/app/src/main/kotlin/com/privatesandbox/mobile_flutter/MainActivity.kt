package com.privatesandbox.mobile_flutter

import android.app.RecoverableSecurityException
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import android.webkit.MimeTypeMap
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

private const val TAG = "PrivateSandboxMedia"

private const val MEDIA_STORE_CHANNEL = "privatesandbox.app/media_store"

// Player brightness override and the "compartición controlada" share sheet.
private const val SYSTEM_CHANNEL = "privatesandbox.app/system"

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth's
// biometric prompt, which relies on FragmentActivity/FragmentManager.
//
// The "Galería" picker itself (photos/videos grid + deletion) lives in Dart
// via the `photo_manager` plugin, not here — this class only handles what's
// specific to file-explorer (SAF) picks: deleting, persisting access to,
// and restoring a document URI.
class MainActivity : FlutterFragmentActivity() {
    private var pendingDeleteResult: MethodChannel.Result? = null
    private lateinit var deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest>

    override fun onCreate(savedInstanceState: Bundle?) {
        // Blocks screenshots/screen recording of this app, and — as the same
        // flag's side effect — makes the system show a blank thumbnail for
        // it in the Recents/app-switcher view instead of the last screen.
        // Always on: there's no scenario where a privacy vault should allow
        // either.
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)

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
                    "takePersistableUriPermission" -> {
                        val uriString = call.argument<String>("uri")
                        result.success(if (uriString.isNullOrEmpty()) false else takePersistableUriPermission(uriString))
                    }
                    "restoreToUri" -> {
                        val uriString = call.argument<String>("uri")
                        val sourcePath = call.argument<String>("sourcePath")
                        val modifiedAtEpochMs = call.argument<Number>("modifiedAtEpochMs")?.toLong()
                        if (uriString.isNullOrEmpty() || sourcePath.isNullOrEmpty()) {
                            result.error("invalid_argument", "uri and sourcePath are required", null)
                        } else {
                            // Videos can be hundreds of MB — copying them here would
                            // block the platform/UI thread for seconds otherwise.
                            runOffMainThread(result) {
                                restoreToUri(uriString, sourcePath, modifiedAtEpochMs)
                            }
                        }
                    }
                    "recreateInMediaStore" -> {
                        val relativePath = call.argument<String>("relativePath")
                        val displayName = call.argument<String>("displayName")
                        val mimeType = call.argument<String>("mimeType")
                        val sourcePath = call.argument<String>("sourcePath")
                        val modifiedAtEpochMs = call.argument<Number>("modifiedAtEpochMs")?.toLong()
                        val createdAtEpochMs = call.argument<Number>("createdAtEpochMs")?.toLong()
                        if (relativePath.isNullOrEmpty() || displayName.isNullOrEmpty() || sourcePath.isNullOrEmpty()) {
                            result.error("invalid_argument", "relativePath, displayName and sourcePath are required", null)
                        } else {
                            runOffMainThread(result) {
                                recreateInMediaStore(
                                    relativePath,
                                    displayName,
                                    mimeType,
                                    sourcePath,
                                    modifiedAtEpochMs,
                                    createdAtEpochMs,
                                )
                            }
                        }
                    }
                    "generateVideoThumbnail" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        if (sourcePath.isNullOrEmpty()) {
                            result.error("invalid_argument", "sourcePath is required", null)
                        } else {
                            runOffMainThread(result) { generateVideoThumbnail(sourcePath) }
                        }
                    }
                    "findCoveringTree" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString.isNullOrEmpty()) {
                            result.error("invalid_argument", "uri is required", null)
                        } else {
                            result.success(findCoveringTree(uriString))
                        }
                    }
                    "recreateInDocumentTree" -> {
                        val treeUri = call.argument<String>("treeUri")
                        val relativeFolderPath = call.argument<String>("relativeFolderPath")
                        val displayName = call.argument<String>("displayName")
                        val mimeType = call.argument<String>("mimeType")
                        val sourcePath = call.argument<String>("sourcePath")
                        val modifiedAtEpochMs = call.argument<Number>("modifiedAtEpochMs")?.toLong()
                        if (treeUri.isNullOrEmpty() || relativeFolderPath == null || displayName.isNullOrEmpty() || sourcePath.isNullOrEmpty()) {
                            result.error(
                                "invalid_argument",
                                "treeUri, relativeFolderPath, displayName and sourcePath are required",
                                null,
                            )
                        } else {
                            runOffMainThread(result) {
                                recreateInDocumentTree(
                                    treeUri,
                                    relativeFolderPath,
                                    displayName,
                                    mimeType,
                                    sourcePath,
                                    modifiedAtEpochMs,
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Brightness/share both touch window/activity state, so they
                    // stay on the platform (UI) thread — none copies file bytes.
                    "getScreenBrightness" -> result.success(getScreenBrightness())
                    "setScreenBrightness" -> {
                        val level = call.argument<Double>("level")
                        if (level == null) {
                            result.error("invalid_argument", "level is required", null)
                        } else {
                            setWindowBrightness(level.toFloat())
                            result.success(null)
                        }
                    }
                    "clearScreenBrightness" -> {
                        setWindowBrightness(WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
                        result.success(null)
                    }
                    "shareFile" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val mimeType = call.argument<String>("mimeType")
                        val displayName = call.argument<String>("displayName")
                        if (sourcePath.isNullOrEmpty()) {
                            result.error("invalid_argument", "sourcePath is required", null)
                        } else {
                            result.success(shareFile(sourcePath, mimeType, displayName))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Current brightness as a 0..1 value: the window override if one is set,
     * otherwise the system setting, so a gesture starts from what the user
     * actually sees rather than jumping.
     */
    private fun getScreenBrightness(): Double {
        val override = window.attributes.screenBrightness
        if (override >= 0f) return override.toDouble()
        return try {
            Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS) / 255.0
        } catch (_: Exception) {
            0.5
        }
    }

    /**
     * Overrides brightness for this window only (doesn't touch the global
     * system setting, needs no WRITE_SETTINGS permission). Pass
     * [WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE] to release the
     * override and hand control back to the system.
     */
    private fun setWindowBrightness(level: Float) {
        val lp = window.attributes
        lp.screenBrightness = if (level < 0f) level else level.coerceIn(0.01f, 1.0f)
        window.attributes = lp
    }

    /**
     * Fase 3's "compartición controlada": hands a single already-decrypted
     * temp file to the system share sheet through the app's own FileProvider,
     * granting the chosen app one-shot read access to just that URI. The
     * caller (Dart) owns decrypting to and later wiping the temp file.
     */
    private fun shareFile(sourcePath: String, mimeType: String?, displayName: String?): Boolean {
        return try {
            val file = File(sourcePath)
            val uri = FileProvider.getUriForFile(this, "$packageName.privatesandbox.fileprovider", file)
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType?.takeIf { it.isNotBlank() } ?: "application/octet-stream"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(sendIntent, displayName).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(chooser)
            true
        } catch (e: Exception) {
            Log.e(TAG, "shareFile failed for $sourcePath", e)
            false
        }
    }

    /**
     * Runs [block] on a plain background thread and delivers its result back
     * on the main thread, as [MethodChannel.Result] requires. Needed for any
     * handler that copies file bytes (videos can be hundreds of MB) — doing
     * that directly in the method channel callback blocks the platform/UI
     * thread for the whole copy, which is what made large-video restores
     * look like they silently failed.
     */
    private fun <T> runOffMainThread(result: MethodChannel.Result, block: () -> T) {
        Thread {
            val outcome = try {
                block()
            } catch (e: Exception) {
                Log.e(TAG, "Background media operation failed", e)
                null
            }
            runOnUiThread { result.success(outcome) }
        }.start()
    }

    /**
     * Retains read/write access to a SAF document URI beyond the immediate
     * picker result, so the vault can restore a file to its exact original
     * location later — even after the app process restarts. Only
     * ACTION_OPEN_DOCUMENT-granted document URIs support this.
     */
    private fun takePersistableUriPermission(uriString: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Checks whether the app already holds a persisted folder-tree grant
     * (granted at some point — by this app or through Android's own
     * document-tree UI, this session or a past one) covering
     * [documentUriString] — Android tracks these grants
     * itself via [android.content.ContentResolver.getPersistedUriPermissions],
     * so there's no separate cache to keep in sync. Returns the covering
     * tree URI and the document's folder path relative to that tree's root
     * (e.g. "" if the document sits directly in the granted folder, or
     * "Sub" if one level deeper), or null if no persisted tree covers it.
     *
     * Only works for document IDs that encode a real filesystem-like path
     * (true for the standard local-storage SAF provider, which is what a
     * plain "explorador de archivos" pick resolves to) — other providers'
     * document IDs won't share a prefix with any tree ID, so this
     * correctly returns null for them rather than a wrong match.
     */
    private fun findCoveringTree(documentUriString: String): Map<String, String>? {
        val targetDocId = try {
            DocumentsContract.getDocumentId(Uri.parse(documentUriString))
        } catch (_: Exception) {
            return null
        }
        for (permission in contentResolver.persistedUriPermissions) {
            val treeUri = permission.uri
            if (!DocumentsContract.isTreeUri(treeUri)) continue
            val treeDocId = DocumentsContract.getTreeDocumentId(treeUri)
            val prefix = "$treeDocId/"
            if (!targetDocId.startsWith(prefix)) continue
            val relativeToTree = targetDocId.removePrefix(prefix)
            val relativeFolderPath = relativeToTree.substringBeforeLast('/', "")
            return mapOf("treeUri" to treeUri.toString(), "relativeFolderPath" to relativeFolderPath)
        }
        return null
    }

    /**
     * Creates (or reuses) [relativeFolderPath]'s subfolders under the
     * granted [treeUriString], then writes a new document named
     * [displayName] there with the bytes at [sourcePath]. Used to restore
     * an explorer-imported file into the exact folder it came from, when
     * its original document was deleted (so writing back to the old
     * document URI is no longer possible) but folder-level access was
     * granted at import time.
     */
    private fun recreateInDocumentTree(
        treeUriString: String,
        relativeFolderPath: String,
        displayName: String,
        mimeType: String?,
        sourcePath: String,
        modifiedAtEpochMs: Long?,
    ): Boolean {
        var createdDocument: DocumentFile? = null
        return try {
            var dir = DocumentFile.fromTreeUri(this, Uri.parse(treeUriString)) ?: return false
            if (relativeFolderPath.isNotEmpty()) {
                for (segment in relativeFolderPath.split('/')) {
                    val existing = dir.findFile(segment)
                    dir = if (existing != null && existing.isDirectory) existing else dir.createDirectory(segment) ?: return false
                }
            }
            var resolvedMime = mimeType?.takeIf { it.isNotBlank() }
            if (resolvedMime == null || resolvedMime == "application/octet-stream") {
                val extension = displayName.substringAfterLast('.', "").lowercase()
                resolvedMime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                    ?: resolvedMime
                    ?: "application/octet-stream"
            }
            val newFile = dir.createFile(resolvedMime, displayName) ?: return false
            createdDocument = newFile
            val source = File(sourcePath)
            val copied = contentResolver.openOutputStream(newFile.uri, "wt")?.use { out ->
                source.inputStream().use { input -> input.copyTo(out) }
            } ?: run {
                newFile.delete()
                return false
            }
            if (copied != source.length()) {
                newFile.delete()
                return false
            }
            if (modifiedAtEpochMs != null) {
                try {
                    val timestamps = ContentValues().apply {
                        put(DocumentsContract.Document.COLUMN_LAST_MODIFIED, modifiedAtEpochMs)
                    }
                    contentResolver.update(newFile.uri, timestamps, null, null)
                } catch (_: Exception) {
                    // Many document providers expose last-modified read-only.
                }
            }
            true
        } catch (e: Exception) {
            try {
                createdDocument?.delete()
            } catch (_: Exception) {
                // Best effort; the provider may already have removed it.
            }
            Log.e(TAG, "recreateInDocumentTree failed for $displayName", e)
            false
        }
    }

    /** Overwrites [uriString] with the bytes at [sourcePath], if still possible. */
    private fun restoreToUri(
        uriString: String,
        sourcePath: String,
        modifiedAtEpochMs: Long?,
    ): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val source = File(sourcePath)
            val copied = contentResolver.openOutputStream(uri, "wt")?.use { out ->
                source.inputStream().use { input -> input.copyTo(out) }
            } ?: return false
            if (copied != source.length()) return false
            if (modifiedAtEpochMs != null) {
                try {
                    val timestamps = ContentValues().apply {
                        put(DocumentsContract.Document.COLUMN_LAST_MODIFIED, modifiedAtEpochMs)
                    }
                    contentResolver.update(uri, timestamps, null, null)
                } catch (_: Exception) {
                    // Timestamp restoration is best-effort for SAF providers.
                }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Re-creates a MediaStore entry for a gallery-sourced file in the
     * folder it originally lived in ([relativePath], e.g. "DCIM/Camera/").
     * Restoring can't just write back to the original content URI here:
     * deleting a gallery asset (as `PhotoManager.editor.deleteWithIds`
     * does on import) removes that URI's row from MediaStore for good, so
     * this inserts a fresh row with the same folder/name/mime type instead.
     */
    private fun recreateInMediaStore(
        relativePath: String,
        displayName: String,
        mimeType: String?,
        sourcePath: String,
        modifiedAtEpochMs: Long?,
        createdAtEpochMs: Long?,
    ): Boolean {
        var insertedUri: Uri? = null
        return try {
            // [mimeType] comes from the vault's stored value, guessed from the
            // file name at import time — fall back to guessing from
            // [displayName]'s extension here too, so a missing/generic stored
            // mime type doesn't route a video/audio file into the generic
            // "Files" collection, which some OEM galleries won't index.
            var resolvedMime = mimeType?.takeIf { it.isNotBlank() }
            if (resolvedMime == null || resolvedMime == "application/octet-stream") {
                val extension = displayName.substringAfterLast('.', "").lowercase()
                resolvedMime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                    ?: resolvedMime
                    ?: "application/octet-stream"
            }
            val collection = when {
                resolvedMime.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                resolvedMime.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                resolvedMime.startsWith("audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Files.getContentUri("external")
            }
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, resolvedMime)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                modifiedAtEpochMs?.let {
                    put(MediaStore.MediaColumns.DATE_MODIFIED, it / 1000L)
                }
                createdAtEpochMs?.let {
                    put(MediaStore.MediaColumns.DATE_ADDED, it / 1000L)
                }
            }
            val uri = contentResolver.insert(collection, values)
            if (uri == null) {
                Log.e(TAG, "recreateInMediaStore: insert returned null for $displayName ($resolvedMime)")
                return false
            }
            insertedUri = uri
            val source = File(sourcePath)
            val written = contentResolver.openOutputStream(uri, "wt")?.use { out ->
                source.inputStream().use { input -> input.copyTo(out) }
            }
            if (written == null || written != source.length()) {
                Log.e(TAG, "recreateInMediaStore: openOutputStream returned null for $uri")
                contentResolver.delete(uri, null, null)
                insertedUri = null
                return false
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val doneValues = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                contentResolver.update(uri, doneValues, null, null)
            }
            true
        } catch (e: Exception) {
            insertedUri?.let { uri ->
                try {
                    contentResolver.delete(uri, null, null)
                } catch (_: Exception) {
                    // Best effort cleanup of an unpublished/partial row.
                }
            }
            Log.e(TAG, "recreateInMediaStore failed for $displayName", e)
            false
        }
    }

    /**
     * Extracts a JPEG preview frame from a video file for the vault's own
     * library grid. `photo_manager`'s thumbnails only cover its gallery
     * picker; the vault list decrypts nothing until a file is opened, so it
     * needs its own small preview generated once at import time, same as
     * images already get via [ThumbnailGenerator] on the Dart side.
     */
    private fun generateVideoThumbnail(sourcePath: String): ByteArray? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(sourcePath)
            val frame = retriever.getFrameAtTime(1_000_000L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: retriever.frameAtTime
                ?: return null
            val maxDimension = 400
            val largestSide = maxOf(frame.width, frame.height)
            val scaled = if (largestSide > maxDimension) {
                val scale = maxDimension.toFloat() / largestSide
                Bitmap.createScaledBitmap(
                    frame,
                    (frame.width * scale).toInt().coerceAtLeast(1),
                    (frame.height * scale).toInt().coerceAtLeast(1),
                    true,
                )
            } else {
                frame
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 72, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "generateVideoThumbnail failed for $sourcePath", e)
            null
        } finally {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) retriever.close() else retriever.release()
            } catch (_: Exception) {
                // Ignore — already-released retriever throwing on cleanup isn't
                // actionable.
            }
        }
    }

    /**
     * Deletes a file picked via the file explorer (SAF), so it stops
     * showing up there once its encrypted copy has been verified inside
     * the sandbox. Scoped storage means this can't just be a filesystem
     * delete: the URI is a SAF *document* URI from ACTION_OPEN_DOCUMENT,
     * which already grants persistent write access — deletable directly —
     * with a MediaStore-consent-flow fallback for the rare case where it
     * isn't a document URI.
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
