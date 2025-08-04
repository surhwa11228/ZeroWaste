package com.chungwoo.zerowaste.upload.service;

import com.chungwoo.zerowaste.exception.exceptions.ImageUploadException;
import com.chungwoo.zerowaste.upload.ImageUploader;
import com.chungwoo.zerowaste.upload.UploadConstants;
import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import com.chungwoo.zerowaste.utils.ImageUtils;
import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.firebase.cloud.StorageClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class StorageImageUploader implements ImageUploader {

    @Override
    public ImageUploadResult upload(String folderName, MultipartFile image) {
        try {
            byte[] convertedImage = ImageUtils.convertToJPG(image);
            String imageName = UUID.randomUUID() + ".jpg";
            String fullPath = folderName + "/" + imageName;

            Bucket bucket = StorageClient.getInstance().bucket();
            Blob blob = bucket.create(fullPath, convertedImage, UploadConstants.JPEG);
            String url = buildDownloadUrl(blob);

            return new ImageUploadResult(blob.getName(), url, blob);

        } catch (IOException e) {
            log.error("ImageUploader failed upload", e);
            throw new ImageUploadException("이미지 업로드에 실패했습니다.", e);
        }
    }

    private String buildDownloadUrl(Blob blob) {
        return "https://firebasestorage.googleapis.com/v0/b/"
                + blob.getBucket() + "/o/"
                + URLEncoder.encode(blob.getName(), StandardCharsets.UTF_8)
                + "?alt=media";
    }
}
