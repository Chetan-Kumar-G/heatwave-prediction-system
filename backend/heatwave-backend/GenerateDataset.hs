import System.IO
import System.Random
import Control.Monad

cities :: [String]
cities =
  [ "Delhi"
  , "Mumbai"
  , "Chennai"
  , "Kolkata"
  , "Jaipur"
  , "Lucknow"
  , "Patna"
  , "Hyderabad"
  , "Bangalore"
  , "Ahmedabad"
  ]

dates :: [String]
dates = ["2023-04-" ++ pad d | d <- [1..100]]
  where
    pad n | n < 10 = "0" ++ show n
          | otherwise = show n

randomRange :: (Double, Double) -> IO Double
randomRange (a,b) = randomRIO (a,b)

main :: IO ()
main = do
  h <- openFile "data.csv" WriteMode

  hPutStrLn h "date,region,max_temp,min_temp,humidity,wind_speed,pressure,rainfall,uv_index,max_temp_today,max_temp_yesterday,max_temp_2days_ago,avg_temp_3days,rainfall_3days,heatwave"

  forM_ dates $ \date ->
    forM_ cities $ \city -> do

      maxT <- randomRange (34,45)
      minT <- randomRange (22,30)
      humidity <- randomRange (20,90)
      wind <- randomRange (5,20)
      pressure <- randomRange (1000,1015)
      rain <- randomRange (0,10)
      uv <- randomRange (5,10)

      let heatwave = if maxT >= 40 then 1 else 0

      -- Mock historical data for training
      let maxT_today = maxT
      let maxT_yest = maxT - 2.0
      let maxT_2ago = maxT - 4.0
      let avgT_3days = (maxT_today + maxT_yest + maxT_2ago) / 3.0
      let rain_3days = rain * 0.5

      hPutStrLn h $
        date ++ "," ++ city ++ "," ++
        show maxT ++ "," ++
        show minT ++ "," ++
        show humidity ++ "," ++
        show wind ++ "," ++
        show pressure ++ "," ++
        show rain ++ "," ++
        show uv ++ "," ++
        show maxT_today ++ "," ++
        show maxT_yest ++ "," ++
        show maxT_2ago ++ "," ++
        show avgT_3days ++ "," ++
        show rain_3days ++ "," ++
        show heatwave

  hClose h

  putStrLn "Dataset generated successfully."