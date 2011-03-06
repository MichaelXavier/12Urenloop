-- | Finite channels
--
module CountVonCount.FiniteChan
    ( FiniteChan
    , newFiniteChan
    , dupFiniteChan
    , runFiniteChan
    , writeFiniteChan
    , endFiniteChan
    , waitFiniteChan
    ) where

import Control.Applicative ((<$>), (<*>), pure)

import Control.Concurrent.Chan.Strict ( Chan, newChan, writeChan, readChan
                                      , dupChan
                                      )
import Control.Concurrent.MVar.Strict (MVar, newEmptyMVar, putMVar, takeMVar)
import Control.DeepSeq (NFData)
import System.IO (hPutStrLn, stderr)

data FiniteChan a = FiniteChan
    { finiteName :: String
    , finiteChan :: Chan (Maybe a)
    , finiteSync :: MVar ()
    }

instance Show (FiniteChan a) where
    show fc = "FiniteChan " ++ finiteName fc

newFiniteChan :: NFData a => String -> IO (FiniteChan a)
newFiniteChan name = FiniteChan <$> pure name
                                <*> newChan
                                <*> newEmptyMVar

dupFiniteChan :: NFData a => String -> FiniteChan a -> IO (FiniteChan a)
dupFiniteChan name (FiniteChan _ c _) = FiniteChan <$> pure name
                                                   <*> dupChan c
                                                   <*> newEmptyMVar

writeFiniteChan :: NFData a => FiniteChan a -> a -> IO ()
writeFiniteChan chan = writeChan (finiteChan chan) . Just

endFiniteChan :: NFData a => FiniteChan a -> IO ()
endFiniteChan chan = do
    writeChan (finiteChan chan) Nothing
    hPutStrLn stderr $ "Closing " ++ show chan

waitFiniteChan :: NFData a => FiniteChan a -> IO ()
waitFiniteChan chan = do
    hPutStrLn stderr $ "Waiting for end of " ++ show chan
    takeMVar $ finiteSync chan
    hPutStrLn stderr $ "Cleanly closed " ++ show chan

readFiniteChan :: NFData a => FiniteChan a -> IO (Maybe a)
readFiniteChan chan = do
    mx <- readChan $ finiteChan chan
    case mx of
        Just x  -> return $ Just x
        Nothing -> do hPutStrLn stderr $ "Reached end of " ++ show chan
                      putMVar (finiteSync chan) () >> return Nothing

runFiniteChan :: NFData a
              => FiniteChan a
              -> s
              -> (a -> s -> IO s)
              -> IO s
runFiniteChan chan initial f = go initial
  where
    go state = do
        mx <- readFiniteChan chan
        case mx of Nothing -> return state
                   Just x  -> f x state >>= go