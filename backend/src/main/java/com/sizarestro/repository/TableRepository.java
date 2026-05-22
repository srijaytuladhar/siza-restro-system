package com.sizarestro.repository;

import com.sizarestro.entity.TableEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface TableRepository extends JpaRepository<TableEntity, Long> {
    Optional<TableEntity> findByTableNumber(String tableNumber);
    Optional<TableEntity> findByQrCodeToken(String qrCodeToken);
}
