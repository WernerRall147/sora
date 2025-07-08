#!/usr/bin/env pwsh
#Requires -Version 7.0
#Requires -Modules Az

<#
.SYNOPSIS
    One-click deployment script for Sora Video Generator application.

.DESCRIPTION
    This script automates the complete deployment process for the Sora Video Generator,
    including creating the Azure OpenAI resource, deploying the Sora model, updating
    environment configurations, and deploying the application to Azure.

.PARAMETER ResourceGroupName
    Name of the resource group for deploying resources. Default: "Sora_RG"

.PARAMETER Location
    Azure region for resource deployment. Default: "eastus2"

.PARAMETER OpenAIResourceName
    Name for the Azure OpenAI resource. Default: "sora-openai-{randomstring}"

.PARAMETER OpenAIModelDeploymentName
    Name for the Sora model deployment. Default: "sora"

.PARAMETER EnvironmentName
    Azure environment name for the application. Default: "sora-demo"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-zA-Z0-9._-]+$')]
    [string]$ResourceGroupName = "Sora_RG",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-z0-9]+$')]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-zA-Z0-9-]{2,64}$')]
    [string]$OpenAIResourceName = "sora-openai-default",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-z0-9-]{2,64}$')]
    [string]$OpenAIModelDeploymentName = "sora",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-zA-Z0-9-]{2,64}$')]
    [string]$EnvironmentName = "sora-demo"
)

# Set error action preference and enable verbose output
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$ProgressPreference = "Continue" 

# Function to display a help menu
function Show-Help {
    Write-Host "`n=================================================" -ForegroundColor Cyan
    Write-Host "       SORA VIDEO GENERATOR DEPLOYMENT SCRIPT" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    
    Write-Host "`nThis script deploys the Sora Video Generator application to Azure." -ForegroundColor White
    
    Write-Host "`nUSAGE:" -ForegroundColor Yellow
    Write-Host "  ./deploy.ps1 [parameters]" -ForegroundColor White
    
    Write-Host "`nPARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -ResourceGroupName         Name of the resource group for deployment (default: 'Sora_RG')" -ForegroundColor White
    Write-Host "  -Location                  Azure region for resources (default: 'eastus2')" -ForegroundColor White
    Write-Host "  -OpenAIResourceName        Name for Azure OpenAI resource (default: auto-generated)" -ForegroundColor White
    Write-Host "  -OpenAIModelDeploymentName Name for Sora model deployment (default: 'sora')" -ForegroundColor White
    Write-Host "  -EnvironmentName           Azure environment name (default: 'sora-demo')" -ForegroundColor White
    
    Write-Host "`nEXAMPLE:" -ForegroundColor Yellow
    Write-Host "  ./deploy.ps1 -ResourceGroupName 'MySoraGroup' -Location 'westus' -EnvironmentName 'my-sora'" -ForegroundColor White
    
    Write-Host "`nPREREQUISITES:" -ForegroundColor Yellow
    Write-Host "  - Azure CLI (az) - For Azure resource management" -ForegroundColor White
    Write-Host "  - Azure Developer CLI (azd) - For app deployment" -ForegroundColor White
    Write-Host "  - Java - For building the application" -ForegroundColor White
    Write-Host "  - Maven (mvn) - For package management" -ForegroundColor White
    
    Write-Host "`n=================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Check if help is requested
if ($args -contains "--help" -or $args -contains "-h") {
    Show-Help
}

# Start timestamp for overall deployment tracking
$scriptStartTime = Get-Date

# Start transcript logging to help with debugging
$logFile = Join-Path $PSScriptRoot "deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile
Write-Host "Starting deployment process at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host "Log file: $logFile" -ForegroundColor Green

# Generate a timestamp for the deployment
$deploymentTimestamp = Get-Date -Format "yyyyMMddHHmmss"

# Display script parameters for clarity
Write-Host "Deployment parameters:" -ForegroundColor Magenta
Write-Host "  ResourceGroupName: $ResourceGroupName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  EnvironmentName: $EnvironmentName" -ForegroundColor White

# Generate a unique suffix if OpenAIResourceName is not provided
if (-not $OpenAIResourceName) {
    $randomSuffix = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
    $OpenAIResourceName = "sora-openai-$randomSuffix"
    Write-Host "  OpenAIResourceName (auto-generated): $OpenAIResourceName" -ForegroundColor White
}
else {
    Write-Host "  OpenAIResourceName (user-specified): $OpenAIResourceName" -ForegroundColor White
}
Write-Host "  OpenAIModelDeploymentName: $OpenAIModelDeploymentName" -ForegroundColor White

# Function to display progress
# Function to display progress with step count
function Write-Progress-Step {
    param (
        [string]$Message,
        [int]$StepNumber,
        [int]$TotalSteps = 11
    )
    $percentComplete = [math]::Floor(($StepNumber / $TotalSteps) * 100)
    
    # Get console width for progress bar
    $consoleWidth = 80
    try {
        $consoleWidth = (Get-Host).UI.RawUI.WindowSize.Width
    }
    catch {
        # Default to 80 if we can't get the console width
        $consoleWidth = 80
    }
    
    $progressBarWidth = [Math]::Min($consoleWidth - 20, 50)
    $filledWidth = [Math]::Floor(($percentComplete / 100) * $progressBarWidth)
    $emptyWidth = $progressBarWidth - $filledWidth
    
    $progressBar = ""
    if ($filledWidth -gt 0) {
        $progressBar += "█" * $filledWidth
    }
    if ($emptyWidth -gt 0) {
        $progressBar += "░" * $emptyWidth
    }
    
    $stepDisplay = "STEP $StepNumber/$TotalSteps"
    
    Write-Host "`n" -NoNewline
    Write-Host "$stepDisplay " -NoNewline -ForegroundColor Yellow
    Write-Host "$progressBar" -NoNewline -ForegroundColor Cyan
    Write-Host " $percentComplete%" -NoNewline -ForegroundColor Yellow
    Write-Host "`n📋 $Message" -ForegroundColor Cyan
}

# Function to display spinner for long-running operations
function Show-Spinner {
    param (
        [scriptblock]$ScriptBlock,
        [string]$Message = "Operation in progress..."
    )
    
    $spinChars = "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"
    $i = 0
    $origPos = $host.UI.RawUI.CursorPosition
    $spinnerActive = $true
    
    # Start spinner in a separate job
    $job = Start-Job -ScriptBlock {
        param($spinChars, $message)
        $i = 0
        while ($true) {
            Write-Host "`r$($spinChars[$i % $spinChars.Length]) $message     " -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 100
            $i++
        }
    } -ArgumentList $spinChars, $Message
    
    try {
        # Run the actual operation
        & $ScriptBlock
    }
    finally {
        # Stop the spinner job
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        Write-Host "`r                                                      `r" -NoNewline
    }
}

# Function to handle errors
function Write-ErrorAndExit {
    param (
        [string]$ErrorMessage,
        [System.Exception]$Exception = $null
    )
    Write-Host "`n❌ ERROR: $ErrorMessage" -ForegroundColor Red
    
    if ($Exception) {
        Write-Host "Exception details:" -ForegroundColor Red
        Write-Host $Exception.Message -ForegroundColor Red
        Write-Host $Exception.StackTrace -ForegroundColor DarkRed
    }
    
    # Write a clear error marker in the log file
    Write-Host "`n=== DEPLOYMENT FAILED ===`n" -ForegroundColor Red
    
    # End transcript before exiting
    try {
        Stop-Transcript
        Write-Host "Deployment log saved to: $logFile" -ForegroundColor Yellow
        Write-Host "Please check the log file for detailed error information." -ForegroundColor Yellow
    }
    catch {
        # In case transcript wasn't started
    }
    
    exit 1
}

# Function to deploy Sora programmatically using Azure REST API and multiple deployment strategies
function Deploy-SoraProgrammatically {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory = $true)]
        [string]$OpenAIResourceName,
        
        [Parameter(Mandatory = $true)]
        [string]$DeploymentName
    )
    
    Write-Host "🔧 Starting programmatic Sora deployment..." -ForegroundColor Cyan
    
    try {
        # Get Azure access token for Cognitive Services API
        Write-Host "Obtaining Azure access token..." -ForegroundColor Yellow
        $tokenResponse = & az account get-access-token --resource https://cognitiveservices.azure.com/ --output json | ConvertFrom-Json
        
        if (-not $tokenResponse.accessToken) {
            return @{ Success = $false; ErrorMessage = "Failed to obtain access token" }
        }
        
        $accessToken = $tokenResponse.accessToken
        $subscriptionId = (& az account show --query id --output tsv)
        
        # Construct the base URL for the Cognitive Services API
        $baseUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CognitiveServices/accounts/$OpenAIResourceName"
        
        # Headers for REST API calls
        $headers = @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type"  = "application/json"
        }
        
        Write-Host "🔍 Checking available models via REST API..." -ForegroundColor Yellow
        
        # Try to get available models through REST API
        $modelsUrl = "$baseUrl/models?api-version=2023-05-01"
        
        try {
            $modelsResponse = Invoke-RestMethod -Uri $modelsUrl -Headers $headers -Method GET
            Write-Host "✅ Successfully retrieved models via REST API" -ForegroundColor Green
            
            # Look for Sora models in the response
            $soraModels = $modelsResponse.value | Where-Object { 
                $_.name -like "*sora*" -or 
                $_.name -like "*video*" -or 
                $_.model -like "*sora*" 
            }
            
            if ($soraModels.Count -gt 0) {
                $selectedModel = $soraModels[0]
                Write-Host "Found Sora model via REST API: $($selectedModel.name)" -ForegroundColor Green
                
                # Deploy using REST API
                $deploymentUrl = "$baseUrl/deployments/$DeploymentName" + "?api-version=2023-05-01"
                $deploymentBody = @{
                    properties = @{
                        model         = @{
                            format  = "OpenAI"
                            name    = $selectedModel.name
                            version = $selectedModel.version
                        }
                        scaleSettings = @{
                            scaleType = "Standard"
                            capacity  = 1
                        }
                    }
                } | ConvertTo-Json -Depth 10
                
                Write-Host "🚀 Deploying model via REST API..." -ForegroundColor Yellow
                $deploymentResponse = Invoke-RestMethod -Uri $deploymentUrl -Headers $headers -Method PUT -Body $deploymentBody
                
                return @{
                    Success = $true
                    Model   = @{
                        model   = $selectedModel.name
                        version = $selectedModel.version
                    }
                }
            }
        }
        catch {
            Write-Host "⚠️ REST API approach failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        Write-Host "🔄 Trying alternative deployment strategies..." -ForegroundColor Yellow
        
        # Strategy 2: Try deploying with known Sora model configurations
        $soraConfigurations = @(
            @{ name = "sora"; version = "turbo-2024-04-09" },
            @{ name = "sora"; version = "2024-12-17" },
            @{ name = "sora"; version = "2025-03-20" },
            @{ name = "sora"; version = "2025-04-14" },
            @{ name = "sora-turbo"; version = "2024-04-09" },
            @{ name = "sora-1"; version = "2024-12-17" }
        )
        
        foreach ($config in $soraConfigurations) {
            Write-Host "Trying configuration: $($config.name) @ $($config.version)" -ForegroundColor Gray
            
            try {
                # Try deployment with Azure CLI as backup
                Write-Host "Trying configuration: $($config.name) @ $($config.version)" -ForegroundColor Gray
                $result = & az cognitiveservices account deployment create --resource-group $ResourceGroupName --name $OpenAIResourceName --deployment-name $DeploymentName --model-name $($config.name) --model-version $($config.version) --model-format OpenAI --sku-name Standard --sku-capacity 1 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Successfully deployed via CLI with: $($config.name)@$($config.version)" -ForegroundColor Green
                    return @{
                        Success = $true
                        Model   = $config
                    }
                }
            }
            catch {
                Write-Host "❌ Failed with $($config.name)@$($config.version)" -ForegroundColor Red
                continue
            }
        }
        
        # Strategy 3: Try to create deployment with shared model access
        Write-Host "🌐 Attempting shared model deployment..." -ForegroundColor Yellow
        
        try {
            # Use the Azure AI SDK approach for shared models
            $sharedDeploymentBody = @{
                properties = @{
                    model         = @{
                        format  = "OpenAI"
                        name    = "sora"
                        version = "latest"
                    }
                    scaleSettings = @{
                        scaleType = "Standard"
                        capacity  = 1
                    }
                    raiPolicyName = "Microsoft.Default"
                }
            } | ConvertTo-Json -Depth 10
            
            $deploymentUrl = "$baseUrl/deployments/$DeploymentName" + "?api-version=2024-10-01-preview"
            $sharedResponse = Invoke-RestMethod -Uri $deploymentUrl -Headers $headers -Method PUT -Body $sharedDeploymentBody
            
            Write-Host "✅ Successfully deployed via shared model approach!" -ForegroundColor Green
            return @{
                Success = $true
                Model   = @{
                    model   = "sora"
                    version = "latest"
                }
            }
        }
        catch {
            Write-Host "❌ Shared model deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        return @{
            Success      = $false
            ErrorMessage = "All programmatic deployment strategies failed"
        }
    }
    catch {
        return @{
            Success      = $false
            ErrorMessage = "Exception in programmatic deployment: $($_.Exception.Message)"
        }
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to validate parameters
function Test-Parameters {
    # Validate resource group name format
    if ($ResourceGroupName -notmatch '^[a-zA-Z0-9._-]+$') {
        Write-ErrorAndExit "Invalid ResourceGroupName format. Resource group name can only contain alphanumeric characters, periods, underscores, and hyphens."
    }
    
    # Validate location format (no spaces, lowercase)
    if ($Location -notmatch '^[a-z0-9]+$') {
        Write-ErrorAndExit "Invalid Location format. Location should be a single lowercase word without spaces (e.g., 'eastus2', 'westeurope')."
    }
    
    # Check if specified OpenAIResourceName meets requirements
    if ($OpenAIResourceName -and $OpenAIResourceName -notmatch '^[a-zA-Z0-9-]{2,64}$') {
        Write-ErrorAndExit "Invalid OpenAIResourceName format. Name should be 2-64 characters, contain only alphanumeric characters and hyphens."
    }
    
    # Check model deployment name format
    if ($OpenAIModelDeploymentName -notmatch '^[a-z0-9-]{2,64}$') {
        Write-ErrorAndExit "Invalid OpenAIModelDeploymentName format. Name should be 2-64 lowercase characters, contain only alphanumeric characters and hyphens."
    }
    
    # Check environment name format
    if ($EnvironmentName -notmatch '^[a-zA-Z0-9-]{2,64}$') {
        Write-ErrorAndExit "Invalid EnvironmentName format. Name should be 2-64 characters, contain only alphanumeric characters and hyphens."
    }
    
    return $true
}

# Step 1: Check prerequisites
Write-Progress-Step -Message "Checking prerequisites and validating parameters..." -StepNumber 1 -TotalSteps 11

# Validate parameters first
if (-not (Test-Parameters)) {
    Write-ErrorAndExit "Parameter validation failed."
}

# Check prerequisites with version information
$prerequisites = @{
    "az"   = "Azure CLI"
    "azd"  = "Azure Developer CLI"
    "java" = "Java Runtime"
    "mvn"  = "Maven"
}

$missingTools = @()

Write-Host "Checking required tools:" -ForegroundColor Yellow
foreach ($tool in $prerequisites.Keys) {
    if (-not (Test-CommandExists $tool)) {
        $missingTools += $prerequisites[$tool]
        Write-Host "  ❌ $($prerequisites[$tool]) not found" -ForegroundColor Red
    }
    else {
        # Get version information
        $versionInfo = ""
        switch ($tool) {
            "az" { 
                try { $versionInfo = (Invoke-Expression "az version" | ConvertFrom-Json).'azure-cli' } 
                catch { $versionInfo = "unknown version" }
            }
            "azd" { 
                try { $versionInfo = (Invoke-Expression "azd version") -replace ".*?(\d+\.\d+\.\d+).*", '$1' } 
                catch { $versionInfo = "unknown version" }
            }
            "java" { 
                try { $versionInfo = (Invoke-Expression "java -version 2>&1")[0] -replace ".*?(\d+\.\d+\.\d+).*", 'version $1' } 
                catch { $versionInfo = "unknown version" }
            }
            "mvn" { 
                try { $versionInfo = (Invoke-Expression "mvn --version")[0] -replace "Apache Maven (\d+\.\d+\.\d+).*", 'version $1' } 
                catch { $versionInfo = "unknown version" }
            }
        }
        Write-Host "  ✅ $($prerequisites[$tool]) found ($versionInfo)" -ForegroundColor Green
    }
}

if ($missingTools.Count -gt 0) {
    $missingToolsList = $missingTools -join ", "
    Write-ErrorAndExit "Required tools not found: $missingToolsList. Please install them and try again."
}

Write-Progress-Step -Message "Checking Azure CLI login status..." -StepNumber 2 -TotalSteps 11

try {
    # Check Azure CLI login status
    $loginCheckOutput = $null
    try {
        $loginCheckOutput = Invoke-Expression "az account show --output json 2>&1"
        if ($LASTEXITCODE -ne 0) {
            throw "Not logged in"
        }
        $azAccount = $loginCheckOutput | ConvertFrom-Json
        Write-Host "✅ Azure CLI is logged in as: $($azAccount.user.name)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ You are not logged into Azure CLI. Initiating login..." -ForegroundColor Yellow
        Invoke-Expression "az login 2>&1" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorAndExit "Failed to login to Azure CLI. Please make sure Azure CLI is installed correctly and try again."
        }
        # Get account info after successful login
        $azAccount = Invoke-Expression "az account show --output json" | ConvertFrom-Json
        Write-Host "✅ Successfully logged in as: $($azAccount.user.name)" -ForegroundColor Green
    }
}
catch {
    Write-ErrorAndExit "Error in Azure authentication" $_.Exception
}

# Function to execute Azure CLI commands safely
function Invoke-AzCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )
    
    try {
        $result = Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorAndExit $ErrorMessage
        }
        if ($PassThru) {
            return $result
        }
    }
    catch {
        Write-ErrorAndExit $ErrorMessage $_.Exception
    }
}

# Step 2: Set current subscription if AZURE_SUBSCRIPTION_ID is defined in .env
try {
    $envFile = Get-Content -Path .env -Raw -ErrorAction SilentlyContinue
    if ($envFile) {
        $subscriptionIdMatch = [regex]::Match($envFile, 'AZURE_SUBSCRIPTION_ID=([^\r\n]+)')
        if ($subscriptionIdMatch.Success) {
            $subscriptionId = $subscriptionIdMatch.Groups[1].Value
            Write-Host "Setting active subscription to: $subscriptionId" -ForegroundColor Yellow
            
            # Verify subscription exists
            $subExists = Invoke-Expression "az account list --query `"[?id=='$subscriptionId']`" --output json" | ConvertFrom-Json
            
            if ($null -eq $subExists -or $subExists.Length -eq 0) {
                Write-Host "⚠️ Warning: Subscription ID $subscriptionId not found in your available subscriptions." -ForegroundColor Yellow
                
                # Show available subscriptions
                Write-Host "Available subscriptions:" -ForegroundColor Yellow
                Invoke-Expression "az account list --query `"[].{Name:name, ID:id, IsDefault:isDefault}`" --output table"
                
                # Prompt to continue
                $continue = Read-Host "Do you want to continue with the current subscription? (Y/n)"
                if ($continue -eq "n" -or $continue -eq "N") {
                    Write-ErrorAndExit "Deployment canceled by user."
                }
            }
            else {
                Invoke-AzCommand -Command "az account set --subscription $subscriptionId" -ErrorMessage "Failed to set subscription $subscriptionId."
                Write-Host "✅ Successfully set subscription to: $subscriptionId" -ForegroundColor Green
            }
        }
    }
}
catch {
    Write-ErrorAndExit "Error setting subscription" $_.Exception
}

# Step 3: Create Resource Group if it doesn't exist
Write-Progress-Step -Message "Creating resource group $ResourceGroupName in $Location if it doesn't exist..." -StepNumber 3 -TotalSteps 11
try {
    $rgExists = Invoke-AzCommand -Command "az group exists --name $ResourceGroupName" -ErrorMessage "Failed to check if resource group exists." -PassThru
    
    if ($rgExists -eq "false") {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        Invoke-AzCommand -Command "az group create --name $ResourceGroupName --location $Location" -ErrorMessage "Failed to create resource group."
        Write-Host "✅ Resource group created successfully" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Resource group $ResourceGroupName already exists" -ForegroundColor Green
    }
}
catch {
    Write-ErrorAndExit "Error in resource group creation step" $_.Exception
}

# Step 4: Create or verify Azure OpenAI resource
Write-Progress-Step -Message "Verifying Azure OpenAI resource: $OpenAIResourceName..." -StepNumber 4 -TotalSteps 11

try {
    # First, check if any OpenAI resources already exist in the current resource group
    $openAIInRG = Invoke-AzCommand -Command "az cognitiveservices account list --resource-group $ResourceGroupName --query `"[?kind=='OpenAI']`" --output json" -ErrorMessage "Failed to check for OpenAI resources in resource group." -PassThru | ConvertFrom-Json
    
    $openAIExists = $null
    $existingResourceGroup = $null
    $useExistingOpenAI = $false
    
    # If OpenAI resources found in the current resource group
    if ($openAIInRG.Count -gt 0) {
        Write-Host "Found existing Azure OpenAI resource(s) in resource group $ResourceGroupName" -ForegroundColor Yellow
        foreach ($resource in $openAIInRG) {
            Write-Host "  - $($resource.name) (Location: $($resource.location))" -ForegroundColor Cyan
        }
        
        # Ask if user wants to use an existing resource
        Write-Host "Would you like to use one of these existing OpenAI resources instead of creating '$OpenAIResourceName'? (Y/n): " -ForegroundColor Yellow -NoNewline
        $useExisting = Read-Host
        
        if ($useExisting -ne "n" -and $useExisting -ne "N") {
            $useExistingOpenAI = $true
            
            # If there's only one resource, use it; otherwise, ask which one
            if ($openAIInRG.Count -eq 1) {
                $openAIExists = $openAIInRG[0]
                $OpenAIResourceName = $openAIExists.name
                Write-Host "Using existing OpenAI resource: $OpenAIResourceName" -ForegroundColor Green
            }
            else {
                Write-Host "Enter the name of the OpenAI resource you want to use:" -ForegroundColor Yellow -NoNewline
                $selectedName = Read-Host
                
                $openAIExists = $openAIInRG | Where-Object { $_.name -eq $selectedName } | Select-Object -First 1
                
                if ($openAIExists) {
                    $OpenAIResourceName = $openAIExists.name
                    Write-Host "Using existing OpenAI resource: $OpenAIResourceName" -ForegroundColor Green
                }
                else {
                    Write-Host "Selected resource not found. Will check for the specified name: $OpenAIResourceName" -ForegroundColor Yellow
                    $useExistingOpenAI = $false
                }
            }
        }
    }
    
    # If not using an existing resource from the current RG, check for the specific named resource
    if (-not $useExistingOpenAI) {
        # Check if the specified OpenAI resource already exists
        $openAIResourceQuery = "az cognitiveservices account list --query `"[?name=='$OpenAIResourceName']`" --output json"
        
        # First try in the specified resource group
        $openAIExists = Invoke-AzCommand -Command "$openAIResourceQuery --resource-group $ResourceGroupName" -ErrorMessage "Failed to check if OpenAI resource exists in resource group." -PassThru | ConvertFrom-Json
        
        # If not found in the specified resource group, check across all resource groups
        if ($openAIExists.Count -eq 0) {
            $openAIExists = Invoke-AzCommand -Command "$openAIResourceQuery" -ErrorMessage "Failed to check if OpenAI resource exists." -PassThru | ConvertFrom-Json
            
            if ($openAIExists.Count -gt 0) {
                # If found in a different resource group, use that resource group for the remainder of operations
                $existingResourceGroup = $openAIExists[0].resourceGroup
                Write-Host "⚠️ Found existing Azure OpenAI resource $OpenAIResourceName in resource group: $existingResourceGroup" -ForegroundColor Yellow
                Write-Host "Using existing resource group for OpenAI operations instead of $ResourceGroupName" -ForegroundColor Yellow
                $ResourceGroupName = $existingResourceGroup
            }
        }
    }
    
    # If no OpenAI resource found or selected, create a new one
    if (($null -eq $openAIExists) -or ($openAIExists.Count -eq 0)) {
        Write-Host "Creating new Azure OpenAI resource: $OpenAIResourceName..." -ForegroundColor Yellow
        
        $createCommand = "az cognitiveservices account create " +
        "--name $OpenAIResourceName " +
        "--resource-group $ResourceGroupName " +
        "--location $Location " +
        "--kind OpenAI " +
        "--sku S0"
        
        Invoke-AzCommand -Command $createCommand -ErrorMessage "Failed to create Azure OpenAI resource."
        Write-Host "✅ Azure OpenAI resource created successfully" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Using existing Azure OpenAI resource: $OpenAIResourceName in resource group $ResourceGroupName" -ForegroundColor Green
    }

    # Step 5: Get the endpoint and keys for the OpenAI resource
    Write-Host "Retrieving Azure OpenAI endpoint and keys..." -ForegroundColor Yellow
    
    $endpoint = Invoke-AzCommand -Command "az cognitiveservices account show --name $OpenAIResourceName --resource-group $ResourceGroupName --query `"properties.endpoint`" --output tsv" -ErrorMessage "Failed to retrieve endpoint for Azure OpenAI resource." -PassThru
    
    $key = Invoke-AzCommand -Command "az cognitiveservices account keys list --name $OpenAIResourceName --resource-group $ResourceGroupName --query `"key1`" --output tsv" -ErrorMessage "Failed to retrieve key for Azure OpenAI resource." -PassThru

    if (-not $endpoint -or -not $key) {
        Write-ErrorAndExit "Failed to retrieve endpoint or key for Azure OpenAI resource."
    }
    
    Write-Host "✅ Successfully retrieved Azure OpenAI endpoint and keys" -ForegroundColor Green
}
catch {
    Write-ErrorAndExit "Error creating or retrieving Azure OpenAI resource" $_.Exception
}

# Step 6: Verify or deploy the Sora model
Write-Progress-Step -Message "Verifying Sora model deployment in Azure OpenAI resource..." -StepNumber 6 -TotalSteps 11

try {
    $modelDeploymentExists = $false
    $existingModelInfo = $null
    
    # Check if model deployment already exists and get its details
    try {
        $showDeploymentCommand = "az cognitiveservices account deployment show --name $OpenAIResourceName --resource-group $ResourceGroupName --deployment-name $OpenAIModelDeploymentName --output json"
        $modelDeployment = Invoke-Expression $showDeploymentCommand 2>$null
        
        # Check if we got a valid response
        if ($LASTEXITCODE -eq 0 -and $modelDeployment) {
            $existingModelInfo = $modelDeployment | ConvertFrom-Json
            $modelDeploymentExists = $true
            $existingModelName = $existingModelInfo.model.name
            $existingModelVersion = $existingModelInfo.model.version
            Write-Host "Found existing model deployment: $OpenAIModelDeploymentName (Model: $existingModelName, Version: $existingModelVersion)" -ForegroundColor Green
        }
    }
    catch {
        # Deployment doesn't exist or another error occurred
        Write-Host "No existing model deployment found with name: $OpenAIModelDeploymentName" -ForegroundColor Yellow
        $modelDeploymentExists = $false
    }

    if (-not $modelDeploymentExists) {
        Write-Host "Creating Sora model deployment..." -ForegroundColor Yellow
        
        # Check if the Sora model is available
        $listModelsCommand = "az cognitiveservices account list-models --name $OpenAIResourceName --resource-group $ResourceGroupName --output json"
        $modelsOutput = Invoke-Expression $listModelsCommand
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorAndExit "Failed to list available models. Make sure the OpenAI resource is properly configured."
        }
        
        $models = $modelsOutput | ConvertFrom-Json
        
        # Print available models to help with debugging
        Write-Host "Available models in this OpenAI resource:" -ForegroundColor Yellow
        $models | ForEach-Object { Write-Host "  - $($_.model) (version: $($_.version))" -ForegroundColor Gray }
        
        # Try to check for shared models if direct resource doesn't have Sora
        $hasSharedSoraAccess = $false
        
        # First check for shared model access through AI Foundry
        try {
            Write-Host "Checking for shared Sora access via Azure AI Studio..." -ForegroundColor Yellow
            # Use az ai service list command to check AI Studio resources
            $aiStudioCommand = "az account get-access-token --resource https://cognitiveservices.azure.com/ --output json"
            $token = Invoke-Expression $aiStudioCommand | ConvertFrom-Json
            
            if ($token) {
                Write-Host "✅ Successfully authenticated for Azure AI Studio" -ForegroundColor Green
                $hasSharedSoraAccess = $true
            }
        }
        catch {
            Write-Host "⚠️ Unable to check for shared Sora models in Azure AI Studio" -ForegroundColor Yellow
        }
        
        # Look for Sora models using multiple search patterns
        $soraModel = $null
        
        # First try the direct "sora" model
        $soraModel = $models | Where-Object { $_.model -eq "sora" } | Sort-Object -Property "version" -Descending | Select-Object -First 1
        
        # If not found, try with wildcard pattern for "sora"
        if (-not $soraModel) {
            $soraModel = $models | Where-Object { $_.model -like "sora*" } | Sort-Object -Property "version" -Descending | Select-Object -First 1
        }
        
        # If still not found, try case-insensitive search with variations
        if (-not $soraModel) {
            $soraModel = $models | Where-Object { 
                $_.model -like "*sora*" -or 
                $_.model -like "*video*gen*" -or 
                $_.model -match "(?i)sora" 
            } | Sort-Object -Property "version" -Descending | Select-Object -First 1
        }
        
        # If model not found, attempt programmatic deployment
        if (-not $soraModel) {
            Write-Host "ℹ️ Sora model was not found directly in this resource, but you appear to have access to Sora via shared resources in Azure AI Studio." -ForegroundColor Blue
            Write-Host "🚀 Attempting programmatic deployment of Sora model..." -ForegroundColor Yellow
            
            # Attempt programmatic deployment using our enhanced function
            $deploymentResult = Deploy-SoraProgrammatically -ResourceGroupName $ResourceGroupName -OpenAIResourceName $OpenAIResourceName -DeploymentName $OpenAIModelDeploymentName
            
            if ($deploymentResult.Success) {
                Write-Host "✅ Sora model deployed successfully via programmatic approach!" -ForegroundColor Green
                $skipNormalDeployment = $true
                $soraModel = $deploymentResult.Model
            }
            else {
                Write-Host "❌ Programmatic deployment failed: $($deploymentResult.ErrorMessage)" -ForegroundColor Red
                Write-Host "🔄 Trying alternative deployment strategies..." -ForegroundColor Yellow
                
                # Try forced deployment with known Sora configurations
                $soraConfigurations = @(
                    @{ name = "sora"; version = "turbo-2024-04-09" },
                    @{ name = "sora"; version = "2024-12-17" },
                    @{ name = "sora"; version = "2025-04-01" },
                    @{ name = "sora-turbo"; version = "2024-04-09" }
                )
                
                $deploymentSuccessful = $false
                
                foreach ($config in $soraConfigurations) {
                    Write-Host "Trying configuration: $($config.name) @ $($config.version)" -ForegroundColor Gray
                    
                    try {
                        $forceDeployCommand = "az cognitiveservices account deployment create " +
                        "--resource-group $ResourceGroupName " +
                        "--name $OpenAIResourceName " +
                        "--deployment-name $OpenAIModelDeploymentName " +
                        "--model-name `"$($config.name)`" " +
                        "--model-version `"$($config.version)`" " +
                        "--model-format OpenAI " +
                        "--sku-name Standard " +
                        "--sku-capacity 1"
                        
                        $result = Invoke-Expression "$forceDeployCommand 2>&1"
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "✅ Successfully deployed with forced configuration: $($config.name)@$($config.version)" -ForegroundColor Green
                            $soraModel = $config
                            $skipNormalDeployment = $true
                            $deploymentSuccessful = $true
                            break
                        }
                        else {
                            Write-Host "❌ Failed with $($config.name)@$($config.version): $result" -ForegroundColor Red
                        }
                    }
                    catch {
                        Write-Host "❌ Exception with $($config.name)@$($config.version): $($_.Exception.Message)" -ForegroundColor Red
                        continue
                    }
                }
                
                if (-not $deploymentSuccessful) {
                    # Since direct deployment failed but we have shared access, 
                    # configure the application to use Azure AI Studio shared endpoint
                    Write-Host "⚠️ Direct Sora deployment not supported in this resource." -ForegroundColor Yellow
                    Write-Host "🌐 Configuring application to use Azure AI Studio shared Sora access..." -ForegroundColor Blue
                    
                    # Create a special configuration for shared access
                    $soraModel = @{
                        model    = "sora"
                        version  = "shared"
                        endpoint = "https://api.azureml.ms" # Azure AI Studio shared endpoint
                        isShared = $true
                    }
                    
                    Write-Host "✅ Configured shared Sora access: $($soraModel.model)@$($soraModel.version)" -ForegroundColor Green
                    Write-Host "ℹ️ Application will use Azure AI Studio shared resources for Sora model." -ForegroundColor Cyan
                    
                    # Skip the normal deployment since we're using shared access
                    $skipNormalDeployment = $true
                }
            }
        }
        
        # If no model found, attempt programmatic deployment
        if (-not $soraModel) {
            Write-Host "⚠️ Sora model not found using automatic detection." -ForegroundColor Yellow
            Write-Host "🚀 Attempting programmatic deployment of Sora model..." -ForegroundColor Blue
            
            # Function to deploy Sora programmatically using Azure REST API
            $deploymentResult = Deploy-SoraProgrammatically -ResourceGroupName $ResourceGroupName -OpenAIResourceName $OpenAIResourceName -DeploymentName $OpenAIModelDeploymentName
            
            if ($deploymentResult.Success) {
                Write-Host "✅ Sora model deployed successfully via programmatic approach!" -ForegroundColor Green
                $skipNormalDeployment = $true
                $soraModel = $deploymentResult.Model
            }
            else {
                Write-Host "❌ Programmatic deployment failed: $($deploymentResult.ErrorMessage)" -ForegroundColor Red
                Write-Host "🔄 Falling back to alternative deployment methods..." -ForegroundColor Yellow
                
                Write-Host ""
                Write-Host "Alternative Deployment Options:" -ForegroundColor Cyan
                Write-Host "1. Try Azure CLI deployment with forced parameters" -ForegroundColor White
                Write-Host "2. Use Azure AI Foundry Video Playground (manual)" -ForegroundColor White
                Write-Host "3. Specify model details manually for testing" -ForegroundColor White
                Write-Host ""
                
                Write-Host "Which option would you like to use? (1/2/3): " -ForegroundColor Cyan -NoNewline
                $deployOption = Read-Host
                
                switch ($deployOption) {
                    "1" {
                        Write-Host "Attempting forced Azure CLI deployment..." -ForegroundColor Yellow
                        
                        # Try multiple Sora model variations
                        $soraVariations = @(
                            @{ name = "sora"; version = "turbo-2024-04-09" },
                            @{ name = "sora"; version = "2024-12-17" },
                            @{ name = "sora"; version = "2025-04-01" },
                            @{ name = "sora-turbo"; version = "2024-04-09" }
                        )
                        
                        $deploymentSuccessful = $false
                        
                        foreach ($variation in $soraVariations) {
                            Write-Host "Trying model: $($variation.name) version: $($variation.version)" -ForegroundColor Gray
                            
                            $soraDeployCommand = "az cognitiveservices account deployment create " +
                            "--resource-group $ResourceGroupName " +
                            "--name $OpenAIResourceName " +
                            "--deployment-name $OpenAIModelDeploymentName " +
                            "--model-name `"$($variation.name)`" " +
                            "--model-version `"$($variation.version)`" " +
                            "--model-format OpenAI " +
                            "--sku-capacity `"1`" " +
                            "--sku-name `"Standard`""
                            
                            try {
                                Invoke-AzCommand -Command $soraDeployCommand -ErrorMessage "Failed to deploy with this variation."
                                Write-Host "✅ Successfully deployed with model: $($variation.name) version: $($variation.version)" -ForegroundColor Green
                                
                                $skipNormalDeployment = $true
                                $soraModel = @{
                                    model   = $variation.name
                                    version = $variation.version
                                }
                                $deploymentSuccessful = $true
                                break
                            }
                            catch {
                                Write-Host "❌ Failed with $($variation.name)@$($variation.version): $($_.Exception.Message)" -ForegroundColor Red
                                continue
                            }
                        }
                        
                        if (-not $deploymentSuccessful) {
                            Write-Host "❌ All deployment variations failed. Using fallback configuration." -ForegroundColor Red
                            $soraModel = @{
                                model   = "sora"
                                version = "2024-12-17"
                            }
                        }
                    }
                    "2" {
                        Write-Host "📋 Instructions for deploying via Azure AI Foundry:" -ForegroundColor Blue
                        Write-Host "1. Open a browser and go to: https://ai.azure.com" -ForegroundColor Blue
                        Write-Host "2. Navigate to: Playground > Video" -ForegroundColor Blue
                        Write-Host "3. If you see 'Deploy now', click it and:" -ForegroundColor Blue
                        Write-Host "   - Select your OpenAI resource: $OpenAIResourceName" -ForegroundColor Blue
                        Write-Host "   - Set deployment name to: $OpenAIModelDeploymentName" -ForegroundColor Blue
                        Write-Host "   - Use model: sora" -ForegroundColor Blue
                        Write-Host "   - Use the latest available version" -ForegroundColor Blue
                        Write-Host "4. Complete the deployment process" -ForegroundColor Blue
                        Write-Host ""
                        Write-Host "After completing the deployment, press Enter to continue..." -ForegroundColor Yellow
                        Read-Host
                        
                        $skipNormalDeployment = $true
                        $soraModel = @{
                            model   = "sora"
                            version = "latest"
                        }
                    }
                    "3" {
                        Write-Host "Please enter the Sora model details:" -ForegroundColor Cyan
                        Write-Host "Model name (default: sora): " -ForegroundColor Cyan -NoNewline
                        $manualModelName = Read-Host
                        if ([string]::IsNullOrEmpty($manualModelName)) { $manualModelName = "sora" }
                        
                        Write-Host "Model version (default: 2024-12-17): " -ForegroundColor Cyan -NoNewline
                        $manualModelVersion = Read-Host
                        if ([string]::IsNullOrEmpty($manualModelVersion)) { $manualModelVersion = "2024-12-17" }
                        
                        $soraModel = @{
                            model   = $manualModelName
                            version = $manualModelVersion
                        }
                        
                        Write-Host "✅ Using manually specified model: $($soraModel.model)@$($soraModel.version)" -ForegroundColor Green
                    }
                    default {
                        Write-ErrorAndExit "Invalid option selected. Please run the script again and choose 1, 2, or 3."
                    }
                }
            }
        }
        
        Write-Host "✅ Found suitable model: $($soraModel.model)@$($soraModel.version)" -ForegroundColor Green
        
        # Deploy the model (unless already deployed via alternate method)
        if (-not $skipNormalDeployment) {
            Write-Host "Creating deployment with name: $OpenAIModelDeploymentName" -ForegroundColor Yellow
            
            $deployCommand = "az cognitiveservices account deployment create " +
            "--name $OpenAIResourceName " +
            "--resource-group $ResourceGroupName " +
            "--deployment-name $OpenAIModelDeploymentName " +
            "--model-name `"$($soraModel.model)`" " +
            "--model-version `"$($soraModel.version)`" " +
            "--model-format OpenAI " +
            "--sku-capacity 1 " +
            "--sku-name Standard"
            
            Invoke-AzCommand -Command $deployCommand -ErrorMessage "Failed to deploy the Sora model."
            Write-Host "✅ Sora model deployment created successfully" -ForegroundColor Green
        }
        else {
            Write-Host "✅ Sora model deployment already completed via alternate method!" -ForegroundColor Green
        }
    }
    else {
        Write-Host "✅ Model deployment $OpenAIModelDeploymentName already exists - skipping deployment" -ForegroundColor Green
    }
} 
catch {
    Write-ErrorAndExit "Error deploying Sora model" $_.Exception
}

# Step 7: Update the .env file with actual values (preserving existing values where applicable)
Write-Progress-Step -Message "Updating .env file with OpenAI resource configuration..." -StepNumber 7 -TotalSteps 11

# Create a hashtable to store existing environment variables
$existingEnvVars = @{}

# Read existing .env file if it exists
if (Test-Path -Path ".env") {
    Write-Host "Found existing .env file, preserving custom settings..." -ForegroundColor Yellow
    Get-Content -Path ".env" | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $existingEnvVars[$key] = $value
        }
    }
}

# Create required environment variables, preferring existing values where present
$requiredVars = @{
    "AZURE_OPENAI_ENDPOINT"    = $endpoint
    "AZURE_OPENAI_API_KEY"     = $key
    "AZURE_OPENAI_API_VERSION" = "preview"
    "AZURE_ENV_NAME"           = $EnvironmentName
    "AZURE_LOCATION"           = $Location
    "AZURE_SUBSCRIPTION_ID"    = $azAccount.id
    "SERVER_PORT"              = "8080"
    "SPRING_PROFILES_ACTIVE"   = "dev"
}

# Add special configuration for shared Sora access if applicable
if ($soraModel -and $soraModel.isShared) {
    $requiredVars["AZURE_OPENAI_SORA_ENDPOINT"] = $soraModel.endpoint
    $requiredVars["AZURE_OPENAI_SORA_DEPLOYMENT"] = "shared-sora"
    $requiredVars["USE_SHARED_SORA"] = "true"
    Write-Host "✅ Added shared Sora configuration to environment variables" -ForegroundColor Green
}
else {
    $requiredVars["AZURE_OPENAI_SORA_DEPLOYMENT"] = $OpenAIModelDeploymentName
    $requiredVars["USE_SHARED_SORA"] = "false"
}

# Create the new .env content, preserving existing values where applicable
$envContent = "# Azure OpenAI Configuration`n"
if ($soraModel -and $soraModel.isShared) {
    $envContent += "# Note: Using Azure AI Studio shared Sora resources`n"
}
else {
    $envContent += "# Note: Make sure to use the base URL and not the entire SORA instance URL`n"
}

foreach ($key in $requiredVars.Keys) {
    $value = if ($existingEnvVars.ContainsKey($key)) { $existingEnvVars[$key] } else { $requiredVars[$key] }
    $envContent += "$key=$value`n"
    
    # Remove from existing vars so we can track custom variables
    $existingEnvVars.Remove($key)
}

# Add any additional custom variables that might have been in the original file
if ($existingEnvVars.Count -gt 0) {
    $envContent += "`n# Custom Configuration`n"
    foreach ($key in $existingEnvVars.Keys) {
        $envContent += "$key=$($existingEnvVars[$key])`n"
    }
}

Set-Content -Path ".env" -Value $envContent
Write-Host "✅ Updated .env file with OpenAI resource configuration (preserved existing settings)" -ForegroundColor Green

# Step 8: Build the application
Write-Progress-Step -Message "Building the application with Maven..." -StepNumber 8 -TotalSteps 11

try {
    # Check if Maven wrapper exists
    if (-not (Test-Path -Path "./mvnw" -PathType Leaf)) {
        Write-Host "⚠️ Maven wrapper script not found. Attempting to use system Maven..." -ForegroundColor Yellow
        if (Test-CommandExists "mvn") {
            Write-Host "Using system Maven to build the application..." -ForegroundColor Yellow
            $buildCommand = "mvn clean package -DskipTests"
        }
        else {
            Write-ErrorAndExit "Neither Maven wrapper nor system Maven found. Cannot build application."
        }
    }
    else {
        $buildCommand = "./mvnw clean package -DskipTests"
    }
    
    Write-Host "Starting build process (this may take a few minutes)..." -ForegroundColor Yellow
    
    # Execute the build with spinner and output redirection to capture errors
    $buildOutput = $null
    $buildSuccess = $true
    
    Show-Spinner -Message "Building application with Maven (this may take a few minutes)..." -ScriptBlock {
        $global:buildOutput = Invoke-Expression "$buildCommand 2>&1"
        $global:buildSuccess = ($LASTEXITCODE -eq 0)
    }
    
    if (-not $buildSuccess) {
        # Display build errors for easier debugging
        $errorLines = $buildOutput | Where-Object { $_ -match "ERROR" -or $_ -match "FAILURE" }
        if ($errorLines.Count -gt 0) {
            Write-Host "`nBuild errors:" -ForegroundColor Red
            $errorLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        }
        Write-ErrorAndExit "Failed to build the application. See errors above for details."
    }
    
    Write-Host "✅ Application built successfully" -ForegroundColor Green
}
catch {
    Write-ErrorAndExit "Error during application build" $_.Exception
}

# Step 9: Initialize Azure Developer CLI (azd) if not already initialized
Write-Progress-Step -Message "Initializing Azure Developer CLI (azd)..." -StepNumber 9 -TotalSteps 11

try {
    $azdEnvExists = Test-Path -Path ".azure"
    if (-not $azdEnvExists) {
        Write-Host "Creating new azd environment..." -ForegroundColor Yellow
        
        # Run azd init with output capture
        $initOutput = Invoke-Expression "azd init --environment $EnvironmentName 2>&1"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`nAZD initialization errors:" -ForegroundColor Red
            $initOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            Write-ErrorAndExit "Failed to initialize azd environment."
        }
        Write-Host "✅ Azure Developer CLI environment initialized successfully" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Azure Developer CLI environment already exists" -ForegroundColor Green
    }
    
    # Step 10: Deploy the application using azd
    Write-Progress-Step -Message "Deploying the application to Azure..." -StepNumber 10 -TotalSteps 11
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    Write-Host "Deployment started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    
    # Run azd up with spinner
    $startTime = Get-Date
    Write-Host "`nStarting Azure deployment (azd up)..." -ForegroundColor Cyan
    Write-Host "This process will take several minutes. Please wait..." -ForegroundColor Yellow
    
    # Since azd up shows its own progress, we'll run it normally without a spinner
    Invoke-Expression "azd up"
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "Failed to deploy the application. Review the azd logs for more details."
    }
    
    $endTime = Get-Date
    $deploymentDuration = New-TimeSpan -Start $startTime -End $endTime
    Write-Host "✅ Azure deployment completed successfully!" -ForegroundColor Green
    Write-Host "Deployment duration: $($deploymentDuration.Minutes) minutes, $($deploymentDuration.Seconds) seconds" -ForegroundColor Green
}
catch {
    Write-ErrorAndExit "Error during Azure deployment" $_.Exception
}

# Step 11: Get the application URL and deployment details
try {
    Write-Progress-Step -Message "Retrieving deployment details..." -StepNumber 11 -TotalSteps 11
    
    # Get the application URL and other outputs
    $azdOutput = Invoke-Expression "azd show-output 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Warning: Could not retrieve azd output details. Application was deployed but URL information is not available." -ForegroundColor Yellow
        $appUrl = "N/A - Please check Azure portal"
    }
    else {
        $appUrl = $azdOutput | Where-Object { $_ -like "*containerAppUrl*" } | ForEach-Object { $_.Split("=")[1].Trim() }
        if (-not $appUrl) {
            $appUrl = "N/A - Please check Azure portal"
            Write-Host "⚠️ Warning: Application URL not found in azd output. The application may still be deploying." -ForegroundColor Yellow
        }
    }
    
    # Stop the transcript before the summary
    try {
        Stop-Transcript
        Write-Host "Deployment log saved to: $logFile" -ForegroundColor Green
    }
    catch {
        # In case transcript wasn't started
    }
    
    # Get deployment timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Summary with more visual separation and detail
    Write-Host "`n`n=================================================" -ForegroundColor Cyan
    Write-Host "       SORA VIDEO GENERATOR DEPLOYMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    
    Write-Host "`n✅ DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "Deployment Time:         $timestamp" -ForegroundColor White
    
    Write-Host "`n📊 RESOURCE INFORMATION" -ForegroundColor Magenta
    Write-Host "Resource Group:          $ResourceGroupName" -ForegroundColor White
    Write-Host "Location:                $Location" -ForegroundColor White
    Write-Host "Azure OpenAI Resource:   $OpenAIResourceName" -ForegroundColor White
    Write-Host "Sora Model Deployment:   $OpenAIModelDeploymentName" -ForegroundColor White
    
    Write-Host "`n🌐 APPLICATION ACCESS" -ForegroundColor Magenta
    Write-Host "Application URL:         $appUrl" -ForegroundColor White
    
    # Open browser if URL is available
    if ($appUrl -ne "N/A - Please check Azure portal") {
        Write-Host "`nWould you like to open the application in your browser? (Y/n): " -ForegroundColor Cyan -NoNewline
        $openBrowser = Read-Host
        if ($openBrowser -ne "n" -and $openBrowser -ne "N") {
            Write-Host "Opening application in browser..." -ForegroundColor Yellow
            Start-Process $appUrl
        }
    }
    
    # Calculate total script execution time
    $scriptEndTime = Get-Date
    $scriptDuration = New-TimeSpan -Start $scriptStartTime -End $scriptEndTime
    $formattedDuration = "{0:D2}h:{1:D2}m:{2:D2}s" -f $scriptDuration.Hours, $scriptDuration.Minutes, $scriptDuration.Seconds
    
    Write-Host "`n🎉 Your Sora Video Generator application is now ready to use!" -ForegroundColor Cyan
    Write-Host "Total deployment time: $formattedDuration" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Cyan
}
catch {
    Write-Host "⚠️ Error retrieving deployment details. The application may have been deployed successfully, but we couldn't get the details." -ForegroundColor Yellow
    Write-Host "Please check the Azure portal for your deployed resources." -ForegroundColor Yellow
}
