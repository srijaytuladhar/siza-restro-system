package com.sizarestro.service;

import com.sizarestro.dto.TableRequest;
import com.sizarestro.dto.TableResponse;
import com.sizarestro.entity.TableEntity;
import com.sizarestro.entity.TableStatus;
import com.sizarestro.exception.BadRequestException;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.mapper.TableMapper;
import com.sizarestro.repository.TableRepository;
import com.sizarestro.repository.BookingRepository;
import com.sizarestro.entity.BookingStatus;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TableService {

    private final TableRepository tableRepository;
    private final TableMapper tableMapper;
    private final BookingRepository bookingRepository;

    public List<TableResponse> getAllTables() {
        log.info("Fetching all tables");
        return tableRepository.findAll().stream()
                .map(this::mapToResponseWithQr)
                .collect(Collectors.toList());
    }

    public TableResponse getTableById(Long id) {
        TableEntity table = tableRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with id: " + id));
        return mapToResponseWithQr(table);
    }

    public TableResponse getTableByToken(String token) {
        log.info("Looking up table with token: {}", token);
        TableEntity table = tableRepository.findByQrCodeToken(token)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with QR token: " + token));
        return mapToResponseWithQr(table);
    }

    @Transactional
    public TableResponse createTable(TableRequest request) {
        log.info("Creating table number: {}", request.getTableNumber());
        if (tableRepository.findByTableNumber(request.getTableNumber()).isPresent()) {
            throw new BadRequestException("Table number '" + request.getTableNumber() + "' already exists");
        }

        TableEntity table = tableMapper.toEntity(request);
        table.setQrCodeToken(UUID.randomUUID().toString());
        table.setStatus(TableStatus.AVAILABLE);

        TableEntity savedTable = tableRepository.save(table);
        log.info("Table created with ID: {} and QR Token: {}", savedTable.getId(), savedTable.getQrCodeToken());
        return mapToResponseWithQr(savedTable);
    }

    @Transactional
    public TableResponse updateTable(Long id, TableRequest request) {
        log.info("Updating table: {}", id);
        TableEntity table = tableRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with id: " + id));

        tableRepository.findByTableNumber(request.getTableNumber()).ifPresent(existing -> {
            if (!existing.getId().equals(id)) {
                throw new BadRequestException("Table number '" + request.getTableNumber() + "' already exists");
            }
        });

        table.setTableNumber(request.getTableNumber());
        table.setCapacity(request.getCapacity());
        TableEntity updatedTable = tableRepository.save(table);
        return mapToResponseWithQr(updatedTable);
    }

    @Transactional
    public void deleteTable(Long id) {
        log.info("Deleting table: {}", id);
        TableEntity table = tableRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with id: " + id));
        tableRepository.delete(table);
    }

    @Transactional
    public TableResponse releaseTable(Long id) {
        log.info("Releasing table: {}", id);
        TableEntity table = tableRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Table not found with id: " + id));

        // Find and close any active bookings for this table
        bookingRepository.findByTableIdAndStatus(id, BookingStatus.ACTIVE).ifPresent(booking -> {
            booking.setStatus(BookingStatus.CLOSED);
            bookingRepository.save(booking);
            log.info("Closed active booking {} for table {}", booking.getId(), table.getTableNumber());
        });

        table.setStatus(TableStatus.AVAILABLE);
        TableEntity updatedTable = tableRepository.save(table);
        return mapToResponseWithQr(updatedTable);
    }

    private TableResponse mapToResponseWithQr(TableEntity table) {
        TableResponse response = tableMapper.toResponse(table);
        String qrPayload = "siza-restro://table/scan?token=" + table.getQrCodeToken();
        response.setQrCodeBase64(generateQRCodeBase64(qrPayload));
        return response;
    }

    private String generateQRCodeBase64(String text) {
        try {
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, 300, 300);
            
            ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
            byte[] pngData = pngOutputStream.toByteArray();
            return Base64.getEncoder().encodeToString(pngData);
        } catch (Exception e) {
            log.error("Failed to generate QR Code image", e);
            return null;
        }
    }
}
