# Terraform AzureRM to AzAPI Conversion Test Guide

## Test Objective

Verify the correctness of converting AzureRM Provider resources to AzAPI Provider resources.

## Test Directory Structure

The `azurermacctest` directory contains multiple test case subdirectories, each representing a test scenario.

A typical test directory contains the following files:
- `main.tf` - Common infrastructure code (provider configuration, random resources, network, etc.) **[Trusted, DO NOT MODIFY]**
- `azurerm.tf` - AzureRM Provider resource declarations (extracted from AzureRM Provider test code) **[Trusted, DO NOT MODIFY]**
- `azapi.tf.bak` - AzAPI implementation converted using the Replicator Module (theoretically equivalent to `azurerm.tf`)

## Test Workflow

**Shell Detection**:
```pseudocode
IF current_shell == "pwsh" OR current_shell == "powershell" THEN
    use PowerShell commands
ELSE
    use Bash commands
END IF
```

### Step 1: Clean Environment

In the test directory, remove previous test artifacts:

**PowerShell**:
```powershell
Remove-Item .terraform, .terraform.lock.hcl, err.log, fix.log -Recurse -Force -ErrorAction SilentlyContinue
```

**Bash**:
```bash
rm -rf .terraform .terraform.lock.hcl err.log fix.log
```

### Step 2: Verify AzureRM Configuration (Baseline Test)

Execute `terraform init` with `main.tf` and `azurerm.tf` present:
```bash
terraform init
```

**Expected Result**: Success, no errors. This is the baseline validation, proving the original configuration works.

### Step 3: Switch to AzAPI Configuration

Rename files to enable AzAPI version:

**PowerShell**:
```powershell
Rename-Item azurerm.tf azurerm.tf.bak -Force
Rename-Item azapi.tf.bak azapi.tf -Force
```

**Bash**:
```bash
mv azurerm.tf azurerm.tf.bak
mv azapi.tf.bak azapi.tf
```

Clean terraform cache to ensure fresh initialization:

**PowerShell**:
```powershell
Remove-Item .terraform, .terraform.lock.hcl -Recurse -Force -ErrorAction SilentlyContinue
```

**Bash**:
```bash
rm -rf .terraform .terraform.lock.hcl
```

### Step 4: Test AzAPI Configuration

Execute `terraform init`:
```bash
terraform init
```

**Possible Results**:
- ✅ **Success**: No errors, test passed
- ❌ **Failed**: Errors occurred, need analysis and fixes

## Error Analysis and Fixes

If Step 4 fails, analyze the error type and attempt fixes.

### Error Analysis Process

**When encountering errors from any `terraform` command (init, plan, apply, etc.)**:

1. **First**, read `common_terraform_error.md` to check for known error patterns
2. **If a matching pattern is found**, follow the instructions in that document to fix the issue
3. **If no match is found**, proceed with the common error type analysis below

### Common Error Types

1. **Type Error**
   - Property type mismatch (string vs number, list vs set, etc.)
   - Example: `expected string, got number`

2. **Naming Error**
   - Property name typo or doesn't exist
   - Example: `unsupported argument "xxx"`

3. **Default Value Error**
   - Missing required property
   - Incorrect default value
   - Example: `missing required argument "xxx"`

4. **Reference Error**
   - Incorrect resource reference
   - Module output reference issues

### Fix Principles

⚠️ **Important Constraints**:
- ✅ CAN modify configuration in `azapi.tf`
- ✅ CAN modify module call parameters
- ❌ **CANNOT modify** `main.tf` and `azurerm.tf.bak` contents
- ❌ **CANNOT change** the semantic meaning of the original Terraform configuration
- ❌ **CANNOT delete** module blocks or azapi_resource blocks to "fix" errors

### Fix Strategies

Use the **simplest possible** method to fix:

1. **Type Conversion**
   ```hcl
   # Error: expected number, got string
   instances = "2"
   
   # Fix: Convert to number
   instances = 2
   ```

2. **Property Name Correction**
   ```hcl
   # Error: unsupported argument "computer_name"
   computer_name = "test"
   
   # Fix: Use correct property name
   computer_name_prefix = "test"
   ```

3. **Add Missing Required Properties**
   ```hcl
   # Error: missing required argument "admin_username"
   
   # Fix: Find corresponding value from azurerm.tf.bak and add
   admin_username = "myadmin"
   ```

4. **Adjust Default Values or Optional Properties**
   ```hcl
   # If a property causes errors but is optional in azurerm.tf.bak
   # Try removing the property or set to null
   ```

## Fix Limits

Maximum **5 attempts** to fix. After each fix:
1. **Immediately log the fix attempt to `fix.log`** (see format in Test Result Documentation section below)
2. Re-run the terraform command (e.g., `terraform init`, `terraform plan`, etc.) to verify the fix

## Test Result Documentation

⚠️ **Critical Logging Requirement**:
- **MUST log each fix attempt to `fix.log` IMMEDIATELY after making changes, BEFORE running the next terraform command**
- Append to `fix.log` incrementally after each fix attempt
- Do NOT wait until all attempts are complete to log
- This ensures progress is documented even if unexpected errors occur

### Successful Fix -> Generate `fix.log`

Record the following content **incrementally after each attempt**:
```
Test Case: [directory name]
================================================================================

Initial Error:
[paste initial error message]

Fix Process:

Attempt 1:
- Problem Analysis: [describe the problem you identified]
- Fix Method: [describe your fix approach]
- Changes Made: [list specific changes]
- Result: [success/failure and new errors]

Attempt 2:
...

Final Result: Fix successful
```

### Failed -> Generate `err.log`

Record the following content **incrementally after each attempt**:
```
Test Case: [directory name]
================================================================================

Still failed after 5 fix attempts

Initial Error:
[paste initial error message]

Attempted Fix Methods:

Attempt 1:
- Problem Analysis: [describe the problem you identified]
- Fix Method: [describe your fix approach]
- Result: [failure reason]

Attempt 2:
...

Attempt 5:
...

Final Error:
[paste last error message]

Conclusion:
[briefly explain why it couldn't be fixed, potential directions for further investigation]
```

## Notes

- Each test directory is independent and does not affect others
- Understand the root cause of errors when fixing, don't try fixes blindly
- Keep modifications minimal to avoid introducing new issues
- If an error is unclear, consult the corresponding AzureRM and AzAPI provider documentation
- Record detailed fix process to facilitate later analysis and improvements to the Replicator Module

