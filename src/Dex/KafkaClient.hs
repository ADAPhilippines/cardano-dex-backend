module Dex.KafkaClient (sendProxy) where

import Plutus.V1.Ledger.Tx ( TxOut(..) )
import RIO
import qualified RIO.List as L
import Data.Aeson
import Prelude (print)
import Kafka.Producer
import RIO.ByteString.Lazy as BS
import Dex.Models.AppSettings (KafkaProducerSettings(..), HasKafkaProducerSettings(..))

-- ---------- Utils functions ------------

producerProps :: [BrokerAddress] -> ProducerProperties
producerProps ips = brokersList ips
                        <> logLevel KafkaLogDebug

runProducerLocal :: [BrokerAddress] -> (KafkaProducer -> IO (Either KafkaError ())) -> IO ()
runProducerLocal ips f =
    bracket mkProducer clProducer runHandler >>= print
    where
      mkProducer = newProducer $ producerProps ips
      clProducer (Left _)     = return ()
      clProducer (Right prod) = closeProducer prod
      runHandler (Left err)   = return $ Left err
      runHandler (Right prod) = f prod

sendMessages :: [ProducerRecord] -> KafkaProducer -> IO (Either KafkaError ())
sendMessages msgs prod = do
    err <- produceMessageBatch prod msgs
    forM_ err print
    return $ Right ()

mkMessage :: TopicName -> Maybe RIO.ByteString -> Maybe RIO.ByteString -> ProducerRecord
mkMessage t k v = ProducerRecord
                  { prTopic = t
                  , prPartition = UnassignedPartition
                  , prKey = k
                  , prValue = v
                  }

formProducerRecord :: RIO.ByteString -> TopicName -> [TxOut] -> [ProducerRecord]
formProducerRecord s t txOuts = L.map ((mkMessage t (Just s)) . Just . BS.toStrict . encode) txOuts

-- ---------- Module api -----------------

-- Send unspent boxes with proxy contract to kafka
sendProxy :: HasKafkaProducerSettings env => [TxOut] -> RIO env ()
sendProxy txOuts = do
    settings <- view kafkaProducerSettingsL
    liftIO $ runProducerLocal (brokersListS settings) (sendMessages $ formProducerRecord (proxyMsgKey settings) (proxyTopic settings) txOuts)

-- sendAmm:: [TxOut] -> IO ()
