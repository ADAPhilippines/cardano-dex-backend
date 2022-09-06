module Spectrum.Executor.EventSink.Handlers.Pools
  ( mkNewPoolsHandler
  ) where

import RIO
  ( (<&>) )

import Spectrum.Executor.Topic
  ( WriteTopic (..) )
import Spectrum.Executor.Data.PoolState
  ( NewPool(..) )
import Spectrum.Executor.EventSink.Types
  ( EventHandler )
import Spectrum.Executor.EventSource.Data.TxEvent
  ( TxEvent(AppliedTx) )
import Spectrum.Executor.EventSource.Data.Tx
  ( MinimalTx(MinimalLedgerTx), MinimalConfirmedTx (..) )
import ErgoDex.Class
  ( FromLedger(parseFromLedger) )
import Spectrum.Executor.Data.State
  ( Confirmed(..) )
import Spectrum.Executor.EventSource.Data.TxContext
  ( TxCtx(LedgerCtx) )

mkNewPoolsHandler
  :: Monad m
  => WriteTopic m (NewPool Confirmed)
  -> EventHandler m 'LedgerCtx
mkNewPoolsHandler WriteTopic{..} = \case 
  AppliedTx (MinimalLedgerTx MinimalConfirmedTx{..}) ->
    foldl process (pure Nothing) (txOutputs <&> parseFromLedger <&> (<&> Confirmed))
      where process _ ordM = mapM publish $ ordM <&> NewPool
  _ -> pure Nothing