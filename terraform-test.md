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

**Test Status Tracking (Apply to ALL Steps)**:

⚠️ **CRITICAL REQUIREMENT**: For each step in the test workflow:
1. **Before starting** any step: Update the `test status` column in `test_cases.md` to `step X in progress`
2. **After completing** a step successfully: Update the `test status` column in `test_cases.md` to `step X finished`
3. **If ANY step fails**: IMMEDIATELY mark the test case in `test_cases.md` as `test failed` or `invalid` (depending on the step)

⚠️ **ABSOLUTE PROHIBITION - NO EXCEPTIONS**:
- **NEVER mark a test as `test success` if ANY test command fails**
- **NEVER rationalize failures as "environmental issues" or "expected behavior"**
- **If a terraform command fails (init, plan, apply, etc.), the test has FAILED**
- **Only mark as `test success` if ALL steps complete without errors**

This tracking is mandatory for:
- Maintaining visibility of test progress
- Preventing duplicate work
- Enabling team coordination
- Facilitating debugging and rollback
- Ensuring test result accuracy

**Example**: When beginning Step 3 for the "basic" test case, update `test_cases.md` to show `step 3 in progress`. Once Step 3 completes successfully, update it to `step 3 finished` before proceeding to Step 4.

**⚠️ IMPORTANT - Interpreting Test Status**:
- If `test_cases.md` shows `step X in progress` for a test case, this means **Step X was started but NOT completed successfully**
- When resuming testing: **Always rerun Step X** (do not assume it finished or proceed to Step X+1)
- Only when status shows `step X finished` can you safely proceed to Step X+1

---

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

⚠️ **This step acts as a gate**: If ANY sub-step fails, mark test case as `invalid` and QUIT after cleanup.

Navigate to the test directory and execute the full baseline validation with `main.tf` and `azurerm.tf` present:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform init
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform init
```

**Possible Results**:
- ✅ **Success**: Proceed to apply
- ❌ **Failed**: Run destroy cleanup, mark test case as `invalid` in `test_cases.md`, QUIT

If init succeeds, apply the configuration:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform apply -auto-approve -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform apply -auto-approve -input=false
```

**Possible Results**:
- ✅ **Success**: Proceed to verify idempotency
- ❌ **Failed**: Run destroy cleanup, mark test case as `invalid` in `test_cases.md`, QUIT

Verify no configuration drift:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform plan -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform plan -input=false
```

**Expected Result**: Plan shows "No changes. Your infrastructure matches the configuration."
- ✅ **Success**: **Keep infrastructure running**, proceed to Step 3
- ❌ **Failed** (drift detected): Run destroy cleanup, mark test case as `invalid` in `test_cases.md`, record error in `azurerm_err.log`, QUIT

**Record Failure**: If Step 2 failed, create `azurerm_err.log` documenting the error, failed command, and root cause analysis before cleanup.

**Cleanup - ONLY IF Step 2 FAILED**:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform destroy -auto-approve -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform destroy -auto-approve -input=false
```

**If destroy fails**: Document the error but continue (mark test case as `invalid` in `test_cases.md`).

**Step 2 Summary**: This baseline validation ensures the original AzureRM configuration is valid, can be applied without errors, and has no drift. If any of these checks fail, the test case is marked as `invalid` and all remaining steps are skipped. **If successful, infrastructure remains running for Step 3.**

### Step 3: Verify State Migration with Moved Blocks

⚠️ **Prerequisites**: Infrastructure from Step 2 must still be running.

Switch to AzAPI configuration with moved blocks:

**PowerShell**:
```powershell
Rename-Item azurerm.tf azurerm.tf.bak -Force
Rename-Item azapi.tf.bak azapi.tf -Force
Rename-Item moved.tf.bak moved.tf -Force
terraform fmt
```

**Bash**:
```bash
mv azurerm.tf azurerm.tf.bak
mv azapi.tf.bak azapi.tf
mv moved.tf.bak moved.tf
terraform fmt
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

Initialize with AzAPI provider:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform init
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform init
```

**Possible Results**:
- ✅ **Success**: Proceed to plan
- ❌ **Failed**: Errors occurred, need analysis and fixes

Navigate to the test directory and execute `terraform plan`:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform plan -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform plan -input=false
```

**Evaluating Results**:

1. **If plan shows NO changes**:
   - ✅ **Perfect Success**: State migration is clean with no drift
   - Proceed to Step 4

2. **If plan shows changes (drift detected)**:
   - **CRITICAL**: Compare ALL detected drifts against `acceptable_drift_patterns.md`
   
   **If ALL drifts are acceptable** (match patterns in the document):
   - ✅ **Success with one-time update required**
   - Apply the changes and verify idempotency:
     
     **PowerShell**:
     ```powershell
     cd azurermacctest\<test_case_name>; terraform apply -auto-approve -input=false; terraform plan -input=false
     ```
     
     **Bash**:
     ```bash
     cd azurermacctest/<test_case_name> && terraform apply -auto-approve -input=false && terraform plan -input=false
     ```
   
   - **Expected**: Second plan shows "No changes"
   - If second plan shows no changes: ✅ Proceed to Step 4
   - If second plan still shows changes: ❌ **Failed** - investigate further
   
   **If ANY drift is NOT acceptable** (doesn't match acceptable patterns):
   - ❌ **Failed**: Module implementation error detected
   - **MUST attempt to fix unacceptable drifts** before applying
   - Follow the Error Analysis and Fixes process (see below)
   - After fixes, re-run `terraform plan` and re-evaluate
   - Do NOT run `terraform apply` until all drifts are acceptable

3. **If plan shows resource recreation** (destroy/create):
   - ❌ **Critical Failure**: State migration completely failed
   - This indicates a fundamental module implementation error
   - Document in `err.log` and proceed to cleanup

### Step 4: Cleanup After State Migration Test

Navigate to the test directory and execute `terraform destroy -auto-approve`:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform destroy -auto-approve -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform destroy -auto-approve -input=false
```

**Possible Results**:
- ✅ **Success**: All resources destroyed, proceed to restore files and Step 5
- ❌ **Failed**: Errors occurred during cleanup, document but continue

After destroy, restore the original file configuration:

**PowerShell**:
```powershell
Rename-Item azapi.tf azapi.tf.bak -Force
Rename-Item moved.tf moved.tf.bak -Force
Rename-Item azurerm.tf.bak azurerm.tf -Force
```

**Bash**:
```bash
mv azapi.tf azapi.tf.bak
mv moved.tf moved.tf.bak
mv azurerm.tf.bak azurerm.tf
```

### Step 5: Fresh AzAPI Deployment Test

⚠️ **This step tests clean AzAPI deployment without state migration.**

Clean environment again:

**PowerShell**:
```powershell
Remove-Item .terraform, .terraform.lock.hcl -Recurse -Force -ErrorAction SilentlyContinue
```

**Bash**:
```bash
rm -rf .terraform .terraform.lock.hcl
```

Switch to AzAPI configuration (without moved blocks):

**PowerShell**:
```powershell
Rename-Item azurerm.tf azurerm.tf.bak -Force
Rename-Item azapi.tf.bak azapi.tf -Force
terraform fmt
```

**Bash**:
```bash
mv azurerm.tf azurerm.tf.bak
mv azapi.tf.bak azapi.tf
terraform fmt
```

Initialize:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform init
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform init
```

**Possible Results**:
- ✅ **Success**: Proceed to plan
- ❌ **Failed**: Errors occurred, need analysis and fixes. After attempting fixes (max 5 attempts per error), if still failing, mark test case as `test failed` in `test_cases.md`, create `err.log`, proceed to cleanup

Plan:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform plan -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform plan -input=false
```

**Possible Results**:
- ✅ **Success**: Proceed to apply
- ❌ **Failed**: Errors occurred, need analysis and fixes. After attempting fixes (max 5 attempts per error), if still failing, mark test case as `test failed` in `test_cases.md`, create `err.log`, proceed to cleanup

Apply:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform apply -auto-approve -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform apply -auto-approve -input=false
```

**Possible Results**:
- ✅ **Success**: Resources created, proceed to verify idempotency
- ❌ **Failed**: Errors occurred, need analysis and fixes. After attempting fixes (max 5 attempts per error), if still failing, mark test case as `test failed` in `test_cases.md`, create `err.log`, proceed to cleanup

Verify idempotency (no config drift):

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform plan -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform plan -input=false
```

**Expected Result**: 
- ✅ **Success**: Plan shows "No changes. Your infrastructure matches the configuration."
- ❌ **Failed**: Plan shows changes (config drift detected), need analysis. After attempting fixes (max 5 attempts per error), if still failing, mark test case as `test failed` in `test_cases.md`, create `err.log`, proceed to cleanup

Destroy:

**PowerShell**:
```powershell
cd azurermacctest\<test_case_name>; terraform destroy -auto-approve -input=false
```

**Bash**:
```bash
cd azurermacctest/<test_case_name> && terraform destroy -auto-approve -input=false
```

**Possible Results**:
- ✅ **Success**: Resources destroyed, proceed to restore files
- ❌ **Failed**: Errors occurred, document but continue

Restore original file configuration:

**PowerShell**:
```powershell
Rename-Item azapi.tf azapi.tf.bak -Force
Rename-Item azurerm.tf.bak azurerm.tf -Force
```

**Bash**:
```bash
mv azapi.tf azapi.tf.bak
mv azurerm.tf.bak azurerm.tf
```

**Expected Result**: Test case directory is restored to its original state with `azurerm.tf` active and `azapi.tf.bak`, `moved.tf.bak` as backups.

**Final Status Update**: 
- ✅ **If ALL steps (Step 1-5) completed successfully without ANY errors**: Update `test_cases.md` to mark the test case's test status as `test success`
- ❌ **If ANY step failed at any point**: The test case MUST be marked as `test failed` or `invalid` in `test_cases.md`. Do NOT mark as success regardless of the reason for failure (environmental, API issues, etc.)

⚠️ **REMINDER**: Success means ZERO failures in ALL steps. Any failure = test failed.

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

Maximum **5 attempts per individual issue/error**. After each fix:
1. **Immediately log the fix attempt to `fix.log`** (see format in Test Result Documentation section below)
2. Re-run the terraform command (e.g., `terraform init`, `terraform plan`, etc.) to verify the fix

**Important**: The 5-attempt limit applies to **the same specific error**, not the entire test case:
- ✅ **Making progress**: If each fix resolves one error and reveals a new different error, continue fixing (you may fix 10+ different issues in total)
- ❌ **Stuck on same error**: If you've tried 5 different approaches to fix the **same error message/issue** and it persists, stop and write `err.log`

The limit prevents infinite loops on unfixable issues while allowing progress through multiple different errors.

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

