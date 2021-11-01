module Core.Streaming
  ( ConfirmedOrderEvent(..)
  , ConfirmedPoolEvent(..)
  ) where

import Data.Aeson
import GHC.Generics
import Prelude 
import Kafka.Producer
import Kafka.Consumer

import ErgoDex.Amm.Orders
import ErgoDex.Amm.Pool
import Cardano.Models 
import Streaming.Class
import Explorer.Types

import qualified Data.ByteString.Lazy as BS
import qualified Data.ByteString      as ByteString

data ConfirmedOrderEvent = ConfirmedOrderEvent
  { anyOrder :: AnyOrder
  , txOut    :: FullTxOut
  , gix      :: Gix
  } deriving (Generic, FromJSON, ToJSON)

instance ToKafka PoolId ConfirmedOrderEvent where
  toKafka topic k v =
      ProducerRecord topic UnassignedPartition encodedKey encodedValue
    where
      encodedValue = asKey v
      encodedKey   = asKey k

data ConfirmedPoolEvent = ConfirmedPoolEvent
  { pool  :: Pool
  , txOut :: FullTxOut
  , gix   :: Gix
  } deriving (Generic, FromJSON, ToJSON)

instance ToKafka PoolId ConfirmedPoolEvent where
  toKafka topic k v =
      ProducerRecord topic UnassignedPartition encodedKey encodedValue
    where
      encodedValue = asKey v
      encodedKey   = asKey k

asKey :: (ToJSON a) => a -> Maybe ByteString.ByteString
asKey = Just . BS.toStrict . encode