package com.chungwoo.zerowaste.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "firebase.store")
@Getter
@Setter
public class FirestoreProperties {
    private String DB;

}
