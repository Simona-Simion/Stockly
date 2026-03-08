package com.stockly.api.controller;

import com.stockly.api.dto.ApiResponse;
import com.stockly.api.dto.MermaRequest;
import com.stockly.api.service.MermaService;
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
