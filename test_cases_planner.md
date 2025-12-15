# Prompt: Extract Terraform Provider Test Cases

## Objective
Extract all valid atomic test configuration case names from a Terraform provider's acceptance test file for a given resource type. This list will be used to systematically test AzAPI migration scenarios.

You should store these names in a table stored in `test_cases.md` file with the following format:

| case name | file url | status |
| ---       | ---      | ---    |
| basic     | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Pending |
...

## Instructions

### Step 1: Locate the Test File
Find the acceptance test file for the target resource type in the HashiCorp Terraform provider repository:
- **Pattern**: `<resource_name>_resource_test.go` or `<resource_name>_resource_*_test.go`
- **Example**: For `azurerm_orchestrated_virtual_machine_scale_set`, look for:
  - `orchestrated_virtual_machine_scale_set_resource_test.go`
  - `orchestrated_virtual_machine_scale_set_resource_*_test.go` (if split into multiple files)

### Step 2: Identify Test Configuration Functions
Scan the test file for configuration functions that return Terraform HCL strings. These typically:
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

For each configuration function, check how it's used in test methods (`func TestAcc...`):

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

1. **Find function**: `func (r Resource) linux(data acceptance.TestData) string`
2. **Check usage**: Search for `r.linux(data)` in test methods
3. **Found in**: `TestAccResource_basic` with `Config: r.linux(data)` → ✅ INCLUDE
4. **Classification**: Basic Linux configuration
5. **Add to list**: Under "Basic/Foundation Cases"

## Validation Checklist

Before finalizing the list:
- [ ] All functions used directly in `TestStep.Config` are included
- [ ] All functions with `ExpectError` in same TestStep are excluded
- [ ] All helper functions (only called by other functions) are excluded
- [ ] All `requiresImport` variants are excluded
- [ ] Each case has a clear, descriptive label
- [ ] Cases are logically categorized
- [ ] Total count is accurate

## Common Pitfalls to Avoid

❌ **Don't include**: Functions that only provide infrastructure for other tests
❌ **Don't include**: Functions testing error conditions or validation failures
❌ **Don't include**: Functions testing import rejection scenarios
✅ **Do include**: Functions that test actual resource configurations that should work
✅ **Do include**: Functions testing updates between valid states
✅ **Do include**: Functions testing different feature combinations

## Notes

- Some test files may be split across multiple `*_test.go` files - check all of them
- Look for patterns like `_template`, `_helper`, `_base` in function names (often indicate helpers)
- Test methods with "Error" or "Invalid" in their names often use error test cases
- Update test cases (testing A → B transitions) are valid if both A and B are valid configs
