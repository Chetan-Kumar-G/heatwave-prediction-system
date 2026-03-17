{-# LANGUAGE OverloadedStrings #-}

module DataLoader where

import qualified Data.ByteString.Lazy as BL
import Data.Csv
import qualified Data.Vector as V
import Types

instance FromNamedRecord HeatwaveData where
    parseNamedRecord r = HeatwaveData 
        <$> r .: "date" 
        <*> r .: "region" 
        <*> r .: "max_temp" 
        <*> r .: "min_temp" 
        <*> r .: "humidity" 
        <*> r .: "wind_speed"
        <*> r .: "pressure"
        <*> r .: "rainfall"
        <*> r .: "uv_index"
        <*> r .: "max_temp_today"
        <*> r .: "max_temp_yesterday"
        <*> r .: "max_temp_2days_ago"
        <*> r .: "avg_temp_3days"
        <*> r .: "rainfall_3days"
        <*> r .: "heatwave"

loadData :: FilePath -> IO [HeatwaveData]
loadData path = do
    csvData <- BL.readFile path
    case decodeByName csvData of
        Left err -> do
            putStrLn $ "Error parsing CSV: " ++ err
            return []
        Right (_, v) -> return $ V.toList v

extractFeatures :: [HeatwaveData] -> [([Double], Double)]
extractFeatures = map (\d -> ([1.0, maxTemp d, minTemp d, humidity d, windSpeed d, pressure d, rainfall d, uvIndex d, maxTempToday d, maxTempYesterday d, maxTemp2DaysAgo d, avgTemp3Days d, rainfall3Days d], fromIntegral (heatwave d)))
