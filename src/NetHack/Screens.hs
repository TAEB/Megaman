module NetHack.Screens where

import NetHack.LogicPlumbing

shallIPick       = isSomewhereOnScreen "Shall I pick a character's"
pickARole        = isSomewhereOnScreen "Pick a role for your character"
pickTheRace      = isSomewhereOnScreen "Pick the race of your"
pickTheGender    = isSomewhereOnScreen "Pick the gender of your"
pickTheAlignment = isSomewhereOnScreen "Pick the alignment of your"
itIsWrittenInTheBook = isSomewhereOnScreen "It is written in the Book of"

morePrompt = isSomewhereOnScreen "--More--"
restoringSave = isSomewhereOnScreen "Restoring save file..."

gameScreen = cursorIsInside (1, 2) (80, 22) =&&=
             ((=~=) morePrompt)

welcomeBackToNetHack = isSomewhereOnScreen ", welcome to NetHack!" =||=
                       isSomewhereOnScreen ", welcome back to NetHack!"


