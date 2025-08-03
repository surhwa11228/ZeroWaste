package com.chungwoo.zerowaste.board.controller;

import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.service.BoardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 게시판 컨트롤러
 * - 게시글/댓글 CRUD API를 제공
 * - URL prefix: /api/board
 * - JSON 요청/응답 기반
 */
@RestController
@RequestMapping("/api/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;

    /** ----------------- 게시글 CRUD ----------------- **/

    /**
     * 게시글 작성 API
     * - POST /api/board
     * - 이미지 + JSON(BoardDto) multipart 요청 처리
     * - 헤더에서 userId(작성자 UID) 전달
     */
    @PostMapping
    public ResponseEntity<Post> createPost(
            @RequestPart(value = "image", required = false) MultipartFile image,
            @RequestPart("post") BoardDto boardDto,
            @AuthenticationPrincipal AuthUser user
    ) {
        Post savedPost = boardService.post(image, boardDto, userId);
        return ResponseEntity.ok(savedPost);
    }

    /**
     * 게시글 목록 조회 API
     * - GET /api/board
     * - optional query params: category, scope, keyword
     * - 예시: /api/board?category=제보&scope=전체&keyword=쓰레기
     */
    @GetMapping
    public ResponseEntity<List<Post>> getPosts(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String scope,
            @RequestParam(required = false) String keyword
    ) {
        return ResponseEntity.ok(boardService.getPosts(category, scope, keyword));
    }

    /**
     * 게시글 상세 조회 API
     * - GET /api/board/{id}
     * - 존재하지 않으면 404 Not Found 반환
     */
    @GetMapping("/{id}")
    public ResponseEntity<Post> getPost(@PathVariable String id) {
        Post post = boardService.getPost(id);
        return (post != null) ? ResponseEntity.ok(post) : ResponseEntity.notFound().build();
    }

    /**
     * 게시글 수정 API
     * - PUT /api/board/{id}
     * - 요청 body: BoardDto(JSON)
     */
    @PutMapping("/{id}")
    public ResponseEntity<Post> updatePost(
            @PathVariable String id,
            @RequestBody BoardDto boardDto
    ) {
        return ResponseEntity.ok(boardService.updatePost(id, boardDto));
    }

    /**
     * 게시글 삭제 API
     * - DELETE /api/board/{id}
     * - 성공 시 단순 메시지 반환
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deletePost(@PathVariable String id) {
        boardService.deletePost(id);
        return ResponseEntity.ok("게시글 삭제 완료: " + id);
    }

    /** ----------------- 댓글 CRUD ----------------- **/

    /**
     * 댓글 작성 API
     * - POST /api/board/{postId}/comments
     * - 요청 body: CommentDto(JSON)
     */
    @PostMapping("/{postId}/comments")
    public ResponseEntity<Comment> addComment(
            @PathVariable String postId,
            @RequestBody CommentDto commentDto
    ) {
        return ResponseEntity.ok(boardService.addComment(postId, commentDto));
    }

    /**
     * 댓글 목록 조회 API
     * - GET /api/board/{postId}/comments
     * - 작성 시간순 정렬
     */
    @GetMapping("/{postId}/comments")
    public ResponseEntity<List<Comment>> getComments(@PathVariable String postId) {
        return ResponseEntity.ok(boardService.getComments(postId));
    }

    /**
     * 댓글 삭제 API
     * - DELETE /api/board/{postId}/comments/{commentId}
     * - 성공 시 단순 메시지 반환
     */
    @DeleteMapping("/{postId}/comments/{commentId}")
    public ResponseEntity<String> deleteComment(
            @PathVariable String postId,
            @PathVariable String commentId
    ) {
        boardService.deleteComment(postId, commentId);
        return ResponseEntity.ok("댓글이 삭제되었습니다: " + commentId);
    }
}
