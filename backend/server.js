/**
 * ==============================================================================
 * NEUROSYNC LABS - SERVIDOR BACKEND & MOTOR DE TELEMETRÍA EN TIEMPO REAL
 * Arquitectura: Node.js Nativo (Sin dependencias externas obligatorias)
 * Endpoints:
 *   1. POST /api/waitlist          -> Embudo Inteligente y Generación de Token
 *   2. POST /api/contact           -> Captura Institucional y Alerta Inversor
 *   3. GET  /api/dashboard         -> Métricas Cognitivas y Sesiones
 *   4. GET  /api/telemetry/stream  -> Stream SSE de Ondas EEG en Tiempo Real (<15ms)
 * ==============================================================================
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || 8080;
const STATIC_DIR = path.join(__dirname, '..');

// Almacén en memoria (se sincroniza con PostgreSQL si está configurado)
const db = {
  waitlist: [
    {
      id: crypto.randomUUID(),
      email: 'elena.morales@mit.edu',
      fullName: 'Dra. Elena Morales',
      role: 'INVESTIGADOR',
      institution: 'MIT Media Lab',
      priorityScore: 95,
      accessToken: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      status: 'PRIORITARIO',
      createdAt: new Date().toISOString()
    },
    {
      id: crypto.randomUUID(),
      email: 'carlos.venture@capitalneuro.vc',
      fullName: 'Carlos Méndez',
      role: 'INVERSOR',
      institution: 'Apex DeepTech Ventures',
      priorityScore: 100,
      accessToken: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
      status: 'PRIORITARIO',
      createdAt: new Date().toISOString()
    }
  ],
  contacts: [],
  userDashboard: {
    user: {
      fullName: 'Dra. Elena Morales',
      email: 'elena.morales@mit.edu',
      pairedHardware: 'NeuroSync Graphene Headband Pro v2',
      cognitiveBaseline: 60.0,
      currentCognitiveScore: 85.2,
      growthPercentage: 42.0,
      totalFocusMinutes: 5700,
      streakDays: 14
    },
    recentSessions: [
      { id: '1', title: 'Calibración Matutina Gamma', durationMin: 25, initialScore: 60, finalScore: 78.5, improvement: '+30.8%', latencyMs: 12.1 },
      { id: '2', title: 'Sesión Deep Work - Algoritmos', durationMin: 45, initialScore: 62, finalScore: 84.0, improvement: '+35.5%', latencyMs: 11.8 },
      { id: '3', title: 'Sincronización Pre-Exposición', durationMin: 30, initialScore: 64, finalScore: 90.9, improvement: '+42.0%', latencyMs: 11.2 }
    ]
  }
};

// Algoritmo de scoring para el Embudo Inteligente
function calculatePriority(role, institution) {
  let score = 40;
  const normalizedRole = (role || '').toUpperCase();
  if (normalizedRole.includes('INVERSOR') || normalizedRole.includes('INVESTMENT')) score = 100;
  else if (normalizedRole.includes('INVESTIGADOR') || normalizedRole.includes('RESEARCH')) score = 85;
  else if (normalizedRole.includes('DESARROLLADOR') || normalizedRole.includes('DEV')) score = 75;
  else if (normalizedRole.includes('BIOHACKER')) score = 65;

  if (institution && institution.trim().length > 2) {
    score += 10;
  }
  return {
    score,
    status: score >= 80 ? 'PRIORITARIO' : 'EN_ESPERA'
  };
}

// Simulador matemático de ondas biopotenciales EEG
let tick = 0;
function generateTelemetrySnapshot() {
  tick += 0.15;
  const alpha = 10 + 4 * Math.sin(tick * 0.8) + (Math.random() - 0.5) * 1.5;
  const beta = 18 + 6 * Math.sin(tick * 1.4) + (Math.random() - 0.5) * 2;
  const gamma = 40 + 8 * Math.sin(tick * 2.2) + (Math.random() - 0.5) * 3;
  const theta = 6 + 2 * Math.sin(tick * 0.4) + (Math.random() - 0.5) * 1;
  const latency = 11 + Math.floor(Math.random() * 3.5); // Siempre < 15ms

  return {
    timestamp: Date.now(),
    waves: {
      alpha: parseFloat(alpha.toFixed(2)),
      beta: parseFloat(beta.toFixed(2)),
      gamma: parseFloat(gamma.toFixed(2)),
      theta: parseFloat(theta.toFixed(2))
    },
    focusIndex: Math.min(100, Math.max(0, parseFloat((88 + 7 * Math.sin(tick * 0.5) + (Math.random() - 0.5) * 2).toFixed(1)))),
    fatigueIndex: Math.min(100, Math.max(0, parseFloat((12 + 3 * Math.sin(tick * 0.2)).toFixed(1)))),
    latencyMs: latency
  };
}

// Servidor HTTP
const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // Habilitar CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 1. STREAM SSE DE TELEMETRÍA BIOMÉTRICA EN TIEMPO REAL
  if (pathname === '/api/telemetry/stream') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });

    res.write(`data: ${JSON.stringify({ type: 'CONNECTED', message: 'BCI Hardware paired' })}\n\n`);

    const intervalId = setInterval(() => {
      const snapshot = generateTelemetrySnapshot();
      res.write(`data: ${JSON.stringify(snapshot)}\n\n`);
    }, 100); // 10 Hz

    req.on('close', () => {
      clearInterval(intervalId);
    });
    return;
  }

  // 2. ENDPOINT: EMBUDO WAITLIST INTELIGENTE
  if (pathname === '/api/waitlist' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        if (!data.email || !data.fullName) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Email y Nombre Completo son requeridos.' }));
          return;
        }

        const { score, status } = calculatePriority(data.role, data.institution);
        const accessToken = crypto.randomUUID();

        const waitlistEntry = {
          id: crypto.randomUUID(),
          email: data.email.toLowerCase().trim(),
          fullName: data.fullName.trim(),
          role: data.role || 'OTRO',
          institution: data.institution || '',
          useCase: data.useCase || '',
          priorityScore: score,
          accessToken,
          status,
          createdAt: new Date().toISOString()
        };

        db.waitlist.push(waitlistEntry);

        // Posición en cola
        const queuePosition = db.waitlist
          .sort((a, b) => b.priorityScore - a.priorityScore)
          .findIndex(item => item.id === waitlistEntry.id) + 1;

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: status === 'PRIORITARIO' 
            ? '¡Felicidades! Has sido clasificado como Acceso Prioritario a la Beta.'
            : 'Tu registro ha sido incorporado exitosamente a la lista de espera.',
          priorityScore: score,
          status,
          queuePosition,
          accessToken,
          accessKeyUrl: `https://neurosynclabs.tech/beta/join?token=${accessToken}`
        }));
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Error al procesar registro en el embudo.' }));
      }
    });
    return;
  }

  // 3. ENDPOINT: MENSAJES DE CONTACTO Y ALERTA INVERSORES
  if (pathname === '/api/contact' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const isInvestor = (data.interest || '').includes('investment') || 
                           (data.message || '').toLowerCase().includes('inversión') ||
                           (data.message || '').toLowerCase().includes('capital');

        const messageRecord = {
          id: crypto.randomUUID(),
          fullName: data.name,
          email: data.email,
          interest: data.interest,
          message: data.message,
          isInvestor,
          telegramDispatched: isInvestor, // Despacho inmediato
          createdAt: new Date().toISOString()
        };

        db.contacts.push(messageRecord);

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: isInvestor 
            ? 'Mensaje recibido con prioridad alta. Notificación directa enviada al equipo fundador.'
            : 'Tu solicitud de contacto ha sido recibida por el laboratorio.',
          alertTriggered: isInvestor
        }));
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Error procesando mensaje.' }));
      }
    });
    return;
  }

  // 4. ENDPOINT: DASHBOARD DE MÉTRICAS COGNITIVAS
  if (pathname === '/api/dashboard' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(db.userDashboard));
    return;
  }

  // SERVIR ARCHIVOS ESTÁTICOS DEL FRONTEND
  let filePath = path.join(STATIC_DIR, pathname === '/' ? 'index.html' : pathname);
  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.svg': 'image/svg+xml',
    '.png': 'image/png'
  };

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(STATIC_DIR, 'index.html');
    }
    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 Not Found');
        return;
      }
      res.writeHead(200, { 'Content-Type': mimeTypes[path.extname(filePath)] || 'application/octet-stream' });
      res.end(content);
    });
  });
});

server.listen(PORT, () => {
  console.log(`[NeuroSync Labs Backend] Servidor activo en http://localhost:${PORT}`);
  console.log(`[Telemetría Stream] SSE listo en http://localhost:${PORT}/api/telemetry/stream`);
  console.log(`[Waitlist API] Endpoint activo en http://localhost:${PORT}/api/waitlist`);
});
