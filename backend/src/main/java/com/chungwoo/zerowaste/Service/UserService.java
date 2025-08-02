package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.PhoneVerificationDto;
import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    //private PhoneVerificationDto phoneVerificationDto;
    private PhoneVerificationService phoneVerificationService;
    // Register user in Firestore
    public UserDto registerUser(UserRegistrationRequest request) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            CollectionReference users = db.collection("users");

            // Check if email already exists
            Query query = users.whereEqualTo("emailId", request.getEmailId());
            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot querySnapshot = future.get();
            if (!querySnapshot.isEmpty()) {
                throw new RuntimeException("Email ID already exists");
            }

            // Prepare user data for Firestore
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("emailId", request.getEmailId());
            userMap.put("name", request.getName());
            userMap.put("phoneNumber", request.getPhoneNumber());
            userMap.put("address", request.getAddress());
            userMap.put("birthDate", request.getBirthDate());
            userMap.put("phoneVerified", false); // Initial state of phone verification

            // Save user data to Firestore
            DocumentReference userRef = db.collection("users").document(request.getEmailId());
            ApiFuture<WriteResult> writeResult = userRef.set(userMap);
            writeResult.get();  // Block until write is completed

            // Return the DTO with user details
            UserDto userDto = new UserDto();
            userDto.setEmailId(request.getEmailId());
            userDto.setName(request.getName());
            userDto.setPhoneNumber(request.getPhoneNumber());
            userDto.setAddress(request.getAddress());
            userDto.setBirthDate(request.getBirthDate());
            userDto.setPhoneVerified(false);  // Initially false until phone verification is done

            return userDto;

        } catch (InterruptedException | ExecutionException e) {
            // Logging the exception for more detailed information
            System.out.println("Error during registration: " + e.getMessage());
            throw new RuntimeException("Registration failed: " + e.getMessage(), e);
        }
    }

    // Verify phone number using verification code
    public void verifyPhoneNumber(String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            CollectionReference users = db.collection("users");

            // Find user by phone number
            Query query = users.whereEqualTo("phoneNumber", phoneNumber);
            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot querySnapshot = future.get();

            if (querySnapshot.isEmpty()) {
                throw new RuntimeException("Phone number not found");
            }

            DocumentSnapshot userDoc = querySnapshot.getDocuments().get(0);

            // Add logic to verify the verification code
            if (!isValidVerificationCode(verificationCode)) {
                throw new RuntimeException("Invalid verification code");
            }

            // Update user's phone verification status in Firestore
            userDoc.getReference().update("phoneVerified", true);

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Phone verification failed", e);
        }
    }

    // Mock-up of phone verification code validation (replace with actual logic)
    private boolean isValidVerificationCode(String verificationCode) {
        // Implement actual verification logic (e.g., compare against a sent code)
        return verificationCode.equals("1234");  // Dummy check for now
    }

    public UserDto getUserInfo(String emailId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference userRef = db.collection("users").document(emailId);
            ApiFuture<DocumentSnapshot> future = userRef.get();
            DocumentSnapshot document = future.get();

            if (document.exists()) {
                UserDto userDto = document.toObject(UserDto.class);  // Firestore의 document를 DTO로 변환
                return userDto;
            } else {
                throw new RuntimeException("User not found");
            }
        } catch (Exception e) {
            throw new RuntimeException("Error fetching user info", e);
        }
    }

    /*public String findId(String name, String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users")
                    .whereEqualTo("name", name)
                    .whereEqualTo("phoneNumber", phoneNumber);

            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot querySnapshot = future.get();

            if (!querySnapshot.isEmpty()) {
                DocumentSnapshot userDoc = querySnapshot.getDocuments().get(0);

                // 전화번호 인증 코드 검증
                PhoneVerificationDto phoneVerification = phoneVerificationService.getVerification(phoneNumber);
                if (!phoneVerification.getVerificationCode().equals(verificationCode)) {
                    throw new RuntimeException("Invalid verification code");
                }

                return userDoc.getString("emailId"); // 아이디 반환
            } else {
                throw new RuntimeException("User not found");
            }
        } catch (Exception e) {
            throw new RuntimeException("Error finding ID", e);
        }
    }*/


    /*public String findPassword(String name, String emailId, String phoneNumber, String verificationCode) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users")
                    .whereEqualTo("name", name)
                    .whereEqualTo("emailId", emailId)
                    .whereEqualTo("phoneNumber", phoneNumber);

            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot querySnapshot = future.get();

            if (!querySnapshot.isEmpty()) {
                DocumentSnapshot userDoc = querySnapshot.getDocuments().get(0);
                // 전화번호 인증 코드 검증
                PhoneVerificationDto phoneVerification = phoneVerificationService.getVerification(phoneNumber);
                if (!phoneVerification.getVerificationCode().equals(verificationCode)) {
                    throw new RuntimeException("Invalid verification code");
                }

                // 임시 비밀번호 발급하여 반환 (예시: "temporaryPassword123")
                String tempPassword = "temporaryPassword123";
                // 비밀번호를 안전하게 처리하고 Firestore에 업데이트하는 코드가 필요
                return tempPassword;
            } else {
                throw new RuntimeException("User not found");
            }
        } catch (Exception e) {
            throw new RuntimeException("Error finding password", e);
        }
    }*/

    public String login(String emailId, String password) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users")
                    .whereEqualTo("emailId", emailId);

            ApiFuture<QuerySnapshot> future = query.get();
            QuerySnapshot querySnapshot = future.get();

            if (!querySnapshot.isEmpty()) {
                DocumentSnapshot userDoc = querySnapshot.getDocuments().get(0);
                String storedPassword = userDoc.getString("password"); // 암호화된 비밀번호 가져오기
                if (storedPassword.equals(password)) { // 실제 환경에서는 비밀번호를 암호화하여 비교해야 함
                    return "Login successful"; // 토큰 발급 로직 필요
                } else {
                    throw new RuntimeException("Invalid password");
                }
            } else {
                throw new RuntimeException("User not found");
            }
        } catch (Exception e) {
            throw new RuntimeException("Login failed", e);
        }
    }



}



