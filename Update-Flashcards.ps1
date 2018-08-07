
function Update-Flashcards(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [array] $Flashcards,
    [Parameter(Mandatory=$true)] [string] $Deck,
    [Parameter(Mandatory=$true)] [string] $Token) {

    $Patch = @{
        'cards' = ($Input | ? { ($_.PSObject.Properties | select -Index 0).Value } | % {
            @{
                'sides' = @($_.PSObject.Properties | % {
                    @{
                        'concepts' = @(
                            @{ 'fact' = @{ 'text' = $_.Value.ToString(); 'type' = 'TEXT' } }
                        )
                    }
                })
            }
        }) | ConvertTo-Json -Depth 50 -Compress
    }

    if ($Patch.cards[0] -eq '{') {
        $Patch.cards = "[$($Patch.cards)]"
    }

    $Headers = @{
        'Content-Type' = 'application/json; charset=utf-8';
        'Cookie'       = "jwt_token=$Token"
    }

    Invoke-WebRequest "https://tinycards.duolingo.com/api/1/decks/$Deck"  `
        -Headers $Headers                                                 `
        -Method Patch                                                     `
        -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $Patch -Compress)))
}
