package com.chungwoo.zerowaste.upload;

import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import org.springframework.web.multipart.MultipartFile;

public interface ImageUploader {
    ImageUploadResult upload(String folderName, MultipartFile image);
}
