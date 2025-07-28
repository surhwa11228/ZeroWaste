package com.chungwoo.zerowaste.Model;

import com.chungwoo.zerowaste.Entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository  // 이 어노테이션을 추가하여 Spring이 리포지토리로 인식하게 해야 합니다.
public interface UserRepository extends JpaRepository<UserEntity, Long> {

    // 이메일로 사용자 조회
    Optional<UserEntity> findByEmailId(String emailId);

    // 전화번호로 사용자 조회
    Optional<UserEntity> findByPhoneNumber(String phoneNumber);
}
