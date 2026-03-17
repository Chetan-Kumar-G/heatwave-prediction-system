{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module WeatherHistoryAPI where

import Data.Aeson
import Network.HTTP.Simple
import GHC.Generics
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time
import Control.Applicative ((<|>))

-- For mapping city names to coordinates
cityCoords :: Text -> (Double, Double)
cityCoords city = case T.toLower city of
    "delhi"     -> (28.61, 77.23)
    "mumbai"    -> (19.07, 72.87)
    "chennai"   -> (13.08, 80.27)
    "kolkata"   -> (22.57, 88.36)
    "jaipur"    -> (26.91, 75.78)
    "lucknow"   -> (26.84, 80.94)
    "patna"     -> (25.59, 85.13)
    "hyderabad" -> (17.38, 78.48)
    "bangalore" -> (12.97, 77.59)
    "ahmedabad" -> (23.02, 72.57)
    _           -> (20.59, 78.96) -- Default to center of India

data OpenMeteoResponse = OpenMeteoResponse
    { daily :: DailyData
    } deriving (Show, Generic)

data DailyData = DailyData
    { time :: [String]
    , temperature_2m_max :: [Double]
    , temperature_2m_min :: [Double]
    , precipitation_sum :: [Double]
    , windspeed_10m_max :: [Double]
    } deriving (Show, Generic)

instance FromJSON OpenMeteoResponse
instance FromJSON DailyData

data HistoricalFeatures = HistoricalFeatures
    { hMaxTempToday :: Double
    , hMaxTempYesterday :: Double
    , hMaxTemp2DaysAgo :: Double
    , hAvgTempLast3Days :: Double
    , hRainfallLast3Days :: Double
    } deriving (Show)

fetchHistory :: Text -> IO (Maybe HistoricalFeatures)
fetchHistory city = do
    now <- getCurrentTime
    let zone = utc -- Simplified
    let today = utctDay now
    let startDate = addDays (-3) today
    let endDate = today
    
    let (lat, lon) = cityCoords city
    let url = "https://archive-api.open-meteo.com/v1/archive?" ++
              "latitude=" ++ show lat ++
              "&longitude=" ++ show lon ++
              "&start_date=" ++ show startDate ++
              "&end_date=" ++ show endDate ++
              "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max" ++
              "&timezone=auto"

    putStrLn $ "Fetching historical data from Open-Meteo for: " ++ T.unpack city
    request <- parseRequest url
    response <- httpJSONEither request :: IO (Response (Either JSONException OpenMeteoResponse))
    
    case getResponseBody response of
        Right om -> do
            let temps = temperature_2m_max (daily om)
            let rains = precipitation_sum (daily om)
            
            -- We expect at least 4 values (3 days ago, 2 days ago, yesterday, today)
            -- However, archive data often has a 2-day delay.
            -- We will take what's available and use the last few.
            if length temps >= 1 then do
                let revTemps = reverse temps
                let revRains = reverse rains
                
                let t_today = head revTemps
                let t_yest = if length revTemps > 1 then revTemps !! 1 else t_today
                let t_2ago = if length revTemps > 2 then revTemps !! 2 else t_yest
                
                let last3Temps = take 3 revTemps
                let avgTemp = sum last3Temps / fromIntegral (length last3Temps)
                let totalRain = sum (take 3 revRains)
                
                let features = HistoricalFeatures
                        { hMaxTempToday = t_today
                        , hMaxTempYesterday = t_yest
                        , hMaxTemp2DaysAgo = t_2ago
                        , hAvgTempLast3Days = avgTemp
                        , hRainfallLast3Days = totalRain
                        }
                
                putStrLn "Historical weather fetched and features computed:"
                print features
                return $ Just features
            else do
                putStrLn "Incomplete historical data received."
                return Nothing
        Left err -> do
            putStrLn $ "Error fetching historical data: " ++ show err
            return Nothing
