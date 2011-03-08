-- | Module that maps station names to actual positions
--
{-# LANGUAGE GeneralizedNewtypeDeriving, OverloadedStrings #-}
module CountVonCount.StationMap
    ( StationMap
    , mapStation
    , loadStationMap
    ) where

import Control.Monad (forM)
import Data.Monoid (Monoid)
import Data.Map (Map)
import qualified Data.Map as M

import Data.Object (fromMapping, fromScalar)
import Data.Object.Yaml (YamlObject, fromYamlScalar)

import CountVonCount.Types

newtype StationMap = StationMap (Map Station Position)
                      deriving (Show, Monoid)

loadStationMap :: YamlObject -> Maybe StationMap
loadStationMap object = do
    mapping <- fromMapping object
    tuples <- forM mapping $ \(k, v) -> do
        v' <- fromScalar v
        return (fromYamlScalar k, read $ fromYamlScalar v')
    return $ StationMap $ M.fromList tuples

mapStation :: StationMap -> Station -> Maybe Position
mapStation (StationMap m) station = M.lookup station m