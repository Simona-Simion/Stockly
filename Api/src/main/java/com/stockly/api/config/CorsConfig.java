package com.stockly.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Configuration
public class CorsConfig {


    // Permitimos desarrollo local y Firebase Hosting.
    // Se puede sobreescribir con cors.allowed.origins en properties o variable de entorno.
    @Value("${cors.allowed.origins:http://localhost:*,http://127.0.0.1:*,https://stockly-app-c232d.web.app}")
    private String allowedOriginsRaw;

    @Bean
    public CorsFilter corsFilter() {
        CorsConfiguration config = new CorsConfiguration();


        // Necesario para peticiones con Authorization y credenciales.
        config.setAllowCredentials(true);


        List<String> origenes = Arrays.stream(allowedOriginsRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());


        //  patterns porque localhost cambia de puerto en Flutter web.
        config.setAllowedOriginPatterns(origenes);

        config.setAllowedHeaders(Arrays.asList(
                "Origin",
                "Content-Type",
                "Accept",
                "Authorization"
        ));

        config.setAllowedMethods(Arrays.asList(
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "OPTIONS",
                "PATCH"
        ));

        config.setExposedHeaders(Arrays.asList(
                "Content-Type",
                "Authorization",
                "X-Total-Count"
        ));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();


        // Aplica CORS a toda la API.
        source.registerCorsConfiguration("/api/**", config);

        return new CorsFilter(source);
    }
}