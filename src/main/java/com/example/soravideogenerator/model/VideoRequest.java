package com.example.soravideogenerator.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotNull;

/**
 * Request model for video generation containing user prompt and video specifications
 */
public class VideoRequest {
    
    @NotBlank(message = "Prompt cannot be empty")
    @Size(max = 1000, message = "Prompt cannot exceed 1000 characters")
    private String prompt;
    
    @NotNull(message = "Resolution must be selected")
    private String resolution;
    
    @NotNull(message = "Duration must be specified")
    @Min(value = 1, message = "Duration must be at least 1 second")
    @Max(value = 20, message = "Duration cannot exceed 20 seconds")
    private Integer duration;
    
    public VideoRequest() {
        // Set defaults
        this.resolution = "1080x1080";
        this.duration = 5;
    }
    
    public VideoRequest(String prompt, String resolution, Integer duration) {
        this.prompt = prompt;
        this.resolution = resolution;
        this.duration = duration;
    }
    
    public String getPrompt() {
        return prompt;
    }
    
    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }
    
    public String getResolution() {
        return resolution;
    }
    
    public void setResolution(String resolution) {
        this.resolution = resolution;
    }
    
    public Integer getDuration() {
        return duration;
    }
    
    public void setDuration(Integer duration) {
        this.duration = duration;
    }
    
    /**
     * Extract width from resolution string (e.g., "1080x1920" -> 1080)
     */
    public String getWidth() {
        if (resolution == null) return "1080";
        return resolution.split("x")[0];
    }
    
    /**
     * Extract height from resolution string (e.g., "1080x1920" -> 1920)
     */
    public String getHeight() {
        if (resolution == null) return "1080";
        return resolution.split("x")[1];
    }
}
