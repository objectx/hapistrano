{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Config
  ( Config (..)
  , CopyThing (..) )
where

import Data.Aeson
import Data.Yaml
import Path
import System.Hapistrano.Commands

-- | Hapistrano configuration typically loaded from @hap.yaml@ file.

data Config = Config
  { configDeployPath :: !(Path Abs Dir)
    -- ^ Top-level deploy directory on target machine
  , configHost :: !(Maybe String)
    -- ^ Host to deploy to. If missing, localhost will be assumed.
  , configPort :: !Word
    -- ^ SSH port number to use, may be omitted
  , configRepo :: !String
    -- ^ Location of repository that contains the source code to deploy
  , configRevision :: !String
    -- ^ Revision to use
  , configRestartCommand :: !(Maybe GenericCommand)
    -- ^ The command to execute when switching to a different release
    -- (usually after a deploy or rollback).
  , configBuildScript :: !(Maybe [GenericCommand])
    -- ^ Build script to execute to build the project
  , configCopyFiles :: ![CopyThing]
    -- ^ Collection of files to copy over to target machine before building
  , configCopyDirs :: ![CopyThing]
    -- ^ Collection of directories to copy over to target machine before building
  } deriving (Eq, Ord, Show)

-- | Information about source and destination locations of a file\/directory
-- to copy.

data CopyThing = CopyThing FilePath FilePath
  deriving (Eq, Ord, Show)

instance FromJSON Config where
  parseJSON = withObject "Hapistrano configuration" $ \o -> do
    configDeployPath <- o .: "deploy_path"
    configHost       <- o .:? "host"
    configPort       <- o .:? "port" .!= 22
    configRepo       <- o .: "repo"
    configRevision   <- o .: "revision"
    configRestartCommand <- (o .:? "restart_command") >>=
      maybe (return Nothing) (fmap Just . mkCmd)
    configBuildScript <- o .:? "build_script" >>=
      maybe (return Nothing) (fmap Just . mapM mkCmd)
    configCopyFiles  <- o .:? "copy_files" .!= []
    configCopyDirs   <- o .:? "copy_dirs"  .!= []
    return Config {..}

instance FromJSON CopyThing where
  parseJSON = withObject "src and dest of a thing to copy" $ \o ->
    CopyThing <$> (o .: "src") <*> (o .: "dest")

mkCmd :: String -> Parser GenericCommand
mkCmd raw =
  case mkGenericCommand raw of
    Nothing -> fail "invalid restart command"
    Just cmd -> return cmd
