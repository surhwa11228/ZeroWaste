package com.chungwoo.zerowaste.FireBase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Component
@Slf4j
public class FireBaseConfig {

    @PostConstruct
    public void init() throws IOException {

        FileInputStream serviceAccount = new FileInputStream("C:/Users/surhw/Desktop/ZeroWaste/backend/src/main/resources/firebase/serviceAccount.json");

//        if (serviceAccount == null)
//            System.out.println("null");
        FirebaseOptions options = FirebaseOptions
                .builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .setProjectId("zerowaste-ccae3")
                //.d/ 실제 GCP 프로젝트 ID
                .build();

        FirebaseApp.initializeApp(options);
        log.info("Firebase app has been initialized");

    }
}
