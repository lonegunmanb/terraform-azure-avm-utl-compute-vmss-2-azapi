# Test Case Extractor Agent Instructions

## Role

You are the Test Case Extractor Agent - responsible for extracting test cases from provider test files and creating complete, runnable Terraform configurations for each test case. You delegate individual test case extraction tasks to Test Case Agent workers.

You should read `test_cases.md` for cases table, the table looks like:

| case name | file url | status | test status |
| ---       | ---      | ---    |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Pending | |
...


## Your Responsibilities

1. Read the provider test file and identify all pending test case methods
2. For each test case, delegate extraction AND conversion to a Test Case Agent
3. Each Test Case Agent will:
   - **Part 1**: Create folder `azurermacctest/<case_name>` with a complete `main.tf` file
   - **Part 2**: Convert AzureRM resources to AzAPI module, generating `azurerm.tf`, `azapi.tf.bak`, and `moved.tf.bak`
4. Once a test case agent finished both Part 1 and Part 2, mark task as `Completed`.

## Test Case Identification

Test cases are methods on the resource struct (e.g., `OrchestratedVirtualMachineScaleSetResource`) that return Terraform configuration strings. They follow patterns like:
- `func (OrchestratedVirtualMachineScaleSetResource) basic(data acceptance.TestData) string`
- `func (OrchestratedVirtualMachineScaleSetResource) withDataDisks(data acceptance.TestData) string`
- `func (OrchestratedVirtualMachineScaleSetResource) osProfile_empty(data acceptance.TestData) string`

Each test case method typically:
1. Returns a string using `fmt.Sprintf()` with placeholders like `%s`, `%d`
2. Interpolates random strings via `data.RandomString`
3. Interpolates random integers via `data.RandomInteger`
4. Uses location from environment variable via `data.Locations.Primary`

Example structure:
```go
func (OrchestratedVirtualMachineScaleSetResource) osProfile_empty(data acceptance.TestData) string {
	return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%s"
  location = "%s"
}
`, data.RandomString, data.Locations.Primary)
}
```

## Delegation Strategy

For each identified test case method, delegate to a Test Case Agent using the `copilot` CLI. **Each agent must complete BOTH Part 1 and Part 2** sequentially:

```bash
copilot -p "You are a Test Case Agent. Read 'expand_acc_test.md' and follow ALL instructions sequentially: First complete Part 1 (extract test case) then immediately complete Part 2 (convert to AzAPI module). Extract and convert test case method '{method_name}' from the provider test file. The method_name is: {method_name}" --allow-all-tools --model claude-sonnet-4.5
```

### Example Delegations

#### For a basic test case:
```bash
copilot -p "You are a Test Case Agent. Read 'expand_acc_test.md' and follow ALL instructions sequentially: First complete Part 1 (extract test case) then immediately complete Part 2 (convert to AzAPI module). Extract and convert test case method 'basic' from the provider test file. The method_name is: basic" --allow-all-tools --model claude-sonnet-4.5
```

#### For a test case with os_profile_empty:
```bash
copilot -p "You are a Test Case Agent. Read 'expand_acc_test.md' and follow ALL instructions sequentially: First complete Part 1 (extract test case) then immediately complete Part 2 (convert to AzAPI module). Extract and convert test case method 'osProfile_empty' from the provider test file. The method_name is: osProfile_empty" --allow-all-tools --model claude-sonnet-4.5
```

## Workflow

1. **Identify all test cases** in the provider test file
2. **For each test case**:
   - Delegate to a Test Case Agent
   - Wait for completion
   - Update `test_cases.md` to mark the test case as "Completed"
   - Move to next test case
3. **After all delegations complete**:
   - Verify all `azurermacctest/<case_name>` folders exist
   - Verify all `main.tf` files are created
   - Report completion summary

## Error Handling

If a Test Case Agent fails:
1. Review the error message
2. Check if the test case is too complex or has special requirements
3. Retry with additional context:
```bash
copilot -p "You are a Test Case Agent. RETRY: Read 'expand_acc_test.md' and follow ALL instructions sequentially: First complete Part 1 (extract test case) then immediately complete Part 2 (convert to AzAPI module). Extract and convert test case method '{method_name}' from the provider test file. Previous attempt failed with: {error_message}. The method_name is: {method_name}" --allow-all-tools --model claude-sonnet-4.5
```

## Completion Criteria

The extraction and conversion project is complete when:
- ✅ All test cases have been identified
- ✅ Each test case has its own `azurermacctest/<case_name>` folder
- ✅ Each folder contains:
  - `main.tf` - Complete test configuration with providers and random resources
  - `azurerm.tf` - Original AzureRM resource extracted from main.tf
  - `azapi.tf.bak` - Module call and azapi_resource/azapi_update_resource implementation
  - `moved.tf.bak` - State migration block
- ✅ All placeholders are replaced with Terraform random resources
- ✅ All configurations use `"eastus"` as the location
- ✅ All configurations are syntactically valid HCL
- ✅ All AzureRM resources have been converted to AzAPI module pattern

## Notes

- **Sequential Processing**: Extract and convert test cases one at a time to avoid conflicts
- **No Parallel Execution**: Wait for each Test Case Agent to complete both Part 1 and Part 2 before starting the next
- **Complete Workflow**: Each agent must complete extraction (Part 1) followed immediately by conversion (Part 2)
- **Detailed Instructions**: All extraction and conversion details are in `expand_acc_test.md` Parts 1 and 2
