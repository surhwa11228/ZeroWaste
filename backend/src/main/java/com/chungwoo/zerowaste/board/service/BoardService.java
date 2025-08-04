package com.chungwoo.zerowaste.board.service;

import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
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

    // ==================== 📌 게시글 CRUD ====================

    /** 게시글 작성 */
    public String post(MultipartFile image, BoardDto boardDto, String userId) throws IOException {
        Firestore db = FirestoreClient.getFirestore("zerowaste");
        String postId = UUID.randomUUID().toString(); //postId는 auto increase Number 구현해서 그거 참조

        //Test
        String testUid = "testUid";

        ImageUploadResult imageResponse = StorageUploadUtils.imageUpload(StorageUploadUtils.BOARD, image);
        String imageUrl = imageResponse.getUrl();


        //매핑 완성하기*****************
        Map<String, Object> post = new HashMap<>();
        post.put("id", postId);
        post.put("title", boardDto.getTitle());
        post.put("content", boardDto.getContent());
        post.put("imageUrl", imageUrl);
        post.put("userId", userId);
        post.put("scope", boardDto.getScope());


//        Post post = Post.builder()
//                .id(postId)
//                .userId(testUid)//test
//                .title(boardDto.getTitle())
//                .content(boardDto.getContent())
//                .category(boardDto.getCategory())
//                .scope(boardDto.getScope())
//                .imageUrl(imageUrl)
//                .createdAt(System.currentTimeMillis())
//                .pinned(false)
//                .build();

        db.collection("posts").document(postId).set(post);
        return postId;
    }

    /** 게시글 목록 조회 (카테고리·스코프 필터링 + 고정글 우선) */
    //List<Post>가 아니라 별도의 dto 구현 (예 BoardSearchResponse)
    public List<Post> getPosts(String category, String scope) {
        Firestore db = FirestoreClient.getFirestore();
        List<Post> posts = new ArrayList<>();

        try {
            List<QueryDocumentSnapshot> docs = db.collection("posts").get().get().getDocuments();
            for (QueryDocumentSnapshot doc : docs) {
                Post post = doc.toObject(Post.class);
                if ((category == null || post.getCategory().equals(category)) &&
                        (scope == null || post.getScope().equals(scope))) {
                    posts.add(post);
                }
            }

            // 상단 고정글 우선 정렬 → 최신순
            posts.sort(Comparator.comparing(Post::isPinned).reversed()
                    .thenComparing(Post::getCreatedAt).reversed());

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

            // (추후 이미지 업데이트 로직 추가)
            String imageUrl = (image != null) ? "uploaded/image/path" : oldPost.getImageUrl();

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

            ref.set(updatedPost);
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

            ref.delete();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    /** 댓글 작성 */
    public Comment addComment(String postId, CommentDto dto, String userId) {
        Firestore db = FirestoreClient.getFirestore();
        String commentId = UUID.randomUUID().toString();

        Comment comment = Comment.builder()
                .id(commentId)
                .userId(userId)
                .content(dto.getContent())
                .parentId(dto.getParentId())
                .createdAt(System.currentTimeMillis())
                .build();

        db.collection("posts").document(postId)
                .collection("comments").document(commentId).set(comment);

        return comment;
    }

    /** 댓글 목록 조회 */
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

            // 최신순 정렬
            comments.sort(Comparator.comparing(Comment::getCreatedAt).reversed());

        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        return comments;
    }

    /** 댓글 삭제 (본인만) */
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

            commentRef.delete();
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
    }
}
