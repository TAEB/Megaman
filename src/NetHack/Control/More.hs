module NetHack.Control.More
  (skipMores)
  where

import Data.Foldable hiding(any)
import Control.Monad(when)
import NetHack.Monad.NHAction
import NetHack.Control.Screen

import qualified Regex as R

harmlessMores :: [NHAction Bool]
harmlessMores = [itIsWrittenInTheBook, welcomeBackToNetHack]

skipMores :: NHAction ()
skipMores = do
  pleaseRepeat <-
    foldlM (\result ac -> do test <- ac
                             when test $ answer ' '
                             if result then return True else ac)
           False harmlessMores
  when pleaseRepeat skipMores
  skipHarmlessMessages

isHarmlessMessage :: String -> Bool
isHarmlessMessage str
  | R.match "^(.+) miss(es)? (.+)$" str = True
  | R.match "^(.+) hits!" str = True  -- TODO: rethink which monster around
                                      -- is peaceful or something else
  | R.match "^(.+) bites!" str = True
  | R.match "^(.+) stings!" str = True
  | R.match "^(.+) butts!" str = True
  | R.match "^(.+) bites (.+)\\.$" str = True
  | R.match "^(.+) stings (.+)\\.$" str = True
  | R.match "^(.+) butts (.+)\\.$" str = True
  | R.match "^(Unknown command ' ')\\.$" str = True
  | R.match "^You displaced (.+)\\.$" str = True
  | R.match "^You hear bubbling water\\.$" str = True
  | R.match "^You hear a door open\\.$" str = True
  | R.match "^You hear some noises in the distance\\.$" str = True
  | str == "" = True
  | otherwise = True -- every message is safe for now.

skipHarmlessMessages :: NHAction ()
skipHarmlessMessages = do
  messages <- getMessagesM
  when (any (not . isHarmlessMessage) messages) $
    error $ "Scary message! Current messages: " ++ show messages
  hasMorePrompt <- morePrompt
  when hasMorePrompt $ do answer ' '
                          skipMores

