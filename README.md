# Pattern Recognition of Regional Heatwaves using IMD Data

This is a complete full-stack web application for predicting heatwaves based on regional temperature and humidity data using Machine Learning (Binary Logistic Regression).

## Tech Stack
- **Backend:** Haskell (Scotty Framework, SQLite, Aeson, Cassava)
- **Frontend:** Vanilla HTML, CSS, JavaScript (Chart.js for visualizations)
- **Machine Learning:** Custom-built Binary Logistic Regression with Gradient Descent

## Project Structure
```
haskell/
├── backend/
│   ├── heatwave-backend/
│   │   ├── app/
│   │   │   └── Main.hs        # Entry point for the Scotty REST API
│   │   ├── src/
│   │   │   ├── Types.hs       # Data structures and JSON instances
│   │   │   ├── Database.hs    # SQLite queries and history management
│   │   │   ├── DataLoader.hs  # Parses data.csv for initial ML training
│   │   │   └── ML.hs          # Custom Logistic Regression algorithms
│   │   ├── heatwave-backend.cabal
│   │   └── data.csv           # 100 rows of training data
└── frontend/
    ├── index.html             # UI Structure
    ├── styles.css             # UI Styling (Modern Dashboard)
    └── app.js                 # API Integration and Chart rendering
```

## Setup Instructions

### 1. Running the Backend
1. Ensure you have [GHC and Cabal](https://www.haskell.org/downloads/) installed.
2. Open a terminal and navigate to the backend directory:
   ```bash
   cd backend/heatwave-backend
   ```
3. Build the Haskell project:
   ```bash
   cabal build
   ```
4. Run the backend server:
   ```bash
   cabal run
   ```
5. The server will start on `http://localhost:3000`. You will see output indicating that the ML model is being trained and the database is initialized.

*(Note: During the first run, the SQLite database `heatwave.db` will be created automatically in the same directory.)*

### 2. Running the Frontend
1. The frontend consists of static files (HTML/CSS/JS). No special build tools are required.
2. You can simply open `frontend/index.html` in your web browser.
3. Alternatively, you can serve it via a basic HTTP server, for example:
   ```bash
   cd frontend
   python -m http.server 8080
   # Then go to http://localhost:8080
   ```

## Functionality
- **Home**: Brief overview of the project.
- **Prediction**: Users can submit temperature, humidity, date, and region. The backend computes the probability of a heatwave using the trained logistic regression model.
- **Results**: Displays the resulting probability in a clean UI with visual feedback.
- **History**: Fetches prediction history from SQLite and visualizes data points with Chart.js line charts.
