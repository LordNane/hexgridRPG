<#
.SYNOPSIS
    Fails if any project script has a GDScript warning. Exit code 0 means every script is clean.

.EXAMPLE
    ./tools/lint.ps1
#>

. (Join-Path $PSScriptRoot "find_godot.ps1")
$godot = Find-Godot
$project = Split-Path -Parent $PSScriptRoot
$override = Join-Path $project "override.cfg"

# Import first so newly added scripts are registered in the class_name cache.
& $godot --headless --path $project --import 2>&1 | Out-Null

& $godot --headless --path $project -s res://tools/lint.gd -- --prepare 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Couldn't write $override" }
try {
    & $godot --headless --path $project -s res://tools/lint.gd
    $result = $LASTEXITCODE
} finally {
    Remove-Item $override -ErrorAction SilentlyContinue
}
exit $result
