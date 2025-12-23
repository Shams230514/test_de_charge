// k6-gogainde-modular.js
// Test de charge GO GAINDÉ - Script modulaire par palier
// Usage : k6 run -e VUS=100 k6-gogainde-modular.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { randomIntBetween, randomItem } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// ============================================
// CONFIGURATION DYNAMIQUE
// ============================================
const TARGET_VUS = parseInt(__ENV.VUS) || 100;
const BASE_URL = __ENV.BASE_URL || 'https://server.gogainde.k8s.heritage.africa';
const INFRA_NAME = __ENV.INFRA || 'LinuxOne-s390x';
const TEST_DURATION = __ENV.DURATION || '5m';

// ============================================
// MÉTRIQUES
// ============================================
const loginLatency = new Trend('login_duration', true);
const postsLatency = new Trend('posts_duration', true);
const matchsLatency = new Trend('matchs_duration', true);
const playersLatency = new Trend('players_duration', true);
const classementLatency = new Trend('classement_duration', true);
const produitsLatency = new Trend('produits_duration', true);
const quizLatency = new Trend('quiz_duration', true);

const errorRate = new Rate('error_rate');
const successRate = new Rate('success_rate');
const loginSuccessRate = new Rate('login_success_rate');
const totalRequests = new Counter('total_requests');

// ============================================
// OPTIONS - STAGES CALCULÉS DYNAMIQUEMENT
// ============================================
function buildStages() {
  if (TARGET_VUS <= 100) {
    return [
      { duration: '30s', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '1m', target: TARGET_VUS },
      { duration: TEST_DURATION, target: TARGET_VUS },
      { duration: '30s', target: Math.floor(TARGET_VUS * 0.5) },
      { duration: '30s', target: 0 },
    ];
  } else if (TARGET_VUS <= 500) {
    return [
      { duration: '1m', target: Math.floor(TARGET_VUS * 0.2) },
      { duration: '1m', target: Math.floor(TARGET_VUS * 0.5) },
      { duration: '1m', target: TARGET_VUS },
      { duration: TEST_DURATION, target: TARGET_VUS },
      { duration: '1m', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '30s', target: 0 },
    ];
  } else if (TARGET_VUS <= 2000) {
    return [
      { duration: '1m', target: Math.floor(TARGET_VUS * 0.1) },
      { duration: '2m', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '2m', target: Math.floor(TARGET_VUS * 0.6) },
      { duration: '2m', target: TARGET_VUS },
      { duration: TEST_DURATION, target: TARGET_VUS },
      { duration: '2m', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '1m', target: 0 },
    ];
  } else {
    return [
      { duration: '2m', target: Math.floor(TARGET_VUS * 0.1) },
      { duration: '3m', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '3m', target: Math.floor(TARGET_VUS * 0.5) },
      { duration: '3m', target: Math.floor(TARGET_VUS * 0.75) },
      { duration: '3m', target: TARGET_VUS },
      { duration: TEST_DURATION, target: TARGET_VUS },
      { duration: '3m', target: Math.floor(TARGET_VUS * 0.3) },
      { duration: '2m', target: 0 },
    ];
  }
}

function buildThresholds() {
  const factor = Math.min(TARGET_VUS / 1000, 3);
  return {
    http_req_duration: [
      `p(50)<${Math.floor(800 + factor * 200)}`,
      `p(90)<${Math.floor(2000 + factor * 500)}`,
      `p(95)<${Math.floor(3000 + factor * 1000)}`,
    ],
    http_req_failed: [`rate<${(0.05 + factor * 0.03).toFixed(2)}`],
    error_rate: [`rate<${(0.08 + factor * 0.04).toFixed(2)}`],
    login_success_rate: ['rate>0.85'],
  };
}

export const options = {
  insecureSkipTLSVerify: true,
  scenarios: {
    load_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: buildStages(),
      gracefulRampDown: '1m',
    },
  },
  thresholds: buildThresholds(),
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)', 'count'],
};

// ============================================
// USER AGENTS RÉALISTES
// ============================================
const userAgents = [
  'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 Mobile',
  'Mozilla/5.0 (Linux; Android 12; TECNO POP 7) AppleWebKit/537.36 Chrome/119.0.0.0 Mobile',
  'GoGainde-iOS/2.1.0',
  'GoGainde-Android/2.1.0',
];

// ============================================
// HELPERS
// ============================================
function getTestUser(vuId) {
  const idx = (vuId % 10000) + 1;
  return { email: `testuser${idx}@gogainde.sn`, password: '123456' };
}

function getHeaders(token) {
  const h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': randomItem(userAgents),
  };
  if (token) h['Authorization'] = `Bearer ${token}`;
  return h;
}

// ============================================
// API CALLS
// ============================================
function doLogin(user) {
  const start = Date.now();
  const res = http.post(
    `${BASE_URL}/api/v1/web/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: getHeaders(null), timeout: '30s', tags: { name: 'login' } }
  );
  loginLatency.add(Date.now() - start);
  totalRequests.add(1);

  const ok = check(res, {
    'login: status 200': (r) => r.status === 200,
    'login: has token': (r) => {
      try {
        const b = r.json();
        return !!(b.token || b.accessToken || b.access_token);
      } catch (e) { return false; }
    },
  });

  if (ok) {
    loginSuccessRate.add(1);
    successRate.add(1);
    try {
      const b = res.json();
      return b.token || b.accessToken || b.access_token;
    } catch (e) { return null; }
  }
  
  loginSuccessRate.add(0);
  errorRate.add(1);
  return null;
}

function apiGet(name, url, token, metric) {
  const start = Date.now();
  const res = http.get(url, {
    headers: getHeaders(token),
    timeout: '20s',
    tags: { name: name },
  });
  metric.add(Date.now() - start);
  totalRequests.add(1);

  const ok = check(res, { [`${name}: status 200`]: (r) => r.status === 200 });
  ok ? successRate.add(1) : errorRate.add(1);
  return ok;
}

const getPosts = (t) => apiGet('posts', `${BASE_URL}/api/v1/posts`, t, postsLatency);
const getMatchs = (t) => apiGet('matchs', `${BASE_URL}/api/v1/mobile/matchs`, t, matchsLatency);
const getPlayers = (t) => apiGet('players', `${BASE_URL}/api/v1/players/allPlayers`, t, playersLatency);
const getClassement = (t) => apiGet('classement', `${BASE_URL}/api/v1/fanzone/classement`, t, classementLatency);
const getProduits = (t) => apiGet('produits', `${BASE_URL}/api/v1/mobile/produits`, t, produitsLatency);
const getQuiz = (t) => apiGet('quiz', `${BASE_URL}/api/v1/mobile/quiz`, t, quizLatency);

// ============================================
// SCÉNARIOS UTILISATEUR
// ============================================
function casualFan(token) {
  getMatchs(token);
  sleep(randomIntBetween(3, 6));
  if (Math.random() < 0.5) {
    getPosts(token);
    sleep(randomIntBetween(4, 8));
  }
  if (Math.random() < 0.25) {
    getPlayers(token);
    sleep(randomIntBetween(2, 4));
  }
}

function engagedFan(token) {
  getPosts(token);
  sleep(randomIntBetween(5, 10));
  getMatchs(token);
  sleep(randomIntBetween(3, 6));
  getPlayers(token);
  sleep(randomIntBetween(4, 8));
  if (Math.random() < 0.6) {
    getClassement(token);
    sleep(randomIntBetween(3, 5));
  }
  if (Math.random() < 0.4) {
    getProduits(token);
    sleep(randomIntBetween(5, 10));
  }
  if (Math.random() < 0.3) {
    getQuiz(token);
    sleep(randomIntBetween(10, 20));
  }
}

function superFan(token) {
  for (let i = 0; i < randomIntBetween(2, 4); i++) {
    getMatchs(token);
    sleep(randomIntBetween(15, 30));
    if (Math.random() < 0.6) {
      getPosts(token);
      sleep(randomIntBetween(5, 10));
    }
  }
  getPlayers(token);
  sleep(randomIntBetween(3, 5));
  getClassement(token);
}

// ============================================
// ÉTAT VU
// ============================================
let state = { user: null, token: null, attempts: 0 };

// ============================================
// SCÉNARIO PRINCIPAL
// ============================================
export default function() {
  if (!state.user) state.user = getTestUser(__VU);

  // Login avec retry
  if (!state.token) {
    if (state.attempts >= 3) {
      sleep(randomIntBetween(20, 40));
      state.attempts = 0;
      return;
    }
    state.token = doLogin(state.user);
    state.attempts++;
    if (!state.token) {
      sleep(randomIntBetween(5, 10) * state.attempts);
      return;
    }
    state.attempts = 0;
    sleep(randomIntBetween(1, 3));
  }

  // Sélection profil utilisateur
  const r = Math.random();
  if (r < 0.60) casualFan(state.token);
  else if (r < 0.85) engagedFan(state.token);
  else superFan(state.token);

  // Think time
  sleep(randomIntBetween(8, 20));

  // Probabilité de déconnexion
  if (Math.random() < 0.05) {
    state.token = null;
    sleep(randomIntBetween(5, 15));
  }
}

// ============================================
// SETUP
// ============================================
export function setup() {
  console.log(`
╔══════════════════════════════════════════════════════════════╗
║            GO GAINDÉ - TEST DE CHARGE                        ║
╠══════════════════════════════════════════════════════════════╣
║  Infrastructure : ${INFRA_NAME}
║  VUs cible      : ${TARGET_VUS}
║  Durée plateau  : ${TEST_DURATION}
║  URL            : ${BASE_URL}
╚══════════════════════════════════════════════════════════════╝
`);

  // Health check
  console.log('Health check...');
  try {
    const res = http.get(`${BASE_URL}/api/v1/mobile/matchs`, { 
      timeout: '10s',
      insecureSkipTLSVerify: true 
    });
    if (res.status === 200) {
      console.log(`API OK (${res.timings.duration.toFixed(0)}ms)\n`);
    } else {
      console.log(`API status: ${res.status}\n`);
    }
  } catch (e) {
    console.log(`API non accessible: ${e.message}\n`);
  }

  return { start: new Date().toISOString(), vus: TARGET_VUS, infra: INFRA_NAME };
}

// ============================================
// RAPPORT HTML + CONSOLE
// ============================================
export function handleSummary(data) {
  const ts = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
  const filename = `report-${INFRA_NAME}-${TARGET_VUS}vus-${ts}.html`;
  
  const reqCount = data.metrics.total_requests ? data.metrics.total_requests.values.count : 0;
  const errRate = data.metrics.error_rate ? (data.metrics.error_rate.values.rate * 100).toFixed(2) : '0.00';
  const loginRate = data.metrics.login_success_rate ? (data.metrics.login_success_rate.values.rate * 100).toFixed(2) : '0.00';
  
  console.log(`
╔══════════════════════════════════════════════════════════════╗
║                    RÉSUMÉ DU TEST                         ║
╠══════════════════════════════════════════════════════════════╣
║  VUs testés    : ${TARGET_VUS}
║  Requêtes      : ${reqCount}
║  Taux erreur   : ${errRate}%
║  Login success : ${loginRate}%
╠══════════════════════════════════════════════════════════════╣
║  Rapport HTML : ${filename}
╚══════════════════════════════════════════════════════════════╝
`);

  return {
    [filename]: htmlReport(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}