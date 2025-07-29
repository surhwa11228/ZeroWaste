package com.chungwoo.zerowaste.utils;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import java.io.FileInputStream;
import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class ImageUtilsTest {

    @Test
    void convertToJPG_shouldReturnJPEGByteArray() throws IOException {
        // given: 테스트용 이미지 (예: src/test/resources/test.png)
        FileInputStream inputStream = new FileInputStream("src/test/resources/test.png");
        MockMultipartFile mockImage = new MockMultipartFile(
                "file", "test.png", "image/png", inputStream);

        // when
        byte[] jpegBytes = ImageUtils.convertToJPG(mockImage);

        // then
        assertThat(jpegBytes).isNotNull();
        assertThat(jpegBytes.length).isGreaterThan(0);
    }
}
