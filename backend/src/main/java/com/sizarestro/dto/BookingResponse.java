package com.sizarestro.dto;

import com.sizarestro.entity.BookingStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookingResponse {
    private Long id;
    private Long tableId;
    private String tableNumber;
    private String userId;
    private BookingStatus status;
    private LocalDateTime createdAt;
}
