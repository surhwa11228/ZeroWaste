package com.chungwoo.zerowaste.upload.dto;

import com.google.cloud.storage.Blob;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ImageUploadResponse {
    private String fileName;
    private String url;
    private Blob blob;
}
