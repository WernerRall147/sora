# Sora Video Generator

A Java Spring Boot web application that generates Sora videos using Azure OpenAI API. This application provides a user-friendly web interface for creating AI-generated videos with **configurable video specifications** including resolution and duration.

## Features

- 🎥 **Video Generation**: Create videos using Azure OpenAI's Sora model
- ⚙️ **Configurable Specifications**: Choose from 9 supported resolutions and duration (1-20 seconds)
- 🔧 **Smart Validation**: Automatic restrictions for resolution-specific limitations (e.g., 1920x1080 max 10 seconds)
- 🖥️ **Web Interface**: Modern, responsive UI built with Bootstrap and Thymeleaf
- ⚡ **Reactive Architecture**: Built with Spring WebFlux for optimal performance with 100MB buffer for large video downloads
- 🔒 **Secure**: Uses Azure managed identity for authentication in production
- 📊 **Monitoring**: Includes health checks and logging for production deployment
- 🚀 **Container Ready**: Dockerized for easy deployment to Azure Container Apps
- 💰 **Cost Estimation**: Real-time cost preview and detailed cost breakdown with warnings

### Cost Calculation Details

The cost estimator is based on **Azure OpenAI Sora per-second pricing** as of June 2025:

## Getting Started

### Prerequisites

- Java 17 or later
- Maven 3.6 or later
- Azure CLI (for deployment)
- Azure Developer CLI (recommended)
- Azure subscription with permission to create OpenAI resources

For the **one-click deployment script**, the Azure OpenAI resource and Sora model will be created automatically. Otherwise, you'll need Azure OpenAI API access with the Sora model.

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sora-video-generator
   ```

2. **Set up environment variables**
   Create a `.env` file in the root directory with your Azure OpenAI credentials:
   ```bash
   # Azure OpenAI Configuration
   AZURE_OPENAI_ENDPOINT=https://your-resource.cognitiveservices.azure.com
   AZURE_OPENAI_API_KEY=your_api_key_here
   AZURE_OPENAI_API_VERSION=preview

   # Azure Configuration
   AZURE_ENV_NAME=your-env-name
   AZURE_LOCATION=eastus

   # Application Configuration
   SERVER_PORT=8080
   SPRING_PROFILES_ACTIVE=dev
   ```

   > **Important**: Use only the base URL for the endpoint (e.g., `https://your-resource.cognitiveservices.azure.com`). Do **not** include the full API path like `/openai/v1/video/generations/jobs?api-version=preview`.

3. **Environment Variable Loading**
   The application automatically loads environment variables from the `.env` file using the dotenv-java library. No manual configuration of `application.properties` is required - all sensitive configuration is handled through environment variables for security. 

4. **Run the application**
   ```bash
   ./mvnw spring-boot:run
   ```

5. **Access the application**
   Open your browser and go to `http://localhost:8080`

### Building for Production

1. **Build the JAR file**
   ```bash
   ./mvnw clean package
   ```

2. **Build Docker image**
   ```bash
   docker build -t sora-video-generator .
   ```

## Deployment to Azure

This application is designed to be deployed to Azure Container Apps using Azure Developer CLI.

### One-Click Deployment (Recommended)

The simplest way to deploy the entire application, including creating the Azure OpenAI resource with Sora model:

1. **Run the deployment script**
   ```bash
   # Using PowerShell script
   ./deploy.ps1
   
   # Or using the batch file (Windows)
   deploy.bat
   ```

2. **What the one-click deployment does:**
   - Creates the Azure OpenAI resource in East US 2
   - Deploys the Sora model
   - Updates the .env file with actual credentials
   - Builds the Java application
   - Deploys all infrastructure to Azure
   - Provides the URL to access your application

3. **Custom deployment options**
   ```bash
   # Specify resource group name and location
   ./deploy.ps1 -ResourceGroupName "MySoraRG" -Location "eastus2"
   
   # Specify OpenAI resource name and environment name
   ./deploy.ps1 -OpenAIResourceName "my-sora-openai" -EnvironmentName "production"
   ```

### Using Azure Developer CLI (Manual Approach)

1. **Install Azure Developer CLI**
   ```bash
   # Windows (PowerShell)
   winget install Microsoft.AzureDeveloperCLI
   
   # macOS
   brew tap azure/azd && brew install azd
   
   # Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

2. **Initialize the project**
   ```bash
   azd init
   ```

3. **Set environment variables**
   ```bash
   azd env set AZURE_OPENAI_ENDPOINT "https://your-resource.cognitiveservices.azure.com"
   azd env set AZURE_OPENAI_API_KEY "your_api_key_here"
   azd env set AZURE_OPENAI_API_VERSION "preview"
   azd env set AZURE_LOCATION "eastus"
   ```

   > **Important**: Use only the base URL for the endpoint (e.g., `https://your-resource.cognitiveservices.azure.com`). Do **not** include the full API path like `/openai/v1/video/generations/jobs?api-version=preview`. 

4. **Deploy to Azure**
   ```bash
   azd up
   ```

## Configuration

### Environment Variables

The application uses environment variables for all configuration to ensure security and flexibility across different environments (local development, Azure deployment). All sensitive configuration is loaded from `.env` files locally or Azure environment variables in production.

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI service endpoint (base URL only) | Required |
| `AZURE_OPENAI_API_KEY` | Azure OpenAI API key | Required |
| `AZURE_OPENAI_API_VERSION` | API version | `preview` |
| `SERVER_PORT` | Application port | `8080` |
| `SPRING_PROFILES_ACTIVE` | Spring profile | `dev` |
| `AZURE_ENV_NAME` | Azure environment name | Required for deployment |
| `AZURE_LOCATION` | Azure region | Required for deployment |

## Troubleshooting

### Common Issues

1. **Azure OpenAI API Key Issues**
   - Verify your API key is correct and has Sora access
   - Check endpoint URL format (use base URL only, not full API path)
   - Ensure environment variables are properly set in `.env` file or Azure environment
   - Verify that Azure environment and local `.env` use the same endpoint

2. **Container App Deployment Issues**
   - Check container registry permissions
   - Verify managed identity configuration
   - Review application logs in Azure portal
   - Ensure Azure location consistency between environment variables and existing resources

3. **Environment Variable Loading Issues**
   - Verify `.env` file is in the project root directory
   - Check that environment variables are correctly set in Azure (use `azd env get-values`)
   - Ensure no hardcoded URLs remain in configuration files
   - Verify dotenv-java dependency is included in Maven build

3. **Video Generation Timeouts**
   - Video generation can take 2-5 minutes
   - Check job status regularly
   - Ensure adequate timeout settings

4. **Video Download Buffer Errors**
   - Application configured with 100MB buffer for large video files
   - If encountering buffer limit issues, videos may be too large
   - Try shorter durations or lower resolutions

5. **Resolution-Duration Restrictions**
   - 1920x1080 resolution limited to maximum 10 seconds
   - Frontend automatically enforces these restrictions
   - Backend validation prevents invalid combinations

### Logs

View application logs:
```bash
# Azure Developer CLI
azd logs

# Azure CLI
az containerapp logs show --name <app-name> --resource-group <rg-name>
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.
