<#
.SYNOPSIS
    Runs the GUT unit tests headless. Exit code 0 means every test passed.

.PARAMETER Select
    Only run test scripts whose file name contains this text, e.g. "test_hex".

.PARAMETER Test
    Only run test functions whose name contains this text.

.EXAMPLE
    ./tools/run_tests.ps1
    ./tools/run_tests.ps1 -Select test_hex_pathfinder
#>
param(
    [string]$Select = "",
    [string]$Test = ""
)

. (Join-Path $PSScriptRoot "find_godot.ps1")
$godot = Find-Godot
$project = Split-Path -Parent $PSScriptRoot

# Import first so newly added scripts and assets are registered (class_name cache, textures).
& $godot --headless --path $project --import 2>&1 | Out-Null

$gutArgs = @("--headless", "--path", $project, "-s", "res://addons/gut/gut_cmdln.gd", "-gexit")
if ($Select) { $gutArgs += "-gselect=$Select" }
if ($Test) { $gutArgs += "-gunit_test_name=$Test" }
& $godot @gutArgs
exit $LASTEXITCODE
