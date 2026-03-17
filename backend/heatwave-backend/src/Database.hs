{-# LANGUAGE OverloadedStrings #-}

module Database where

import Database.SQLite.Simple
import Types
import Database.SQLite.Simple.ToField (toField)
import Data.Text (Text)

dbName :: String
dbName = "heatwave.db"

initDB :: IO ()
initDB = do
    conn <- open dbName
    execute_ conn "CREATE TABLE IF NOT EXISTS history_v2 (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, region TEXT, max_temp REAL, min_temp REAL, humidity REAL, wind_speed REAL, pressure REAL, rainfall REAL, uv_index REAL, probability REAL, prediction INTEGER)"
    close conn

savePrediction :: PredictRequest -> WeatherData -> PredictResponse -> IO ()
savePrediction req weather res = do
    conn <- open dbName
    let dStr = case reqDate req of
                    Just d -> d
                    Nothing -> "2023-05-01" -- Default fallback
    execute conn "INSERT INTO history_v2 (date, region, max_temp, min_temp, humidity, wind_speed, pressure, rainfall, uv_index, probability, prediction) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        [ toField dStr, toField (reqCity req), toField (wTempMax weather)
        , toField (wTempMin weather), toField (wHumidity weather), toField (wWindSpeed weather)
        , toField (wPressure weather), toField (wRainfall weather), toField (wUvIndex weather)
        , toField (probability res), toField (prediction res) ]
    close conn

getHistory :: IO [HistoryRecord]
getHistory = do
    conn <- open dbName
    rows <- query_ conn "SELECT id, date, region, max_temp, min_temp, humidity, wind_speed, pressure, rainfall, uv_index, probability, prediction FROM history_v2 ORDER BY id DESC LIMIT 50" :: IO [HistoryRecord]
    close conn
    return rows
