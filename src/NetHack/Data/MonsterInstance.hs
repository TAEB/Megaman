module NetHack.Data.MonsterInstance
  (MonsterInstance(),
   MonsterAttributes(),
   monsterNameTrim,
   monsterByName,
   newMonsterInstance,
   freshMonsterInstance,
   defaultMonsterAttributes,
   monsterByAppearance,
   setAttributes,
   isHostile,
   respectsElbereth)
  where

import qualified Data.Map as M

import Data.Foldable(foldl')

import NetHack.Data.Appearance

import Control.Monad

import qualified Data.ByteString.Char8 as B
import qualified NetHack.Imported.MonsterData as MD
import qualified Regex as R
import qualified Terminal.Data as T

data MonsterAttributes = MonsterAttributes
  { peaceful :: Maybe Bool,
    tame :: Maybe Bool } deriving(Eq, Show)

data MonsterInstance = MonsterInstance MD.Monster MonsterAttributes
                       deriving(Eq, Show)

-- | 'isHostile' returns Just True if the monster is definitely hostile,
-- Just False if the monster is definitely peaceful (or tame) and Nothing
-- if hostility is not known.
isHostile :: MonsterInstance -> Maybe Bool
isHostile (MonsterInstance _ ma) = fmap not (peacefulness |^| tameness)
               where
                 peacefulness = peaceful ma
                 tameness = tame ma
                 (|^|) = liftM2 (||)

newMonsterInstance :: MD.Monster -> MonsterAttributes -> MonsterInstance
newMonsterInstance = MonsterInstance

defaultMonsterAttributes = MonsterAttributes Nothing Nothing

mdCToTermAttributes :: MD.Color -> T.Attributes
mdCToTermAttributes MD.Black         = T.newAttributes T.Blue T.Black False False
mdCToTermAttributes MD.Red           = T.newAttributes T.Red T.Black False False
mdCToTermAttributes MD.Green         = T.newAttributes T.Green T.Black False False
mdCToTermAttributes MD.Brown         = T.newAttributes T.Yellow T.Black False False
mdCToTermAttributes MD.Blue          = T.newAttributes T.Blue T.Black False False
mdCToTermAttributes MD.Magenta       = T.newAttributes T.Magenta T.Black False False
mdCToTermAttributes MD.Cyan          = T.newAttributes T.Cyan T.Black False False
mdCToTermAttributes MD.Gray          = T.newAttributes T.White T.Black False False
mdCToTermAttributes MD.Orange        = T.newAttributes T.Red T.Black True False
mdCToTermAttributes MD.BrightGreen   = T.newAttributes T.Green T.Black True False
mdCToTermAttributes MD.Yellow        = T.newAttributes T.Yellow T.Black True False
mdCToTermAttributes MD.BrightBlue    = T.newAttributes T.Blue T.Black True False
mdCToTermAttributes MD.BrightMagenta = T.newAttributes T.Magenta T.Black True False
mdCToTermAttributes MD.BrightCyan    = T.newAttributes T.Cyan T.Black True False
mdCToTermAttributes MD.White         = T.newAttributes T.White T.Black True False

freshMonsterInstance mon =
  newMonsterInstance mon defaultMonsterAttributes

monsterSymbolTuning :: Char -> Char
monsterSymbolTuning ' ' = '8'   -- ghosts
monsterSymbolTuning '\'' = '7'  -- golems
monsterSymbolTuning ch  = ch

tunedMoSymbol :: MD.Monster -> Char
tunedMoSymbol = monsterSymbolTuning . MD.moSymbol

monsterMapByString :: M.Map String [MD.Monster]
monsterMapByString =
  foldl' (\map name -> let Just mon = MD.monster name
                           symb = [tunedMoSymbol mon]
                        in M.insert symb
                             (case M.lookup symb map of
                                Nothing      -> [mon]
                                Just oldlist -> mon:oldlist)
                             map)

         M.empty
         MD.allMonsterNames

monsterMapByStringLookup :: String -> [MD.Monster]
monsterMapByStringLookup str =
  case M.lookup str monsterMapByString of
    Nothing -> []
    Just l  -> l

monsterByName :: String -> Maybe MD.Monster
monsterByName str = MD.monster $ B.pack str

monsterByAppearance :: Appearance -> [MD.Monster]
monsterByAppearance (str, attributes) =
  foldl accumulateMonsters [] $ monsterMapByStringLookup str
  where
    accumulateMonsters accum mons =
       if (mdCToTermAttributes . MD.moColor $ mons) == attributes &&
           [tunedMoSymbol mons] == str
             then mons:accum
             else accum

monsterNameTrim :: String -> (String, MonsterAttributes)
monsterNameTrim monsname = peacefulness monsname
  where
    peacefulness monsname =
      case R.match "^peaceful (.+)$" monsname of
        Just rest -> tameness rest True
        Nothing   -> tameness monsname False
    tameness monsname peaceful =
      case R.match "^tame (.+)$" monsname of
        Just rest -> coyoteness rest     (peaceful, True)
        Nothing   -> coyoteness monsname (peaceful, False)
    coyoteness monsname attrs =
      case R.match "^(.+) \\- .+$" monsname of
        Just rest -> nameness rest attrs
        Nothing   -> nameness monsname attrs
    nameness monsname (peaceful, tame) =
      case R.match "^(.+) called .+$" monsname of
        Just rest -> (rest,     MonsterAttributes (Just peaceful) (Just tame))
        Nothing   -> (monsname, MonsterAttributes (Just peaceful) (Just tame))

setAttributes :: MonsterInstance -> MonsterAttributes -> MonsterInstance
setAttributes (MonsterInstance mon _) newAttrs = MonsterInstance mon newAttrs

class ElberethQueryable a where
  respectsElbereth :: a -> Bool

instance ElberethQueryable MonsterInstance where
  respectsElbereth (MonsterInstance mon _) = respectsElbereth mon

instance ElberethQueryable MD.Monster where
  respectsElbereth mon
    | tunedMoSymbol mon == '@' = False
    | tunedMoSymbol mon == 'A' = False
    | B.unpack (MD.moName mon) == "minotaur" = False
    | B.unpack (MD.moName mon) == "shopkeeper" = False
    | B.unpack (MD.moName mon) == "Death" = False
    | B.unpack (MD.moName mon) == "Pestilence" = False
    | B.unpack (MD.moName mon) == "Famine" = False
    | otherwise = True

instance ElberethQueryable ((Int, Int), MonsterInstance) where
  respectsElbereth (_, mi) = respectsElbereth mi


