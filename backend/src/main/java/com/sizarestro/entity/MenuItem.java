package com.sizarestro.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "menu_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MenuItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "category_id", nullable = false)
    private MenuCategory category;

    @Column(name = "is_available", nullable = false)
    private boolean isAvailable = true;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "estimated_prep_time", nullable = false)
    private Integer estimatedPrepTime = 15; // default 15 mins

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}
