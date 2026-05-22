package com.sizarestro.controller;

import com.sizarestro.dto.TableRequest;
import com.sizarestro.dto.TableResponse;
import com.sizarestro.service.TableService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/table")
@RequiredArgsConstructor
public class TableController {

    private final TableService tableService;

    @GetMapping
    public ResponseEntity<List<TableResponse>> getAllTables() {
        return ResponseEntity.ok(tableService.getAllTables());
    }

    @GetMapping("/{id}")
    public ResponseEntity<TableResponse> getTableById(@PathVariable Long id) {
        return ResponseEntity.ok(tableService.getTableById(id));
    }

    // Public lookup endpoint for scanned QR code token
    @GetMapping("/scan/{token}")
    public ResponseEntity<TableResponse> getTableByToken(@PathVariable String token) {
        TableResponse response = tableService.getTableByToken(token);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    public ResponseEntity<TableResponse> createTable(@Valid @RequestBody TableRequest request) {
        TableResponse created = tableService.createTable(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TableResponse> updateTable(@PathVariable Long id, @Valid @RequestBody TableRequest request) {
        TableResponse updated = tableService.updateTable(id, request);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTable(@PathVariable Long id) {
        tableService.deleteTable(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/release")
    public ResponseEntity<TableResponse> releaseTable(@PathVariable Long id) {
        TableResponse released = tableService.releaseTable(id);
        return ResponseEntity.ok(released);
    }
}
