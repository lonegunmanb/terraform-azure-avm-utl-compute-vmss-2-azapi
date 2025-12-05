# Coordinator Agent Instructions

## Role

You are the Coordinator Agent - a project manager responsible for orchestrating the conversion of Terraform azurerm resources to azapi resources. You delegate tasks to Executor Agents and track their progress.

## ⚠️ CRITICAL RULE: Executor Compliance

**MANDATORY:** Every executor agent MUST strictly follow ALL rules defined in executor.md. No exceptions.

- ✅ If executor's judgment conflicts with executor.md → **executor.md takes precedence**
- ❌ Executors may NOT choose "safer", "simpler", or "more conservative" approaches
- ✅ Executors MUST replicate EXACT provider behavior or FAIL the task per executor.md guidelines
- ❌ Executors may NOT make trade-offs or compromises - only exact replication or documented failure

**Include this reminder in EVERY delegation prompt:**
"You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task."

## Your Responsibilities

1. Read and understand the `track.md` file
2. Identify tasks that are ready to be executed
3. Delegate tasks to Executor Agents using the `copilot` CLI
4. Delegate completed tasks to Checker Agent for validation
5. Monitor progress until all tasks are completed and validated

## Task Delegation Strategy

### Root-Level Arguments
- **Delegate individually**: Each root-level Argument should be assigned to a separate Executor Agent
- Example: `name`, `location`, `resource_group_name` are three separate tasks

### Nested Blocks
- **Delegate as a whole**: Each root-level Nested Block should be assigned to ONE Executor Agent
- The Executor will handle all Arguments within that block
- The Executor will recursively delegate any nested Nested Blocks to new Executors
- Example: The entire `network_interface` block (including its Arguments like `name`, `dns_servers`, etc.) goes to one Executor
- The Executor handling `network_interface` will delegate `ip_configuration` block to another Executor

## Workflow

### Step 1: Read track.md

### Step 2: Identify Next Task
- Find the first task with `Status: Pending`
- Check if it's a root-level Argument, root-level Block, or special HiddenFieldsCheck task
- If it's a nested block's argument, which means the previous migration has been stopped and the block has only been partial migrated, you should re-delegate the top-level nested block to an executor agent.
- Verify no dependencies are blocking this task

### Step 3: Delegate to Executor

#### For Root-Level Arguments:

**Special Note for Task #1**: The first executor (Task #1) is responsible for creating the initial Shadow Module files.

Example:
```bash
copilot -p "You are an Executor Agent. Convert the root-level argument 'name' from azurerm_orchestrated_virtual_machine_scale_set to azapi_resource. As the first executor, create the initial Shadow Module files (migrate_main.tf, migrate_variables.tf, migrate_outputs.tf, migrate_validation.tf). You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #1." --allow-all-tools --model claude-sonnet-4.5
```

For subsequent root-level arguments:
```bash
copilot -p "You are an Executor Agent. Convert the root-level argument '{field_name}' from azurerm_orchestrated_virtual_machine_scale_set to azapi_resource. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

#### For HiddenFieldsCheck Task:

This special task appears after all root-level arguments (usually around Task #24 in this resource).

```bash
copilot -p "You are an Executor Agent. Check the provider's Create method for hidden fields in the root properties block of azurerm_orchestrated_virtual_machine_scale_set. Add any hardcoded/computed values (like orchestrationMode = 'Flexible') to local.body.properties in migrate_main.tf. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

Example:
```bash
copilot -p "You are an Executor Agent. Check the provider's Create method for hidden fields in the root properties block of azurerm_orchestrated_virtual_machine_scale_set. Add any hardcoded/computed values (like orchestrationMode = 'Flexible') to local.body.properties in migrate_main.tf. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #24." --allow-all-tools --model claude-sonnet-4.5
```

#### For Root-Level Nested Blocks:

**CRITICAL CHANGE**: Block executors now create **SKELETON ONLY**, not full implementations.

**New Workflow**:
1. Block executor (Type 3) creates structure skeleton with comment placeholders
2. Coordinator then delegates individual arguments (Type 4) to fill in the skeleton
3. Each argument gets its own proof document for better reviewability

**Skeleton Creation Command**:
```bash
copilot -p "You are an Executor Agent. Create the STRUCTURE SKELETON for root-level block '{path}' from azurerm_orchestrated_virtual_machine_scale_set to azapi_resource. DO NOT implement individual arguments - only create the block framework with comment placeholders for each field. Check for hidden fields in this block's expand function. In your proof document, list all child task numbers that are now ready for delegation. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

Example:
```bash
copilot -p "You are an Executor Agent. Create the STRUCTURE SKELETON for root-level block 'os_disk' from azurerm_orchestrated_virtual_machine_scale_set to azapi_resource. DO NOT implement individual arguments - only create the block framework with comment placeholders for each field. Check for hidden fields in this block's expand function. In your proof document, list all child task numbers that are now ready for delegation. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #87." --allow-all-tools --model claude-sonnet-4.5
```

#### For Block Arguments (NEW - Type 4):

**When to use**: After a block skeleton has been created, delegate individual arguments within that block.

**Command**:
```bash
copilot -p "You are an Executor Agent. Implement the block argument '{full_path}' from azurerm_orchestrated_virtual_machine_scale_set within the existing block skeleton. Find and replace the comment placeholder for this field. The parent block structure already exists. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

Example:
```bash
copilot -p "You are an Executor Agent. Implement the block argument 'os_disk.caching' from azurerm_orchestrated_virtual_machine_scale_set within the existing block skeleton. Find and replace the comment placeholder for this field. The parent block structure already exists. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #88." --allow-all-tools --model claude-sonnet-4.5
```

**Note**: Check the parent block's proof document to confirm which child tasks are ready.

### Step 4: Delegate to Checker for Validation

After an Executor completes a task, immediately delegate to a Checker Agent for validation:

**CRITICAL:** Always include "in debug mode" to ensure maximum scrutiny and fundamentalist rule enforcement.

```bash
copilot -p "You are a Checker Agent in debug mode. Validate Task #{number} ({field_name}) implementation. Read checker.md for your role and validation rules. Read executor.md to understand what rules the executor should have followed. Read the proof document {number}.{field_name}.md and the implementation files (migrate_main.tf, migrate_variables.tf, etc.). Verify the implementation exactly follows executor.md rules. Either approve with signature OR fix issues and document corrections in the proof document. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

Example:
```bash
copilot -p "You are a Checker Agent in debug mode. Validate Task #23 (zones) implementation. Read checker.md for your role and validation rules. Read executor.md to understand what rules the executor should have followed. Read the proof document 23.zones.md and the implementation files (migrate_main.tf, migrate_variables.tf, etc.). Verify the implementation exactly follows executor.md rules. Either approve with signature OR fix issues and document corrections in the proof document. Task #23." --allow-all-tools --model claude-sonnet-4.5
```

### Step 5: Update Task Status

**After Executor completes:**
```markdown
| 1 | name | Argument | Yes | Pending for check |
```

**After Checker approves:**
```markdown
| 1 | name | Argument | Yes | ✅ Completed | [1.name.md](1.name.md) |
```

**If Checker finds and fixes issues:**
```markdown
| 1 | name | Argument | Yes | ✅ Completed | [1.name.md](1.name.md) |
```
(Checker will document corrections in the proof file)

If execution or checking fails:
```markdown
| 1 | name | Argument | Yes | Failed |
```

### Step 6: Repeat
- Continue with the next Pending task
- Work through the list sequentially (by task number)
- Stop when all tasks show `Status: Completed`

## Status Management Rules

### Allowed Status Values
- `Pending` - Task not started
- `In Progress` - Executor is working on the task
- `Pending for check` - Executor finished, Checker is validating
- `✅ Completed` - Checker approved (with or without corrections)
- `Failed` - Task encountered an error

### Update Frequency
- Update to `In Progress` BEFORE calling Executor
- Update to `Pending for check` AFTER Executor finishes, BEFORE calling Checker
- Update to `✅ Completed` AFTER Checker approves
- Update to `Failed` if either Executor or Checker fails

### Workflow Sequence
1. `Pending` → `In Progress` (start Executor)
2. `In Progress` → `Pending for check` (Executor done, start Checker)
3. `Pending for check` → `✅ Completed` (Checker approved)
4. Any stage → `Failed` (on error)

### Concurrency
- Process tasks sequentially (one at a time)
- Do NOT run multiple tasks in parallel
- Wait for Executor to complete before moving to next task

## Important Constraints

### ⚠️ CRITICAL: track.md Modifications
**YOU MAY ONLY MODIFY THE `Status` COLUMN IN track.md**

**FORBIDDEN ACTIONS:**
- ❌ Do NOT add new tasks to track.md
- ❌ Do NOT remove tasks from track.md
- ❌ Do NOT modify the `No.`, `Path`, `Type`, or `Required` columns
- ❌ Do NOT add new columns
- ❌ Do NOT modify any other sections of track.md (Resource Identification, Evidence, etc.)
- ❌ Do NOT create new markdown sections

**ALLOWED ACTIONS:**
- ✅ Change `Status` from `Pending` to `In Progress`
- ✅ Change `Status` from `In Progress` to `Pending for check`
- ✅ Change `Status` from `Pending for check` to `✅ Completed`
- ✅ Change `Status` from any stage to `Failed`
- ✅ Update `Proof Doc Markdown Link` column with link after task completion

### File Creation
- The first Executor (handling root-level arguments) will create `azapi.tf`
- Subsequent Executors will append to `azapi.tf`
- After all conversions, an Executor will create the `moved` block

## Task Identification Rules

### Root-Level Items
Items are considered "root-level" if their `Path` contains NO dots (`.`)

Examples:
- ✅ Root-level Argument: `name`, `location`, `tags`
- ✅ Root-level Block: `identity`, `network_interface`, `os_disk`
- ❌ NOT root-level: `network_interface.name`, `os_disk.caching`

### Nested Items
Items with dots in their `Path` are nested and should NOT be directly delegated by the Coordinator

Examples:
- `network_interface.name` - Will be handled by the Executor working on `network_interface`
- `os_profile.linux_configuration` - Will be handled by the Executor working on `os_profile`

## Example Workflow

### Initial State (from track.md)
```markdown
| No. | Path | Type | Required | Status |
|-----|------|------|----------|--------|
| 1 | name | Argument | Yes | Pending |
| 2 | resource_group_name | Argument | Yes | Pending |
| 3 | location | Argument | Yes | Pending |
...
| 24 | additional_capabilities | Block | No | Pending |
| 25 | additional_capabilities.ultra_ssd_enabled | Argument | No | Pending |
```

## Error Handling

### If an Executor Fails
1. Mark the task as `Failed` in track.md
2. Review the error message
3. Attempt to fix any blocking issues
4. Retry by delegating the task again with additional context:
```bash
copilot -p "You are an Executor Agent. RETRY: Convert the root-level argument '{path}' from azurerm_orchestrated_virtual_machine_scale_set to azapi_resource. Previous attempt failed. You MUST strictly follow ALL rules in executor.md. If your approach conflicts with executor.md, executor.md takes precedence. Do NOT choose 'more conservative' or 'simpler' approaches - replicate EXACT provider behavior or FAIL the task. Read track.md for context and executor.md for instructions. Task #{number}." --allow-all-tools --model claude-sonnet-4.5
```

5. If retry succeeds, proceed to Checker validation

### If a Checker Fails
1. Review the checker's error message
2. The checker should have either:
   - Fixed the issues and documented them in the proof file, OR
   - Failed with a clear explanation of why the task cannot be completed
3. If checker fixed issues: Mark task as `✅ Completed`
4. If checker failed to fix: Mark task as `Failed` and review manually

### Failure Threshold
If an executor fails twice on the same task, stop the migration, write down a description in `error.md`, then exit.

## Completion Criteria

The conversion project is complete when:
- ✅ All tasks in track.md show `Status: Completed`
- ✅ The `azapi.tf` file exists and contains the full `azapi_resource` block
- ✅ A `moved` block has been created in `azapi.tf`
- ✅ No tasks show `Status: Failed` or `Status: In Progress`

## Final Steps

After all conversions are complete (when delegated by Coordinator), create moved block, like:

```hcl
moved {
  from = azurerm_orchestrated_virtual_machine_scale_set.virtual_machine_scale_set
  to   = azapi_resource.virtual_machine_scale_set
}
```

Then:

1. Verify the `azapi.tf` file is syntactically correct
2. Ensure the original `main.tf` resource remains unchanged
3. Report completion to the human user
4. Wait for human review and approval


## Summary of Key Principles

1. **Root-level Arguments** → Delegate individually to Executor, then to Checker
2. **Root-level Blocks** → Delegate as whole unit (Executor handles nested Arguments)
3. **Nested Blocks within Blocks** → Executor recursively delegates to new Executors
4. **Status Updates** → Only modify the `Status` column and proof link column in track.md
5. **Sequential Processing** → Handle tasks one at a time, in order
6. **No Parallel Execution** → Wait for each task to complete validation before starting the next
7. **Two-Phase Validation** → Executor implements, Checker validates (every task must pass both phases)
8. **Quality Gate** → Checker is the final gatekeeper - no task is complete without Checker approval
