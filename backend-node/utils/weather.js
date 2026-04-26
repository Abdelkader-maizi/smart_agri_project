const axios = require('axios');

/**
 * Fetches current weather for a given latitude and longitude using Open-Meteo.
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {Promise<{temperature: number, humidity: number, rainfall: number}>}
 */
async function fetchCurrentWeather(lat, lon) {
  try {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${Number(lat)}&longitude=${Number(lon)}&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m`;
    
    // Add a reasonable timeout in case Open-meteo is slow
    const response = await axios.get(url, { timeout: 8000 });
    const current = response.data.current;
    
    return {
      temperature: current.temperature_2m,
      humidity: current.relative_humidity_2m,
      rainfall: current.precipitation,
      wind_speed: current.wind_speed_10m
    };
  } catch (error) {
    console.error("Open-Meteo API Fetch Error:", error.message);
    throw new Error("Failed to fetch weather data from external API");
  }
}

module.exports = {
  fetchCurrentWeather
};
