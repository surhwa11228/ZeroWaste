package com.chungwoo.zerowaste.board.model;

import lombok.*;

/**
 * 게시판 댓글(Comment)을 표현하는 모델 클래스
 * - 단일 댓글뿐만 아니라 대댓글(답글)까지 표현 가능
 * - Firestore 또는 DB에 저장될 댓글 데이터를 담기 위한 DTO/Entity 역할
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
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
    private String uid;

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
     * 댓글 작성 시간 (Date)
     * Firestore에 저장 시 Timestamp로 자동 변환됨
     */
    private Long createdAt;
}
