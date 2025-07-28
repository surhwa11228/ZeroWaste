package com.chungwoo.zerowaste.Entity;
import jakarta.persistence.*;
import lombok.*;


import java.util.Date;
@Builder
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userId;

    @Column(nullable = false, unique = true)
    private String emailId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String phoneNumber;

    @Column(nullable = false)
    private boolean phoneVerified = false;  // 전화번호 인증 여부

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private Date birthDate;

    @Column(nullable = false)
    private Date createdAt = new Date();  // 가입일자

    private String socialProvider;

    // Getters and Setters
}
