module ML where

import Types

-- Sigmoid function
sigmoid :: Double -> Double
sigmoid z = 1.0 / (1.0 + exp (-z))

-- Dot product
dotProduct :: [Double] -> [Double] -> Double
dotProduct w x = sum $ zipWith (*) w x

-- Predict probability
predictProb :: [Double] -> [Double] -> Double
predictProb weights features = sigmoid (dotProduct weights features)

-- Predict class (0 or 1)
predictClass :: [Double] -> [Double] -> Double -> Int
predictClass weights features threshold = 
    if predictProb weights features >= threshold then 1 else 0

-- Feature Scaling (Min-Max Normalization)
scaleFeatures :: [[Double]] -> [[Double]]
scaleFeatures [] = []
scaleFeatures rows = 
    let cols = length (head rows)
        mins = [ minimum [ row !! i | row <- rows ] | i <- [0..cols-1] ]
        maxs = [ maximum [ row !! i | row <- rows ] | i <- [0..cols-1] ]
        ranges = zipWith (\mx mn -> if mx == mn then 1.0 else mx - mn) maxs mins
    in [ zipWith3 (\v mn rng -> (v - mn) / rng) row mins ranges | row <- rows ]

-- Scale a single new feature vector using previously computed mins/ranges
scaleSingleFeature :: [Double] -> [Double] -> [Double] -> [Double]
scaleSingleFeature feature mins ranges = 
    zipWith3 (\v mn rng -> (v - mn) / rng) feature mins ranges

-- Compute Min/Max arrays natively from list
computeMinMax :: [[Double]] -> ([Double], [Double])
computeMinMax [] = ([], [])
computeMinMax rows = 
    let cols = length (head rows)
        mins = [ minimum [ row !! i | row <- rows ] | i <- [0..cols-1] ]
        maxs = [ maximum [ row !! i | row <- rows ] | i <- [0..cols-1] ]
        ranges = zipWith (\mx mn -> if mx == mn then 1.0 else mx - mn) maxs mins
    in (mins, ranges)

-- Gradient descent step for logistic regression
updateWeights :: [Double] -> Double -> [([Double], Double)] -> [Double]
updateWeights weights alpha dataset = 
    let m = fromIntegral (length dataset) :: Double
        gradients = foldl (\acc (x, y) -> 
            let h = predictProb weights x
                error_val = h - y
                grad = map (* error_val) x
            in zipWith (+) acc grad
            ) (replicate (length weights) 0.0) dataset
    in zipWith (\w g -> w - alpha * (g / m)) weights gradients

-- Train model
train :: Int -> Double -> [([Double], Double)] -> [Double] -> [Double]
train 0 _ _ weights = weights
train epochs alpha dataset weights = 
    let newWeights = updateWeights weights alpha dataset
    in train (epochs - 1) alpha dataset newWeights

-- Split dataset
splitData :: Double -> [a] -> ([a], [a])
splitData ratio dataset = 
    let cutoff = round (ratio * fromIntegral (length dataset))
    in splitAt cutoff dataset

-- Evaluate Model (Accuracy, Precision, Recall)
evaluateModel :: [Double] -> [([Double], Double)] -> (Double, Double, Double)
evaluateModel weights testData = 
    let predictions = map (\(features, actual) -> (predictClass weights features 0.5, round actual)) testData
        tp = fromIntegral $ length $ filter (\(p, a) -> p == 1 && a == 1) predictions
        tn = fromIntegral $ length $ filter (\(p, a) -> p == 0 && a == 0) predictions
        fp = fromIntegral $ length $ filter (\(p, a) -> p == 1 && a == 0) predictions
        fn = fromIntegral $ length $ filter (\(p, a) -> p == 0 && a == 1) predictions
        
        accuracy = if total == 0 then 0 else (tp + tn) / total
          where total = tp + tn + fp + fn
        precision = if tp + fp == 0 then 0 else tp / (tp + fp)
        recall = if tp + fn == 0 then 0 else tp / (tp + fn)
    in (accuracy, precision, recall)
