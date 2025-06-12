package com.example.soravideogenerator.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Request model for video generation containing user prompt and video specifications
 */
@ValidDurationForResolution
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

/**
 * Custom validation annotation for duration based on resolution
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = DurationForResolutionValidator.class)
@interface ValidDurationForResolution {
    String message() default "1920x1080 resolution does not support more than 10 seconds duration. Maximum duration is 10 seconds.";
    Class<?>[] groups() default {};
    Class<? extends Payload>[] payload() default {};
}

/**
 * Validator for duration based on resolution restrictions
 */
class DurationForResolutionValidator implements ConstraintValidator<ValidDurationForResolution, VideoRequest> {
    
    @Override
    public void initialize(ValidDurationForResolution constraintAnnotation) {
        // No initialization needed
    }
    
    @Override
    public boolean isValid(VideoRequest request, ConstraintValidatorContext context) {
        if (request == null || request.getResolution() == null || request.getDuration() == null) {
            return true; // Let other validators handle null values
        }
          // Check if 1920x1080 resolution with duration > 10
        if ("1920x1080".equals(request.getResolution()) && request.getDuration() > 10) {
            return false;
        }
        
        return true;
    }
}
