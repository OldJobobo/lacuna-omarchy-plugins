.pragma library

function text(value) {
  return String(value === undefined || value === null ? "" : value).trim()
}

function normalizeLocation(value) {
  return text(value)
}

function buildWttrUrl(location) {
  var normalized = normalizeLocation(location)
  var path = normalized === "" ? "/" : "/" + encodeURIComponent(normalized).replace(/%20/g, "+")
  return "https://wttr.in" + path + "?format=j1"
}

function buildLocationUrl(location) {
  var normalized = normalizeLocation(location)
  if (normalized === "") return "https://ipapi.co/json/"
  return "https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&format=json&name="
    + encodeURIComponent(normalized)
}

function parseLocation(raw, override) {
  try {
    var payload = JSON.parse(String(raw || ""))
    var source = payload && payload.results && payload.results[0] ? payload.results[0] : payload
    var latitude = Number(source.latitude)
    var longitude = Number(source.longitude)
    if (isNaN(latitude) || isNaN(longitude)) return null
    var name = text(source.name || source.city) || normalizeLocation(override) || "Current location"
    var region = text(source.admin1 || source.region)
    var country = text(source.country || source.country_name)
    return { latitude: latitude, longitude: longitude, name: name, region: region, country: country }
  } catch (error) {
    return null
  }
}

function buildOpenMeteoWeatherUrl(location) {
  if (!location) return ""
  return "https://api.open-meteo.com/v1/forecast"
    + "?latitude=" + encodeURIComponent(String(location.latitude))
    + "&longitude=" + encodeURIComponent(String(location.longitude))
    + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"
    + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
    + "&forecast_days=4&timezone=auto"
}

function parseReport(raw) {
  try {
    var report = JSON.parse(String(raw || ""))
    return currentCondition(report) ? report : null
  } catch (error) {
    return null
  }
}

function currentCondition(report) {
  return report && report.current_condition && report.current_condition[0]
    ? report.current_condition[0]
    : null
}

function areaInfo(report) {
  return report && report.nearest_area && report.nearest_area[0]
    ? report.nearest_area[0]
    : null
}

function nestedValue(container, key) {
  var values = container && container[key]
  return values && values[0] && values[0].value !== undefined ? text(values[0].value) : ""
}

function reportLocation(report, override) {
  var area = areaInfo(report)
  return nestedValue(area, "areaName") || normalizeLocation(override) || "Current location"
}

function reportCountry(report) {
  return nestedValue(areaInfo(report), "country")
}

function conditionDescription(report) {
  return nestedValue(currentCondition(report), "weatherDesc") || "Current conditions"
}

function normalizedUnit(value) {
  var unit = text(value).toLowerCase()
  return unit === "metric" || unit === "imperial" ? unit : "auto"
}

function localeUsesImperial(localeName) {
  var name = text(localeName).replace(".", "_")
  return /^en[_-]US($|[_.-])/.test(name) || /^en[_-]LR($|[_.-])/.test(name) || /^my($|[_.-])/.test(name)
}

function countryUsesImperial(countryName) {
  var country = text(countryName).replace(/[._-]+/g, " ").toLowerCase()
  if (!country) return null
  if (country === "us" || country === "usa" || country === "united states" || country === "united states of america") return true
  if (country === "liberia" || country === "myanmar" || country === "burma") return true
  return false
}

function shouldUseImperial(unitOverride, localeName, countryName) {
  var unit = normalizedUnit(unitOverride)
  if (unit === "imperial") return true
  if (unit === "metric") return false
  var countryPreference = countryUsesImperial(countryName)
  return countryPreference === null ? localeUsesImperial(localeName) : countryPreference
}

function numberString(value) {
  if (value === undefined || value === null || value === "") return ""
  var number = Number(value)
  return isNaN(number) ? "" : String(Math.round(number))
}

function celsiusToFahrenheit(value) {
  var number = Number(value)
  return isNaN(number) ? "" : numberString(number * 9 / 5 + 32)
}

function kilometersToMiles(value) {
  var number = Number(value)
  return isNaN(number) ? "" : numberString(number * 0.621371)
}

function temperatureValue(current, useImperial, keyPrefix) {
  if (!current) return ""
  return numberString(current[keyPrefix + (useImperial ? "F" : "C")])
}

function temperature(value, useImperial, spacedUnit) {
  var number = numberString(value)
  if (number === "") return "—"
  return number + "°" + (spacedUnit ? " " : "") + (useImperial ? "F" : "C")
}

function iconForCode(code, night) {
  var value = parseInt(String(code || "0"), 10)
  switch (value) {
    case 113: return night ? "" : ""
    case 116: return night ? "" : ""
    case 119: case 122: return ""
    case 143: case 248: case 260: return ""
    case 176: case 263: case 353: return night ? "" : ""
    case 179: case 227: case 230: case 323: case 326: case 368: return night ? "" : ""
    case 182: case 185: case 281: case 284: case 311: case 314:
    case 317: case 320: case 350: case 362: case 365: case 374: case 377: return ""
    case 200: case 386: case 389: case 392: case 395: return ""
    case 266: case 293: case 296: case 299: case 302: case 305: case 308: case 356: case 359: return ""
    case 329: case 332: case 335: case 338: case 371: return ""
    default: return ""
  }
}

function iconForOpenMeteoCode(code) {
  var value = parseInt(String(code || "0"), 10)
  if (value === 0) return iconForCode(113, false)
  if (value === 1 || value === 2) return iconForCode(116, false)
  if (value === 3) return iconForCode(119, false)
  if (value === 45 || value === 48) return iconForCode(143, false)
  if ([51, 53, 55, 56, 57, 61].indexOf(value) >= 0) return iconForCode(266, false)
  if ([63, 65, 66, 67, 80, 81, 82].indexOf(value) >= 0) return iconForCode(308, false)
  if ([71, 73, 75, 77, 85, 86].indexOf(value) >= 0) return iconForCode(338, false)
  if ([95, 96, 99].indexOf(value) >= 0) return iconForCode(389, false)
  return iconForCode(119, false)
}

function descriptionForOpenMeteoCode(code) {
  var value = parseInt(String(code || "0"), 10)
  if (value === 0) return "Clear sky"
  if (value === 1) return "Mostly clear"
  if (value === 2) return "Partly cloudy"
  if (value === 3) return "Overcast"
  if (value === 45 || value === 48) return "Fog"
  if ([51, 53, 55, 56, 57].indexOf(value) >= 0) return "Drizzle"
  if ([61, 63, 65, 66, 67, 80, 81, 82].indexOf(value) >= 0) return "Rain"
  if ([71, 73, 75, 77, 85, 86].indexOf(value) >= 0) return "Snow"
  if ([95, 96, 99].indexOf(value) >= 0) return "Thunderstorms"
  return "Current conditions"
}

function reportFromOpenMeteo(payload, location) {
  var current = payload && payload.current ? payload.current : null
  if (!current || !location) return null
  var tempC = numberString(current.temperature_2m)
  var feelsC = numberString(current.apparent_temperature)
  var windKmph = numberString(current.wind_speed_10m)
  return {
    current_condition: [{
      temp_C: tempC,
      temp_F: celsiusToFahrenheit(tempC),
      FeelsLikeC: feelsC,
      FeelsLikeF: celsiusToFahrenheit(feelsC),
      weatherCode: "",
      openMeteoWeatherCode: current.weather_code,
      weatherDesc: [{ value: descriptionForOpenMeteoCode(current.weather_code) }],
      windspeedKmph: windKmph,
      windspeedMiles: kilometersToMiles(windKmph),
      humidity: numberString(current.relative_humidity_2m)
    }],
    nearest_area: [{
      areaName: [{ value: location.name }],
      region: [{ value: location.region }],
      country: [{ value: location.country }],
      latitude: String(location.latitude),
      longitude: String(location.longitude)
    }]
  }
}

function currentData(report, unitOverride, localeName, locationOverride) {
  var current = currentCondition(report)
  var imperial = shouldUseImperial(unitOverride, localeName, reportCountry(report))
  var tempNumber = temperatureValue(current, imperial, "temp_")
  var feelsNumber = temperatureValue(current, imperial, "FeelsLike")
  return {
    available: !!current,
    useImperial: imperial,
    location: reportLocation(report, locationOverride),
    country: reportCountry(report),
    description: conditionDescription(report),
    icon: current
      ? (current.openMeteoWeatherCode !== undefined
        ? iconForOpenMeteoCode(current.openMeteoWeatherCode)
        : iconForCode(current.weatherCode, false))
      : "󰖐",
    temperatureNumber: tempNumber,
    temperature: temperature(tempNumber, imperial, false),
    barLabel: temperature(tempNumber, imperial, true),
    feelsLike: temperature(feelsNumber, imperial, false),
    wind: current ? (imperial ? text(current.windspeedMiles) + " mph" : text(current.windspeedKmph) + " km/h") : "—",
    humidity: current && current.humidity !== undefined ? text(current.humidity) + "%" : "—"
  }
}

function openMeteoUrl(report) {
  var area = areaInfo(report)
  var latitude = area ? Number(area.latitude) : NaN
  var longitude = area ? Number(area.longitude) : NaN
  if (isNaN(latitude) || isNaN(longitude)) return ""
  return "https://api.open-meteo.com/v1/forecast"
    + "?latitude=" + encodeURIComponent(String(latitude))
    + "&longitude=" + encodeURIComponent(String(longitude))
    + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
    + "&forecast_days=4&timezone=auto"
}

function futureDate(value, today) {
  return text(value).slice(0, 10) > text(today).slice(0, 10)
}

function openMeteoForecast(report, today) {
  var daily = report && report.daily ? report.daily : null
  if (!daily || !daily.time) return []
  var result = []
  for (var index = 0; index < daily.time.length && result.length < 3; index++) {
    if (!futureDate(daily.time[index], today)) continue
    var maxC = daily.temperature_2m_max ? daily.temperature_2m_max[index] : ""
    var minC = daily.temperature_2m_min ? daily.temperature_2m_min[index] : ""
    var code = daily.weather_code ? daily.weather_code[index] : null
    result.push({
      date: text(daily.time[index]).slice(0, 10),
      maxC: numberString(maxC),
      minC: numberString(minC),
      maxF: celsiusToFahrenheit(maxC),
      minF: celsiusToFahrenheit(minC),
      icon: iconForOpenMeteoCode(code)
    })
  }
  return result
}

function wttrForecast(report, today) {
  var days = report && report.weather ? report.weather : []
  var result = []
  for (var index = 0; index < days.length && result.length < 3; index++) {
    var day = days[index]
    if (!futureDate(day.date, today)) continue
    result.push({
      date: text(day.date).slice(0, 10),
      maxC: numberString(day.maxtempC),
      minC: numberString(day.mintempC),
      maxF: numberString(day.maxtempF),
      minF: numberString(day.mintempF),
      icon: representativeWttrIcon(day)
    })
  }
  return result
}

function representativeWttrIcon(day) {
  if (!day || !day.hourly || day.hourly.length === 0) return ""
  var best = day.hourly[0]
  var distance = 9999
  for (var index = 0; index < day.hourly.length; index++) {
    var time = parseInt(String(day.hourly[index].time || "0"), 10)
    var nextDistance = Math.abs(time - 1200)
    if (nextDistance < distance) {
      distance = nextDistance
      best = day.hourly[index]
    }
  }
  return iconForCode(best.weatherCode, false)
}

function buildForecastDays(report, dailyReport, today) {
  var preferred = openMeteoForecast(dailyReport, today)
  return preferred.length ? preferred : wttrForecast(report, today)
}

function forecastTemperature(day, kind, useImperial) {
  if (!day) return "—"
  var key = kind + (useImperial ? "F" : "C")
  return temperature(day[key], useImperial, false)
}

function dayName(dateString, locale) {
  var date = new Date(text(dateString) + "T12:00:00")
  if (isNaN(date.getTime())) return "—"
  if (locale && typeof locale.toString === "function") return locale.toString(date, "ddd")
  return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()]
}

function notificationText(data) {
  if (!data || !data.available) return "Weather unavailable"
  return data.location + " · " + data.description + " · " + data.temperature
    + " · Feels " + data.feelsLike + " · Wind " + data.wind + " · Humidity " + data.humidity
}

if (typeof module !== "undefined") {
  module.exports = {
    normalizeLocation: normalizeLocation,
    buildWttrUrl: buildWttrUrl,
    buildLocationUrl: buildLocationUrl,
    parseLocation: parseLocation,
    buildOpenMeteoWeatherUrl: buildOpenMeteoWeatherUrl,
    parseReport: parseReport,
    reportLocation: reportLocation,
    reportCountry: reportCountry,
    conditionDescription: conditionDescription,
    normalizedUnit: normalizedUnit,
    localeUsesImperial: localeUsesImperial,
    countryUsesImperial: countryUsesImperial,
    shouldUseImperial: shouldUseImperial,
    celsiusToFahrenheit: celsiusToFahrenheit,
    kilometersToMiles: kilometersToMiles,
    temperature: temperature,
    iconForCode: iconForCode,
    iconForOpenMeteoCode: iconForOpenMeteoCode,
    descriptionForOpenMeteoCode: descriptionForOpenMeteoCode,
    reportFromOpenMeteo: reportFromOpenMeteo,
    currentData: currentData,
    openMeteoUrl: openMeteoUrl,
    futureDate: futureDate,
    openMeteoForecast: openMeteoForecast,
    wttrForecast: wttrForecast,
    buildForecastDays: buildForecastDays,
    forecastTemperature: forecastTemperature,
    dayName: dayName,
    notificationText: notificationText
  }
}
