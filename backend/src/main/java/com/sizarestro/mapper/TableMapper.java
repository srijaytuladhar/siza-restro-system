package com.sizarestro.mapper;

import com.sizarestro.dto.TableRequest;
import com.sizarestro.dto.TableResponse;
import com.sizarestro.entity.TableEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface TableMapper {
    @Mapping(target = "qrCodeBase64", ignore = true)
    TableResponse toResponse(TableEntity table);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "qrCodeToken", ignore = true)
    @Mapping(target = "status", ignore = true)
    TableEntity toEntity(TableRequest request);
}
