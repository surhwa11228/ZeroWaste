package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.utils.ImageUtils;
import com.google.cloud.storage.Bucket;
import com.google.firebase.cloud.StorageClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.net.URLEncoder;
import java.util.UUID;

@Slf4j
@Service
public class FirebaseStorageUploadService {

    public String imageUpload(MultipartFile image) throws IOException {

        byte[] convertedImage = ImageUtils.convertToJPG(image);
        String imageName = UUID.randomUUID() + ".jpg";
        String folderName = "report/";


        Bucket bucket = StorageClient.getInstance().bucket();
        String fullPath = folderName + imageName;
        String encodedPath = URLEncoder.encode(fullPath, StandardCharsets.UTF_8);
        String url = "https://firebasestorage.googleapis.com/v0/b/" +
                bucket.getName() + "/o/" +
                encodedPath + "?alt=media";
        //url 형식에 다소 문제 있음 juan3355

        bucket.create(fullPath, convertedImage, "image/jpeg");

        return url;
    }
}
