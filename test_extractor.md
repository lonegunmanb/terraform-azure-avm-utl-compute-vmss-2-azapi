# Test Case Extractor Agent Instructions

## Role

You are the Test Case Extractor Agent - responsible for extracting test cases from provider test files and creating complete, runnable Terraform configurations for each test case. You delegate individual test case extraction tasks to Test Case Agent workers.

You should read `test_cases.md` for cases table, the table looks like:

| case name | file url | status |
| ---       | ---      | ---    |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Pending |
...


## Your Responsibilities

1. Read the provider test file and identify all pending test case methods
2. For each test case, delegate extraction to a Test Case Agent
3. Each Test Case Agent will create a folder `test/<case_name>` with a complete `main.tf` file
4. Once a test case agent finished it's task, mark task as `Completed`.

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

For each identified test case method, delegate to a Test Case Agent using the `copilot` CLI:

```bash
copilot -p "You are a Test Case Agent. Extract test case method '{method_name}' from the provider test file and create a complete Terraform configuration. Create folder 'test/{case_name}' and generate 'main.tf' with the following transformations: 1) Create exactly ONE random_string resource and ONE random_integer resource (positive numbers only, min >= 1), 2) Replace ALL random string placeholders with references to the single random_string.result, 3) Replace ALL random integer placeholders with references to the single random_integer.result, 4) Replace location variables with 'eastus', 5) Ensure the configuration is complete and runnable. Include required provider blocks (azurerm, random)." --allow-all-tools --model claude-sonnet-4.5
```

### Example Delegations

#### For a basic test case:
```bash
copilot -p "You are a Test Case Agent. Extract test case method 'basic' from the provider test file and create a complete Terraform configuration. Create folder 'test/basic' and generate 'main.tf' with the following transformations: 1) Create exactly ONE random_string resource and ONE random_integer resource (positive numbers only, min >= 1), 2) Replace ALL random string placeholders with references to the single random_string.result, 3) Replace ALL random integer placeholders with references to the single random_integer.result, 4) Replace location variables with 'eastus', 5) Ensure the configuration is complete and runnable. Include required provider blocks (azurerm, random)." --allow-all-tools --model claude-sonnet-4.5
```

#### For a test case with os_profile_empty:
```bash
copilot -p "You are a Test Case Agent. Extract test case method 'osProfile_empty' from the provider test file and create a complete Terraform configuration. Create folder 'test/os_profile_empty' and generate 'main.tf' with the following transformations: 1) Create exactly ONE random_string resource and ONE random_integer resource (positive numbers only, min >= 1), 2) Replace ALL random string placeholders with references to the single random_string.result, 3) Replace ALL random integer placeholders with references to the single random_integer.result, 4) Replace location variables with 'eastus', 5) Ensure the configuration is complete and runnable. Include required provider blocks (azurerm, random)." --allow-all-tools --model claude-sonnet-4.5
```

## Test Case Agent Instructions (for delegated agents)

When you receive a delegation as a Test Case Agent, follow these steps:

### Step 1: Locate the Test Method
- Find the test case method on the resource struct (e.g., `func (OrchestratedVirtualMachineScaleSetResource) methodName(data acceptance.TestData) string`)
- Identify the Terraform configuration template string returned by `fmt.Sprintf()`
- Note all placeholders and their context

### Step 2: Create Test Directory
- Create directory `test/<case_name>` 
- Folder name should be snake_case, using the method name directly
- Example: `basic` → `test/basic`
- Example: `osProfile_empty` → `test/os_profile_empty`
- Example: `withDataDisks` → `test/with_data_disks`

### Step 3: Transform the Configuration

**CRITICAL RULE**: Create exactly ONE `random_string` and ONE `random_integer` resource per test case, regardless of how many placeholders exist.

#### Random String Replacements
Original test code pattern (note multiple `%s` placeholders):
```go
fmt.Sprintf(`
resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%s"
  location = "%s"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name = "acctestVMSS-%s"
  ...
}
`, data.RandomString, data.Locations.Primary, data.RandomString)
```

Transform to (using a single random_string for ALL string placeholders):
```hcl
resource "random_string" "name" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_string.name.result}"
  location = "eastus"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name = "acctestVMSS-${random_string.name.result}"
  ...
}
```

#### Random Integer Replacements
Original test code pattern (note multiple `%d` placeholders):
```go
fmt.Sprintf(`
  disk_size_gb = %d
  instances = %d
`, data.RandomInteger, data.RandomInteger)
```

Transform to (using a single random_integer for ALL integer placeholders, **positive numbers only**):
```hcl
resource "random_integer" "number" {
  min = 1
  max = 100
}

# In the resource blocks:
disk_size_gb = random_integer.number.result
instances = random_integer.number.result
```

**IMPORTANT**: Always set `min >= 1` for random_integer to ensure positive numbers only.

#### Location Replacements
- Replace `data.Locations.Primary` → `"eastus"`
- Replace `data.Locations.Secondary` → `"westus"` (if needed)

### Step 4: Generate Complete main.tf

Include these sections in order:

1. **Terraform block** (if needed for specific provider versions)
2. **Provider blocks**:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {}
```

3. **Random resource definitions** (exactly one random_string and one random_integer resource)
4. **Main resources** (the actual test configuration with placeholders replaced by references to the single random resources)

### Step 5: Validate
- Ensure all placeholders are replaced
- Ensure all resources have valid references
- Ensure no hardcoded random values (use random provider instead)
- Ensure the configuration is syntactically correct HCL

## Naming Conventions

### Folder Names
- Use snake_case, using the method name directly
- Convert camelCase to snake_case where needed
- Example: `basic` → `basic`
- Example: `osProfile_empty` → `os_profile_empty`
- Example: `withDataDisks` → `with_data_disks`

### Random Resource Names
**Use these standard names** (one of each per test case):
- `random_string.name` - the single random string resource for all string placeholders
- `random_integer.number` - the single random integer resource for all integer placeholders (min >= 1 for positive numbers only)

## Example Transformations

### Example 1: Simple Test Case Method

**Original Go Method:**
```go
func (OrchestratedVirtualMachineScaleSetResource) basic(data acceptance.TestData) string {
    return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%s"
  location = "%s"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestVMSS-%s"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  platform_fault_domain_count = 1
  
  instances = %d
}
`, data.RandomString, data.Locations.Primary, data.RandomString, data.RandomInteger)
}
```

**Generated test/basic/main.tf:**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {}

resource "random_string" "name" {
  length  = 8
  special = false
  upper   = false
}

resource "random_integer" "number" {
  min = 1
  max = 100
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_string.name.result}"
  location = "eastus"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                        = "acctestVMSS-${random_string.name.result}"
  location                    = azurerm_resource_group.test.location
  resource_group_name         = azurerm_resource_group.test.name
  platform_fault_domain_count = 1
  
  instances = random_integer.number.result
}
```

## Workflow

1. **Identify all test cases** in the provider test file
2. **For each test case**:
   - Delegate to a Test Case Agent
   - Wait for completion
   - Move to next test case
3. **After all delegations complete**:
   - Verify all `test/<case_name>` folders exist
   - Verify all `main.tf` files are created
   - Report completion summary

## Error Handling

If a Test Case Agent fails:
1. Review the error message
2. Check if the test case is too complex or has special requirements
3. Retry with additional context:
```bash
copilot -p "You are a Test Case Agent. RETRY: Extract test case '{case_name}' from the provider test file. Previous attempt failed with: {error_message}. Create folder 'test/{case_name}' and generate 'main.tf' with the following transformations: 1) Create exactly ONE random_string resource and ONE random_integer resource (positive numbers only, min >= 1), 2) Replace ALL random string placeholders with references to the single random_string.result, 3) Replace ALL random integer placeholders with references to the single random_integer.result, 4) Replace location variables with 'eastus', 5) Ensure the configuration is complete and runnable. Include required provider blocks (azurerm, random)." --allow-all-tools --model claude-sonnet-4.5
```

## Completion Criteria

The extraction project is complete when:
- ✅ All test cases have been identified
- ✅ Each test case has its own `test/<case_name>` folder
- ✅ Each folder contains a complete `main.tf` file
- ✅ All placeholders are replaced with Terraform random resources
- ✅ All configurations use `"eastus"` as the location
- ✅ All configurations are syntactically valid HCL

## Notes

- **Sequential Processing**: Extract test cases one at a time to avoid conflicts
- **No Parallel Execution**: Wait for each Test Case Agent to complete before starting the next
- **Preserve Test Logic**: Ensure the extracted configuration maintains the same resource dependencies and structure as the original test
- **Use Reasonable Random Ranges**: 
  - String length: 8 characters (special=false, upper=false for most Azure resources)
  - Integer ranges: Choose appropriate min/max based on context (e.g., instances: 1-10, disk_size: 10-1000)
