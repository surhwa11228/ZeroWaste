package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Entity.PhoneVerificationEntity;
import com.chungwoo.zerowaste.Model.PhoneVerificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.Random;

@Service
public class PhoneVerificationService {
    @Autowired
    private PhoneVerificationRepository phoneVerificationRepository;

    public PhoneVerificationEntity sendVerificationCode(String phoneNumber) {
        String verificationCode = generateVerificationCode();
        Date expiresAt = new Date(System.currentTimeMillis() + 10 * 60 * 1000); // 10분 유효

        PhoneVerificationEntity entity = new PhoneVerificationEntity();
        entity.setPhoneNumber(phoneNumber);
        entity.setVerificationCode(verificationCode);
        entity.setExpiresAt(expiresAt);
        entity.setCreatedAt(new Date());
        entity.setVerified(false);

        return phoneVerificationRepository.save(entity);
    }

    private String generateVerificationCode() {
        Random random = new Random();
        return String.format("%06d", random.nextInt(1000000));
    }
}
