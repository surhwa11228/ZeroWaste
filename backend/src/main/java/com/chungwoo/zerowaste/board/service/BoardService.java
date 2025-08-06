package com.chungwoo.zerowaste.board.service;

import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
import com.chungwoo.zerowaste.board.boarddto.BoardSearchResponseDto;
import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import com.chungwoo.zerowaste.utils.StorageUploadUtils;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class BoardService {

    /** 게시글 작성 */
    public String post(MultipartFile image, BoardDto boardDto, String userId){
        Firestore db = FirestoreClient.getFirestore();

        // 🔹 Firestore 트랜잭션으로 auto-increment postId 생성
        Long postIdLong;
        try {
            DocumentReference counterRef = db.collection("counters").document("postId");
            postIdLong = db.runTransaction(transaction -> {
                DocumentSnapshot snapshot = transaction.get(counterRef).get();

                Long currentValue = snapshot.getLong("value");
                if (currentValue == null) currentValue = 0L;

                Long nextValue = currentValue + 1;
                transaction.set(counterRef, Collections.singletonMap("value", nextValue));

                return nextValue;
            }).get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("게시글 ID 생성 실패 (스레드 인터럽트)", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("게시글 ID 생성 실패", e);
        }

        String postId = String.valueOf(postIdLong);

        // 🔹 이미지 업로드 (null이면 기본값 처리)
        String imageUrl = null;
        try {
            if (image != null && !image.isEmpty()) {
                ImageUploadResult imageResponse = StorageUploadUtils.imageUpload(StorageUploadUtils.BOARD, image);
                imageUrl = imageResponse.getUrl();
            }
        } catch (Exception e) {
            System.out.println("⚠ 이미지 업로드 실패: " + e.getMessage());
        }

        // 🔹 Firestore에 저장할 Map
        Map<String, Object> post = new HashMap<>();
        post.put("id", postId);
        post.put("title", boardDto.getTitle());
        post.put("content", boardDto.getContent());
        post.put("imageUrl", imageUrl);
        post.put("userId", userId);
        post.put("scope", boardDto.getScope());
        post.put("category", boardDto.getCategory());
        post.put("createdAt", System.currentTimeMillis()); // ✅ Long으로 통일
        post.put("pinned", false);

        System.out.println("🔥 Firestore 저장 직전: " + post);

        try {
            // ✅ posts 컬렉션에 문서 생성 (컬렉션이 없으면 Firestore가 자동 생성)
            db.collection("posts").document(postId).set(post).get();
            System.out.println("✅ Firestore 저장 완료: posts/" + postId);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("게시글 저장 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("게시글 저장 실패: " + e.getMessage(), e);
        }

        return postId;
    }

    /** 게시글 목록 조회 */
    public List<BoardSearchResponseDto> getPosts(String category, String scope) {
        Firestore db = FirestoreClient.getFirestore();
        List<BoardSearchResponseDto> posts = new ArrayList<>();

        try {
            Query query = db.collection("posts")
                    .orderBy("createdAt", Query.Direction.DESCENDING);

            List<QueryDocumentSnapshot> docs = query.get().get().getDocuments();

            for (QueryDocumentSnapshot doc : docs) {
                Post post = doc.toObject(Post.class);

                if ((category == null || post.getCategory().equals(category)) &&
                        (scope == null || post.getScope().equals(scope))) {

                    posts.add(BoardSearchResponseDto.builder()
                            .id(post.getId())
                            .title(post.getTitle())
                            .content(post.getContent())
                            .category(post.getCategory())
                            .scope(post.getScope())
                            .imageUrl(post.getImageUrl())
                            .createdAt(post.getCreatedAt())
                            .pinned(post.isPinned())
                            .userId(post.getUserId())
                            .build());
                }
            }

            // 🔹 상단 고정글 우선 정렬
            posts.sort(Comparator.comparing(BoardSearchResponseDto::isPinned).reversed()
                    .thenComparing(BoardSearchResponseDto::getCreatedAt).reversed());

        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return posts;
    }

    /** 게시글 상세 조회 */
    public Post getPostById(String id) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentSnapshot doc = db.collection("posts").document(id).get().get();
            return doc.exists() ? doc.toObject(Post.class) : null;
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** 게시글 수정 */
    public Post updatePost(String id, MultipartFile image, BoardDto boardDto, String userId) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentReference ref = db.collection("posts").document(id);
            DocumentSnapshot snapshot = ref.get().get();

            if (!snapshot.exists()) throw new RuntimeException("게시글을 찾을 수 없음");
            Post oldPost = snapshot.toObject(Post.class);
            if (!oldPost.getUserId().equals(userId)) throw new RuntimeException("본인 글만 수정 가능");

            String imageUrl = oldPost.getImageUrl();
            if (image != null && !image.isEmpty()) {
                try {
                    ImageUploadResult imageResponse = StorageUploadUtils.imageUpload(StorageUploadUtils.BOARD, image);
                    imageUrl = imageResponse.getUrl();
                } catch (Exception e) {
                    System.out.println("⚠ 이미지 업로드 실패: " + e.getMessage());
                }
            }

            Post updatedPost = Post.builder()
                    .id(id)
                    .userId(userId)
                    .title(boardDto.getTitle())
                    .content(boardDto.getContent())
                    .category(boardDto.getCategory())
                    .scope(boardDto.getScope())
                    .imageUrl(imageUrl)
                    .createdAt(oldPost.getCreatedAt())
                    .pinned(oldPost.isPinned())
                    .build();

            ref.set(updatedPost).get(); // 동기 저장
            return updatedPost;

        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return null;
    }

    /** 게시글 삭제 */
    public void deletePost(String id, String userId) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentReference ref = db.collection("posts").document(id);
            DocumentSnapshot snapshot = ref.get().get();
            if (!snapshot.exists()) throw new RuntimeException("게시글 없음");

            Post post = snapshot.toObject(Post.class);
            if (!post.getUserId().equals(userId)) throw new RuntimeException("본인 글만 삭제 가능");

            ref.delete().get(); // 동기 삭제
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    public Comment addComment(String postId, CommentDto dto, String userId) {
        Firestore db = FirestoreClient.getFirestore();
        String commentId = UUID.randomUUID().toString();

        Comment comment = Comment.builder()
                .id(commentId)
                .userId(userId)
                .content(dto.getContent())
                .parentId(dto.getParentId())
                .createdAt(new Date(System.currentTimeMillis()))
                .build();

        try {
            db.collection("posts").document(postId)
                    .collection("comments").document(commentId)
                    .set(comment).get();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }

        return comment;
    }

    public List<Comment> getComments(String postId) {
        Firestore db = FirestoreClient.getFirestore();
        List<Comment> comments = new ArrayList<>();

        try {
            List<QueryDocumentSnapshot> docs = db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .get().get().getDocuments();

            for (QueryDocumentSnapshot doc : docs) {
                comments.add(doc.toObject(Comment.class));
            }

            comments.sort(Comparator.comparing(Comment::getCreatedAt).reversed());

        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return comments;
    }

    public void deleteComment(String postId, String commentId, String userId) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentReference commentRef = db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .document(commentId);

            DocumentSnapshot snapshot = commentRef.get().get();
            if (!snapshot.exists()) throw new RuntimeException("댓글 없음");

            Comment comment = snapshot.toObject(Comment.class);
            if (!comment.getUserId().equals(userId))
                throw new RuntimeException("본인 댓글만 삭제 가능");

            commentRef.delete().get();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }
}
