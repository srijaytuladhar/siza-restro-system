package com.sizarestro.repository;

import com.sizarestro.entity.Booking;
import com.sizarestro.entity.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Long> {
    Optional<Booking> findByTableIdAndStatus(Long tableId, BookingStatus status);
    Optional<Booking> findByIdAndStatus(Long id, BookingStatus status);
    boolean existsByTableIdAndStatus(Long tableId, BookingStatus status);
}
