{-# LANGUAGE OverloadedStrings #-}

module Main where

import Web.Scotty
import Network.Wai.Middleware.Cors
import Network.HTTP.Types.Status (status400)
import Data.Aeson (Value, encode, decode)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString.Lazy as BL
import System.Directory (doesFileExist)
import Types
import Database
import DataLoader
import ML
import WeatherAPI (fetchWeather)
import WeatherHistoryAPI
import Data.IORef
import qualified Data.Text as T

main :: IO ()
main = do
    putStrLn "Initializing Database..."
    initDB

    putStrLn "Loading dataset for training..."
    dataset <- loadData "data.csv"
    let featuresAndLabels = extractFeatures dataset
    let (trainData, testData) = splitData 0.8 featuresAndLabels
    
    let allFeatures = map fst trainData
    let (mins, ranges) = computeMinMax allFeatures
    let scaledTrainData = zipWith (\(f, l) sf -> (sf, l)) trainData (scaleFeatures allFeatures)
    
    let weightsFile = "model_weights.json"
    fileExists <- doesFileExist weightsFile
    
    (trainedWeights, activeMins, activeRanges) <- if fileExists
        then do
            putStrLn "Loading existing weights from model_weights.json..."
            res <- decode <$> BL.readFile weightsFile
            case res of
                Just (w, m, r) -> return (w, m, r)
                Nothing -> do
                    putStrLn "Could not decode model_weights.json, retraining..."
                    let initialWeights = replicate 13 0.0
                    let learningRate = 0.001
                    let epochs = 5000
                    let weights = train epochs learningRate scaledTrainData initialWeights
                    BL.writeFile weightsFile (encode (weights, mins, ranges))
                    return (weights, mins, ranges)
        else do
            putStrLn "Training Logistic Regression model..."
            -- Initialize with 13 zeros: [bias, 7 original features, 5 historical features]
            let initialWeights = replicate 13 0.0
            let learningRate = 0.001
            let epochs = 5000
            let weights = train epochs learningRate scaledTrainData initialWeights
            BL.writeFile weightsFile (encode (weights, mins, ranges))
            putStrLn "Model trained and weights saved."
            return (weights, mins, ranges)

    let testFeatures = map fst testData
    let scaledTestFeatures = map (\f -> scaleSingleFeature f activeMins activeRanges) testFeatures
    let scaledTestData = zipWith (\(_, l) sf -> (sf, l)) testData scaledTestFeatures
    
    let (acc, prec, rec) = evaluateModel trainedWeights scaledTestData
    putStrLn "\nModel Evaluation Results"
    putStrLn $ "Accuracy:  " ++ show (acc * 100) ++ "%"
    putStrLn $ "Precision: " ++ show (prec * 100) ++ "%"
    putStrLn $ "Recall:    " ++ show (rec * 100) ++ "%"
    putStrLn ""
    
    -- Store both weights and scaling parameters
    stateRef <- newIORef (trainedWeights, activeMins, activeRanges)

    putStrLn "Starting Scotty server on port 3000..."
    scotty 3000 $ do
        middleware $ cors $ const $ Just simpleCorsResourcePolicy
            { corsRequestHeaders = "Content-Type" : "Authorization" : simpleHeaders
            , corsMethods = "GET" : "POST" : "OPTIONS" : simpleMethods
            }

        get "/health" $ do
            json ("OK" :: String)

        post "/predict" $ do
            req <- jsonData :: ActionM PredictRequest
            weatherOpt <- liftIO $ fetchWeather (reqCity req)
            case weatherOpt of
                Nothing -> do
                    status status400
                    json ("Error fetching weather API data for city: " ++ show (reqCity req) :: String)
                Just weather -> do
                    (weights, mns, rngs) <- liftIO $ readIORef stateRef
                    
                    -- Fetch historical data
                    historyOpt <- liftIO $ fetchHistory (reqCity req)
                    
                    let (hToday, hYest, h2Ago, hAvg, hRain) = case historyOpt of
                            Just h -> (hMaxTempToday h, hMaxTempYesterday h, hMaxTemp2DaysAgo h, hAvgTempLast3Days h, hRainfallLast3Days h)
                            Nothing -> 
                                -- Fallback to current weather values as proxies if history fetch fails
                                (wTempMax weather, wTempMax weather, wTempMax weather, wTempMax weather, wRainfall weather * 3.0)
                    
                    let reqFeatures = [ 1.0, wTempMax weather, wTempMin weather, wHumidity weather
                                      , wWindSpeed weather, wPressure weather, wRainfall weather, wUvIndex weather
                                      , hToday, hYest, h2Ago, hAvg, hRain
                                      ]
                    
                    liftIO $ do
                        putStrLn $ "Processing prediction for: " ++ T.unpack (reqCity req)
                        putStrLn $ "Final feature vector: " ++ show reqFeatures
                    
                    let scaledReq = scaleSingleFeature reqFeatures mns rngs
                    
                    let prob = predictProb weights scaledReq
                    let pClass = predictClass weights scaledReq 0.5
                    
                    let resp = PredictResponse prob pClass weather (reqCity req)
                    
                    liftIO $ savePrediction req weather resp
                    json resp

        get "/history" $ do
            history <- liftIO getHistory
            json history
