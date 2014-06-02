module Main where

import qualified Hapistrano as Hap
import Control.Monad (void)

testConfig :: Hap.Config
testConfig = Hap.Config { Hap._deployPath = "/tmp/project"
                        , Hap._host       = "localhost"
                        , Hap._repository = "/tmp/testrepo"
                        , Hap._revision    = "origin/transformer-refactor"
                        }

main :: IO ()
main = do
  initState <- Hap.initialState testConfig

  Hap.runRC errorHandler successHandler initState $
    do
      Hap.pushRelease
      Hap.defaultBuildRelease
      void Hap.activateRelease

  where
    errorHandler   = Hap.defaultErrorHandler
    successHandler = Hap.defaultSuccessHandler