package com.example.soravideogenerator.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.ExchangeStrategies;

/**
 * Configuration for Azure OpenAI WebClient and application settings
 */
@Configuration
public class AzureOpenAIConfig {
    
    @Value("${azure.openai.endpoint}")
    private String azureOpenAIEndpoint;
    
    @Value("${azure.openai.api-key}")
    private String azureOpenAIApiKey;
    
    @Value("${azure.openai.api-version:preview}")
    private String apiVersion;
    
    @Bean
    public WebClient azureOpenAIWebClient() {
        // Configure larger memory size for handling video responses
        ExchangeStrategies strategies = ExchangeStrategies.builder()
            .codecs(codecs -> codecs.defaultCodecs().maxInMemorySize(10 * 1024 * 1024)) // 10MB
            .build();
            
        return WebClient.builder()
            .baseUrl(azureOpenAIEndpoint)
            .defaultHeader("Content-Type", "application/json")
            .defaultHeader("Api-key", azureOpenAIApiKey)
            .exchangeStrategies(strategies)
            .build();
    }
    
    public String getApiVersion() {
        return apiVersion;
    }
}
