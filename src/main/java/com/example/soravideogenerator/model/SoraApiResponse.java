package com.example.soravideogenerator.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Response model from Azure OpenAI Sora API
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class SoraApiResponse {
    
    private String id;
    private String status;
    private String model;
    
    @JsonProperty("created_at")
    private String createdAt;
    
    @JsonProperty("expires_at")
    private String expiresAt;
    
    private SoraVideo result;
    private List<Generation> generations;
    
    public SoraApiResponse() {}
    
    public String getId() {
        return id;
    }
    
    public void setId(String id) {
        this.id = id;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getModel() {
        return model;
    }
    
    public void setModel(String model) {
        this.model = model;
    }
      public String getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
    
    public String getExpiresAt() {
        return expiresAt;
    }
    
    public void setExpiresAt(String expiresAt) {
        this.expiresAt = expiresAt;
    }
    
    public SoraVideo getResult() {
        return result;
    }
    
    public void setResult(SoraVideo result) {
        this.result = result;
    }
    
    public List<Generation> getGenerations() {
        return generations;
    }
    
    public void setGenerations(List<Generation> generations) {
        this.generations = generations;
    }
    
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SoraVideo {
        private String url;
        
        public String getUrl() {
            return url;
        }
        
        public void setUrl(String url) {
            this.url = url;
        }
    }
    
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Generation {
        private String id;
        
        public String getId() {
            return id;
        }
        
        public void setId(String id) {
            this.id = id;
        }
    }
}
