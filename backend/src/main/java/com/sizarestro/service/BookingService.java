package com.sizarestro.service;

import com.sizarestro.dto.BookingResponse;
import com.sizarestro.dto.ScanRequest;
import com.sizarestro.entity.Booking;
import com.sizarestro.entity.BookingStatus;
import com.sizarestro.entity.TableEntity;
import com.sizarestro.entity.TableStatus;
import com.sizarestro.exception.BadRequestException;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.repository.BookingRepository;
import com.sizarestro.repository.TableRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Service
@RequiredArgsConstructor
@Slf4j
public class BookingService {

    private final TableRepository tableRepository;
    private final BookingRepository bookingRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public BookingResponse scanAndBookTable(ScanRequest scanRequest) {
        log.info("Processing scan and book request for qrCodeToken: {}, userId: {}", scanRequest.getQrCodeToken(), scanRequest.getUserId());
        
        TableEntity table = tableRepository.findByQrCodeToken(scanRequest.getQrCodeToken())
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with QR token: " + scanRequest.getQrCodeToken()));

        // Check if there is already an active booking for this table
        Booking activeBooking = bookingRepository.findByTableIdAndStatus(table.getId(), BookingStatus.ACTIVE).orElse(null);

        if (activeBooking != null) {
            // If the active booking is by the same user, treat it as reconnecting/restoring the session
            if (activeBooking.getUserId().equals(scanRequest.getUserId())) {
                log.info("User {} already has an active booking {} for table {}. Restoring session.", 
                        scanRequest.getUserId(), activeBooking.getId(), table.getTableNumber());
                
                // Ensure table status is in sync
                if (table.getStatus() != TableStatus.OCCUPIED) {
                    table.setStatus(TableStatus.OCCUPIED);
                    tableRepository.save(table);
                }
                
                return mapToResponse(activeBooking);
            } else {
                throw new BadRequestException("Table " + table.getTableNumber() + " is currently occupied.");
            }
        }

        // If table is occupied by status but booking not found (inconsistent state), reset table status
        if (table.getStatus() == TableStatus.OCCUPIED) {
            log.warn("Table {} was marked as OCCUPIED, but no active booking was found in the database. Resetting table status.", table.getTableNumber());
        }

        // Create new active booking
        table.setStatus(TableStatus.OCCUPIED);
        tableRepository.save(table);

        Booking booking = Booking.builder()
                .table(table)
                .userId(scanRequest.getUserId())
                .status(BookingStatus.ACTIVE)
                .build();
        
        Booking savedBooking = bookingRepository.save(booking);
        log.info("Table {} successfully booked. Booking ID: {}", table.getTableNumber(), savedBooking.getId());
        
        messagingTemplate.convertAndSend("/topic/tables", java.util.Collections.singletonMap("status", "updated"));
        return mapToResponse(savedBooking);
    }

    public BookingResponse getBooking(Long bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));
        return mapToResponse(booking);
    }

    @Transactional
    public BookingResponse closeBooking(Long bookingId) {
        log.info("Closing bookingId: {}", bookingId);
        Booking booking = bookingRepository.findByIdAndStatus(bookingId, BookingStatus.ACTIVE)
                .orElseThrow(() -> new ResourceNotFoundException("Active booking not found with id: " + bookingId));
        
        booking.setStatus(BookingStatus.CLOSED);
        TableEntity table = booking.getTable();
        table.setStatus(TableStatus.AVAILABLE);
        tableRepository.save(table);
        
        Booking closedBooking = bookingRepository.save(booking);
        log.info("Booking {} closed successfully. Table {} is now AVAILABLE.", bookingId, table.getTableNumber());
        
        messagingTemplate.convertAndSend("/topic/tables", java.util.Collections.singletonMap("status", "updated"));
        return mapToResponse(closedBooking);
    }

    private BookingResponse mapToResponse(Booking booking) {
        return BookingResponse.builder()
                .id(booking.getId())
                .tableId(booking.getTable().getId())
                .tableNumber(booking.getTable().getTableNumber())
                .userId(booking.getUserId())
                .status(booking.getStatus())
                .createdAt(booking.getCreatedAt())
                .build();
    }
}
