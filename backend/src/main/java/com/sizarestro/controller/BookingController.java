package com.sizarestro.controller;

import com.sizarestro.dto.BookingResponse;
import com.sizarestro.dto.ScanRequest;
import com.sizarestro.service.BookingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/booking")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping("/scan")
    public ResponseEntity<BookingResponse> scanAndBook(@RequestBody ScanRequest scanRequest) {
        BookingResponse response = bookingService.scanAndBookTable(scanRequest);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{bookingId}")
    public ResponseEntity<BookingResponse> getBooking(@PathVariable Long bookingId) {
        BookingResponse response = bookingService.getBooking(bookingId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{bookingId}/close")
    public ResponseEntity<BookingResponse> closeBooking(@PathVariable Long bookingId) {
        BookingResponse response = bookingService.closeBooking(bookingId);
        return ResponseEntity.ok(response);
    }
}
