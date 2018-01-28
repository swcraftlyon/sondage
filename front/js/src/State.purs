module State (State(..), Error(..), initialState, changeSlots, changeActivity, validateSlots, validateActivities) where

import Prelude

import Activity (Activity)
import Data.Argonaut.Core (Json, jsonEmptyObject)
import Data.Argonaut.Decode (class DecodeJson, decodeJson, getField)
import Data.Argonaut.Encode (class EncodeJson, encodeJson, (:=), (~>))
import Data.Either (Either)
import Data.Enum (enumFromTo)
import Data.Newtype (class Newtype, unwrap)
import Data.Set (Set, delete, empty, fromFoldable, insert, isEmpty, toUnfoldable)
import Slot (Slot)

data Error
  = NoActivity
  | NoSlot

derive instance eqError :: Eq Error
derive instance ordError :: Ord Error
instance showError :: Show Error where
  show :: Error -> String
  show NoActivity = "Pas d'activité"
  show NoSlot = "Pas de créneau"

newtype State =
  State { slots :: Array Slot
        , activities :: Set Activity
        , errors :: Set Error
        }

derive instance newtypeState :: Newtype State _
derive instance eqState :: Eq State

instance showState :: Show State where
  show :: State -> String
  show (State { slots: slots, activities: activities, errors: errors})
    = "State { slots: " <> show slots <>
      ", activities: " <> show activities <>
      ", errors: " <> show errors <> " }"

instance decodeState :: DecodeJson State where
  decodeJson :: Json -> Either String State
  decodeJson json = do
    obj <- decodeJson json
    slots <- getField obj "slots"
    activities <- fromArray <$> getField obj "activities"
    pure $ State { slots: slots
                 , activities: activities
                 , errors: empty
                 }

      where
        fromArray :: Array Activity -> Set Activity
        fromArray activities = fromFoldable activities

instance encodeState :: EncodeJson State where
  encodeJson :: State -> Json
  encodeJson state
    = encodeJson
      ( "slots" := (unwrap state).slots
      ~> "activities" := activities
      ~> jsonEmptyObject
      )
      where
        activities :: Array Activity
        activities = toUnfoldable (unwrap state).activities

initialState :: State
initialState = State { slots: [], activities: fromFoldable allActivities, errors: empty }
  where
    allActivities :: Array Activity
    allActivities = enumFromTo bottom top

changeSlots :: (Array Slot -> Array Slot) -> State -> State
changeSlots changer state =
  State { slots: changer (unwrap state).slots
        , activities: (unwrap state).activities
        , errors: (unwrap state).errors
        }

changeActivity :: (Set Activity -> Set Activity) -> State -> State
changeActivity changer state
  = State { slots: (unwrap state).slots
          , activities: changer (unwrap state).activities
          , errors: (unwrap state).errors
          }

changeErrors :: (Set Error -> Set Error) -> State -> State
changeErrors changer state
  = State { slots: (unwrap state).slots
          , activities: (unwrap state).activities
          , errors: changer (unwrap state).errors
          }

validateSlots :: State -> State
validateSlots state
  = if (unwrap state).slots == []
    then changeErrors (insert NoSlot) state
    else changeErrors (delete NoSlot) state

validateActivities :: State -> State
validateActivities state
  = if isEmpty (unwrap state).activities
    then changeErrors (insert NoActivity) state
    else changeErrors (delete NoActivity) state
