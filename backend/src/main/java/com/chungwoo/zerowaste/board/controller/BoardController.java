package com.chungwoo.zerowaste.board.controller;

import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
import com.chungwoo.zerowaste.board.service.BoardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;

    // ==================== 📌 게시글 CRUD ====================

    /** 게시글 작성 */
    @PostMapping("/post")
    public ResponseEntity<?> createPost(
            @RequestPart("image") MultipartFile image,
            @RequestPart("post") BoardDto boardDto,
            @AuthenticationPrincipal String userId) throws IOException {

        //test
        String testUid;
        if(userId == null){
            testUid = "testUid";
        }
        else {
            testUid = userId;
        }

        String postId = boardService.post(image, boardDto, testUid);
        return ResponseEntity.ok(postId);
    }

    /** 게시글 목록 조회 */
    @GetMapping
    public ResponseEntity<List<Post>> getAllPosts(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String scope) {
        return ResponseEntity.ok(boardService.getPosts(category, scope));
    }

    /** 게시글 상세 조회 */
    @GetMapping("/{id}")
    public ResponseEntity<Post> getPost(@PathVariable String id) {
        return ResponseEntity.ok(boardService.getPostById(id));
    }

    /** 게시글 수정 */
    @PostMapping("/update/{id}")
    public ResponseEntity<Post> updatePost(
            @PathVariable String id,
            @RequestPart(value = "image", required = false) MultipartFile image,
            @RequestPart(value = "post") BoardDto boardDto,
            @AuthenticationPrincipal AuthUserDetails user) throws IOException {

        return ResponseEntity.ok(boardService.updatePost(id, image, boardDto, user.getUid()));
    }

    /** 게시글 삭제 */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<String> deletePost(
            @PathVariable String id,
            @AuthenticationPrincipal AuthUserDetails user) throws IOException {

        boardService.deletePost(id, user.getUid());
        return ResponseEntity.ok("게시글이 삭제되었습니다.");
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    /** 댓글 작성 */
    @PostMapping("/{postId}/comments")
    public ResponseEntity<Comment> addComment(
            @PathVariable String postId,
            @RequestBody CommentDto commentDto,
            @AuthenticationPrincipal AuthUserDetails user) throws IOException {

        return ResponseEntity.ok(boardService.addComment(postId, commentDto, user.getUid()));
    }

    /** 댓글 목록 조회 */
    @GetMapping("/{postId}/comments")
    public ResponseEntity<List<Comment>> getComments(@PathVariable String postId) {
        return ResponseEntity.ok(boardService.getComments(postId));
    }

    /** 댓글 삭제 (본인만) */
    @DeleteMapping("/{postId}/comments/{commentId}")
    public ResponseEntity<String> deleteComment(
            @PathVariable String postId,
            @PathVariable String commentId,
            @AuthenticationPrincipal AuthUserDetails user) throws IOException {

        boardService.deleteComment(postId, commentId, user.getUid());
        return ResponseEntity.ok("댓글이 삭제되었습니다.");
    }
}
