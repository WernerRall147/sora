# Copilot Instructions for Sora Video Generator

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview
This is a Java Spring Boot web application that generates Sora videos using Azure OpenAI API. The application provides a web interface for users to input prompts and generates videos with fixed technical parameters.

## Key Technologies
- Java 17
- Spring Boot 3.5.0
- Spring WebFlux for reactive HTTP calls
- Thymeleaf for templating
- Azure OpenAI API for video generation
- Azure Container Apps for deployment

## Architecture Guidelines
- Use reactive programming patterns with WebFlux for external API calls
- Implement proper error handling and retry logic for Azure API calls
- Follow Spring Boot best practices for configuration management
- Use Azure managed identity for authentication when deployed
- Implement proper logging for debugging and monitoring

## Security Considerations
- Never hardcode API keys in source code
- Use Azure Key Vault or environment variables for sensitive configuration
- Implement proper CORS configuration for web interface
- Use HTTPS for all external API calls
- Implement rate limiting for video generation requests

## Code Style
- Follow Java naming conventions
- Use Spring's dependency injection
- Implement proper exception handling
- Add comprehensive logging
- Write clean, readable code with proper documentation
