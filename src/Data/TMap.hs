{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE Rank2Types          #-}

{- |
Module                  : Data.TMap
Copyright               : (c) 2017-2021 Kowainik
SPDX-License-Identifier : MPL-2.0
Maintainer              : Kowainik <xrom.xkov@gmail.com>
Stability               : Stable
Portability             : Portable

'TMap' is a heterogeneous data structure similar in its essence to
'Data.Map.Map' with types as keys, where each value has the type of its key.

Here is an example of a 'TMap' with a comparison to 'Data.Map.Map':

@
 'Data.Map.Map' 'Prelude.String' 'Prelude.String'             'TMap'
--------------------     -----------------
 \"Int\"  -> \"5\"             'Prelude.Int'  -> 5
 \"Bool\" -> \"True\"          'Prelude.Bool' -> 'Prelude.True'
 \"Char\" -> \"\'x\'\"           'Prelude.Char' -> \'x\'
@

The runtime representation of 'TMap' is an array, not a tree. This makes
'lookup' significantly more efficient.
-}

module Data.TMap
       ( -- * Map type
         TMap

         -- * Construction
       , empty
       , one

         -- * Modification
       , insert
       , delete
       , unionWith
       , union
       , intersectionWith
       , intersection
       , map
       , adjust
       , alter

         -- * Query
       , lookup
       , member
       , size
       , keys
       , keysWith
       , toListWith
       ) where

import Prelude hiding (lookup, map)

import Data.Functor.Identity (Identity (..))
import Data.Typeable (Typeable)
import GHC.Exts (coerce)
import Type.Reflection (SomeTypeRep, TypeRep)

import qualified Data.TypeRepMap as F

-- | 'TMap' is a special case of 'F.TypeRepMap' when the interpretation is
-- 'Identity'.
type TMap = F.TypeRepMap Identity

{- |

A 'TMap' with no values stored in it.

prop> size empty == 0
prop> member @a empty == False

-}
empty :: TMap
empty = F.empty
{-# INLINE empty #-}

{- |

Construct a 'TMap' with a single element.

prop> size (one x) == 1
prop> member @a (one (x :: a)) == True

-}
one :: forall a . Typeable a => a -> TMap
one x = coerce (F.one @a @Identity $ coerce x)
{-# INLINE one #-}

{- |

Insert a value into a 'TMap'.
TMap optimizes for fast reads rather than inserts, as a trade-off inserts are @O(n)@.

prop> size (insert v tm) >= size tm
prop> member @a (insert (x :: a) tm) == True

-}
insert :: forall a . Typeable a => a -> TMap -> TMap
insert x = coerce (F.insert @a @Identity $ coerce x)
{-# INLINE insert #-}

{- | Delete a value from a 'TMap'.

TMap optimizes for fast reads rather than modifications, as a trade-off deletes are @O(n)@,
with an @O(log(n))@ optimization for when the element is already missing.

prop> size (delete @a tm) <= size tm
prop> member @a (delete @a tm) == False

>>> tm = delete @Bool $ insert True $ one 'a'
>>> size tm
1
>>> member @Bool tm
False
>>> member @Char tm
True
-}
delete :: forall a . Typeable a => TMap -> TMap
delete = F.delete @a @Identity
{-# INLINE delete #-}

-- | The union of two 'TMap's using a combining function.
unionWith :: (forall x . Typeable x => x -> x -> x) -> TMap -> TMap -> TMap
unionWith f = F.unionWith fId
  where
    fId :: forall y . Typeable y => Identity y -> Identity y -> Identity y
    fId y1 y2 = Identity $ f (coerce y1) (coerce y2)
{-# INLINE unionWith #-}

-- | The (left-biased) union of two 'TMap's. It prefers the first map when
-- duplicate keys are encountered, i.e. @'union' == 'unionWith' const@.
union :: TMap -> TMap -> TMap
union = F.union
{-# INLINE union #-}

-- | The intersection of two 'TMap's using a combining function.
--
-- @O(n + m)@
intersectionWith :: (forall x . Typeable x => x -> x -> x) -> TMap -> TMap -> TMap
intersectionWith f = F.intersectionWith fId
  where
    fId :: forall y . Typeable y => Identity y -> Identity y -> Identity y
    fId y1 y2 = f (coerce y1) (coerce y2)
{-# INLINE intersectionWith #-}

-- | The intersection of two 'TMap's.
-- It keeps all values from the first map whose keys are present in the second.
--
-- @O(n + m)@
intersection :: TMap -> TMap -> TMap
intersection = F.intersection
{-# INLINE intersection #-}

{- | Lookup a value of the given type in a 'TMap'.

>>> x = lookup $ insert (11 :: Int) empty
>>> x :: Maybe Int
Just 11
>>> x :: Maybe ()
Nothing
-}
lookup :: forall a . Typeable a => TMap -> Maybe a
lookup = coerce (F.lookup @a @Identity)
{-# INLINE lookup #-}

{- | Check if a value of the given type is present in a 'TMap'.

>>> member @Char $ one 'a'
True
>>> member @Bool $ one 'a'
False
-}
member :: forall a . Typeable a => TMap -> Bool
member = F.member @a @Identity
{-# INLINE member #-}

-- | Get the amount of elements in a 'TMap'.
size :: TMap -> Int
size = F.size
{-# INLINE size #-}

-- | Returns the list of 'SomeTypeRep's from keys.
keys :: TMap -> [SomeTypeRep]
keys = F.keys
{-# INLINE keys #-}

-- | Return the list of keys by wrapping them with a user-provided function.
keysWith :: (forall a . TypeRep a -> r) -> TMap -> [r]
keysWith = F.keysWith
{-# INLINE keysWith #-}

-- | Return the list of key-value pairs by wrapping them with a user-provided function.
toListWith :: (forall a . Typeable a => a -> r) -> TMap -> [r]
toListWith f = F.toListWith (f . runIdentity)
{-# INLINE toListWith #-}

-- | Map a function over the values.
map :: (forall a . Typeable a => a -> a) -> TMap -> TMap
map f = F.hoistWithKey (liftToIdentity f)
{-# INLINE map #-}

-- | Update a value with the result of the provided function.
adjust :: Typeable a => (a -> a) -> TMap -> TMap
adjust f = F.adjust (liftToIdentity f)
{-# INLINE adjust #-}

-- | Updates a value at a specific key, whether or not it exists.
--   This can be used to insert, delete, or update a value of a given type in the map.
alter :: Typeable a => (Maybe a -> Maybe a) -> TMap -> TMap
alter f = F.alter (liftF f)
  where
    liftF :: forall a . (Maybe a -> Maybe a) -> Maybe (Identity a) -> Maybe (Identity a)
    liftF = coerce
{-# INLINE alter #-}

liftToIdentity :: forall a . (a -> a) -> Identity a -> Identity a
liftToIdentity = coerce
