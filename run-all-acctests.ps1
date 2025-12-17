param(
    [switch]$rerun
)

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$acctestDir = Join-Path $scriptDir "azurermacctest"

# Check if azurermacctest directory exists
if (-not (Test-Path $acctestDir)) {
    Write-Error "Directory 'azurermacctest' not found at: $acctestDir"
    exit 1
}

# Get all subdirectories in azurermacctest
$subDirs = Get-ChildItem -Path $acctestDir -Directory | Sort-Object Name

if ($subDirs.Count -eq 0) {
    Write-Warning "No subdirectories found in 'azurermacctest'"
    exit 0
}

Write-Host "Found $($subDirs.Count) test case(s) in azurermacctest" -ForegroundColor Cyan
Write-Host ""

# Prepare the prompt based on the rerun parameter
if ($rerun) {
    $promptTemplate = "Read ``terraform-test.md`` and play as a tester role, but in debug mode, which means you'll proceed step by step, each step must have my permission. You WILL NOT take any action without my permission. Your given task is ``azurermacctest/{0}``. You should check case status first in ``test_cases.md``, if it's status is ``invalid``, skip it. Otherwise, even it's test status is ``test success``, you still need to test it."
    Write-Host "Running in RERUN mode - will test all cases except 'invalid'" -ForegroundColor Yellow
} else {
    $promptTemplate = "Read ``terraform-test.md`` and play as a tester role, but in debug mode, which means you'll proceed step by step, each step must have my permission. You WILL NOT take any action without my permission. Your given task is ``azurermacctest/{0}``. You should check case status first in ``test_cases.md``, if it's status is ``invalid``, or ``test status`` is ``test success``, skip it."
    Write-Host "Running in NORMAL mode - will skip 'invalid' and 'test success' cases" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

# Iterate through each subdirectory
foreach ($subDir in $subDirs) {
    $subDirName = $subDir.Name
    
    Write-Host ""
    Write-Host "Processing test case: $subDirName" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    # Build the prompt for this subdirectory
    $prompt = $promptTemplate -f $subDirName
    
    # Execute the copilot command
    Write-Host "Executing copilot command..." -ForegroundColor Yellow
    
    copilot -p $prompt
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "Completed: $subDirName" -ForegroundColor Green
    } else {
        Write-Host "Failed or interrupted: $subDirName (Exit code: $exitCode)" -ForegroundColor Red
        
        # Ask user if they want to continue
        $continue = Read-Host "Do you want to continue with the next test case? (Y/N)"
        if ($continue -notmatch '^[Yy]') {
            Write-Host "Script execution stopped by user." -ForegroundColor Yellow
            exit $exitCode
        }
    }
    
    # Check if 'break' file exists in current folder
    $breakFile = Join-Path $scriptDir "break"
    if (Test-Path $breakFile) {
        Write-Host ""
        Write-Host "Break file detected. Stopping script execution." -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Cyan
        break
    }
    
    Write-Host "============================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "All test cases processed!" -ForegroundColor Green
