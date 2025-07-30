package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

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
            throw new RuntimeException("Registration failed", e);
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
}



