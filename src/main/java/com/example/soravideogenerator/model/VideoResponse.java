package com.example.soravideogenerator.model;

/**
 * Response model for video generation result
 */
public class VideoResponse {
    
    private String jobId;
    private String status;
    private String videoUrl;
    private String generationId;
    private String message;
    private boolean success;
    
    public VideoResponse() {}
    
    public VideoResponse(String jobId, String status) {
        this.jobId = jobId;
        this.status = status;
        this.success = true;
    }
    
    public VideoResponse(String message, boolean success) {
        this.message = message;
        this.success = success;
    }
    
    public String getJobId() {
        return jobId;
    }
    
    public void setJobId(String jobId) {
        this.jobId = jobId;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getVideoUrl() {
        return videoUrl;
    }
    
    public void setVideoUrl(String videoUrl) {
        this.videoUrl = videoUrl;
    }
    
    public String getGenerationId() {
        return generationId;
    }
    
    public void setGenerationId(String generationId) {
        this.generationId = generationId;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
}
