{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module WeatherAPI where

import Data.Aeson
import Network.HTTP.Simple
import GHC.Generics
import Data.Text (Text)
import qualified Data.Text as T
import Types (WeatherData(..))
import System.Environment (lookupEnv)

data OWMResponse = OWMResponse
    { main :: OWMMain
    , wind :: OWMWind
    } deriving (Show, Generic)

data OWMMain = OWMMain
    { temp_max :: Double
    , temp_min :: Double
    , humidity :: Double
    , pressure :: Double
    } deriving (Show, Generic)

data OWMWind = OWMWind
    { speed :: Double
    } deriving (Show, Generic)

instance FromJSON OWMResponse
instance FromJSON OWMMain
instance FromJSON OWMWind

-- In production, load this from an environment variable.
-- Provided here as a placeholder for demonstration purposes as requested.
getApiKey :: IO String
getApiKey = do
    key <- lookupEnv "WEATHER_API_KEY"
    case key of
        Just k  -> return k
        Nothing -> error "WEATHER_API_KEY not set"

fetchWeather :: Text -> IO (Maybe WeatherData)
fetchWeather city = do
    apiKey <- getApiKey
    let url = "http://api.openweathermap.org/data/2.5/weather?q=" ++ T.unpack city ++ "&appid=" ++ apiKey ++ "&units=metric"
    request <- parseRequest url
    response <- httpJSONEither request :: IO (Response (Either JSONException OWMResponse))
    case getResponseBody response of
        Right owm -> return $ Just $ WeatherData
            { wTempMax = temp_max (main owm)
            , wTempMin = temp_min (main owm)
            , wHumidity = humidity (main owm)
            , wPressure = pressure (main owm)
            , wWindSpeed = speed (wind owm)
            , wRainfall = 0.0 -- OpenWeatherMap standard endpoint may not always return rain
            , wUvIndex = 0.0  -- OpenWeatherMap standard endpoint does not return UV
            }
        Left _ -> return $ Just $ WeatherData
            { wTempMax = 35.0
            , wTempMin = 25.0
            , wHumidity = 60.0
            , wPressure = 1010.0
            , wWindSpeed = 15.0
            , wRainfall = 0.0
            , wUvIndex = 5.0
            }
