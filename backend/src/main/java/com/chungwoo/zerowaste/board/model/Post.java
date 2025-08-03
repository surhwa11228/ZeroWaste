package com.chungwoo.zerowaste.board.model;

import lombok.*;

/**
 * 게시판의 개별 게시글(Post)을 표현하는 모델 클래스
 * Firestore 또는 DB에 저장될 게시글 데이터를 담기 위한 DTO/Entity 역할을 수행함
 */
@Getter  // Lombok 어노테이션: 모든 필드에 대한 Getter 메서드 자동 생성
@Setter  // Lombok 어노테이션: 모든 필드에 대한 Setter 메서드 자동 생성
@NoArgsConstructor  // Lombok 어노테이션: 파라미터 없는 기본 생성자 자동 생성
@AllArgsConstructor // Lombok 어노테이션: 모든 필드를 초기화하는 생성자 자동 생성
@Builder            // Lombok 어노테이션: Builder 패턴 사용 가능
public class Post {

    /**
     * 게시글 고유 ID
     * Firestore 문서 ID 또는 DB의 Primary Key 역할
     */
    private String id;

    /**
     * 작성자 고유 ID
     * Firebase Authentication의 UID와 매핑됨
     */
    private String userId;

    /**
     * 게시글 제목
     */
    private String title;

    /**
     * 게시글 본문 내용
     */
    private String content;

    /**
     * 게시글 카테고리
     * 예: "제보", "질문", "기타"
     */
    private String category;

    /**
     * 게시글 공개 범위 (지역/전체)
     * "지역" = 작성자 지역 한정, "전체" = 전체 사용자 열람 가능
     */
    private String scope;

    /**
     * 첨부 이미지 URL
     * Firebase Storage 등 외부 스토리지 경로 저장
     */
    private String imageUrl;

    /**
     * 게시글 작성 시간 (UNIX Timestamp, millisecond 단위)
     */
    private Long createdAt;

    /**
     * 상단 고정 여부
     * true면 게시판 목록에서 최상단에 노출되는 공지/중요글
     */
    private boolean pinned;
}