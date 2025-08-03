package com.chungwoo.zerowaste.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class FirebaseConfig {

    private final FirebaseProperties firebaseProperties;

    @PostConstruct
    public void init() throws IOException {

        log.info("GOOGLE_APPLICATION_CREDENTIALS = {}", System.getenv("GOOGLE_APPLICATION_CREDENTIALS"));

        FirebaseOptions options = FirebaseOptions
                .builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())//getApplicationDefault로 설정한 환경변수 로드
                .setStorageBucket(firebaseProperties.getBucket())//storage bucket 초기화
                .build();

        if(FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
            log.info("Firebase app has been initialized");
        }

    }


}
