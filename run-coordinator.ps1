#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automates the execution of coordinator tasks for Terraform migration.

.DESCRIPTION
    This script runs the coordinator role for a range of tasks, processing them sequentially.
    It delegates each task to the copilot agent and waits for completion before moving to the next task.

.PARAMETER StartTask
    The starting task number (inclusive).

.PARAMETER EndTask
    The ending task number (inclusive).

.EXAMPLE
    .\run-coordinator.ps1 -StartTask 75 -EndTask 164
    Processes tasks from 75 to 164.

.EXAMPLE
    .\run-coordinator.ps1 75 164
    Processes tasks from 75 to 164 using positional parameters.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$StartTask,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$EndTask
)

# Validate parameters
if ($StartTask -gt $EndTask) {
    Write-Error "StartTask ($StartTask) cannot be greater than EndTask ($EndTask)"
    exit 1
}

# Check if track.md exists
if (-not (Test-Path "track.md")) {
    Write-Error "track.md not found in current directory. Please run this script from the project root."
    exit 1
}

# Check if coordinator.md exists
if (-not (Test-Path "coordinator.md")) {
    Write-Error "coordinator.md not found in current directory. Please run this script from the project root."
    exit 1
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Coordinator Task Runner" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Task Range: $StartTask to $EndTask" -ForegroundColor Yellow
Write-Host "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Function to check if a task is completed in track.md
function Test-TaskCompleted {
    param([int]$TaskNumber)
    
    $trackContent = Get-Content "track.md" -Raw
    $pattern = "^\|\s*$TaskNumber\s*\|.*\|\s*✅\s+Completed\s*\|"
    
    if ($trackContent -match $pattern) {
        return $true
    }
    return $false
}

# Main loop
for ($taskNum = $StartTask; $taskNum -le $EndTask; $taskNum++) {
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "Processing Task #$taskNum" -ForegroundColor Green
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    
    # Check if task is already completed
    if (Test-TaskCompleted -TaskNumber $taskNum) {
        Write-Host "Task #$taskNum is already completed. Skipping..." -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    
    # Construct the copilot prompt
    $prompt = "Read ``coordinator.md`` file, play as coordinator role, finish task $taskNum then take a break"
    
    Write-Host "Executing: copilot -p `"$prompt`" --allow-all-tools --model claude-sonnet-4.5" -ForegroundColor Cyan
    Write-Host ""
    
    # Execute copilot command
    $copilotArgs = @(
        "-p", $prompt,
        "--allow-all-tools",
        "--model", "claude-sonnet-4.5"
    )
    
    & copilot @copilotArgs
    $exitCode = $LASTEXITCODE
    
    Write-Host ""
    
    if ($exitCode -ne 0) {
        Write-Error "Copilot command failed with exit code $exitCode for Task #$taskNum"
        Write-Host "Stopping execution." -ForegroundColor Red
        exit $exitCode
    }
    
    # Check if the task was completed after execution
    if (Test-TaskCompleted -TaskNumber $taskNum) {
        Write-Host "✓ Task #$taskNum completed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ Task #$taskNum may not be completed yet (not marked as completed in track.md)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Small pause between tasks to avoid overwhelming the system
    if ($taskNum -lt $EndTask) {
        Write-Host "Taking a 2-second break before next task..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
        Write-Host ""
    }
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "All tasks completed!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Task Range: $StartTask to $EndTask" -ForegroundColor White
Write-Host "  Total Tasks: $($EndTask - $StartTask + 1)" -ForegroundColor White
Write-Host ""
