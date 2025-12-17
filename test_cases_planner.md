# Prompt: Extract Terraform Provider Test Cases

## Objective
Extract all valid atomic test configuration case names from a Terraform provider's acceptance test file for a given resource type. This list will be used to systematically test AzAPI migration scenarios.

You should store these names in a table stored in `test_cases.md` file with the following format:

| case name | file url | status |
| ---       | ---      | ---    |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Pending |
...

## Instructions

### Step 1: Locate ALL Test Files
Find ALL acceptance test files for the target resource type in the HashiCorp Terraform provider repository. **IMPORTANT**: Many resources have their tests split across multiple files by feature area.

**Search Pattern**: `<resource_name>_resource*_test.go`

**Example**: For `azurerm_orchestrated_virtual_machine_scale_set`, search for files matching:
- Pattern: `orchestrated_virtual_machine_scale_set_resource*_test.go`
- This will match:
  - `orchestrated_virtual_machine_scale_set_resource_test.go` (main test file)
  - `orchestrated_virtual_machine_scale_set_resource_disk_data_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_disk_os_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_extensions_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_identity_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_network_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_other_test.go`
  - And any other split files

**How to Search**:
1. Use GitHub search with pattern: `filename:orchestrated_virtual_machine_scale_set_resource repo:hashicorp/terraform-provider-azurerm path:internal/services/compute`
2. Or fetch URLs for all matching files:
   - `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go`
   - `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go`
   - Continue for each file matching the pattern

**EXCLUSIONS**: 
- ❌ **IGNORE files containing `legacy` in the filename** (e.g., `*_resource_legacy_test.go`) - we don't care about legacy code

**CRITICAL**: You MUST scan ALL test files (except legacy), not just the main one, to get a complete list of test cases.

### Step 2: Identify Test Configuration Functions Across ALL Files
Scan **ALL test files** for configuration functions that return Terraform HCL strings. These typically:
- Are methods on the resource's test struct (e.g., `(r ResourceType) functionName(data acceptance.TestData) string`)
- Return `fmt.Sprintf(...)` with Terraform configuration
- Are called within `TestStep.Config` in test methods

**Example Pattern**:
```go
func (OrchestratedVirtualMachineScaleSetResource) basic(data acceptance.TestData) string {
    return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%[1]d"
  location = "%[2]s"
}
// ... more resources
`, data.RandomInteger, data.Locations.Primary)
}
```

### Step 3: Classify Each Configuration Function

For each function found, determine its classification:

#### ✅ **INCLUDE** - Valid Atomic Test Cases:
- Functions used directly in `TestStep.Config` field
- Represent a specific feature or scenario to test
- Examples: `basic()`, `withPPG()`, `linux()`, `basicWindows()`

#### ❌ **EXCLUDE** - Not Valid Test Cases:

1. **Helper/Template Functions**
   - Functions that are only called BY other test functions (never used directly in TestStep)
   - Provide shared infrastructure or common setup
   - Example: `natgateway_template()` that's only used via `%[3]s` injection in other configs

2. **Error Test Cases**
   - Functions used with `ExpectError` in TestStep
   - Validate that provider correctly rejects invalid configurations
   - Look for test steps with `ExpectError: regexp.MustCompile(...)` or `ExpectError: acceptance.RequiresImportError(...)`
   - Examples: `requiresImport()`, `skuProfileNotExist()`, `skuProfileWithoutSkuName()`

### Step 4: Analyze Test Methods for Usage

For each configuration function, check how it's used in test methods (`func TestAcc...`) **across ALL test files**:

**Direct Usage (INCLUDE)**:
```go
func TestAccResource_basic(t *testing.T) {
    data.ResourceTest(t, r, []acceptance.TestStep{
        {
            Config: r.basic(data),  // ✅ Direct usage
            Check: acceptance.ComposeTestCheckFunc(...),
        },
    })
}
```

**Error Test Usage (EXCLUDE)**:
```go
func TestAccResource_requiresImport(t *testing.T) {
    data.ResourceTest(t, r, []acceptance.TestStep{
        {
            Config: r.basic(data),
            Check: acceptance.ComposeTestCheckFunc(...),
        },
        {
            Config:      r.requiresImport(data),  // ❌ Used with ExpectError
            ExpectError: acceptance.RequiresImportError("azurerm_resource"),
        },
    })
}
```

**Helper Usage (EXCLUDE)**:
```go
func (r Resource) someTest(data acceptance.TestData) string {
    return fmt.Sprintf(`
%[3]s  // ❌ natgateway_template injected here, never used directly in TestStep
resource "azurerm_resource" "test" {
  // ...
}
`, data.RandomInteger, data.Locations.Primary, r.natgateway_template(data))
}
```

### Step 5: Organize the Final List

Group valid test cases by category for clarity:

#### Suggested Categories:
1. **Basic/Foundation Cases** - Core functionality, minimal configuration
2. **OS-Specific Cases** - Linux, Windows, different distributions
3. **Feature-Specific Cases** - Individual features like boot diagnostics, proximity placement groups
4. **Advanced Configuration Cases** - Complex scenarios, multiple features combined
5. **Update/Lifecycle Cases** - Testing updates, changes between configurations
6. **Edge Cases** - Regression tests, boundary conditions

### Step 6: Document Each Test Case

For each valid test case, provide:
1. **Function signature**: `r.functionName(data)`
2. **Brief description**: What feature/scenario it tests
3. **Key characteristics**: What makes it unique (e.g., "2 instances vs 1", "with Ed25519 SSH key")

## Output Format

```markdown
## Test Configuration Functions for [Resource Type]

### [Category Name] (X cases):
1. **`r.functionName(data)`** - Brief description
2. **`r.anotherFunction(data)`** - Brief description
   ...

### [Another Category] (Y cases):
...

---

**Removed Cases**:
- ❌ `r.helperFunction(data)` - Helper/template function (only called by other configs)
- ❌ `r.errorCase(data)` - Error test case (used with ExpectError)
- ❌ `r.requiresImport(data)` - Error test case (validates import rejection)

**Total Valid Test Cases**: [Number]
```

## Example Analysis Workflow

1. **Find ALL test files**: Search for `orchestrated_virtual_machine_scale_set_resource*_test.go` - found 7 files
2. **Scan all files for functions**: `func (r Resource) linux(data acceptance.TestData) string` found in main test file
3. **Check usage across all files**: Search for `r.linux(data)` in all 7 test files
4. **Found in**: `TestAccResource_basic` with `Config: r.linux(data)` → ✅ INCLUDE
5. **Classification**: Basic Linux configuration
6. **Add to list**: Under "Basic/Foundation Cases"

## Validation Checklist

Before finalizing the list:
- [ ] All test files matching `<resource_name>_resource*_test.go` pattern have been identified (excluding `*legacy*` files)
- [ ] All test files have been scanned for configuration functions (excluding legacy files)
- [ ] All functions used directly in `TestStep.Config` are included (from all files)
- [ ] All functions with `ExpectError` in same TestStep are excluded
- [ ] All helper functions (only called by other functions) are excluded
- [ ] All `requiresImport` variants are excluded
- [ ] Each case has a clear, descriptive label
- [ ] Cases are logically categorized
- [ ] Total count is accurate
- [ ] File source is documented for each test case

## Common Pitfalls to Avoid

❌ **Don't include**: Functions that only provide infrastructure for other tests
❌ **Don't include**: Functions testing error conditions or validation failures
❌ **Don't include**: Functions testing import rejection scenarios
✅ **Do include**: Functions that test actual resource configurations that should work
✅ **Do include**: Functions testing updates between valid states
✅ **Do include**: Functions testing different feature combinations

## Notes

- **CRITICAL**: Some test files are split across multiple `*_test.go` files - check ALL of them by using the pattern `<resource_name>_resource*_test.go`
- **EXCLUDE**: Files containing `legacy` in the filename (e.g., `*_resource_legacy_test.go`) - ignore these completely
- Use GitHub file search or fetch multiple URLs to retrieve all test files
- Look for patterns like `_disk_`, `_network_`, `_identity_`, `_extensions_`, `_other_` in filenames (often indicate split test files by feature area)
- Look for patterns like `_template`, `_helper`, `_base` in function names (often indicate helpers)
- Test methods with "Error" or "Invalid" in their names often use error test cases
- Update test cases (testing A → B transitions) are valid if both A and B are valid configs
