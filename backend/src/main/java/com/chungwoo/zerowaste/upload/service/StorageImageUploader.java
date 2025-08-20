package com.chungwoo.zerowaste.upload.service;

import com.chungwoo.zerowaste.exception.exceptions.ImageUploadException;
import com.chungwoo.zerowaste.upload.IImageUploader;
import com.chungwoo.zerowaste.upload.UploadConstants;
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
import java.util.*;

@Slf4j
@Component
@RequiredArgsConstructor
public class StorageImageUploader implements IImageUploader {

    @Override
    public Map<String,String> upload(String folderName, MultipartFile image) {
        try {
            byte[] convertedImage = ImageUtils.convertToJPG(image);
            String imageName = UUID.randomUUID() + ".jpg";
            String fullPath = folderName + "/" + imageName;

            Bucket bucket = StorageClient.getInstance().bucket();
            Blob blob = bucket.create(fullPath, convertedImage, UploadConstants.JPEG);
            String url = buildDownloadUrl(blob);

            Map<String,String> result = new HashMap<>();
            result.put("imageName",blob.getName());
            result.put("url",url);
            return result;

        } catch (IOException e) {
            log.error("ImageUploader failed upload", e);
            throw new ImageUploadException("이미지 업로드에 실패했습니다.", e);
        }
    }

    @Override
    public List<Map<String,String>> upload(String folderName, List<MultipartFile> images) {
        if (images == null) return null;
        List<Map<String,String>> results = new ArrayList<>();
        for (MultipartFile image : images) {
            if (image != null && !image.isEmpty()) {
                results.add(upload(folderName, image));  // 각 이미지의 URL 저장
            }
        }
        return results;
    }

    private String buildDownloadUrl(Blob blob) {
        return "https://firebasestorage.googleapis.com/v0/b/"
                + blob.getBucket() + "/o/"
                + URLEncoder.encode(blob.getName(), StandardCharsets.UTF_8)
                + "?alt=media";
    }
}
