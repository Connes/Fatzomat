import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const CUISINE_PATTERNS: Record<string, string> = {
  Italienisch: 'italian|pizza',
  Griechisch: 'greek',
  Asiatisch: 'asian|chinese|thai|vietnamese|korean|japanese',
  Indisch: 'indian',
  Burger: 'burger|hamburger',
  Mexikanisch: 'mexican',
  Vegetarisch: 'vegetarian',
  Sushi: 'sushi|japanese',
  Pizza: 'pizza|italian',
  Döner: 'kebab|doner|turkish',
  Steak: 'steak|grill|beef',
};

const PHOTON_ENDPOINT = 'https://photon.komoot.io/';
const OVERPASS_ENDPOINTS = [
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://lz4.overpass-api.de/api/interpreter',
  'https://overpass.nchc.org.tw/api/interpreter',
];
const PHOTON_TIMEOUT_MS = 9000;
const OVERPASS_TIMEOUT_MS = 9000;
const NOMINATIM_ENDPOINT = 'https://nominatim.openstreetmap.org/search';
const NOMINATIM_TIMEOUT_MS = 9000;
const CACHE_TTL_MS = 60_000;
const resultCache = new Map<string, { expiresAt: number; payload: unknown }>();

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

function number(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function normalizeUrl(value: unknown): string | null {
  const raw = String(value ?? '').trim();
  if (!raw) return null;
  const candidate = /^https?:\/\//i.test(raw) ? raw : `https://${raw}`;
  try {
    const url = new URL(candidate);
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.toString() : null;
  } catch (_) {
    return null;
  }
}

function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const dLat = radians(lat2 - lat1);
  const dLon = radians(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
      Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function deliveryMetadata(properties: Record<string, any>): { available: boolean; status: 'verified' | 'unknown' | 'not_available'; orderUrl: string | null } {
  const rawDelivery = String(properties.delivery ?? '').trim().toLowerCase();
  const orderUrl = normalizeUrl(properties['delivery:website']);
  if (/^(yes|only)$/.test(rawDelivery) || Boolean(orderUrl)) {
    return { available: true, status: 'verified', orderUrl };
  }
  if (rawDelivery === 'no') {
    return { available: false, status: 'not_available', orderUrl: null };
  }
  return { available: false, status: 'unknown', orderUrl: null };
}

function deliveryRank(value: unknown): number {
  return value === 'verified' ? 0 : value === 'unknown' ? 1 : 2;
}

function cacheKey(latitude: number, longitude: number, cuisine: string, deliveryOnly: boolean): string {
  return [latitude.toFixed(4), longitude.toFixed(4), cuisine.toLowerCase(), deliveryOnly ? 'delivery' : 'all'].join('|');
}

function photonQuery(cuisine: string): string {
  const queries: Record<string, string> = {
    Pizza: 'pizza restaurant',
    Burger: 'burger restaurant',
    Asiatisch: 'asian restaurant',
    Döner: 'kebab restaurant',
    Sushi: 'sushi restaurant',
    Indisch: 'indian restaurant',
    Italienisch: 'italian restaurant',
    Griechisch: 'greek restaurant',
    Mexikanisch: 'mexican restaurant',
    Vegetarisch: 'vegetarian restaurant',
    Steak: 'steak restaurant',
  };
  return queries[cuisine] ?? 'restaurant';
}

async function authenticateUser(req: Request) {
  const authorization = req.headers.get('Authorization') ?? '';
  if (!authorization.toLowerCase().startsWith('bearer ')) return null;
  const token = authorization.slice(7).trim();
  if (!token) return null;

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
      Deno.env.get('SUPABASE_ANON_KEY') ??
      Deno.env.get('SUPABASE_PUBLISHABLE_KEY');
  if (!supabaseUrl || !supabaseKey) throw new Error('Supabase Auth ist serverseitig nicht konfiguriert.');

  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabase.auth.getUser(token);
  return error || !data.user ? null : data.user;
}

function normalizeSearchText(value: unknown): string {
  return String(value ?? '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\\u0300-\\u036f]/g, '');
}

function cuisineMatches(properties: Record<string, any>, cuisine: string): boolean {
  const pattern = CUISINE_PATTERNS[cuisine];
  if (!pattern) return true;
  const terms = pattern.split('|').map((term) => normalizeSearchText(term)).filter(Boolean);
  const searchable = [
    properties.cuisine,
    properties['cuisine:en'],
    properties['cuisine:de'],
    properties.osm_value,
    properties.name,
  ].map(normalizeSearchText).filter(Boolean).join(' ');
  return terms.some((term) => searchable.includes(term));
}

async function queryPhoton(latitude: number, longitude: number, cuisine: string): Promise<any[]> {
  const params = new URLSearchParams({
    lat: String(latitude), lon: String(longitude), radius: '20', limit: '50', lang: 'de',
    osm_tag: 'amenity:restaurant',
  });
  const response = await fetch(PHOTON_ENDPOINT + 'reverse?' + params.toString(), {
    method: 'GET',
    headers: { 'Accept': 'application/json', 'User-Agent': 'Schmackofatz/1.13 restaurant-discovery' },
    signal: AbortSignal.timeout(PHOTON_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error('Photon reverse HTTP ' + response.status);
  const payload = await response.json();
  const features = Array.isArray(payload?.features) ? payload.features : [];
  return features.filter((feature) => cuisineMatches((feature?.properties ?? {}) as Record<string, any>, cuisine));
}
function buildResultsFromPhoton(features: any[], latitude: number, longitude: number, limit: number, deliveryOnly: boolean) {
  const seen = new Set<string>();
  const results: Array<Record<string, unknown>> = [];

  for (const feature of features) {
    const properties = (feature?.properties ?? {}) as Record<string, any>;
    const coordinates = feature?.geometry?.coordinates;
    const lon = number(coordinates?.[0], NaN);
    const lat = number(coordinates?.[1], NaN);
    const name = String(properties.name ?? '').trim();
    if (!name || !Number.isFinite(lat) || !Number.isFinite(lon)) continue;

    const distance = distanceKm(latitude, longitude, lat, lon);
    if (distance > 20.0001) continue;

    const street = [properties.street, properties.housenumber].filter(Boolean).join(' ') || null;
    const city = properties.city ?? properties.town ?? properties.village ?? properties.locality ?? null;
    const key = [name.toLowerCase(), String(street ?? '').toLowerCase(), String(city ?? '').toLowerCase()].join('|');
    if (seen.has(key)) continue;
    seen.add(key);

    const delivery = deliveryMetadata(properties);
    if (deliveryOnly && delivery.status === 'not_available') continue;

    results.push({
      id: `${String(properties.osm_type ?? 'N')}/${String(properties.osm_id ?? feature?.id ?? '')}`,
      name,
      address: street,
      city,
      distance_km: Math.round(distance * 100) / 100,
      latitude: lat,
      longitude: lon,
      phone: String(properties.phone ?? properties['contact:phone'] ?? '').trim() || null,
      website: normalizeUrl(properties.website ?? properties['contact:website']),
      order_url: delivery.orderUrl ?? normalizeUrl(properties['website:orders']),
      opening_hours: properties.opening_hours ?? null,
      delivery_available: delivery.available,
      delivery_status: delivery.status,
      cuisine: properties.cuisine ?? properties.osm_value ?? null,
    });
  }

  results.sort((a, b) => deliveryRank(a.delivery_status) - deliveryRank(b.delivery_status) || Number(a.distance_km) - Number(b.distance_km));
  return results.slice(0, limit);
}

async function queryNominatim(latitude: number, longitude: number, cuisine: string): Promise<any[]> {
  const dy = 20 / 111.32;
  const dx = 20 / Math.max(111.32 * Math.cos(latitude * Math.PI / 180), 1);
  const params = new URLSearchParams({
    q: photonQuery(cuisine), format: 'jsonv2', addressdetails: '1', limit: '50', bounded: '1',
    viewbox: [longitude + dx, latitude + dy, longitude - dx, latitude - dy].join(','),
    'accept-language': 'de',
  });
  const response = await fetch(NOMINATIM_ENDPOINT + '?' + params.toString(), {
    method: 'GET',
    headers: { 'Accept': 'application/json', 'User-Agent': 'Schmackofatz/1.13 restaurant-discovery' },
    signal: AbortSignal.timeout(NOMINATIM_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error('Nominatim HTTP ' + response.status);
  const payload = await response.json();
  if (!Array.isArray(payload)) throw new Error('Ungültige Nominatim-Antwort');
  return payload;
}

function buildResultsFromNominatim(items: any[], latitude: number, longitude: number, limit: number, deliveryOnly: boolean) {
  const seen = new Set<string>();
  const results: Array<Record<string, unknown>> = [];
  for (const item of items) {
    const name = String(item?.name ?? item?.display_name?.split(',')?.[0] ?? '').trim();
    const lat = number(item?.lat, NaN); const lon = number(item?.lon, NaN);
    if (!name || !Number.isFinite(lat) || !Number.isFinite(lon)) continue;
    const distance = distanceKm(latitude, longitude, lat, lon); if (distance > 20.0001) continue;
    const a = (item?.address ?? {}) as Record<string, any>;
    const address = [a.road, a.house_number].filter(Boolean).join(' ') || null;
    const city = a.city ?? a.town ?? a.village ?? a.municipality ?? null;
    const key = [name.toLowerCase(), String(address ?? '').toLowerCase(), String(city ?? '').toLowerCase()].join('|');
    if (seen.has(key)) continue; seen.add(key);
    const deliveryStatus = 'unknown';
    if (deliveryOnly && deliveryStatus === 'not_available') continue;
    results.push({ id: String(item?.osm_type ?? 'N') + '/' + String(item?.osm_id ?? ''), name, address, city,
      distance_km: Math.round(distance * 100) / 100, latitude: lat, longitude: lon, phone: null, website: null,
      order_url: null, opening_hours: null, delivery_available: false, delivery_status: deliveryStatus, cuisine: null });
  }
  results.sort((a, b) => Number(a.distance_km) - Number(b.distance_km));
  return results.slice(0, limit);
}
function overpassQuery(latitude: number, longitude: number, cuisine: string): string {
  const pattern = CUISINE_PATTERNS[cuisine];
  const cuisineFilter = pattern ? `[cuisine~"${pattern}",i]` : '';
  const nameFilter = pattern ? `[name~"${pattern}",i]` : '';
  const selector = pattern
      ? `(nwr[amenity~"^(restaurant|fast_food)$",i][name]${cuisineFilter}(around:20000,${latitude},${longitude});nwr[amenity~"^(restaurant|fast_food)$",i][name]${nameFilter}(around:20000,${latitude},${longitude}););`
      : `nwr[amenity~"^(restaurant|fast_food)$",i][name](around:20000,${latitude},${longitude});`;
  return `[out:json][timeout:12];${selector}out center tags;`;
}

async function queryOverpass(query: string): Promise<any> {
  const attempts = OVERPASS_ENDPOINTS.map(async (endpoint) => {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Schmackofatz/1.13 restaurant-discovery',
      },
      body: `data=${encodeURIComponent(query)}`,
      signal: AbortSignal.timeout(OVERPASS_TIMEOUT_MS),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const payload = await response.json();
    if (!payload || !Array.isArray(payload.elements)) throw new Error('Ungültige Overpass-Antwort');
    return payload;
  });
  return await Promise.any(attempts);
}

function buildResultsFromOverpass(payload: any, latitude: number, longitude: number, limit: number, deliveryOnly: boolean) {
  const seen = new Set<string>();
  const results: Array<Record<string, unknown>> = [];
  for (const element of Array.isArray(payload?.elements) ? payload.elements : []) {
    const tags = (element?.tags ?? {}) as Record<string, string>;
    const name = String(tags.name ?? '').trim();
    const lat = number(element.lat ?? element.center?.lat, NaN);
    const lon = number(element.lon ?? element.center?.lon, NaN);
    if (!name || !Number.isFinite(lat) || !Number.isFinite(lon)) continue;
    const distance = distanceKm(latitude, longitude, lat, lon);
    if (distance > 20.0001) continue;
    const address = [tags['addr:street'], tags['addr:housenumber']].filter(Boolean).join(' ') || null;
    const city = tags['addr:city'] ?? tags['addr:town'] ?? tags['addr:village'] ?? null;
    const key = [name.toLowerCase(), String(address ?? '').toLowerCase(), String(city ?? '').toLowerCase()].join('|');
    if (seen.has(key)) continue;
    seen.add(key);
    const delivery = deliveryMetadata(tags);
    if (deliveryOnly && delivery.status === 'not_available') continue;
    results.push({
      id: `${element.type}/${element.id}`,
      name,
      address,
      city,
      distance_km: Math.round(distance * 100) / 100,
      latitude: lat,
      longitude: lon,
      phone: String(tags.phone ?? tags['contact:phone'] ?? '').trim() || null,
      website: normalizeUrl(tags.website ?? tags['contact:website']),
      order_url: delivery.orderUrl ?? normalizeUrl(tags['website:orders']),
      opening_hours: tags.opening_hours ?? null,
      delivery_available: delivery.available,
      delivery_status: delivery.status,
      cuisine: tags.cuisine ?? null,
    });
  }
  results.sort((a, b) => Number(a.distance_km) - Number(b.distance_km));
  return results.slice(0, limit);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Nur POST ist für die Restaurantsuche erlaubt.' }, 405);

  try {
    const user = await authenticateUser(req);
    if (!user?.id) return json({ error: 'Die persönliche Sitzung ist nicht gültig. Bitte starte Schmackofatz neu.' }, 401);

    const body = await req.json();
    const latitude = number(body?.latitude, NaN);
    const longitude = number(body?.longitude, NaN);
    const cuisine = String(body?.cuisine ?? '').trim();
    const deliveryOnly = body?.delivery_only === true;
    const radiusKm = number(body?.radius_km, 20);
    const limit = Math.min(Math.max(Math.floor(number(body?.limit, 10)), 1), 10);

    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 ||
        !Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
      return json({ error: 'Ungültiger Standort.' }, 400);
    }
    if (radiusKm !== 20) return json({ error: 'Die Suche ist fest auf 20 km begrenzt.' }, 400);
    if (cuisine && !CUISINE_PATTERNS[cuisine]) {
      return json({ error: `Die Küche „${cuisine}“ wird derzeit nicht unterstützt.` }, 400);
    }

    const key = cacheKey(latitude, longitude, cuisine, deliveryOnly);
    const cached = resultCache.get(key);
    if (cached && cached.expiresAt > Date.now()) return json(cached.payload);

    // Prefer Overpass for the actual result payload because it returns the
    // complete OSM tag set, including phone/contact and website/contact tags.
    // Photon is used only as a fallback for availability when Overpass is down
    // or temporarily exhausted. This prevents a successful Photon lookup from
    // silently stripping contact details from otherwise complete OSM entries.
    try {
      const results = buildResultsFromOverpass(
        await queryOverpass(overpassQuery(latitude, longitude, cuisine)),
        latitude,
        longitude,
        limit,
        deliveryOnly,
      );
      const payload = {
        source: 'OpenStreetMap/Overpass',
        radius_km: 20,
        results,
        delivery_filter: deliveryOnly ? 'verified_or_unknown' : 'not_requested',
      };
      resultCache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, payload });
      console.log('restaurant-discovery success: overpass results=', results.length, 'delivery=', deliveryOnly);
      return json(payload);
    } catch (overpassError) {
      console.warn('Overpass failed; trying Photon:', String(overpassError));
    }

    try {
      const results = buildResultsFromPhoton(await queryPhoton(latitude, longitude, cuisine), latitude, longitude, limit, deliveryOnly);
      if (results.length) {
        const payload = {
          source: 'OpenStreetMap/Photon',
          radius_km: 20,
          results,
          delivery_filter: deliveryOnly ? 'verified_or_unknown' : 'not_requested',
        };
        resultCache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, payload });
        console.log('restaurant-discovery success: photon fallback results=', results.length, 'delivery=', deliveryOnly);
        return json(payload);
      }
      console.warn('Photon returned no results; trying Nominatim.');
    } catch (photonError) {
      console.warn('Photon failed; trying Nominatim:', String(photonError));
    }

    try {
      const results = buildResultsFromNominatim(await queryNominatim(latitude, longitude, cuisine), latitude, longitude, limit, deliveryOnly);
      const payload = { source: 'OpenStreetMap/Nominatim', radius_km: 20, results, delivery_filter: deliveryOnly ? 'verified_or_unknown' : 'not_requested' };
      resultCache.set(key, { expiresAt: Date.now() + CACHE_TTL_MS, payload });
      console.log('restaurant-discovery success: nominatim results=', results.length, 'delivery=', deliveryOnly);
      return json(payload);
    } catch (nominatimError) {
      console.error('All restaurant discovery sources failed:', String(nominatimError));
      return json({ error: 'Die Restaurantdaten konnten gerade nicht geladen werden. Bitte versuche es erneut.' }, 503);
    }
  } catch (error) {
    console.error('restaurant-discovery request failed:', error);
    return json({ error: error instanceof Error ? error.message : 'Die Restaurantsuche ist fehlgeschlagen.' }, 500);
  }
});
