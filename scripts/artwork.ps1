# Script: scripts\artwork.ps1

# Function Show-AsciiArt
function Show-AsciiArt {
    $asciiArt = @"
               _    __  ____     __
              / \  |  \/  \ \   / /
       _____ / _ \_| |\/| |\ \_/ /____
      |_____/ ___ \| |__| |_\ V /_____|
           /_/   \_\_|  |_|  \_/
===============( AntiMsVirus )===============
"@
    Write-Host $asciiArt
}

# Function Show-Header
function Show-Header {
    $header = @"

===============( AntiMsVirus )===============

"@
    Write-Host $header
}

# Function Show-SatanHeader
function Show-SatanHeader {
    $header = @"

========( Disable Satan Inside )========

"@
    Write-Host $header
}