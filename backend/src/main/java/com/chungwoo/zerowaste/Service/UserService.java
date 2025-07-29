package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    public UserDto registerUser(UserRegistrationRequest request) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            // 이메일 중복 확인
            CollectionReference users = db.collection("users");
            Query query = users.whereEqualTo("emailId", request.getEmailId());
            if (!query.get().get().isEmpty()) {
                throw new RuntimeException("Email ID already exists");
            }

            // 유저 등록 (Map 형태로 변환)
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("emailId", request.getEmailId());
            userMap.put("name", request.getName());
            userMap.put("phoneNumber", request.getPhoneNumber());
            userMap.put("address", request.getAddress());
            userMap.put("birthDate", request.getBirthDate());
            userMap.put("phoneVerified", true);

            // Firestore에 저장
            db.collection("users").document(request.getEmailId()).set(userMap);

            // 반환할 DTO
            UserDto userDto = new UserDto();
            userDto.setEmailId(request.getEmailId());
            userDto.setName(request.getName());
            userDto.setPhoneNumber(request.getPhoneNumber());
            userDto.setAddress(request.getAddress());
            userDto.setBirthDate(request.getBirthDate());
            userDto.setPhoneVerified(true);

            return userDto;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Registration failed", e);
        }
    }
}


