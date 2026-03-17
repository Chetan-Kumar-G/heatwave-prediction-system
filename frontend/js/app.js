const API_BASE = 'https://heatwave-prediction-system.onrender.com';

/**
 * Initializes the dashboard on load.
 */
document.addEventListener('DOMContentLoaded', () => {
    checkSystemStatus();
    loadHistory(); // Load data for dashboard stats
});

/**
 * Checks if the backend API is reachable.
 */
async function checkSystemStatus() {
    const statusDot = document.querySelector('.status-dot');
    const statusText = document.querySelector('.system-status span');

    try {
        const res = await fetch(`${API_BASE}/health`, { timeout: 3000 });
        if (res.ok) {
            statusDot.style.backgroundColor = 'var(--success)';
            statusText.innerText = 'System Online';
        } else {
            throw new Error();
        }
    } catch (e) {
        statusDot.style.backgroundColor = 'var(--danger)';
        statusText.innerText = 'System Offline';
    }
}

/**
 * Switches between navigation tabs.
 */
function switchTab(tabId, element) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

    const targetTab = document.getElementById(tabId);
    if (targetTab) targetTab.classList.add('active');

    if (element) element.classList.add('active');

    // Update Header Title
    constTitles = {
        'dashboard': 'Dashboard Overview',
        'predict': 'Heatwave Prediction',
        'history': 'Analytics & History',
        'map-view': 'Regional Risk Map'
    };
    document.getElementById('page-title').innerText = constTitles[tabId] || 'Heatwave ML';

    // Trigger specific logic per tab
    if (tabId === 'history' || tabId === 'dashboard') loadHistory();
    if (tabId === 'map-view') loadMapView(API_BASE);
}

/**
 * Handles Prediction Form Submission.
 */
document.getElementById('predict-form').addEventListener('submit', async (e) => {
    e.preventDefault();

    const city = document.getElementById('reqCity').value.trim();
    const date = document.getElementById('reqDate').value;
    const loadingOverlay = document.getElementById('loading-overlay');
    const submitBtn = e.target.querySelector('button[type="submit"]');

    if (!city) {
        showAlert("Please enter a city name.", "error");
        return;
    }

    // Show Loading
    loadingOverlay.classList.remove('hidden');
    submitBtn.disabled = true;

    try {
        const response = await fetch(`${API_BASE}/predict`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ reqCity: city, reqDate: date || null })
        });

        if (!response.ok) {
            if (response.status === 404) throw new Error("City not found or weather data unavailable.");
            throw new Error("Prediction request failed.");
        }

        const result = await response.json();
        showResults(result);
        showAlert("Prediction generated successfully!", "success");

    } catch (err) {
        console.error(err);
        showAlert(err.message || "Could not connect to the prediction server.", "error");
    } finally {
        loadingOverlay.classList.add('hidden');
        submitBtn.disabled = false;
    }
});

/**
 * Displays Prediction Results in the UI.
 */
function showResults(data) {
    const container = document.getElementById('result-container');
    container.classList.remove('hidden');

    const prob = data.probability;
    const isHeatwave = data.prediction === 1;

    // Risk Level Logic
    let risk = "Low Risk";
    let riskClass = "risk-low";
    if (prob > 0.7) { risk = "High Risk"; riskClass = "risk-high"; }
    else if (prob > 0.4) { risk = "Moderate Risk"; riskClass = "risk-medium"; }

    // Update Elements
    document.getElementById('res-city-name').innerText = data.responseCity;
    const badge = document.getElementById('res-risk-badge');
    badge.innerText = risk;
    badge.className = `risk-badge ${riskClass}`;

    if (data.usedWeather) {
        document.getElementById('res-temp').innerText = `${data.usedWeather.wTempMax.toFixed(1)}°C`;
        document.getElementById('res-hum').innerText = `${data.usedWeather.wHumidity.toFixed(1)}%`;
        document.getElementById('res-wind').innerText = `${data.usedWeather.wWindSpeed.toFixed(1)} km/h`;
    }

    document.getElementById('res-status-text').innerText = isHeatwave ? "Heatwave Warning" : "Clear Conditions";
    document.getElementById('res-description').innerText = isHeatwave
        ? "Warning: Atmospheric patterns indicate a high likelihood of heatwave conditions. Stay hydrated and avoid outdoor activities."
        : "Stable: Current weather patterns are within normal ranges. No immediate heatwave threat detected.";

    // Render Gauge
    renderGauge(prob);
}

/**
 * Fetches and populates history data.
 */
async function loadHistory() {
    try {
        const response = await fetch(`${API_BASE}/history`);
        if (!response.ok) throw new Error("Could not load history.");
        const data = await response.json();

        // Update Dashboard Stats
        const totalEl = document.getElementById('stat-total');
        const lastEl = document.getElementById('stat-last');
        if (totalEl && data.length > 0) {
            totalEl.innerText = data.length;
            const last = data[0];
            lastEl.innerText = `${last.hRegion} (${last.hDate.split('T')[0]})`;
        }

        // Update Table
        renderTable(data);

        // Update Charts (only if visible)
        if (document.getElementById('history').classList.contains('active')) {
            renderCharts(data);
        }
    } catch (err) {
        console.error(err);
    }
}

function renderTable(data) {
    const tbody = document.querySelector('#history-table tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    data.slice(0, 10).forEach(row => {
        const tr = document.createElement('tr');
        const probPct = (row.hProbability * 100).toFixed(1);
        const isHeatwave = row.hPrediction === 1;

        tr.innerHTML = `
            <td>${row.hDate.split('T')[0]}</td>
            <td>${row.hRegion}</td>
            <td>${row.hMaxTemp.toFixed(1)}°C</td>
            <td>${row.hHumidity.toFixed(1)}%</td>
            <td>${probPct}%</td>
            <td><span class="risk-badge ${isHeatwave ? 'risk-high' : 'risk-low'}">${isHeatwave ? 'YES' : 'NO'}</span></td>
        `;
        tbody.appendChild(tr);
    });
}

/**
 * Custom Alert System.
 */
function showAlert(message, type = 'error') {
    const container = document.getElementById('alert-container');
    const alert = document.createElement('div');
    alert.className = `alert ${type}`;

    const icon = type === 'error' ? 'fa-exclamation-circle' : 'fa-check-circle';
    const color = type === 'error' ? 'var(--danger)' : 'var(--success)';

    alert.style.borderLeftColor = color;
    alert.innerHTML = `<i class="fas ${icon}" style="color: ${color}"></i><span>${message}</span>`;

    container.appendChild(alert);

    setTimeout(() => {
        alert.style.opacity = '0';
        alert.style.transform = 'translateX(20px)';
        setTimeout(() => alert.remove(), 300);
    }, 4000);
}
