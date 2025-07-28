package com.chungwoo.zerowaste.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;


@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PhoneVerificationEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long verificationId;

    @Column(nullable = false)
    private String phoneNumber;

    @Column(nullable = false)
    private String verificationCode;

    @Column(nullable = false)
    private Date expiresAt;  // 인증번호 만료 시간

    @Column(nullable = false)
    private boolean isVerified = false;  // 인증 성공 여부


    @Column(nullable = false)
    private Date createdAt = new Date();  // 인증 요청 시간

    // Getters and Setters
}
