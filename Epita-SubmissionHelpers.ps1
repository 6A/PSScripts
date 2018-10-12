
$FirstName = 'Grégoire'
$LastName  = 'Geis'
$Username  = 'gregoire.geis'

function Clone-TP {
  param([string][Parameter(Mandatory = $true)] $Number, [switch] $Initialize)

  git clone "git@git.cri.epita.net:p/2022-spe-tp/tp$Number-$Username"

  if ($Initialize) {
    Initialize-TP "tp$Number-$Username"
  }
}

function Initialize-TP {
  param([string][Parameter(Mandatory = $true)] $Directory)

  if (-not (Test-Path $Directory)) {
    Write-Error "Directory '$Directory' does not exist. Have you clone the repository?"

    return
  }

  "main`n*.o" > $Directory/.gitignore
  "$FirstName`n$LastName`n$Username`n$Username@epita.fr" > $Directory/AUTHORS
}

function New-ExerciceDirectory {
  param([string][Parameter(Mandatory = $true)] $Name, [string][Parameter] $CName)

  if (-not $CName) { $CName = $Name }

  mkdir $Name

  echo "#include ""$CName.h""`n`n" > $Name/$CName.c
  echo "#pragma once`n`n" > $Name/$CName.h
  echo "#include <stdlib.h>`n#include <stdio.h>`n#include ""$CName.h""`n`nint main(int argc, char** argv) {`n  return 0;`n}" > $Name/main.c
}

function Execute-Main {
  bash -c 'gcc -Wall -Wextra -Werror -std=c99 -O1 -o main *.c && ./main'
}
