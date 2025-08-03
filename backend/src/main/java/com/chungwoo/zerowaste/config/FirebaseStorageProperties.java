package com.chungwoo.zerowaste.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "firebase.storage")
@Getter
@Setter
public class FirebaseStorageProperties {
    private String bucket;

}
