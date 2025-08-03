package com.chungwoo.zerowaste.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.FirestoreOptions;
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

    private final FirebaseStorageProperties firebaseStorageProperties;
    private final FirestoreProperties firestoreProperties;

    @PostConstruct
    public void init() throws IOException {

        log.info("GOOGLE_APPLICATION_CREDENTIALS = {}", System.getenv("GOOGLE_APPLICATION_CREDENTIALS"));

//        FirestoreOptions firestoreOptions = FirestoreOptions.newBuilder()
//                .setDatabaseId(firestoreProperties.getDB())
//                .build();



        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())
//                .setFirestoreOptions(firestoreOptions)
                .setStorageBucket(firebaseStorageProperties.getBucket())
                .build();



        if(FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
            log.info("Firebase app has been initialized");
        }

    }


}
