package com.example.soravideogenerator.controller;

import com.example.soravideogenerator.model.VideoRequest;
import com.example.soravideogenerator.model.VideoResponse;
import com.example.soravideogenerator.service.SoraVideoService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Controller for handling video generation requests and web interface
 */
@Controller
public class VideoController {
    
    private static final Logger logger = LoggerFactory.getLogger(VideoController.class);
    
    private final SoraVideoService soraVideoService;
    
    @Autowired
    public VideoController(SoraVideoService soraVideoService) {
        this.soraVideoService = soraVideoService;
    }
    
    /**
     * Display the main video generation form
     */
    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("videoRequest", new VideoRequest());
        return "index";
    }
      /**
     * Handle video generation form submission
     */
    @PostMapping("/generate")
    public Mono<String> generateVideo(@Valid @ModelAttribute VideoRequest videoRequest, 
                                     BindingResult bindingResult, 
                                     Model model) {
        
        if (bindingResult.hasErrors()) {
            model.addAttribute("error", "Please check your input and try again");
            model.addAttribute("videoRequest", videoRequest);
            return Mono.just("index");
        }
        
        logger.info("Received video generation request with prompt: {}, resolution: {}, duration: {}s", 
                   videoRequest.getPrompt(), videoRequest.getResolution(), videoRequest.getDuration());
        
        return soraVideoService.generateVideo(videoRequest)
            .map(response -> {
                if (response.isSuccess()) {
                    model.addAttribute("jobId", response.getJobId());
                    model.addAttribute("status", response.getStatus());
                    model.addAttribute("message", "Video generation started successfully!");
                    model.addAttribute("resolution", videoRequest.getResolution());
                    model.addAttribute("duration", videoRequest.getDuration());
                    return "result";
                } else {
                    model.addAttribute("error", response.getMessage());
                    model.addAttribute("videoRequest", videoRequest);
                    return "index";
                }
            })
            .onErrorReturn("error");
    }
    
    /**
     * REST endpoint to check job status
     */
    @GetMapping("/api/status/{jobId}")
    @ResponseBody
    public Mono<VideoResponse> checkStatus(@PathVariable String jobId) {
        logger.info("Checking status for job: {}", jobId);
        return soraVideoService.checkJobStatus(jobId);
    }
    
    /**
     * Display job status page
     */
    @GetMapping("/status/{jobId}")
    public String statusPage(@PathVariable String jobId, Model model) {
        model.addAttribute("jobId", jobId);
        return "status";
    }
      /**
     * Download endpoint for completed videos
     */
    @GetMapping("/api/download/{jobId}")
    public Mono<ResponseEntity<InputStreamResource>> downloadVideo(@PathVariable String jobId) {
        logger.info("Download request for job: {}", jobId);
        
        return soraVideoService.checkJobStatus(jobId)
            .flatMap(response -> {
                if (response.isSuccess() && 
                    ("completed".equals(response.getStatus()) || "succeeded".equals(response.getStatus()))) {
                    
                    // Check if we have a generation ID for the new API structure
                    if (response.getGenerationId() != null) {
                        return soraVideoService.downloadVideoContent(response.getGenerationId())
                            .map(videoData -> {
                                InputStream inputStream = new java.io.ByteArrayInputStream(videoData);
                                InputStreamResource resource = new InputStreamResource(inputStream);
                                
                                // Generate filename with timestamp
                                String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
                                String filename = String.format("sora_video_%s_%s.mp4", jobId, timestamp);
                                
                                HttpHeaders headers = new HttpHeaders();
                                headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"");
                                headers.add(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_OCTET_STREAM_VALUE);
                                headers.add(HttpHeaders.CONTENT_LENGTH, String.valueOf(videoData.length));
                                
                                logger.info("Successfully prepared download for job: {} with {} bytes", jobId, videoData.length);
                                
                                return ResponseEntity.ok()
                                    .headers(headers)
                                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                                    .body(resource);
                            })
                            .onErrorReturn(ResponseEntity.internalServerError()
                                .body(new InputStreamResource(InputStream.nullInputStream())));
                    }
                    // Fallback to direct URL download (for backward compatibility)
                    else if (response.getVideoUrl() != null && !response.getVideoUrl().equals("available")) {
                        try {
                            URL url = new URL(response.getVideoUrl());
                            InputStream inputStream = url.openStream();
                            InputStreamResource resource = new InputStreamResource(inputStream);
                            
                            // Generate filename with timestamp
                            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
                            String filename = String.format("sora_video_%s_%s.mp4", jobId, timestamp);
                            
                            HttpHeaders headers = new HttpHeaders();
                            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"");
                            headers.add(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_OCTET_STREAM_VALUE);
                            
                            logger.info("Successfully prepared download for job: {}", jobId);
                            
                            return Mono.just(ResponseEntity.ok()
                                .headers(headers)
                                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                                .body(resource));
                                
                        } catch (IOException e) {
                            logger.error("Failed to download video for job {}: {}", jobId, e.getMessage());
                            return Mono.just(ResponseEntity.badRequest()
                                .body(new InputStreamResource(InputStream.nullInputStream())));
                        }
                    } else {
                        logger.warn("No video URL or generation ID available for job: {}", jobId);
                        return Mono.just(ResponseEntity.badRequest()
                            .body(new InputStreamResource(InputStream.nullInputStream())));
                    }
                } else {
                    logger.warn("Video not ready for download - Job: {}, Status: {}", jobId, response.getStatus());
                    return Mono.just(ResponseEntity.badRequest()
                        .body(new InputStreamResource(InputStream.nullInputStream())));
                }
            })
            .onErrorReturn(ResponseEntity.internalServerError()
                .body(new InputStreamResource(InputStream.nullInputStream())));
    }
}
