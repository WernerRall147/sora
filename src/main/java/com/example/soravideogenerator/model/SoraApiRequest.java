package com.example.soravideogenerator.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Request model for Azure OpenAI Sora API
 */
public class SoraApiRequest {
    
    private final String model = "sora";
    private final String height = "1080";
    private final String width = "1080";
    @JsonProperty("n_seconds")
    private final String nSeconds = "5";
    @JsonProperty("n_variants")
    private final String nVariants = "1";
    
    private String prompt;
    
    public SoraApiRequest() {}
    
    public SoraApiRequest(String prompt) {
        this.prompt = prompt;
    }
    
    public String getModel() {
        return model;
    }
    
    public String getHeight() {
        return height;
    }
    
    public String getWidth() {
        return width;
    }
    
    public String getNSeconds() {
        return nSeconds;
    }
    
    public String getNVariants() {
        return nVariants;
    }
    
    public String getPrompt() {
        return prompt;
    }
    
    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }
}
