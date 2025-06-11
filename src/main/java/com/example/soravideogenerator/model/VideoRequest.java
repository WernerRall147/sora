package com.example.soravideogenerator.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request model for video generation containing user prompt
 */
public class VideoRequest {
    
    @NotBlank(message = "Prompt cannot be empty")
    @Size(max = 1000, message = "Prompt cannot exceed 1000 characters")
    private String prompt;
    
    public VideoRequest() {}
    
    public VideoRequest(String prompt) {
        this.prompt = prompt;
    }
    
    public String getPrompt() {
        return prompt;
    }
    
    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }
}
