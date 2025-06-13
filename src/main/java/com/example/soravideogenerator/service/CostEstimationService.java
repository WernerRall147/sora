package com.example.soravideogenerator.service;

import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Service for calculating estimated costs of Sora video generation
 * Based on Azure AI Studio Sora pricing as of mid-2025
 */
@Service
public class CostEstimationService {
      // Base costs in USD (based on Azure AI Studio Sora pricing mid-2025)
    private static final BigDecimal BASE_PROMPT_COST = new BigDecimal("0.02"); // $0.01-$0.03 per request
    private static final BigDecimal BASE_COST_PER_MINUTE = new BigDecimal("30.00"); // $10-$80 per minute, using $30 average
    private static final BigDecimal STORAGE_EGRESS_COST = new BigDecimal("1.00"); // Storage, egress, and processing overhead
    
    // Resolution multipliers (higher resolutions significantly increase cost)
    private static final BigDecimal RESOLUTION_480P_MULTIPLIER = new BigDecimal("0.5");
    private static final BigDecimal RESOLUTION_720P_MULTIPLIER = new BigDecimal("0.8");
    private static final BigDecimal RESOLUTION_1080P_MULTIPLIER = new BigDecimal("1.0");
    private static final BigDecimal RESOLUTION_1920P_MULTIPLIER = new BigDecimal("3.0"); // 1920x1080 premium pricing (2x-4x baseline)
    
    /**
     * Calculate estimated cost for video generation
     * @param resolution Video resolution (e.g., "1080x1080")
     * @param durationSeconds Duration in seconds
     * @return Estimated cost in USD
     */
    public BigDecimal calculateEstimatedCost(String resolution, int durationSeconds) {
        // Base prompt submission cost
        BigDecimal totalCost = BASE_PROMPT_COST;
        
        // Calculate duration cost (convert seconds to minutes)
        BigDecimal durationMinutes = new BigDecimal(durationSeconds).divide(new BigDecimal("60"), 4, RoundingMode.HALF_UP);
        BigDecimal durationCost = BASE_COST_PER_MINUTE.multiply(durationMinutes);
        
        // Apply resolution multiplier
        BigDecimal resolutionMultiplier = getResolutionMultiplier(resolution);
        durationCost = durationCost.multiply(resolutionMultiplier);
        
        // Add duration cost
        totalCost = totalCost.add(durationCost);
          // Add storage, egress, and processing costs
        totalCost = totalCost.add(STORAGE_EGRESS_COST);
        
        return totalCost.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * Get resolution multiplier based on video resolution
     * @param resolution Video resolution string
     * @return Multiplier for cost calculation
     */
    private BigDecimal getResolutionMultiplier(String resolution) {
        if (resolution == null) return RESOLUTION_1080P_MULTIPLIER;
        
        return switch (resolution) {
            case "480x480", "480x854", "854x480" -> RESOLUTION_480P_MULTIPLIER;
            case "720x720", "720x1280", "1280x720" -> RESOLUTION_720P_MULTIPLIER;
            case "1080x1080", "1080x1920" -> RESOLUTION_1080P_MULTIPLIER;
            case "1920x1080" -> RESOLUTION_1920P_MULTIPLIER; // Premium pricing for landscape 1080p
            default -> RESOLUTION_1080P_MULTIPLIER;
        };
    }
    
    /**
     * Get cost breakdown details for display
     * @param resolution Video resolution
     * @param durationSeconds Duration in seconds
     * @return Formatted cost breakdown string
     */
    public String getCostBreakdown(String resolution, int durationSeconds) {
        BigDecimal promptCost = BASE_PROMPT_COST;
        BigDecimal durationMinutes = new BigDecimal(durationSeconds).divide(new BigDecimal("60"), 4, RoundingMode.HALF_UP);
        BigDecimal baseDurationCost = BASE_COST_PER_MINUTE.multiply(durationMinutes);
        BigDecimal resolutionMultiplier = getResolutionMultiplier(resolution);
        BigDecimal adjustedDurationCost = baseDurationCost.multiply(resolutionMultiplier);
        BigDecimal storageCost = STORAGE_EGRESS_COST;
        BigDecimal totalCost = calculateEstimatedCost(resolution, durationSeconds);
          return String.format(
            "• Prompt submission: $%.2f%n" +
            "• Video generation (%ds at %s): $%.2f%n" +
            "  └─ GPU compute time: ~%.1f minutes @ $%.0f/min%n" +
            "  └─ Resolution multiplier: %.1fx%n" +
            "• Storage, egress & processing: $%.2f%n" +
            "• **Total estimated cost: $%.2f**%n%n" +
            "💡 *Note: Based on Azure AI Studio Sora pricing (mid-2025)*",
            promptCost, durationSeconds, resolution, adjustedDurationCost, 
            durationMinutes, BASE_COST_PER_MINUTE, resolutionMultiplier,
            storageCost, totalCost
        );
    }
      /**
     * Get cost warning message based on estimated cost
     * @param estimatedCost Estimated cost
     * @return Warning message or empty string
     */
    public String getCostWarning(BigDecimal estimatedCost) {
        if (estimatedCost.compareTo(new BigDecimal("20")) > 0) {
            return "🔥 EXPENSIVE ALERT: This video generation will cost over $20! Azure Sora pricing can get shockingly expensive for longer or higher-resolution videos. Consider shorter duration or lower resolution to significantly reduce costs.";
        } else if (estimatedCost.compareTo(new BigDecimal("10")) > 0) {
            return "⚠️ High cost alert: This video generation will cost over $10. For reference, a 15-second 1080p video typically costs $7.50. Consider optimizing your specifications.";
        } else if (estimatedCost.compareTo(new BigDecimal("5")) > 0) {
            return "💡 Cost notice: This generation will cost over $5. You can reduce costs with shorter duration or lower resolution.";
        }
        return "";
    }
}
