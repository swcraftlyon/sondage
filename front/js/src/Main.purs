module Main where

import Components.ActivityPicker as ActivityPicker
import Components.NameInput as NameInput
import Components.SlotPicker as SlotPicker
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (log)
import Data.Argonaut.Decode (decodeJson)
import Data.Argonaut.Parser (jsonParser)
import Data.Either (Either(..))
import Preferences (DomainEvent(..), applyEvent)
import Prelude (Unit, bind, discard, void, ($), (<>), (=<<))
import React.DOM as R
import React.DOM.Props as RP
import State (State, initialState)
import StaticProps (StaticProps(..), getInitProps)
import Thermite as T
import ThermiteUtils (defaultMain)

render :: T.Render State StaticProps DomainEvent
render dispatch props state _ =
  [ SlotPicker.render dispatch props state
  , ActivityPicker.render dispatch state
  , R.div [RP.className "is-not-expanded"] [
      NameInput.render dispatch state,
      R.div [RP.className "field is-grouped is-grouped-right"] [
        R.p [RP.className "control"] [
          R.button [
            RP.onClick \_ -> dispatch Submit,
            RP.className "button is-primary"] [R.text "Valider"]
        ]
      ]
    ]
  ]

performAction :: T.PerformAction _ State StaticProps DomainEvent
performAction event props state = void $ T.cotransform $ applyEvent props event

spec :: forall e. T.Spec _ State StaticProps DomainEvent
spec = T.simpleSpec performAction render

main :: forall e. Eff _ Unit
main = do
  str <- getInitProps
  case decodeJson =<< jsonParser str of
    Right props -> defaultMain spec initialState props
    Left message -> do
      log ("error: " <> message)
      defaultMain spec initialState (StaticProps {id: "", range: []})
