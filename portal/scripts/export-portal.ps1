<#
.SYNOPSIS
    Exports APIM developer portal customizations to source-controlled artifacts.

.DESCRIPTION
    Connects to an existing Azure API Management instance and exports all developer
    portal content (pages, layouts, styles, templates, media) to the portal/artifacts
    directory for source control and subsequent promotion through environments.

    The script uses the Azure Resource Manager REST API (via Azure CLI) and requires
    no additional tooling beyond the Azure CLI.

.PARAMETER Environment
    The source environment name (e.g. sbox, dev, test, stg, prod). Used only for
    metadata labelling; it does not affect which APIM instance is targeted.

.PARAMETER SubscriptionId
    The Azure subscription ID containing the APIM instance.

.PARAMETER ResourceGroupName
    The resource group containing the APIM instance.

.PARAMETER ApimName
    The name of the APIM service (e.g. sps-api-mgmt-sbox).

.PARAMETER OutputPath
    Path to write exported artifacts. Defaults to the portal/artifacts directory
    adjacent to the scripts directory (i.e. ../artifacts relative to this script).

.EXAMPLE
    # Authenticate first:
    az login
    az account set --subscription "bd2864ed-4f3e-45ed-9c6a-8d179674bab1"

    # Export from sbox:
    .\export-portal.ps1 `
        -Environment sbox `
        -SubscriptionId "bd2864ed-4f3e-45ed-9c6a-8d179674bab1" `
        -ResourceGroupName "rg-sps-platform-sbox" `
        -ApimName "sps-api-mgmt-sbox"

.NOTES
    Prerequisites:
    - Azure CLI 2.30 or later installed and authenticated (az login / service principal)
    - Contributor or API Management Service Contributor role on the APIM instance
    - Storage Blob Data Reader on the APIM-associated storage account (for media export)

    The APIM instance name and resource group for each environment can be found from
    the Terraform outputs produced by the components/apim stage:
      terraform -chdir=components/apim output apim_name
      terraform -chdir=components/apim output resource_group_name

    After running this script, review changes with 'git diff portal/artifacts' and
    commit them to the repository so CI/CD can promote the content to other environments.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$ApimName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Resolve default output path relative to this script's location
if (-not $OutputPath) {
    $ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
    $OutputPath = Join-Path (Split-Path -Parent $ScriptDir) 'artifacts'
}

Write-Host "=== APIM Developer Portal Export ==="
Write-Host "Environment    : $Environment"
Write-Host "Subscription   : $SubscriptionId"
Write-Host "Resource Group : $ResourceGroupName"
Write-Host "APIM Name      : $ApimName"
Write-Host "Output Path    : $OutputPath"
Write-Host ''

# Ensure output subdirectories exist
$contentDir = Join-Path $OutputPath 'content'
$mediaDir   = Join-Path $OutputPath 'media'
New-Item -ItemType Directory -Path $contentDir -Force | Out-Null
New-Item -ItemType Directory -Path $mediaDir   -Force | Out-Null

$apiVersion = '2022-08-01'
$baseUrl    = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ApiManagement/service/$ApimName"

function Invoke-ApimApi {
    param (
        [string]$Uri,
        [string]$Method = 'GET'
    )
    $result = az rest --method $Method --uri $Uri --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI REST call failed (HTTP $Method $Uri):`n$result"
    }
    return ($result | ConvertFrom-Json)
}

# 1. Portal settings (sign-in, sign-up, delegation)
Write-Host 'Exporting portal settings...'
try {
    $settings = @{
        signin     = Invoke-ApimApi -Uri "$baseUrl/portalsettings/signin?api-version=$apiVersion"
        signup     = Invoke-ApimApi -Uri "$baseUrl/portalsettings/signup?api-version=$apiVersion"
        delegation = Invoke-ApimApi -Uri "$baseUrl/portalsettings/delegation?api-version=$apiVersion"
    }
    $settings | ConvertTo-Json -Depth 20 |
        Set-Content -Path (Join-Path $contentDir 'portalsettings.json') -Encoding UTF8
    Write-Host '  Portal settings exported.'
}
catch {
    Write-Warning "  Could not export portal settings (non-fatal): $_"
}

# 2. Content types and their items (pages, layouts, widgets, styles, etc.)
Write-Host 'Exporting content types and items...'
$contentTypes = Invoke-ApimApi -Uri "$baseUrl/contentTypes?api-version=$apiVersion"
$allContent   = [ordered]@{}

foreach ($ct in $contentTypes.value) {
    $ctId = ($ct.id -split '/contentTypes/')[1]
    Write-Host "  Content type: $ctId"

    $items = Invoke-ApimApi -Uri "$baseUrl/contentTypes/$ctId/contentItems?api-version=$apiVersion"
    $allContent[$ctId] = @{
        contentType = $ct
        items       = $items.value
    }
}

$allContent | ConvertTo-Json -Depth 20 |
    Set-Content -Path (Join-Path $contentDir 'content.json') -Encoding UTF8
Write-Host "  Exported $($allContent.Keys.Count) content type(s)."

# 3. Media / blob storage assets
Write-Host 'Exporting media files...'
try {
    $mediaSecrets = az rest `
        --method post `
        --uri "$baseUrl/portalSettings/mediaContent/listSecrets?api-version=$apiVersion" `
        --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  Could not retrieve media SAS URL (non-fatal): $mediaSecrets"
    }
    else {
        $mediaInfo      = $mediaSecrets | ConvertFrom-Json
        $sasUrl         = $mediaInfo.containerSasUrl
        $containerUrl   = $sasUrl -replace '\?.*', ''
        $sasToken       = ($sasUrl -split '\?', 2)[1]
        $containerName  = ($containerUrl -split '/')[-1]
        $storageAccount = (($containerUrl -split '//')[1] -split '\.')[0]

        Write-Host "  Downloading media from storage account: $storageAccount / container: $containerName"
        az storage blob download-batch `
            --destination $mediaDir `
            --source      $containerName `
            --account-name $storageAccount `
            --sas-token   "?$sasToken" `
            --output none 2>&1

        if ($LASTEXITCODE -eq 0) {
            $mediaCount = (Get-ChildItem -Path $mediaDir -Recurse -File).Count
            Write-Host "  Media export complete ($mediaCount file(s))."
        }
        else {
            Write-Warning "  Media download encountered errors; some assets may be missing."
        }
    }
}
catch {
    Write-Warning "  Media export skipped: $_"
}

# 4. Write export metadata for traceability
$metadata = [ordered]@{
    exportedAt     = (Get-Date -Format 'o')
    environment    = $Environment
    subscriptionId = $SubscriptionId
    resourceGroup  = $ResourceGroupName
    apimName       = $ApimName
}
$metadata | ConvertTo-Json |
    Set-Content -Path (Join-Path $OutputPath 'export-metadata.json') -Encoding UTF8

Write-Host ''
Write-Host "Export complete. Artifacts written to: $OutputPath"
Write-Host "Next steps:"
Write-Host "  git diff portal/artifacts    # review what changed"
Write-Host "  git add portal/artifacts"
Write-Host "  git commit -m 'chore: update APIM developer portal artifacts'"
Write-Host "  git push                     # CI/CD will promote to other environments"
