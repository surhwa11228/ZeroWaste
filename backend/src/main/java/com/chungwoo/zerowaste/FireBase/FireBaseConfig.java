package com.chungwoo.zerowaste.FireBase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import javax.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FireBaseConfig {

    @PostConstruct
    public void init() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                // 환경 변수로부터 파일 경로 읽기

                InputStream serviceAccount = getClass().getClassLoader()
                        .getResourceAsStream("firebase/serviceAccount.json");


                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                System.out.println("초기화 전");
                // FirebaseApp 초기화
                FirebaseApp.initializeApp(options);
                System.out.println("✅ FirebaseApp 초기화 완료");
            }
        } catch (IOException e) {
            throw new RuntimeException("Firebase 초기화 실패", e);
        }
    }
}

