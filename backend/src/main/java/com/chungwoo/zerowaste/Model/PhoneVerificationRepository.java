package com.chungwoo.zerowaste.Model;

import com.chungwoo.zerowaste.Entity.PhoneVerificationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository  // @Repository 어노테이션 추가하여 Spring이 리포지토리로 인식하도록 함
public interface PhoneVerificationRepository extends JpaRepository<PhoneVerificationEntity, Long> {

    // 전화번호로 인증 정보 조회
    Optional<PhoneVerificationEntity> findByPhoneNumber(String phoneNumber);
}
