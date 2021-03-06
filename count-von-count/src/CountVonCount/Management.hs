-- | Very high-level management utilities. These are usually called from within
-- the web application.
module CountVonCount.Management
    ( findBaton
    , assignBaton
    , assignment
    , addBonus
    ) where

import Control.Applicative ((<$>))
import Control.Arrow ((&&&))
import Control.Monad.Trans (liftIO)
import Data.Foldable (forM_)
import Data.List (find, sort, sortBy)
import Data.Maybe (mapMaybe)
import Data.Ord (comparing)
import Data.Text (Text)
import Data.Time (getCurrentTime)
import qualified Data.Map as M

import CountVonCount.Boxxy
import CountVonCount.Counter
import CountVonCount.Log (Log)
import CountVonCount.Persistence
import CountVonCount.Types

findBaton :: Mac -> [Baton] -> Maybe Baton
findBaton mac = find ((== mac) . batonMac)

assignBaton :: Counter -> [Baton] -> Baton -> Ref Team -> IO ()
assignBaton counter batons baton teamRef = runPersistence $ do
    team <- getTeam teamRef

    -- Reset the old baton, if needed
    forM_ (teamBaton team >>= flip findBaton batons) $ \b ->
        liftIO $ resetCounterFor b counter

    -- Reset the new baton
    liftIO $ resetCounterFor baton counter

    setTeamBaton teamRef $ Just baton

assignment :: [Baton] -> IO ([(Ref Team, Team, Maybe Baton)], [Baton])
assignment batons = do
    teams  <- sortBy (comparing snd) <$> runPersistence getAllTeams
    let batonMap   = M.fromList $ map (batonMac &&& id) batons
        withBatons = flip map teams $ \(ref, team) ->
            (ref, team, teamBaton team >>= flip M.lookup batonMap)
        freeBatons = map snd $ M.toList $ foldl (flip M.delete) batonMap $
            mapMaybe (teamBaton . snd) teams

    return (withBatons, sort freeBatons)

addBonus :: Log -> Boxxies -> Ref Team -> Text -> Int -> Persistence ()
addBonus logger boxxies ref reason laps = do
    timestamp <- liftIO getCurrentTime
    team      <- addLaps ref timestamp reason laps
    liftIO $ withBoxxies logger boxxies $ \b ->
        putLaps b team timestamp laps Nothing (Just reason)
