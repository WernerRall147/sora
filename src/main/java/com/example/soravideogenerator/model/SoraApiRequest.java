package com.example.soravideogenerator.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Request model for Azure OpenAI Sora API
 */
public class SoraApiRequest {
    
    private final String model = "sora";
    private String height;
    private String width;
    @JsonProperty("n_seconds")
    private String nSeconds;
    @JsonProperty("n_variants")
    private final String nVariants = "1";
    
    private String prompt;
    
    public SoraApiRequest() {}
    
    public SoraApiRequest(String prompt, String width, String height, String duration) {
        this.prompt = prompt;
        this.width = width;
        this.height = height;
        this.nSeconds = duration;
    }
    
    public String getModel() {
        return model;
    }
    
    public String getHeight() {
        return height;
    }
    
    public void setHeight(String height) {
        this.height = height;
    }
    
    public String getWidth() {
        return width;
    }
    
    public void setWidth(String width) {
        this.width = width;
    }
    
    public String getNSeconds() {
        return nSeconds;
    }
    
    public void setNSeconds(String nSeconds) {
        this.nSeconds = nSeconds;
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
