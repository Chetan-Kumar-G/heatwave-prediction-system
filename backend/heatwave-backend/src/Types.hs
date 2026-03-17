{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Types where

import Data.Aeson
import GHC.Generics
import Database.SQLite.Simple
import Database.SQLite.Simple.ToField (toField)
import Data.Text (Text)

-- Data from CSV
data HeatwaveData = HeatwaveData
    { date :: Text
    , region :: Text
    , maxTemp :: Double
    , minTemp :: Double
    , humidity :: Double
    , windSpeed :: Double
    , pressure :: Double
    , rainfall :: Double
    , uvIndex :: Double
    , maxTempToday :: Double
    , maxTempYesterday :: Double
    , maxTemp2DaysAgo :: Double
    , avgTemp3Days :: Double
    , rainfall3Days :: Double
    , heatwave :: Int 
    } deriving (Show, Generic)

instance FromJSON HeatwaveData
instance ToJSON HeatwaveData

-- Request to predict
data PredictRequest = PredictRequest
    { reqCity :: Text
    , reqDate :: Maybe Text
    } deriving (Show, Generic)

instance FromJSON PredictRequest
instance ToJSON PredictRequest

-- Isolated Weather Object mapping the API outcome to database arrays
data WeatherData = WeatherData
    { wTempMax :: Double
    , wTempMin :: Double
    , wHumidity :: Double
    , wWindSpeed :: Double
    , wPressure :: Double
    , wRainfall :: Double
    , wUvIndex :: Double
    } deriving (Show, Generic)

instance FromJSON WeatherData
instance ToJSON WeatherData

-- Response from predict
data PredictResponse = PredictResponse
    { probability :: Double
    , prediction :: Int
    , usedWeather :: WeatherData
    , responseCity :: Text
    } deriving (Show, Generic)

instance FromJSON PredictResponse
instance ToJSON PredictResponse

-- Structure for history DB
data HistoryRecord = HistoryRecord
    { hId :: Int
    , hDate :: Text
    , hRegion :: Text
    , hMaxTemp :: Double
    , hMinTemp :: Double
    , hHumidity :: Double
    , hWindSpeed :: Double
    , hPressure :: Double
    , hRainfall :: Double
    , hUvIndex :: Double
    , hProbability :: Double
    , hPrediction :: Int
    } deriving (Show, Generic)

instance FromJSON HistoryRecord
instance ToJSON HistoryRecord

instance FromRow HistoryRecord where
    fromRow = HistoryRecord <$> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field

instance ToRow HistoryRecord where
    toRow (HistoryRecord _ d r mt mint hum ws p rain uv prob predV) = 
        [toField d, toField r, toField mt, toField mint, toField hum, toField ws, toField p, toField rain, toField uv, toField prob, toField predV]
