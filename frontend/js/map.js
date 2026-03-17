let heatMap = null;
let geojsonLayer = null;
const INDIA_GEOJSON_URL = "https://raw.githubusercontent.com/geohacker/india/master/state/india_telengana.geojson";

/**
 * Loads and renders the interactive India heatwave map.
 * @param {string} apiBase - The base URL for API calls.
 */
async function loadMapView(apiBase) {
    try {
        const response = await fetch(`${apiBase}/history`);
        if (!response.ok) throw new Error("Could not fetch history for map.");
        
        const historyData = await response.json();

        // Latest tracked probabilities per region
        const stateProbs = {};
        historyData.forEach(row => {
            const state = row.hRegion.toLowerCase();
            if (stateProbs[state] === undefined) {
                stateProbs[state] = row.hProbability;
            }
        });

        if (!heatMap) {
            heatMap = L.map('india-map', {
                zoomControl: false // Move zoom control later
            }).setView([22.5937, 78.9629], 5);
            
            // Clean CartoDB Positron theme
            L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
                attribution: '&copy; CARTO'
            }).addTo(heatMap);

            L.control.zoom({ position: 'bottomright' }).addTo(heatMap);
        }

        // Force resize for hidden tabs
        setTimeout(() => { heatMap.invalidateSize(); }, 300);

        if (geojsonLayer) {
            heatMap.removeLayer(geojsonLayer);
        }

        const geoJsonResponse = await fetch(INDIA_GEOJSON_URL);
        if (!geoJsonResponse.ok) throw new Error("Could not load India GeoJSON.");
        const geoJsonData = await geoJsonResponse.json();

        geojsonLayer = L.geoJSON(geoJsonData, {
            style: function (feature) {
                const stateName = String(feature.properties.NAME_1 || feature.properties.name || feature.properties.st_nm || "Unknown").toLowerCase();
                let prob = 0;

                for (const [key, val] of Object.entries(stateProbs)) {
                    if (stateName.includes(key) || key.includes(stateName)) {
                        prob = val;
                        break;
                    }
                }

                return {
                    fillColor: getHeatColor(prob),
                    weight: 1.5,
                    opacity: 1,
                    color: 'white',
                    fillOpacity: 0.6
                };
            },
            onEachFeature: function (feature, layer) {
                const stateName = feature.properties.NAME_1 || feature.properties.name || feature.properties.st_nm || "Unknown";
                let prob = 0;
                let matched = false;

                for (const [key, val] of Object.entries(stateProbs)) {
                    if (stateName.toLowerCase().includes(key) || key.includes(stateName.toLowerCase())) {
                        prob = val;
                        matched = true;
                        break;
                    }
                }

                const probPct = (prob * 100).toFixed(1);
                const status = prob > 0.7 ? "CRITICAL" : prob > 0.4 ? "WARNING" : "SAFE";
                const color = prob > 0.7 ? "#ff4757" : prob > 0.4 ? "#ffa502" : "#2ed573";

                const popupContent = `
                    <div style="padding: 10px; font-family: 'Inter', sans-serif;">
                        <h4 style="margin-bottom: 5px; color: #2f3542;">${stateName}</h4>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <div style="width: 10px; height: 10px; border-radius: 50%; background: ${color};"></div>
                            <span style="font-weight: 700; color: ${color};">${status}</span>
                        </div>
                        <p style="margin-top: 5px; font-size: 0.9rem; color: #747d8c;">
                            ${matched ? `Latest Probability: <b>${probPct}%</b>` : "No historical records"}
                        </p>
                    </div>
                `;
                layer.bindPopup(popupContent);
                
                layer.on({
                    mouseover: (e) => {
                        const l = e.target;
                        l.setStyle({ fillOpacity: 0.8, weight: 2 });
                    },
                    mouseout: (e) => {
                        const l = e.target;
                        l.setStyle({ fillOpacity: 0.6, weight: 1.5 });
                    }
                });
            }
        }).addTo(heatMap);

    } catch (err) {
        console.error("Error loading interactive map:", err);
    }
}

/**
 * Modern color palette for heat shades.
 */
function getHeatColor(p) {
    if (p > 0.8) return '#b91c1c'; // Red-700
    if (p > 0.6) return '#dc2626'; // Red-600
    if (p > 0.4) return '#ea580c'; // Orange-600
    if (p > 0.2) return '#f97316'; // Orange-500
    if (p > 0.1) return '#fbbf24'; // Amber-400
    return '#fcd34d'; // Amber-300
}
