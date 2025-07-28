package com.chungwoo.zerowaste.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void init() throws IOException {
        InputStream serviceAccount =
                getClass().getClassLoader().getResourceAsStream("firebase/serviceAccount.json");//

        if (serviceAccount == null) {
            throw new IllegalStateException("Firebase serviceAccount.json 파일을 찾을 수 없습니다.");
        }

        FirebaseOptions options = FirebaseOptions
                .builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .setStorageBucket("zerowaste-ccae3.firebasestorage.app")
                .build();

        //추후 환경 변수 설정 등 필요해보임. juan3355

        if(FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
            log.info("Firebase app has been initialized");
        }

    }


}
