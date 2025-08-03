package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.PhoneVerificationDto;
import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.internal.FirebaseRequestInitializer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class UserService {

    private final PhoneVerificationService phoneVerificationService;

    public UserDto registerUser(UserRegistrationRequest request) {
        try {
            Firestore db = FirestoreClient.getFirestore("zerowaste");
            CollectionReference users = db.collection("users");
            Query query = users.whereEqualTo("emailId", request.getEmailId());
            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot snapshot = future.get();
            if (!snapshot.isEmpty()) {
                throw new RuntimeException("Email ID already exists");
            }

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("emailId", request.getEmailId());
            userMap.put("name", request.getName());
            userMap.put("phoneNumber", request.getPhoneNumber());
            userMap.put("address", request.getAddress());
            userMap.put("birthDate", request.getBirthDate());
            //userMap.put("password", request.getPassword());
            userMap.put("phoneVerified", false);

            DocumentReference userRef = users.document(request.getEmailId());
            userRef.set(userMap).get();

            UserDto dto = new UserDto();
            dto.setEmailId(request.getEmailId());
            dto.setName(request.getName());
            dto.setPhoneNumber(request.getPhoneNumber());
            dto.setAddress(request.getAddress());
            dto.setBirthDate(request.getBirthDate());
            dto.setPhoneVerified(false);
            return dto;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Registration failed: " + e.getMessage(), e);
        }
    }

    public void verifyPhoneNumber(String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            CollectionReference users = db.collection("users");
            Query query = users.whereEqualTo("phoneNumber", phoneNumber);
            QuerySnapshot snapshot = query.get().get();
            if (snapshot.isEmpty()) throw new RuntimeException("Phone number not found");

            PhoneVerificationDto verification = phoneVerificationService.getVerification(phoneNumber);
            if (!verification.getVerificationCode().equals(verificationCode) ||
                    verification.getExpiresAt().before(new java.util.Date())) {
                throw new RuntimeException("Invalid or expired verification code");
            }

            DocumentReference userRef = snapshot.getDocuments().get(0).getReference();
            userRef.update("phoneVerified", true).get();

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Phone verification failed", e);
        }
    }

    public UserDto getUserInfo(String emailId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference ref = db.collection("users").document(emailId);
            DocumentSnapshot doc = ref.get().get();
            if (!doc.exists()) throw new RuntimeException("User not found");
            return doc.toObject(UserDto.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error fetching user info", e);
        }
    }

    public String findId(String name, String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users")
                    .whereEqualTo("name", name)
                    .whereEqualTo("phoneNumber", phoneNumber);
            QuerySnapshot snapshot = query.get().get();
            if (snapshot.isEmpty()) throw new RuntimeException("User not found");

            PhoneVerificationDto verification = phoneVerificationService.getVerification(phoneNumber);
            if (!verification.getVerificationCode().equals(verificationCode) ||
                    verification.getExpiresAt().before(new java.util.Date())) {
                throw new RuntimeException("Invalid or expired verification code");
            }

            return snapshot.getDocuments().get(0).getString("emailId");
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error finding ID", e);
        }
    }

    public String findPassword(String name, String emailId, String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore("zerowaste");
            Query query = db.collection("users")
                    .whereEqualTo("name", name)
                    .whereEqualTo("emailId", emailId)
                    .whereEqualTo("phoneNumber", phoneNumber);
            QuerySnapshot snapshot = query.get().get();
            if (snapshot.isEmpty()) throw new RuntimeException("User not found");

            PhoneVerificationDto verification = phoneVerificationService.getVerification(phoneNumber);
            if (!verification.getVerificationCode().equals(verificationCode) ||
                    verification.getExpiresAt().before(new java.util.Date())) {
                throw new RuntimeException("Invalid or expired verification code");
            }

            // 임시 비밀번호 생성 및 업데이트
            String tempPassword = java.util.UUID.randomUUID().toString().substring(0, 8);
            snapshot.getDocuments().get(0).getReference()
                    .update("password", tempPassword).get();
            return tempPassword;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error finding password", e);
        }
    }

    public String login(String emailId, String password) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users").whereEqualTo("emailId", emailId);
            QuerySnapshot snapshot = query.get().get();
            if (snapshot.isEmpty()) throw new RuntimeException("User not found");

            String storedPassword = snapshot.getDocuments().get(0).getString("password");
            if (!storedPassword.equals(password)) throw new RuntimeException("Invalid password");
            return "Login successful";
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Login failed", e);
        }
    }
}
