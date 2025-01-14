{-# LANGUAGE NoImplicitPrelude #-}

{- |
Module                  : Data.TypeRepMap
Copyright               : (c) 2017-2021 Kowainik
SPDX-License-Identifier : MPL-2.0
Maintainer              : Kowainik <xrom.xkov@gmail.com>
Stability               : Stable
Portability             : Portable

A version of 'Data.TMap.TMap' parametrized by an interpretation @f@. This
sort of parametrization may be familiar to users of @vinyl@ records.

@'TypeRepMap' f@ is a more efficient replacement for @DMap
'Type.Reflection.TypeRep' f@ (where @DMap@ is from the @dependent-map@
package).

Here is an example of using 'Prelude.Maybe' as an interpretation, with a
comparison to 'Data.TMap.TMap':

@
     'Data.TMap.TMap'              'TypeRepMap' 'Prelude.Maybe'
--------------       -------------------
 Int  -> 5             Int  -> Just 5
 Bool -> True          Bool -> Nothing
 Char -> \'x\'           Char -> Just \'x\'
@

In fact, a 'Data.TMap.TMap' is defined as 'TypeRepMap'
'Data.Functor.Identity'.

Since 'Type.Reflection.TypeRep' is poly-kinded, the interpretation can use
any kind for the keys. For instance, we can use the 'GHC.TypeLits.Symbol'
kind to use 'TypeRepMap' as an extensible record:

@
newtype Field name = F (FType name)

type family FType (name :: Symbol) :: Type
type instance FType "radius" = Double
type instance FType "border-color" = RGB
type instance FType "border-width" = Double

       'TypeRepMap' Field
--------------------------------------
 "radius"       -> F 5.7
 "border-color" -> F (rgb 148 0 211)
 "border-width" -> F 0.5
@
-}

module Data.TypeRepMap
       ( -- * Map type
         TypeRepMap()

         -- * Construction
       , empty
       , one

         -- * Modification
       , insert
       , delete
       , adjust
       , alter
       , hoist
       , hoistA
       , hoistWithKey
       , unionWith
       , union
       , intersectionWith
       , intersection

         -- * Query
       , lookup
       , member
       , size
       , keys
       , keysWith
       , toListWith

         -- * 'IsList'
       , WrapTypeable (..)
       ) where

import Data.TypeRepMap.Internal
