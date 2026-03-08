package com.horecastock.api.controller;

import com.horecastock.api.dto.ApiResponse;
import com.horecastock.api.dto.MermaRequest;
import com.horecastock.api.service.MermaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/mermas")
@RequiredArgsConstructor
public class MermaController {

    private final MermaService mermaService;

    @PostMapping
    public ResponseEntity<ApiResponse<Void>> registrarMerma(@RequestBody MermaRequest request) {
        mermaService.registrarMerma(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Merma registrada correctamente", null));
    }
}
