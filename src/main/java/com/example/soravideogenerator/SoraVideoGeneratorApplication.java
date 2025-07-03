package com.example.soravideogenerator;

import com.example.soravideogenerator.config.EnvironmentConfig;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SoraVideoGeneratorApplication {

	public static void main(String[] args) {
		// Force loading of EnvironmentConfig to load .env file
		new EnvironmentConfig();
		SpringApplication.run(SoraVideoGeneratorApplication.class, args);
	}

}
