const fs = require('fs');
const file = 'data.csv';

const lines = fs.readFileSync(file, 'utf8').trim().split('\n');
const out = [];

// Fix Header
const headers = lines[0].trim().split(',');
if (!headers.includes('wind_speed')) {
    headers.splice(headers.length - 1, 0, 'wind_speed', 'pressure', 'rainfall', 'uv_index');
    out.push(headers.join(','));

    // Fix Data Rows
    for (let i = 1; i < lines.length; i++) {
        const cols = lines[i].trim().split(',');
        if (cols.length < 5) continue;
        const hw = cols.pop(); // Remove heatwave momentarily

        // Random normal values for metrics
        const wind = (10 + Math.random() * 10).toFixed(1);
        const press = (1000 + Math.random() * 15).toFixed(1);
        const rain = (Math.random() > 0.8 ? (Math.random() * 10).toFixed(1) : "0.0");
        const uv = (5 + Math.random() * 5).toFixed(1);

        cols.push(wind, press, rain, uv, hw);
        out.push(cols.join(','));
    }

    fs.writeFileSync(file, out.join('\n'));
    console.log("data.csv updated with new columns successfully.");
} else {
    console.log("data.csv already has the columns.");
}
