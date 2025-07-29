package com.chungwoo.zerowaste.upload.dto;

import com.google.cloud.storage.Blob;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ImageUploadResult {
    private String fileName;
    private String url;
    private Blob blob;
}
