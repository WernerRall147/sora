package com.example.soravideogenerator.service;

import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Service for calculating estimated costs of Sora video generation
 * Based on Azure OpenAI Sora per-second pricing (June 2025)
 */
@Service
public class CostEstimationService {
    
    // Per-second pricing in USD (based on Azure OpenAI Sora pricing June 2025)
    // Pricing covers 1-20 second duration tiers with some variations for higher resolutions
    private static final BigDecimal COST_480_SQUARE_PER_SEC = new BigDecimal("0.15");    // 480x480
    private static final BigDecimal COST_480P_PER_SEC = new BigDecimal("0.20");          // 480x854, 854x480
    private static final BigDecimal COST_720_SQUARE_PER_SEC = new BigDecimal("0.30");    // 720x720
    private static final BigDecimal COST_720P_MIN_PER_SEC = new BigDecimal("0.45");      // 720x1280, 1280x720 (min)
    private static final BigDecimal COST_720P_MAX_PER_SEC = new BigDecimal("0.50");      // 720x1280, 1280x720 (max)
    private static final BigDecimal COST_1080_SQUARE_MIN_PER_SEC = new BigDecimal("0.60"); // 1080x1080 (min)
    private static final BigDecimal COST_1080_SQUARE_MAX_PER_SEC = new BigDecimal("0.75"); // 1080x1080 (max)
    private static final BigDecimal COST_1080P_MIN_PER_SEC = new BigDecimal("1.30");     // 1080x1920, 1920x1080 (min)
    private static final BigDecimal COST_1080P_MAX_PER_SEC = new BigDecimal("1.85");     // 1080x1920, 1920x1080 (max)
      /**
     * Calculate estimated cost for video generation using per-second pricing
     * @param resolution Video resolution (e.g., "1080x1080")
     * @param durationSeconds Duration in seconds
     * @return Estimated cost in USD
     */
    public BigDecimal calculateEstimatedCost(String resolution, int durationSeconds) {
        BigDecimal costPerSecond = getCostPerSecond(resolution);
        BigDecimal totalCost = costPerSecond.multiply(new BigDecimal(durationSeconds));
        
        return totalCost.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * Get per-second cost based on video resolution
     * For resolutions with variable pricing, uses the average of min/max
     * @param resolution Video resolution string
     * @return Cost per second for the specified resolution
     */
    private BigDecimal getCostPerSecond(String resolution) {
        if (resolution == null) return COST_1080P_MIN_PER_SEC; // Default to 1080p min pricing
        
        return switch (resolution) {
            case "480x480" -> COST_480_SQUARE_PER_SEC;
            case "480x854", "854x480" -> COST_480P_PER_SEC;
            case "720x720" -> COST_720_SQUARE_PER_SEC;
            case "720x1280", "1280x720" -> COST_720P_MIN_PER_SEC.add(COST_720P_MAX_PER_SEC)
                                           .divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP); // Average
            case "1080x1080" -> COST_1080_SQUARE_MIN_PER_SEC.add(COST_1080_SQUARE_MAX_PER_SEC)
                                .divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP); // Average
            case "1080x1920", "1920x1080" -> COST_1080P_MIN_PER_SEC.add(COST_1080P_MAX_PER_SEC)
                                              .divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP); // Average
            default -> COST_1080P_MIN_PER_SEC; // Default to 1080p min pricing
        };
    }
    
    /**
     * Get cost range for resolutions with variable pricing
     * @param resolution Video resolution
     * @param durationSeconds Duration in seconds
     * @return Array with [minCost, maxCost] or single cost for fixed pricing
     */
    public BigDecimal[] getCostRange(String resolution, int durationSeconds) {
        BigDecimal duration = new BigDecimal(durationSeconds);
        
        return switch (resolution) {
            case "720x1280", "1280x720" -> new BigDecimal[]{
                COST_720P_MIN_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP),
                COST_720P_MAX_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP)
            };
            case "1080x1080" -> new BigDecimal[]{
                COST_1080_SQUARE_MIN_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP),
                COST_1080_SQUARE_MAX_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP)
            };
            case "1080x1920", "1920x1080" -> new BigDecimal[]{
                COST_1080P_MIN_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP),
                COST_1080P_MAX_PER_SEC.multiply(duration).setScale(2, RoundingMode.HALF_UP)
            };
            default -> {
                BigDecimal cost = calculateEstimatedCost(resolution, durationSeconds);
                yield new BigDecimal[]{cost, cost};
            }
        };
    }
      /**
     * Get cost breakdown details for display
     * @param resolution Video resolution
     * @param durationSeconds Duration in seconds
     * @return Formatted cost breakdown string
     */
    public String getCostBreakdown(String resolution, int durationSeconds) {
        BigDecimal costPerSecond = getCostPerSecond(resolution);
        BigDecimal totalCost = calculateEstimatedCost(resolution, durationSeconds);
        BigDecimal[] costRange = getCostRange(resolution, durationSeconds);
        
        String costInfo;
        if (costRange[0].equals(costRange[1])) {
            // Fixed pricing
            costInfo = String.format("$%.2f/sec × %ds = $%.2f", 
                                   costPerSecond, durationSeconds, totalCost);
        } else {
            // Variable pricing - show range
            costInfo = String.format("$%.2f-$%.2f (range: $%.2f-$%.2f)", 
                                   totalCost, totalCost, costRange[0], costRange[1]);
        }
        
        return String.format(
            "🎬 **Azure OpenAI Sora Video Generation Cost**%n%n" +
            "• Resolution: %s%n" +
            "• Duration: %d seconds%n" +
            "• Rate: $%.2f per second%n" +
            "• **Total cost: %s**%n%n" +
            "💡 *Pricing based on Azure OpenAI Sora (June 2025)*%n" +
            "📊 *Some resolutions have variable pricing within 1-20s tiers*",
            resolution, durationSeconds, costPerSecond, costInfo
        );
    }    /**
     * Get cost warning message based on estimated cost
     * @param estimatedCost Estimated cost
     * @return Warning message or empty string
     */
    public String getCostWarning(BigDecimal estimatedCost) {
        if (estimatedCost.compareTo(new BigDecimal("25")) > 0) {
            return "🔥 EXPENSIVE ALERT: This video generation will cost over $25! Azure OpenAI Sora pricing escalates quickly for longer or higher-resolution videos. Consider shorter duration or lower resolution to significantly reduce costs.";
        } else if (estimatedCost.compareTo(new BigDecimal("15")) > 0) {
            return "⚠️ High cost alert: This video generation will cost over $15. For reference, a 10-second 1080p video costs $13-$18.50. Consider optimizing your specifications.";
        } else if (estimatedCost.compareTo(new BigDecimal("8")) > 0) {
            return "💡 Cost notice: This generation will cost over $8. Higher resolutions like 1080p can be expensive at $1.30-$1.85 per second.";
        }
        return "";
    }
}
