# Sora Video Generator

A Java Spring Boot web application that generates Sora videos using Azure OpenAI API. This application provides a user-friendly web interface for creating AI-generated videos with fixed technical parameters (1080x1080, 5 seconds).

## Features

- 🎥 **Video Generation**: Create videos using Azure OpenAI's Sora model
- 🖥️ **Web Interface**: Modern, responsive UI built with Bootstrap and Thymeleaf
- ⚡ **Reactive Architecture**: Built with Spring WebFlux for optimal performance
- 🔒 **Secure**: Uses Azure managed identity for authentication in production
- 📊 **Monitoring**: Includes health checks and logging for production deployment
- 🚀 **Container Ready**: Dockerized for easy deployment to Azure Container Apps

## Architecture

- **Backend**: Java 17 + Spring Boot 3.5.0
- **Frontend**: Thymeleaf templates with Bootstrap 5
- **HTTP Client**: Spring WebFlux for reactive API calls
- **Deployment**: Azure Container Apps with Container Registry
- **Monitoring**: Spring Boot Actuator with Azure Log Analytics

## Getting Started

### Prerequisites

- Java 17 or later
- Maven 3.6 or later
- Azure OpenAI API access with Sora model
- Azure CLI (for deployment)
- Azure Developer CLI (recommended)

### Local Development

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sora-video-generator
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Azure OpenAI credentials
   ```

3. **Configure application properties**
   Update `src/main/resources/application.properties` with your Azure OpenAI endpoint and API key:
   ```properties
   azure.openai.endpoint=https://your-openai-resource.cognitiveservices.azure.com
   azure.openai.api-key=your_api_key_here
   ```

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

### Using Azure Developer CLI (Recommended)

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
   ```

4. **Deploy to Azure**
   ```bash
   azd up
   ```

### Manual Deployment

1. **Create Azure resources**
   ```bash
   az group create --name rg-sora-video --location eastus
   az deployment group create --resource-group rg-sora-video --template-file infra/main.bicep --parameters @infra/main.parameters.json
   ```

2. **Build and push container image**
   ```bash
   az acr build --registry <your-acr-name> --image sora-video-generator:latest .
   ```

3. **Update container app**
   ```bash
   az containerapp update --name <your-container-app> --resource-group rg-sora-video --image <your-acr-name>.azurecr.io/sora-video-generator:latest
   ```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI service endpoint | Required |
| `AZURE_OPENAI_API_KEY` | Azure OpenAI API key | Required |
| `AZURE_OPENAI_API_VERSION` | API version | `preview` |
| `SERVER_PORT` | Application port | `8080` |
| `SPRING_PROFILES_ACTIVE` | Spring profile | `dev` |

### Video Generation Parameters

The application uses fixed parameters for video generation:
- **Resolution**: 1080x1080 pixels
- **Duration**: 5 seconds
- **Variants**: 1
- **Model**: Sora

## Usage

1. **Access the web interface** at your deployed URL or `http://localhost:8080`
2. **Enter a prompt** describing the video you want to generate
3. **Click "Generate Video"** to start the process
4. **Check the status** of your video generation job
5. **Download the video** once generation is complete

## API Endpoints

- `GET /` - Main video generation form
- `POST /generate` - Submit video generation request
- `GET /status/{jobId}` - View job status page
- `GET /api/status/{jobId}` - Get job status (JSON)
- `GET /actuator/health` - Health check endpoint

## Monitoring and Logging

The application includes comprehensive monitoring:

- **Health Checks**: `/actuator/health` endpoint
- **Readiness Probe**: `/actuator/health/readiness`
- **Liveness Probe**: `/actuator/health/liveness`
- **Logging**: Configured for Azure Log Analytics

## Security

- Environment variables for sensitive configuration
- CORS policy configured for web interface
- Container runs as non-root user
- Azure managed identity for production authentication

## Development

### Project Structure

```
src/
├── main/
│   ├── java/com/example/soravideogenerator/
│   │   ├── SoraVideoGeneratorApplication.java
│   │   ├── config/
│   │   │   └── AzureOpenAIConfig.java
│   │   ├── controller/
│   │   │   └── VideoController.java
│   │   ├── model/
│   │   │   ├── VideoRequest.java
│   │   │   ├── VideoResponse.java
│   │   │   ├── SoraApiRequest.java
│   │   │   └── SoraApiResponse.java
│   │   └── service/
│   │       └── SoraVideoService.java
│   └── resources/
│       ├── application.properties
│       └── templates/
│           ├── index.html
│           ├── result.html
│           ├── status.html
│           └── error.html
├── test/
└── ...
```

### Key Components

- **VideoController**: Handles web requests and form submissions
- **SoraVideoService**: Manages video generation API calls
- **AzureOpenAIConfig**: Configuration for Azure OpenAI WebClient
- **Model Classes**: Request/response DTOs for API communication

## Troubleshooting

### Common Issues

1. **Azure OpenAI API Key Issues**
   - Verify your API key is correct
   - Check endpoint URL format
   - Ensure your subscription has access to Sora model

2. **Container App Deployment Issues**
   - Check container registry permissions
   - Verify managed identity configuration
   - Review application logs in Azure portal

3. **Video Generation Timeouts**
   - Video generation can take 2-5 minutes
   - Check job status regularly
   - Ensure adequate timeout settings

### Logs

View application logs:
```bash
# Azure Developer CLI
azd logs

# Azure CLI
az containerapp logs show --name <app-name> --resource-group <rg-name>
```

## Contributing

### Setting up CI/CD with GitHub Actions

This repository includes a comprehensive CI/CD pipeline using GitHub Actions. To set it up:

1. **Create Azure Service Principal**
   ```bash
   az ad sp create-for-rbac --name "sora-video-generator-sp" --role contributor \
     --scopes /subscriptions/<subscription-id> --sdk-auth
   ```

2. **Configure GitHub Secrets**
   Go to your repository Settings > Secrets and variables > Actions, and add:

   - `AZURE_CREDENTIALS`: Output from the service principal creation
   - `AZURE_ENV_NAME`: Your azd environment name (from `.azure` folder)
   - `AZURE_LOCATION`: Azure region (e.g., `eastus`)
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI endpoint URL
   - `AZURE_OPENAI_API_KEY`: Your Azure OpenAI API key
   - `AZURE_CLIENT_ID`: Service principal client ID
   - `AZURE_CLIENT_SECRET`: Service principal client secret
   - `AZURE_TENANT_ID`: Your Azure tenant ID

3. **Pipeline Features**
   - **Automated Testing**: Runs unit tests on every push/PR
   - **Security Scanning**: OWASP dependency check and CodeQL analysis
   - **Build & Deploy**: Automatically deploys to Azure on main branch
   - **Docker Integration**: Builds and pushes to Azure Container Registry

4. **Triggering Deployments**
   - Push to `main` branch triggers automatic deployment
   - Pull requests run tests and security scans
   - Manual deployment via GitHub Actions UI

### Local Development

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Azure OpenAI documentation
- Open an issue in the repository
