package com.chungwoo.zerowaste.FireBase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FireBaseConfig {

    @Bean
    public Firestore firestore() {
        // resources/firebase/serviceAccount.json 경로에 파일을 두세요.
        try (InputStream serviceAccount = new ClassPathResource("firebase/serviceAccount.json").getInputStream()) {
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();
                FirebaseApp.initializeApp(options);
                System.out.println("✅ FirebaseApp 초기화 완료");
            }
        } catch (IOException e) {
            throw new RuntimeException("Firebase service account 파일을 로드하지 못했습니다.", e);
        }
        return FirestoreClient.getFirestore();
    }
}
