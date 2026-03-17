let historyChart = null;
let tempChart = null;
let humidityChart = null;
let gaugeChart = null;

const COLORS = {
    primary: '#ff4757',
    primaryLight: 'rgba(255, 71, 87, 0.2)',
    secondary: '#2f3542',
    success: '#2ed573',
    warning: '#ffa502',
    danger: '#ff4757',
    info: '#1e90ff'
};

/**
 * Destroys existing charts to prevent memory leaks.
 */
function destroyCharts() {
    if (historyChart) historyChart.destroy();
    if (tempChart) tempChart.destroy();
    if (humidityChart) humidityChart.destroy();
}

/**
 * Renders a probability gauge (Doughnut chart).
 * @param {number} probability - Probability from 0 to 1.
 */
function renderGauge(probability) {
    const ctx = document.getElementById('gaugeChart').getContext('2d');
    const probPct = probability * 100;
    
    let color = COLORS.success;
    if (probPct > 70) color = COLORS.danger;
    else if (probPct > 40) color = COLORS.warning;

    if (gaugeChart) gaugeChart.destroy();

    gaugeChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            datasets: [{
                data: [probPct, 100 - probPct],
                backgroundColor: [color, '#f1f2f6'],
                borderWidth: 0,
                circumference: 270,
                rotation: 225,
                borderRadius: 10,
                cutout: '80%'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                tooltip: { enabled: false },
                legend: { display: false }
            }
        }
    });

    // Update the text value in HTML
    document.getElementById('res-prob-pct').innerText = `${probPct.toFixed(1)}%`;
    document.getElementById('res-prob-pct').style.color = color;
}

/**
 * Renders temperature and humidity trend charts.
 * @param {Array} data - History data from API.
 */
function renderCharts(data) {
    const ctxTemp = document.getElementById('tempChart').getContext('2d');
    const ctxHumidity = document.getElementById('humidityChart').getContext('2d');

    const chartData = [...data].reverse().slice(-10); // Show last 10 records

    const labels = chartData.map(d => d.hDate.split('T')[0]);
    const maxTemps = chartData.map(d => d.hMaxTemp);
    const humidities = chartData.map(d => d.hHumidity);

    destroyCharts();

    // Temperature Trend
    tempChart = new Chart(ctxTemp, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Max Temp (°C)',
                data: maxTemps,
                borderColor: COLORS.primary,
                backgroundColor: 'rgba(255, 71, 87, 0.1)',
                borderWidth: 3,
                tension: 0.4,
                fill: true,
                pointRadius: 4,
                pointBackgroundColor: COLORS.primary
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { grid: { display: false }, beginAtZero: false },
                x: { grid: { display: false } }
            }
        }
    });

    // Humidity Trend
    humidityChart = new Chart(ctxHumidity, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Humidity (%)',
                data: humidities,
                borderColor: COLORS.info,
                backgroundColor: 'rgba(30, 144, 255, 0.1)',
                borderWidth: 3,
                tension: 0.4,
                fill: true,
                pointRadius: 4,
                pointBackgroundColor: COLORS.info
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: {
                y: { grid: { display: false }, beginAtZero: false },
                x: { grid: { display: false } }
            }
        }
    });
}
