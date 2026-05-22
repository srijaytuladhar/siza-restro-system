package com.sizarestro.controller;

import com.sizarestro.dto.NotificationResponse;
import com.sizarestro.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notification")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/booking/{bookingId}")
    public ResponseEntity<List<NotificationResponse>> getNotificationsByBooking(@PathVariable Long bookingId) {
        List<NotificationResponse> notifications = notificationService.getNotificationsByBooking(bookingId);
        return ResponseEntity.ok(notifications);
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable Long id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok().build();
    }
}
