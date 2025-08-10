package com.chungwoo.zerowaste.upload;

import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;


public interface IImageUploader {
    Map<String, String> upload(String folderName, MultipartFile image);
    List<Map<String, String>> upload(String folderName, List<MultipartFile> images);
}
