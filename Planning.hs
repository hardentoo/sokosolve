module Planning (
  solve
 ) where

import Routing
import Grid

import Data.List
import Data.Maybe
import qualified Data.Set as S

--TODO: The Hungarian algorithm is a better heuristic
heuristic = const 0

solve g = case astar heuristic solved walks g of
  [] -> Nothing
  ((s,_,_):_) -> Just $ concat s

clearSteps :: Grid -> [(Integer, Direction, Grid)]
clearSteps g = let
  p = gridPlayer g
  in map (\(d,p') -> (1,d,g {gridPlayer = p'})) $
    filter (\(_,p') -> isClear p' g) $
    map (\d -> let p' = step d p in (d,p')) directions

byBox g = let
  p = gridPlayer g
  in any (flip isBox g . flip step p) directions

pushSteps :: Grid -> [(Integer, [Direction], Grid)]
pushSteps g = let
  p = gridPlayer g
  in map (\(d,p',b') -> (1,[d],g {
      gridPlayer = p',
      gridBoxes = S.delete p' $ S.insert b' $ gridBoxes g
     })) $
    filter (\(_,p',b') -> isBox p' g && isClear b' g
     ) $
    map (\d -> let p' = step d p in (d,p',step d p')) directions

clearWalks :: Grid -> [(Integer,[Direction],Grid)]
clearWalks g = let
  -- Originally this only returned tiles adjacent to boxes
  -- but that's no longer necessary because the relationship
  -- between this function and pushSteps was changed, making
  -- the extra check redundant.
  r = dijkstra (const True) clearSteps g
  in map (\(s,g',c) -> (c,s,g')) r

wrapStep :: (n -> [(Integer,s,n)]) -> n -> [(Integer,[s],n)]
wrapStep b = map (\(c,s,n) -> (c,[s],n)) . b

walks :: Grid -> [(Integer,[Direction],Grid)]
walks g = do
  (c1,p1,g1) <- clearWalks g
  (c2,p2,g2) <- pushSteps g1
  return (c1 + c2, p1 ++ p2, g2)

