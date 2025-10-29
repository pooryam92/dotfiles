$dotfiles = "$HOME\dotfiles"

Write-Host "Setting up symlinks from $dotfiles..." -ForegroundColor Cyan

$profileTarget = "$dotfiles\Whim\whim.config.yaml"
$profileLink = "$HOME\.whim\whim.config.yaml"

if (Test-Path $profileLink) { Remove-Item $profileLink -Force }
New-Item -ItemType SymbolicLink -Path $profileLink -Target $profileTarget | Out-Null
Write-Host "Linked Whim"


Write-Host "`nAll symlinks created successfully!" -Foregrouncd cddColor Green
