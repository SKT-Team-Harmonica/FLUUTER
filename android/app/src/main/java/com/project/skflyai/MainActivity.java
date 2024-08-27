package com.project.skflyai;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.example.clovaspeech.client.ClovaSpeechClient;
import org.example.clovaspeech.client.ClovaSpeechClient.NestRequestEntity;

import java.io.File;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.project.skflyai/clova_speech";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        new MethodChannel.MethodCallHandler() {
                            @Override
                            public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
                                if (call.method.equals("uploadFile")) {
                                    String filePath = call.arguments.toString();
                                    uploadFile(filePath, result);
                                } else {
                                    result.notImplemented();
                                }
                            }
                        }
                );
    }

    private void uploadFile(String filePath, MethodChannel.Result result) {
        // Run the upload task in a background thread
        new Thread(() -> {
            try {
                File file = new File(filePath);
                if (!file.exists()) {
                    throw new RuntimeException("File not found: " + filePath);
                }

                ClovaSpeechClient client = new ClovaSpeechClient();
                NestRequestEntity requestEntity = new NestRequestEntity();
                
                // Configure additional request parameters if needed
                requestEntity.setLanguage("ko-KR");
                requestEntity.setCompletion("sync");

                String uploadResult = client.upload(file, requestEntity);

                // Process and format the result
                String formattedResult = processResult(uploadResult);

                // Return the result to the main thread
                new Handler(Looper.getMainLooper()).post(() -> {
                    result.success(formattedResult);
                });

            } catch (Exception e) {
                Log.e("MainActivity", "File upload failed", e);
                new Handler(Looper.getMainLooper()).post(() -> {
                    result.error("UPLOAD_FAILED", "File upload failed: " + e.getMessage(), null);
                });
            }
        }).start();
    }

    private String processResult(String response) {
        StringBuilder sb = new StringBuilder();

        try {
            Gson gson = new Gson();
            JsonObject result = gson.fromJson(response, JsonObject.class);
            JsonArray segments = result.getAsJsonArray("segments");

            for (JsonElement segmentElement : segments) {
                JsonObject segment = segmentElement.getAsJsonObject();
                long startTimeMs = segment.get("start").getAsLong();
                JsonObject speaker = segment.getAsJsonObject("speaker");
                String speakerLabel = speaker.get("label").getAsString();
                String text = segment.get("text").getAsString();

                // Convert milliseconds to MM:SS format without milliseconds
                String startTime = convertMillisToMMSS(startTimeMs);

                sb.append("화자").append(speakerLabel).append(" ").append(startTime).append("\n");
                sb.append(text).append("\n\n");
            }

        } catch (Exception e) {
            Log.e("MainActivity", "Response processing failed", e);
        }

        return sb.toString();
    }

    private String convertMillisToMMSS(long millis) {
        long seconds = millis / 1000;
        long minutes = seconds / 60;
        seconds = seconds % 60;
        return String.format("%02d:%02d", minutes, seconds);
    }
}
