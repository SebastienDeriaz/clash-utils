{-# LANGUAGE RecordWildCards #-}

{-| Implements the lookup side of a <https://en.wikipedia.org/wiki/Cuckoo_hashing Cuckoo hashtable>.

    Cuckoo hashtables are well suited to communicating key value pairs with hardware where the space of keys is large.
 -}
module Clash.Cuckoo (
    TableEntry(..),
    cuckoo
    ) where

import Clash.Prelude

data TableEntry k v = TableEntry {
    key   :: k,
    value :: v
}

{-| The lookup side of a Cuckoo hashtable. Uses split tables. -}
cuckoo 
    :: forall dom gated sync m n k v. (HasClockReset dom gated sync, KnownNat m, KnownNat n, Eq k)
    => Vec (m + 1) (k -> Unsigned n)                                         -- ^ Vector of hash functions, one for each table. CRCs make good hash functions.
    -> Vec (m + 1) (Signal dom (Maybe (Unsigned n, Maybe (TableEntry k v)))) -- ^ Table updates from software. A vector of (row number, row value) pair updates, one for each table. 
    -> Signal dom k                                                          -- ^ The key to lookup.
    -> Signal dom (Maybe (Index (m + 1), Unsigned n, v))                     -- ^ The result of the lookup. Will be ready one cycle after the key is input. The table index and hash of the matching entry are also returned so that future table updates can be made from hardware.
cuckoo hashFunctions tableUpdates lookupKey = fold (liftA2 (<|>)) candidates
    where

    --compute all the hashes
    readAddresses :: Vec (m + 1) (Signal dom (Unsigned n))
    readAddresses = map (($ lookupKey) . fmap) hashFunctions

    --Do the lookups
    fromMem :: Vec (m + 1) (Signal dom (Maybe (TableEntry k v)))
    fromMem = zipWith (blockRamPow2 (repeat Nothing)) readAddresses tableUpdates

    --Check if each item returned from memory matches
    candidates :: Vec (m + 1) (Signal dom (Maybe (Index (m + 1), Unsigned n, v)))
    candidates = izipWith (\idx -> liftA3 (checkCandidate idx) (register (errorX "key") lookupKey)) (map (register (errorX "initial hashes")) readAddresses) fromMem 
        where
        --Get rid of signals
        checkCandidate :: Index (m + 1) -> k -> Unsigned n -> Maybe (TableEntry k v) -> Maybe (Index (m + 1), Unsigned n, v)
        checkCandidate _   lookupKey _    Nothing = Nothing
        checkCandidate idx lookupKey hash (Just TableEntry{..}) 
            | lookupKey == key = Just (idx, hash, value)
            | otherwise        = Nothing

