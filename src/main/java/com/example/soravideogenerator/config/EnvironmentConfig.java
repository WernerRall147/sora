package com.example.soravideogenerator.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration class to load environment variables from .env file
 * This class has a static block that loads the .env file before Spring Boot starts
 */
@Configuration
public class EnvironmentConfig {

    static {
        try {
            Dotenv dotenv = Dotenv.configure()
                    .directory(".")
                    .filename(".env")
                    .ignoreIfMissing()
                    .load();
            
            // Set system properties from .env file
            dotenv.entries().forEach(entry -> {
                String key = entry.getKey();
                String value = entry.getValue();
                
                // Only set if not already set by system environment
                if (System.getProperty(key) == null && System.getenv(key) == null) {
                    System.setProperty(key, value);
                }
            });
            
            System.out.println("Loaded environment variables from .env file");
        } catch (Exception e) {
            System.err.println("Warning: Could not load .env file: " + e.getMessage());
        }
    }
}
