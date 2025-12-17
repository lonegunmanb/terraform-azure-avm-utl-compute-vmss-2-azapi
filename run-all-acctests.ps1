param(
    [switch]$rerun
)

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$acctestDir = Join-Path $scriptDir "azurermacctest"
$testCasesFile = Join-Path $scriptDir "test_cases.md"

# Check if azurermacctest directory exists
if (-not (Test-Path $acctestDir)) {
    Write-Error "Directory 'azurermacctest' not found at: $acctestDir"
    exit 1
}

# Check if test_cases.md exists
if (-not (Test-Path $testCasesFile)) {
    Write-Error "File 'test_cases.md' not found at: $testCasesFile"
    exit 1
}

# Parse test_cases.md to get test case names and their status
$testCases = @()
$content = Get-Content -Path $testCasesFile
$inTable = $false

foreach ($line in $content) {
    # Check if we're in the table (starts after the header separator)
    if ($line -match '^\|\s*---') {
        $inTable = $true
        continue
    }
    
    # Parse table rows
    if ($inTable -and $line -match '^\|') {
        $columns = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        
        if ($columns.Count -ge 3) {
            $caseName = $columns[0]
            $status = if ($columns.Count -ge 3) { $columns[2] } else { "" }
            $testStatus = if ($columns.Count -ge 4) { $columns[3] } else { "" }
            
            # Skip empty case names or if status/testStatus contains "invalid" or "test success"
            $shouldSkip = $false
            if ($status -match 'invalid' -or $testStatus -match 'invalid') {
                $shouldSkip = $true
            }
            if ($testStatus -match 'test success') {
                $shouldSkip = $true
            }
            
            if ($caseName -ne '' -and $caseName -ne 'case name') {
                $testCases += [PSCustomObject]@{
                    Name = $caseName
                    Status = $status
                    TestStatus = $testStatus
                    ShouldSkip = $shouldSkip
                }
            }
        }
    }
}

# Filter test cases based on mode
if ($rerun) {
    # In rerun mode, only skip cases with "invalid" status
    $casesToRun = $testCases | Where-Object { $_.Status -notmatch 'invalid' -and $_.TestStatus -notmatch 'invalid' }
    Write-Host "Running in RERUN mode - will test all cases except 'invalid'" -ForegroundColor Yellow
} else {
    # In normal mode, skip cases with "invalid" or "test success"
    $casesToRun = $testCases | Where-Object { -not $_.ShouldSkip }
    Write-Host "Running in NORMAL mode - will skip 'invalid' and 'test success' cases" -ForegroundColor Green
}

Write-Host "Total test cases in test_cases.md: $($testCases.Count)" -ForegroundColor Cyan
Write-Host "Test cases to run: $($casesToRun.Count)" -ForegroundColor Cyan
Write-Host "Test cases skipped: $($testCases.Count - $casesToRun.Count)" -ForegroundColor Yellow
Write-Host ""

# Prepare the prompt template
$promptTemplate = "Read ``terraform-test.md`` and play as a tester role.  You're running in non-interactive mode now, do not ask for instruction. Your given task is ``azurermacctest/{0}``."

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

# Iterate through each test case
foreach ($testCase in $casesToRun) {
    $caseName = $testCase.Name
    
    Write-Host ""
    Write-Host "Processing test case: $caseName" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    
    # Build the prompt for this test case
    $prompt = $promptTemplate -f $caseName
    
    # Execute the copilot command
    Write-Host "Executing copilot command..." -ForegroundColor Yellow
    
    copilot --allow-all-tools --model "claude-sonnet-4.5" -p $prompt
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "Completed: $caseName" -ForegroundColor Green
    } else {
        Write-Host "Failed or interrupted: $caseName (Exit code: $exitCode)" -ForegroundColor Red
        
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
