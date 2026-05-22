package com.sizarestro.repository;

import com.sizarestro.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByBookingIdOrderByCreatedAtDesc(Long bookingId);
    List<Notification> findByIsReadFalseOrderByCreatedAtDesc();
}
