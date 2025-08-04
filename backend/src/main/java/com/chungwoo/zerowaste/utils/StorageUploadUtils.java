package com.chungwoo.zerowaste.utils;

import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.firebase.cloud.StorageClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;


//삭제예정
@Slf4j
public class StorageUploadUtils {

    public static final String REPORT = "reportImage";
    public static final String BOARD = "boardImage";
    public static final String PROFILE = "profileImage";
    private static final String JPEG = "image/jpeg";

    public static ImageUploadResult imageUpload(String folderName, MultipartFile image) throws IOException {
        byte[] convertedImage = ImageUtils.convertToJPG(image);

        String imageName = UUID.randomUUID() + ".jpg";
        String fullPath = folderName +"/"+ imageName;

        Bucket bucket = StorageClient.getInstance().bucket();
        Blob blob = bucket.create(fullPath, convertedImage, JPEG);
        String url = buildDownloadUrl(blob);

        return new ImageUploadResult(blob.getName(), url, blob);
    }

    private static String buildDownloadUrl(Blob blob){

        return "https://firebasestorage.googleapis.com/v0/b/"
                + blob.getBucket() + "/o/"
                + URLEncoder.encode(blob.getName(), StandardCharsets.UTF_8)
                + "?alt=media";
    }
}
