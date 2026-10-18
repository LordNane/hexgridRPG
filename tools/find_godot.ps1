# Dot-source this file, then call Find-Godot to get the Godot console executable.
# Looks at $env:GODOT, then PATH, then the default local install.
function Find-Godot {
    $godot = $env:GODOT
    if (-not $godot) {
        $onPath = Get-Command godot -ErrorAction SilentlyContinue
        if ($onPath) { $godot = $onPath.Source }
    }
    if (-not $godot) {
        $godot = Join-Path $HOME "dev\tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
    }
    if (-not (Test-Path $godot)) {
        throw "Godot not found at '$godot'. Set the GODOT environment variable to the Godot console executable."
    }
    return $godot
}
