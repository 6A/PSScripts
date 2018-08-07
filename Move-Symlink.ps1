<#
.SYNOPSIS
    Moves a directory to a new location, and creates a symlink from the
    previous location to the new one.
#>

function Move-Symlink([String] $Source, [String] $Destination) {
    ROBOCOPY $Source $Destination /S /E /MOVE
    CMD /C MKLINK /J $Source $Destination
}
