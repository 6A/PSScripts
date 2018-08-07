# PSScripts
My own PowerShell scripts. Not really intended for consumption, but useful nonetheless.

## Update-Flashcards
```powershell
~
λ $Cards = Import-Excel '.\Korean.xlsx'

~
λ $Cards

Hangul     Meaning
------     -------
안녕하세요   Hello, hi, greetings.
감사합니다   Thank you.

~
λ $Cards | Update-Flashcards -Deck '<Tinycards GUID>' -Token '<Tinycards JWT>'

StatusCode        : 200
StatusDescription : OK
Content           : {
                      "awardEligible": false,
                      "blacklistedQuestionTypes": [],
                      "blacklistedSideIndices": [],
                      "cardCount": 2,
                      "compactId": "...",
                      "coverImageUrl": null,
                      "createdAt": 1533551207.6912...
RawContentLength  : 1167
...

```
