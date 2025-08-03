package com.chungwoo.zerowaste.board.model;

import lombok.*;

/**
 * 게시판 댓글(Comment)을 표현하는 모델 클래스
 * - 단일 댓글뿐만 아니라 대댓글(답글)까지 표현 가능
 * - Firestore 또는 DB에 저장될 댓글 데이터를 담기 위한 DTO/Entity 역할
 */
@Getter              // Lombok: 모든 필드에 대한 Getter 메서드 자동 생성
@Setter              // Lombok: 모든 필드에 대한 Setter 메서드 자동 생성
@NoArgsConstructor   // Lombok: 파라미터 없는 기본 생성자 자동 생성
@AllArgsConstructor  // Lombok: 모든 필드를 초기화하는 생성자 자동 생성
@Builder             // Lombok: Builder 패턴 사용 가능
public class Comment {

    /**
     * 댓글 고유 ID
     * Firestore 문서 ID 또는 DB의 Primary Key 역할
     */
    private String id;

    /**
     * 댓글 작성자 고유 ID
     * Firebase Authentication의 UID와 매핑됨
     */
    private String userId;

    /**
     * 댓글 본문 내용
     */
    private String content;

    /**
     * 부모 댓글 ID
     * - 일반 댓글: null
     * - 대댓글(답글): 부모 댓글의 ID 값
     * 이를 통해 트리 구조 형태로 댓글/대댓글을 구현 가능
     */
    private String parentId;

    /**
     * 댓글 작성 시간 (UNIX Timestamp, millisecond 단위)
     */
    private Long createdAt;
}
