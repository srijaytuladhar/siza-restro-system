package com.sizarestro.service;

import com.sizarestro.dto.NotificationResponse;
import com.sizarestro.entity.*;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.mapper.NotificationMapper;
import com.sizarestro.repository.BookingRepository;
import com.sizarestro.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final BookingRepository bookingRepository;
    private final NotificationMapper notificationMapper;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public NotificationResponse sendNotification(Long bookingId, String title, String message, NotificationType type) {
        log.info("Sending notification: bookingId={}, title={}, type={}", bookingId, title, type);
        
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        Notification notification = Notification.builder()
                .booking(booking)
                .title(title)
                .message(message)
                .type(type)
                .isRead(false)
                .build();

        Notification saved = notificationRepository.save(notification);
        NotificationResponse response = notificationMapper.toResponse(saved);

        // Broadcast to general notification topic (e.g. for admin/staff dashboard)
        messagingTemplate.convertAndSend("/topic/notifications", response);
        
        // Broadcast to specific customer booking channel (Flutter app)
        messagingTemplate.convertAndSend("/topic/booking/" + bookingId + "/notifications", response);

        return response;
    }

    public List<NotificationResponse> getNotificationsByBooking(Long bookingId) {
        return notificationRepository.findByBookingIdOrderByCreatedAtDesc(bookingId).stream()
                .map(notificationMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void markAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with id: " + notificationId));
        notification.setRead(true);
        notificationRepository.save(notification);
    }
}
