
function Update-Flashcards(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [array] $Flashcards,
    [Parameter(Mandatory=$true)] [string] $Deck,
    [Parameter(Mandatory=$true)] [string] $Token) {

    $Headers = @{
        'Content-Type' = 'application/json; charset=utf-8'
        'Cookie'       = "jwt_token=$Token"
    }


    # Fetch existing cards in order to keep their ID (we don't want to lose our progress).
    $Req = Invoke-WebRequest "https://tinycards.duolingo.com/api/1/decks/$($Deck)?expand=true" `
                -Headers $Headers                                                              `
                -Method Get

    $ExistingCards = (ConvertFrom-Json $Req.Content).cards


    # Create request
    $Patch = @{
        'cards' = ($Input | % { $_.PSObject } | ? { ($_.Properties | select -Index 0).Value } | % {
            $PropertyCount = ($_.Properties | measure).Count
            $FrontText     = ($_.Properties | select -Index 0).Value.ToString().Trim()

            $ExistingCard = $ExistingCards                                                `
                          | ? { $_.sides[0].concepts[0].fact.text.Trim() -eq $FrontText } `
                          | ? { $_.sides.Count -eq $PropertyCount }                       `
                          | select -First 1

            if ($ExistingCard) {
                $_.Properties | % { $i = 0 } {
                    $ExistingCard.sides[$i++].concepts[0].fact.text = $_.Value
                }

                $ExistingCard
            } else {
                @{
                    'sides' = @($_.Properties | % {
                        @{
                            'concepts' = @(
                                @{ 'fact' = @{ 'text' = $_.Value.ToString(); 'type' = 'TEXT' } }
                            )
                        }
                    })
                }
            }
        }) | ConvertTo-Json -Depth 50 -Compress
    }

    # Fix request in case there is only one card
    if ($Patch.cards[0] -eq '{') {
        $Patch.cards = "[$($Patch.cards)]"
    }

    # Update everything
    Invoke-WebRequest "https://tinycards.duolingo.com/api/1/decks/$Deck"  `
        -Headers $Headers                                                 `
        -Method Patch                                                     `
        -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $Patch -Compress)))
}
