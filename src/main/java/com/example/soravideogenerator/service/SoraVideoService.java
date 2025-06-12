package com.example.soravideogenerator.service;

import com.example.soravideogenerator.config.AzureOpenAIConfig;
import com.example.soravideogenerator.model.SoraApiRequest;
import com.example.soravideogenerator.model.SoraApiResponse;
import com.example.soravideogenerator.model.VideoRequest;
import com.example.soravideogenerator.model.VideoResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;

/**
 * Service for handling Sora video generation using Azure OpenAI API
 */
@Service
public class SoraVideoService {
    
    private static final Logger logger = LoggerFactory.getLogger(SoraVideoService.class);
    
    private final WebClient webClient;
    private final AzureOpenAIConfig config;
    
    @Autowired
    public SoraVideoService(WebClient azureOpenAIWebClient, AzureOpenAIConfig config) {
        this.webClient = azureOpenAIWebClient;
        this.config = config;
    }
      /**
     * Generate a video using the Azure OpenAI Sora API
     * @param videoRequest The video request containing prompt, resolution, and duration
     * @return Mono<VideoResponse> containing the job details or error information
     */
    public Mono<VideoResponse> generateVideo(VideoRequest videoRequest) {
        logger.info("Starting video generation for prompt: {} with resolution: {} and duration: {}s", 
                   videoRequest.getPrompt(), videoRequest.getResolution(), videoRequest.getDuration());
        
        SoraApiRequest request = new SoraApiRequest(
            videoRequest.getPrompt(),
            videoRequest.getWidth(),
            videoRequest.getHeight(),
            videoRequest.getDuration().toString()
        );
        
        return webClient.post()
            .uri(uriBuilder -> uriBuilder
                .path("/openai/v1/video/generations/jobs")
                .queryParam("api-version", config.getApiVersion())
                .build())
            .bodyValue(request)
            .retrieve()
            .bodyToMono(SoraApiResponse.class)
            .map(this::mapToVideoResponse)
            .retryWhen(Retry.backoff(3, Duration.ofSeconds(1))
                .filter(this::isRetryableException))
            .doOnSuccess(response -> logger.info("Video generation job created: {}", response.getJobId()))
            .doOnError(error -> logger.error("Error generating video: {}", error.getMessage()))
            .onErrorReturn(new VideoResponse("Failed to generate video. Please try again.", false));
    }
      /**
     * Check the status of a video generation job
     * @param jobId The job ID to check
     * @return Mono<VideoResponse> containing the current status and video URL if completed
     */
    public Mono<VideoResponse> checkJobStatus(String jobId) {
        logger.info("Checking status for job: {}", jobId);
        
        return webClient.get()
            .uri(uriBuilder -> uriBuilder
                .path("/openai/v1/video/generations/jobs/{jobId}")
                .queryParam("api-version", config.getApiVersion())
                .build(jobId))
            .retrieve()
            .bodyToMono(SoraApiResponse.class)
            .map(this::mapToVideoResponse)
            .doOnSuccess(response -> logger.info("Job {} status: {}", jobId, response.getStatus()))
            .doOnError(error -> logger.error("Error checking job status: {}", error.getMessage()))
            .onErrorReturn(new VideoResponse("Failed to check job status.", false));
    }
    
    /**
     * Download video content for a completed generation
     * @param generationId The generation ID to download
     * @return Mono<byte[]> containing the video data
     */
    public Mono<byte[]> downloadVideoContent(String generationId) {
        logger.info("Downloading video content for generation: {}", generationId);
        
        return webClient.get()
            .uri(uriBuilder -> uriBuilder
                .path("/openai/v1/video/generations/{generationId}/content/video")
                .queryParam("api-version", config.getApiVersion())
                .build(generationId))
            .retrieve()
            .bodyToMono(byte[].class)
            .doOnSuccess(data -> logger.info("Successfully downloaded video content, size: {} bytes", data.length))
            .doOnError(error -> logger.error("Error downloading video content: {}", error.getMessage()));
    }    private VideoResponse mapToVideoResponse(SoraApiResponse apiResponse) {
        VideoResponse response = new VideoResponse(apiResponse.getId(), apiResponse.getStatus());
        
        // Handle both "completed" and "succeeded" as final success states
        if (("completed".equalsIgnoreCase(apiResponse.getStatus()) || "succeeded".equalsIgnoreCase(apiResponse.getStatus()))) {
            // Check if generations array has content
            if (apiResponse.getGenerations() != null && !apiResponse.getGenerations().isEmpty()) {
                String generationId = apiResponse.getGenerations().get(0).getId();
                response.setGenerationId(generationId);
                // Set a placeholder URL for display purposes
                response.setVideoUrl("available");
            }
            // Fallback to result.url if available (for backward compatibility)
            else if (apiResponse.getResult() != null && apiResponse.getResult().getUrl() != null) {
                response.setVideoUrl(apiResponse.getResult().getUrl());
            }
        }
        
        return response;
    }
      private boolean isRetryableException(Throwable throwable) {
        if (throwable instanceof WebClientResponseException) {
            WebClientResponseException ex = (WebClientResponseException) throwable;
            // Retry on server errors (5xx) and rate limiting (429)
            return ex.getStatusCode().is5xxServerError() || ex.getStatusCode().value() == 429;
        }
        return false;
    }
}
