package com.sizarestro.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderRequest {
    private Long bookingId;
    private List<OrderItemRequest> items;
    private String specialInstructions;
}
