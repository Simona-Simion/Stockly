package com.stockly.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.credentials.path}")
    private String credentialsPath;

    private final ResourceLoader resourceLoader;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    // Inicializa el SDK de Firebase Admin al arrancar la aplicación.
    // Si el archivo de credenciales no existe, Firebase queda desactivado
    // pero la app sigue funcionando (las notificaciones simplemente no se envían).
    @PostConstruct
    public void initialize() {
        if (!FirebaseApp.getApps().isEmpty()) return;

        try {
            Resource resource = resourceLoader.getResource(credentialsPath);
            GoogleCredentials credentials = GoogleCredentials.fromStream(resource.getInputStream());

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();

            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK inicializado correctamente");

        } catch (Exception e) {
            log.warn("Firebase Admin SDK no inicializado (credenciales no encontradas): {}", e.getMessage());
        }
    }
}
