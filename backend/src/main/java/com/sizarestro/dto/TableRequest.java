package com.sizarestro.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TableRequest {
    @NotBlank(message = "Table number is required")
    private String tableNumber;
    
    @Min(value = 1, message = "Capacity must be at least 1")
    private Integer capacity;
}
