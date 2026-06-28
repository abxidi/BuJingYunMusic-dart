package com.novapulse.mp3;

import android.Manifest;
import android.app.Activity;
import android.content.ContentUris;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Build;
import android.provider.DocumentsContract;
import android.provider.MediaStore;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.ryanheise.audioservice.AudioServiceActivity;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends AudioServiceActivity {
    private static final String CHANNEL_NAME = "com.novapulse.mp3/music_library";
    private static final int REQUEST_AUDIO_PERMISSION = 1001;
    private static final int REQUEST_FOLDER = 1002;
    private static final int MAX_AUDIO_STORE_SCAN_COUNT = 300;
    private static final int MAX_TREE_SCAN_COUNT = 500;
    private static final int MAX_TREE_SCAN_DEPTH = 16;
    private static final List<String> AUDIO_EXTENSIONS = Arrays.asList(
            ".mp3",
            ".m4a",
            ".aac",
            ".wav",
            ".wave",
            ".flac",
            ".alac",
            ".aif",
            ".aiff",
            ".ogg",
            ".oga",
            ".opus",
            ".amr",
            ".3gp",
            ".wma"
    );

    @Nullable
    private MethodChannel channel;
    @Nullable
    private MethodChannel.Result pendingAudioStoreResult;
    @Nullable
    private MethodChannel.Result pendingFolderResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        channel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL_NAME
        );
        channel.setMethodCallHandler(this::handleMethodCall);
    }

    private void handleMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "scanAudioStore":
                scanAudioStoreWithPermission(result);
                break;
            case "pickAndScanFolder":
                pickAndScanFolder(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void scanAudioStoreWithPermission(@NonNull MethodChannel.Result result) {
        String permission = audioPermission();
        if (Build.VERSION.SDK_INT >= 23
                && checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
            pendingAudioStoreResult = result;
            requestPermissions(new String[]{permission}, REQUEST_AUDIO_PERMISSION);
            return;
        }
        result.success(scanAudioStore());
    }

    @Override
    public void onRequestPermissionsResult(
            int requestCode,
            @NonNull String[] permissions,
            @NonNull int[] grantResults
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_AUDIO_PERMISSION) {
            return;
        }

        MethodChannel.Result result = pendingAudioStoreResult;
        if (result == null) {
            return;
        }
        pendingAudioStoreResult = null;
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            result.success(scanAudioStore());
        } else {
            result.error("audio_permission_denied", "需要音频读取权限", null);
        }
    }

    private void pickAndScanFolder(@NonNull MethodChannel.Result result) {
        if (pendingFolderResult != null) {
            result.error("folder_picker_busy", "目录选择正在进行", null);
            return;
        }
        pendingFolderResult = result;
        startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), REQUEST_FOLDER);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_FOLDER) {
            return;
        }

        MethodChannel.Result result = pendingFolderResult;
        pendingFolderResult = null;
        Uri treeUri = data == null ? null : data.getData();
        if (result == null) {
            return;
        }
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            result.success(new ArrayList<Map<String, String>>());
            return;
        }

        int flags = data.getFlags() & (
                Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        );
        try {
            getContentResolver().takePersistableUriPermission(treeUri, flags);
            result.success(scanSelectedFolder(treeUri));
        } catch (RuntimeException error) {
            result.error("folder_scan_failed", "无法读取所选目录", null);
        }
    }

    private List<Map<String, String>> scanAudioStore() {
        List<Map<String, String>> scanned = new ArrayList<>();
        Uri collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
        String[] projection = new String[]{
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.SIZE
        };

        Cursor cursor = getContentResolver().query(
                collection,
                projection,
                MediaStore.Audio.Media.IS_MUSIC + "!=0",
                null,
                MediaStore.Audio.Media.DATE_ADDED + " DESC"
        );
        if (cursor == null) {
            return scanned;
        }

        try {
            int idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID);
            int displayColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME);
            int titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE);
            int artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST);
            int durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION);
            int sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE);

            while (cursor.moveToNext() && scanned.size() < MAX_AUDIO_STORE_SCAN_COUNT) {
                long duration = cursor.getLong(durationColumn);
                if (duration <= 0) {
                    continue;
                }

                long id = cursor.getLong(idColumn);
                String displayName = cursor.getString(displayColumn);
                String title = cursor.getString(titleColumn);
                String artist = cursor.getString(artistColumn);
                long size = cursor.getLong(sizeColumn);
                Uri uri = ContentUris.withAppendedId(collection, id);
                String safeTitle = isBlank(displayName) ? title : displayName;
                String safeArtist = isBlank(artist) ? "手机存储" : artist;

                Map<String, String> item = new HashMap<>();
                item.put("title", safeTitle == null ? "未知音频" : safeTitle);
                item.put("meta", "手机存储 / Music / " + safeArtist);
                item.put("duration", formatDuration(duration));
                item.put("size", formatSize(size));
                item.put("uri", uri.toString());
                scanned.add(item);
            }
        } finally {
            cursor.close();
        }
        return scanned;
    }

    private List<Map<String, String>> scanSelectedFolder(@NonNull Uri treeUri) {
        List<Map<String, String>> scanned = new ArrayList<>();
        String documentId = DocumentsContract.getTreeDocumentId(treeUri);
        scanDocumentChildren(treeUri, documentId, scanned, 0);
        return scanned;
    }

    private void scanDocumentChildren(
            @NonNull Uri treeUri,
            @NonNull String documentId,
            @NonNull List<Map<String, String>> scanned,
            int depth
    ) {
        if (depth > MAX_TREE_SCAN_DEPTH || scanned.size() >= MAX_TREE_SCAN_COUNT) {
            return;
        }

        Uri childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId);
        String[] projection = new String[]{
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE
        };
        Cursor cursor = getContentResolver().query(
                childrenUri,
                projection,
                null,
                null,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME
        );
        if (cursor == null) {
            return;
        }

        try {
            int idColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID);
            int nameColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME);
            int mimeColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE);
            int sizeColumn = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_SIZE);

            while (cursor.moveToNext() && scanned.size() < MAX_TREE_SCAN_COUNT) {
                String childId = cursor.getString(idColumn);
                String name = cursor.getString(nameColumn);
                String mimeType = cursor.getString(mimeColumn);
                long size = cursor.isNull(sizeColumn) ? 0L : cursor.getLong(sizeColumn);

                if (DocumentsContract.Document.MIME_TYPE_DIR.equals(mimeType)) {
                    scanDocumentChildren(treeUri, childId, scanned, depth + 1);
                } else if (isAudioDocument(name, mimeType)) {
                    Uri documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, childId);
                    String safeName = isBlank(name) ? "未知音频" : name;

                    Map<String, String> item = new HashMap<>();
                    item.put("title", safeName);
                    item.put("meta", "所选目录 / 子目录");
                    item.put("duration", readAudioDuration(documentUri));
                    item.put("size", formatSize(size));
                    item.put("uri", documentUri.toString());
                    scanned.add(item);
                }
            }
        } finally {
            cursor.close();
        }
    }

    private String readAudioDuration(@NonNull Uri uri) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(this, uri);
            String duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
            if (isBlank(duration)) {
                return "--:--";
            }
            return formatDuration(Long.parseLong(duration));
        } catch (RuntimeException error) {
            return "--:--";
        } finally {
            retriever.release();
        }
    }

    private boolean isAudioDocument(@Nullable String name, @Nullable String mimeType) {
        if (mimeType != null && mimeType.startsWith("audio/")) {
            return true;
        }
        if (name == null) {
            return false;
        }
        String lowerName = name.toLowerCase(Locale.US);
        for (String extension : AUDIO_EXTENSIONS) {
            if (lowerName.endsWith(extension)) {
                return true;
            }
        }
        return false;
    }

    private String audioPermission() {
        if (Build.VERSION.SDK_INT >= 33) {
            return Manifest.permission.READ_MEDIA_AUDIO;
        }
        return Manifest.permission.READ_EXTERNAL_STORAGE;
    }

    private String formatSize(long bytes) {
        if (bytes <= 0) {
            return "未知大小";
        }
        return String.format(Locale.US, "%.1f MB", bytes / 1024f / 1024f);
    }

    private String formatDuration(long milliseconds) {
        long totalSeconds = milliseconds / 1000;
        long minutes = totalSeconds / 60;
        long seconds = totalSeconds % 60;
        return String.format(Locale.US, "%02d:%02d", minutes, seconds);
    }

    private boolean isBlank(@Nullable String value) {
        return value == null || value.trim().isEmpty();
    }
}
