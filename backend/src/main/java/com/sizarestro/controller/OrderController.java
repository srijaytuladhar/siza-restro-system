package com.sizarestro.controller;

import com.sizarestro.dto.OrderRequest;
import com.sizarestro.dto.OrderResponse;
import com.sizarestro.dto.OrderStatusUpdateRequest;
import com.sizarestro.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/order")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<OrderResponse> placeOrder(@RequestBody OrderRequest orderRequest) {
        OrderResponse response = orderService.placeOrder(orderRequest);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<List<OrderResponse>> getAllOrders() {
        List<OrderResponse> response = orderService.getAllOrders();
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable Long orderId) {
        OrderResponse response = orderService.getOrder(orderId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/booking/{bookingId}")
    public ResponseEntity<List<OrderResponse>> getOrdersByBooking(@PathVariable Long bookingId) {
        List<OrderResponse> response = orderService.getOrdersByBooking(bookingId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{orderId}/status")
    public ResponseEntity<OrderResponse> updateOrderStatus(
            @PathVariable Long orderId, 
            @RequestBody OrderStatusUpdateRequest statusRequest) {
        OrderResponse response = orderService.updateOrderStatus(orderId, statusRequest.getStatus());
        return ResponseEntity.ok(response);
    }
}
