package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Entity.PhoneVerificationEntity;
import com.chungwoo.zerowaste.Entity.UserEntity;
import com.chungwoo.zerowaste.Model.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PhoneVerificationRepository phoneVerificationRepository;

    @Transactional
    public UserDto registerUser(UserRegistrationRequest request) {
        if (userRepository.findByEmailId(request.getEmailId()).isPresent()) {
            throw new RuntimeException("Email ID already exists");
        }

        Optional<PhoneVerificationEntity> verification = phoneVerificationRepository.findByPhoneNumber(request.getPhoneNumber());
        if (!verification.isPresent() || !verification.get().isVerified()) {
            throw new RuntimeException("Phone number is not verified");
        }

        UserEntity user = UserEntity.builder()
                .emailId(request.getEmailId())
                .name(request.getName())
                .phoneNumber(request.getPhoneNumber())
                .address(request.getAddress())
                .birthDate(request.getBirthDate())
                .phoneVerified(true)
                .build();

        UserEntity savedUser = userRepository.save(user);

        UserDto response = new UserDto();
        response.setEmailId(savedUser.getEmailId());
        response.setName(savedUser.getName());
        response.setPhoneNumber(savedUser.getPhoneNumber());
        response.setAddress(savedUser.getAddress());
        response.setBirthDate(savedUser.getBirthDate());
        response.setSocialProvider(savedUser.getSocialProvider());

        return response;
    }

    public void verifyPhoneNumber(String phoneNumber, String verificationCode) {
        Optional<PhoneVerificationEntity> phoneVerification = phoneVerificationRepository.findByPhoneNumber(phoneNumber);

        if (phoneVerification.isPresent()) {
            PhoneVerificationEntity verification = phoneVerification.get();
            if (verification.getVerificationCode().equals(verificationCode) &&
                    verification.getExpiresAt().after(new Date())) {
                verification.setVerified(true);
                phoneVerificationRepository.save(verification);
            } else {
                throw new RuntimeException("Verification failed or expired");
            }
        } else {
            throw new RuntimeException("Phone number verification record not found");
        }
    }

}
