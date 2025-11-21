# Script to test the stats.yml workflow locally using act

Write-Host "Testing GitHub Actions workflow locally with act" -ForegroundColor Green
Write-Host ""

# Check if act is available
if (!(Get-Command act -ErrorAction SilentlyContinue)) {
    Write-Host "Error: act is not found in PATH. Please restart your terminal." -ForegroundColor Red
    exit 1
}

# Check if Docker is running
$dockerRunning = docker info 2>$null
if (!$?) {
    Write-Host "Error: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "Running the stats.yml workflow..." -ForegroundColor Cyan
Write-Host ""

# Run act with workflow_dispatch trigger
# -j specifies the job name
# --secret-file can be used to pass secrets (create .secrets file with GITHUB_TOKEN=your_token)
act workflow_dispatch -j update_stats -W .github/workflows/stats.yml

Write-Host ""
Write-Host "Workflow execution completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Check the following files:" -ForegroundColor Yellow
Write-Host "  - README.md (updated with stats)" -ForegroundColor White
Write-Host "  - stats_timeline.png (closed issues chart)" -ForegroundColor White
Write-Host "  - stats_publishers_timeline.png (publishers chart)" -ForegroundColor White
Write-Host ""
Write-Host "To test locally without Docker, run:" -ForegroundColor Yellow
Write-Host "  bash stats.sh" -ForegroundColor White
