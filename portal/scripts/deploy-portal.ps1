<#
.SYNOPSIS
    Deploys APIM developer portal customizations from source-controlled artifacts.

.DESCRIPTION
    Imports developer portal content from the portal/artifacts directory into a
    target Azure API Management instance, then optionally publishes the portal.

    Designed for non-interactive execution inside Azure DevOps pipelines via the
    AzureCLI@2 task (which handles Azure authentication automatically). Can also
    be run locally after 'az login'.

.PARAMETER Environment
    Target environment name (e.g. sbox, dev, test, stg, prod). Used to load an
    optional per-environment substitution config from portal/config/<env>.json.

.PARAMETER SubscriptionId
    Azure subscription ID. When running inside an AzureCLI@2 task this is
    provided automatically; when running locally, defaults to the current
    'az account' subscription.

.PARAMETER ResourceGroupName
    The resource group containing the target APIM instance.

.PARAMETER ApimName
    The name of the target APIM service (e.g. sps-api-mgmt-sbox).

.PARAMETER ArtifactsPath
    Path to the portal artifacts directory. Defaults to portal/artifacts relative
    to the script's parent directory.

.PARAMETER ConfigPath
    Path to the portal config directory containing <env>.json files. Defaults to
    portal/config relative to the script's parent directory.

.PARAMETER Publish
    Switch: when specified, creates a new portal revision and sets it as current,
    making the imported changes visible to portal visitors.

.EXAMPLE
    # Local usage (authenticate first):
    az login
    .\deploy-portal.ps1 `
        -Environment sbox `
        -SubscriptionId "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" `
        -ResourceGroupName "rg-sps-platform-sbox" `
        -ApimName "sps-api-mgmt-sbox" `
        -Publish

.NOTES
    Prerequisites:
    - Azure CLI 2.30 or later
    - API Management Service Contributor role on the APIM instance
    - Storage Blob Data Contributor on the APIM-associated storage account (for media)

    The script will exit with a non-zero code if the artifacts directory is missing,
    causing the pipeline stage to fail with a clear error message.

    Rollback: re-run the script pointing at a previous artifact commit/tag, or
    revert the portal/artifacts commit and trigger the pipeline.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = '',

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$ApimName,

    [Parameter(Mandatory = $false)]
    [string]$ArtifactsPath = '',

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = '',

    [switch]$Publish
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Resolve default paths relative to this script's location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PortalDir = Split-Path -Parent $ScriptDir
if (-not $ArtifactsPath) { $ArtifactsPath = Join-Path $PortalDir 'artifacts' }
if (-not $ConfigPath)    { $ConfigPath    = Join-Path $PortalDir 'config' }

# Resolve subscription from current az context when not provided
if (-not $SubscriptionId) {
    $accountJson    = az account show --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Failed to retrieve current Azure subscription: $accountJson" }
    $SubscriptionId = ($accountJson | ConvertFrom-Json).id
}

Write-Host '=== APIM Developer Portal Deploy ==='
Write-Host "Environment    : $Environment"
Write-Host "Subscription   : $SubscriptionId"
Write-Host "Resource Group : $ResourceGroupName"
Write-Host "APIM Name      : $ApimName"
Write-Host "Artifacts Path : $ArtifactsPath"
Write-Host "Config Path    : $ConfigPath"
Write-Host "Publish Portal : $($Publish.IsPresent)"
Write-Host ''

# Validate artifacts directory
$contentDir  = Join-Path $ArtifactsPath 'content'
$contentFile = Join-Path $contentDir 'content.json'

if (-not (Test-Path $ArtifactsPath)) {
    Write-Error "Artifacts directory not found: $ArtifactsPath`nRun portal/scripts/export-portal.ps1 to populate it, then commit the results."
    exit 1
}

$apiVersion = '2022-08-01'
$baseUrl    = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimName"

function Invoke-ApimApi {
    param (
        [string]$Uri,
        [string]$Method      = 'GET',
        [string]$Body        = '',
        [switch]$IgnoreErrors
    )
    $cliArgs = @('rest', '--method', $Method, '--uri', $Uri, '--output', 'json')
    if ($Body) { $cliArgs += @('--body', $Body) }

    $result = az @cliArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($IgnoreErrors) {
            Write-Warning "Non-fatal REST call error ($Method $Uri): $result"
            return $null
        }
        throw "Azure CLI REST call failed ($Method $Uri):`n$result"
    }
    return ($result | ConvertFrom-Json)
}

function Apply-EnvSubstitutions {
    param ([string]$Content, [PSCustomObject]$Config)
    if (-not $Config -or -not $Config.substitutions) { return $Content }
    foreach ($prop in $Config.substitutions.PSObject.Properties) {
        $Content = $Content.Replace($prop.Name, $prop.Value)
    }
    return $Content
}

# Load optional environment-specific config for substitutions
$envConfig = $null
$envConfigFile = Join-Path $ConfigPath "$Environment.json"
if (Test-Path $envConfigFile) {
    Write-Host "Loading environment config: $envConfigFile"
    $envConfig = Get-Content $envConfigFile -Raw | ConvertFrom-Json
}
else {
    Write-Host "No environment config found at $envConfigFile (skipping substitutions)."
}

# 1. Import portal content items
if (Test-Path $contentFile) {
    Write-Host 'Importing portal content items...'
    $rawContent = Get-Content $contentFile -Raw
    if ($envConfig) {
        $rawContent = Apply-EnvSubstitutions -Content $rawContent -Config $envConfig
    }

    # ConvertFrom-Json without -AsHashtable for compatibility with older PowerShell
    $allContent = $rawContent | ConvertFrom-Json
    $contentTypes = $allContent.PSObject.Properties.Name

    foreach ($ctId in $contentTypes) {
        Write-Host "  Content type: $ctId"
        $typeData = $allContent.$ctId
        $items    = if ($typeData.items) { $typeData.items } else { @() }
        $count    = 0

        foreach ($item in $items) {
            $itemId  = ($item.id -split '/contentItems/')[1]
            $itemUri = "$baseUrl/contentTypes/$ctId/contentItems/$($itemId)?api-version=$apiVersion"
            $itemBody = $item | ConvertTo-Json -Depth 20 -Compress

            Invoke-ApimApi -Uri $itemUri -Method 'PUT' -Body $itemBody -IgnoreErrors | Out-Null
            $count++
        }
        Write-Host "    Upserted $count item(s)."
    }
    Write-Host '  Content import complete.'
}
else {
    Write-Warning "No content.json found at $contentFile. Skipping content import."
}

# 2. Upload media files
$mediaDir = Join-Path $ArtifactsPath 'media'
if (Test-Path $mediaDir) {
    $mediaFiles = Get-ChildItem -Path $mediaDir -Recurse -File
    if ($mediaFiles.Count -gt 0) {
        Write-Host "Uploading $($mediaFiles.Count) media file(s)..."
        try {
            $mediaSecrets = az rest `
                --method post `
                --uri "$baseUrl/portalSettings/mediaContent/listSecrets?api-version=$apiVersion" `
                --output json 2>&1

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Could not retrieve media SAS URL (non-fatal): $mediaSecrets"
            }
            else {
                $mediaInfo      = $mediaSecrets | ConvertFrom-Json
                $sasUrl         = $mediaInfo.containerSasUrl
                $containerUrl   = $sasUrl -replace '\?.*', ''
                $sasToken       = ($sasUrl -split '\?', 2)[1]
                $containerName  = ($containerUrl -split '/')[-1]
                $storageAccount = (($containerUrl -split '//')[1] -split '\.')[0]

                az storage blob upload-batch `
                    --source       $mediaDir `
                    --destination  $containerName `
                    --account-name $storageAccount `
                    --sas-token    "?$sasToken" `
                    --overwrite `
                    --output none 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host '  Media upload complete.'
                }
                else {
                    Write-Warning '  Media upload encountered errors; some assets may be missing from the portal.'
                }
            }
        }
        catch {
            Write-Warning "Media upload error (non-fatal): $_"
        }
    }
    else {
        Write-Host 'No media files to upload.'
    }
}

# 3. Publish the portal
if ($Publish) {
    Write-Host 'Publishing developer portal...'
    $revisionId  = "deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $publishBody = @{
        properties = @{
            description = "Automated deployment from Azure DevOps - environment: $Environment"
            isCurrent   = $true
        }
    } | ConvertTo-Json -Compress

    Invoke-ApimApi `
        -Uri    "$baseUrl/portalRevisions/$($revisionId)?api-version=$apiVersion" `
        -Method 'PUT' `
        -Body   $publishBody `
        -IgnoreErrors | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Portal revision '$revisionId' created and published."
    }
    else {
        Write-Warning "  Portal publish step failed. Content was imported but the portal may need to be published manually via the Azure portal."
    }
}

Write-Host ''
Write-Host 'Developer portal deployment complete.'
