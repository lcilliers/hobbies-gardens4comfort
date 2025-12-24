# PowerShell script to update DNS records on domain controller for gardens4comfort.uk
# Run this script on UKCODC01.lsusa.local with Administrator privileges

# DNS Zone name
$zoneName = "gardens4comfort.uk"

# GitHub Pages IP addresses
$githubIPs = @(
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153"
)

# Remove existing records if they exist (to avoid conflicts)
Write-Host "Removing existing DNS records if present..." -ForegroundColor Yellow

try {
    # Remove old www CNAME if exists
    Remove-DnsServerResourceRecord -ZoneName $zoneName -Name "www" -RRType CNAME -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed existing www CNAME record" -ForegroundColor Green
} catch {
    Write-Host "  No existing www CNAME to remove" -ForegroundColor Gray
}

try {
    # Remove old apex A records if exist
    Get-DnsServerResourceRecord -ZoneName $zoneName -Name "@" -RRType A -ErrorAction SilentlyContinue | 
        Where-Object { $_.RecordData.IPv4Address.IPAddressToString -in $githubIPs } |
        Remove-DnsServerResourceRecord -ZoneName $zoneName -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed existing apex A records" -ForegroundColor Green
} catch {
    Write-Host "  No existing apex A records to remove" -ForegroundColor Gray
}

# Add new CNAME record for www subdomain
Write-Host "`nAdding new DNS records..." -ForegroundColor Yellow

try {
    Add-DnsServerResourceRecordCName -ZoneName $zoneName -Name "www" -HostNameAlias "lcilliers.github.io" -TimeToLive 01:00:00
    Write-Host "  ✓ Added CNAME: www.gardens4comfort.uk -> lcilliers.github.io" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to add CNAME: $($_.Exception.Message)" -ForegroundColor Red
}

# Add A records for apex domain
foreach ($ip in $githubIPs) {
    try {
        Add-DnsServerResourceRecordA -ZoneName $zoneName -Name "@" -IPv4Address $ip -TimeToLive 01:00:00
        Write-Host "  ✓ Added A record: gardens4comfort.uk -> $ip" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to add A record for ${ip}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify the records
Write-Host "`nVerifying DNS records..." -ForegroundColor Yellow
Write-Host "`nCNAME Records:" -ForegroundColor Cyan
Get-DnsServerResourceRecord -ZoneName $zoneName -Name "www" -RRType CNAME | Select-Object HostName, RecordType, @{Name='Target';Expression={$_.RecordData.HostNameAlias}}

Write-Host "`nA Records (apex domain):" -ForegroundColor Cyan
Get-DnsServerResourceRecord -ZoneName $zoneName -Name "@" -RRType A | Select-Object HostName, RecordType, @{Name='IPAddress';Expression={$_.RecordData.IPv4Address}}

Write-Host "`n✓ DNS records updated successfully!" -ForegroundColor Green
Write-Host "Note: Run 'ipconfig /flushdns' on client machines to clear DNS cache" -ForegroundColor Yellow
