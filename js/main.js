/**
 * ==========================================================================
 * NEUROSYNC LABS - JAVASCRIPT PRINCIPAL
 * Funcionalidad:
 * 1. Navegación móvil y ScrollSpy para anclas
 * 2. Carrusel interactivo (Autoplay, botones, dots y soporte táctil)
 * 3. Manejador del formulario de contacto / beta tester
 * ==========================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  'use strict';

  /* --------------------------------------------------------------------------
     1. NAVEGACIÓN Y MENÚ MÓVIL
     -------------------------------------------------------------------------- */
  const header = document.getElementById('header');
  const mobileToggle = document.getElementById('mobile-toggle');
  const navMenu = document.getElementById('nav-menu');
  const navLinks = document.querySelectorAll('.nav-link');
  const sections = document.querySelectorAll('section[id]');

  // Toggle menú responsive móvil
  if (mobileToggle && navMenu) {
    mobileToggle.addEventListener('click', () => {
      const isOpen = navMenu.classList.contains('open');
      navMenu.classList.toggle('open');
      mobileToggle.classList.toggle('active');
      mobileToggle.setAttribute('aria-expanded', !isOpen);
    });

    // Cerrar menú móvil al hacer click en cualquier enlace de navegación
    navLinks.forEach(link => {
      link.addEventListener('click', () => {
        if (navMenu.classList.contains('open')) {
          navMenu.classList.remove('open');
          mobileToggle.classList.remove('active');
          mobileToggle.setAttribute('aria-expanded', 'false');
        }
      });
    });
  }

  // Estilo sticky dinámico al hacer scroll
  const handleHeaderScroll = () => {
    if (window.scrollY > 40) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  };

  // ScrollSpy: activar enlace según la sección visible
  const handleScrollSpy = () => {
    const scrollY = window.pageYOffset;

    sections.forEach(current => {
      const sectionHeight = current.offsetHeight;
      const sectionTop = current.offsetTop - 120;
      const sectionId = current.getAttribute('id');
      const activeLink = document.querySelector(`.nav-link[href*="${sectionId}"]`);

      if (scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
        if (activeLink) {
          navLinks.forEach(l => l.classList.remove('active'));
          activeLink.classList.add('active');
        }
      }
    });
  };

  window.addEventListener('scroll', () => {
    handleHeaderScroll();
    handleScrollSpy();
  });

  // Ejecución inicial
  handleHeaderScroll();

  /* --------------------------------------------------------------------------
     2. CARRUSEL DE INNOVACIÓN INTERACTIVO
     -------------------------------------------------------------------------- */
  const track = document.getElementById('carousel-track');
  const slides = Array.from(document.querySelectorAll('.carousel-slide'));
  const prevBtn = document.getElementById('carousel-prev');
  const nextBtn = document.getElementById('carousel-next');
  const dots = Array.from(document.querySelectorAll('.carousel-dot'));
  const carouselContainer = document.querySelector('.carousel-container');

  if (track && slides.length > 0) {
    let currentIndex = 0;
    const totalSlides = slides.length;
    let autoplayTimer = null;
    const autoplayDelay = 5000; // 5 segundos

    // Función central para actualizar la posición del carrusel
    const updateCarousel = (index) => {
      // Normalizar índice cíclico
      if (index < 0) {
        currentIndex = totalSlides - 1;
      } else if (index >= totalSlides) {
        currentIndex = 0;
      } else {
        currentIndex = index;
      }

      // Desplazamiento horizontal por porcentaje
      track.style.transform = `translateX(-${currentIndex * 100}%)`;

      // Actualizar estado de las diapositivas
      slides.forEach((slide, idx) => {
        slide.classList.toggle('active', idx === currentIndex);
      });

      // Actualizar estado visual y de accesibilidad de los indicadores
      dots.forEach((dot, idx) => {
        const isCurrent = idx === currentIndex;
        dot.classList.toggle('active', isCurrent);
        dot.setAttribute('aria-selected', isCurrent ? 'true' : 'false');
      });
    };

    // Navegar a la siguiente diapositiva
    const nextSlide = () => {
      updateCarousel(currentIndex + 1);
    };

    // Navegar a la anterior diapositiva
    const prevSlide = () => {
      updateCarousel(currentIndex - 1);
    };

    // Event listeners para botones
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        nextSlide();
        resetAutoplay();
      });
    }

    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        prevSlide();
        resetAutoplay();
      });
    }

    // Event listeners para indicadores (dots)
    dots.forEach((dot, idx) => {
      dot.addEventListener('click', () => {
        updateCarousel(idx);
        resetAutoplay();
      });
    });

    // Control de Autoplay
    const startAutoplay = () => {
      stopAutoplay();
      autoplayTimer = setInterval(nextSlide, autoplayDelay);
    };

    const stopAutoplay = () => {
      if (autoplayTimer) {
        clearInterval(autoplayTimer);
        autoplayTimer = null;
      }
    };

    const resetAutoplay = () => {
      stopAutoplay();
      startAutoplay();
    };

    // Pausar autoplay cuando el cursor entra al carrusel
    if (carouselContainer) {
      carouselContainer.addEventListener('mouseenter', stopAutoplay);
      carouselContainer.addEventListener('mouseleave', startAutoplay);
    }

    // Soporte táctil / gestos swipe para dispositivos móviles
    let touchStartX = 0;
    let touchEndX = 0;

    track.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX;
      stopAutoplay();
    }, { passive: true });

    track.addEventListener('touchend', (e) => {
      touchEndX = e.changedTouches[0].screenX;
      const swipeDistance = touchStartX - touchEndX;

      // Umbral mínimo de 45px para reconocer el gesto de arrastre
      if (swipeDistance > 45) {
        nextSlide();
      } else if (swipeDistance < -45) {
        prevSlide();
      }
      startAutoplay();
    }, { passive: true });

    // Iniciar autoplay inicial
    startAutoplay();
  }

  /* --------------------------------------------------------------------------
     3. FORMULARIO DE CONTACTO / REGISTRO BETA
     -------------------------------------------------------------------------- */
  const contactForm = document.getElementById('contact-form');
  const formFeedback = document.getElementById('form-feedback');

  if (contactForm && formFeedback) {
    contactForm.addEventListener('submit', (e) => {
      e.preventDefault();

      const nameInput = document.getElementById('form-name');
      const emailInput = document.getElementById('form-email');

      // Validación básica
      if (!nameInput.value.trim() || !emailInput.value.trim()) {
        formFeedback.textContent = 'Por favor, completa tu nombre y correo electrónico.';
        formFeedback.className = 'form-feedback error';
        return;
      }

      // Simulación de envío exitoso
      const submitBtn = contactForm.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;
      submitBtn.textContent = 'Procesando registro...';
      submitBtn.disabled = true;

      setTimeout(() => {
        formFeedback.textContent = `¡Excelente, ${nameInput.value.trim()}! Tu solicitud ha sido registrada para la Fase 1.`;
        formFeedback.className = 'form-feedback success';
        contactForm.reset();
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;

        // Limpiar mensaje tras 6 segundos
        setTimeout(() => {
          formFeedback.textContent = '';
          formFeedback.className = 'form-feedback';
        }, 6000);
      }, 1000);
    });
  }

  /* --------------------------------------------------------------------------
     4. NAVEGACIÓN SUAVE PARA ENLACES ANCLA INTERNOS
     -------------------------------------------------------------------------- */
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;

      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        e.preventDefault();
        const headerOffset = 75;
        const elementPosition = targetElement.getBoundingClientRect().top;
        const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

        window.scrollTo({
          top: offsetPosition,
          behavior: 'smooth'
        });
      }
    });
  });

  /* --------------------------------------------------------------------------
     5. REGISTRO DEL SERVICE WORKER (PWA)
     -------------------------------------------------------------------------- */
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js')
        .then((registration) => {
          console.log('[PWA] Service Worker registrado exitosamente con scope:', registration.scope);
        })
        .catch((error) => {
          console.warn('[PWA] Fallo el registro del Service Worker:', error);
        });
    });
  }

  /* --------------------------------------------------------------------------
     6. BOTÓN Y GESTOR DE INSTALACIÓN PWA
     -------------------------------------------------------------------------- */
  let deferredPrompt = null;
  const btnInstall = document.getElementById('btn-install-pwa');
  const installModal = document.getElementById('install-modal');
  const modalClose = document.getElementById('modal-close');
  const modalOk = document.getElementById('modal-ok');
  const modalBackdrop = document.getElementById('modal-backdrop');

  window.addEventListener('beforeinstallprompt', (e) => {
    // Previene el mini-infobar por defecto en navegadores Chromium
    e.preventDefault();
    deferredPrompt = e;
  });

  const showModal = () => {
    if (installModal) installModal.style.display = 'flex';
  };

  const hideModal = () => {
    if (installModal) installModal.style.display = 'none';
  };

  if (btnInstall) {
    btnInstall.addEventListener('click', async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt();
        const { outcome } = await deferredPrompt.userChoice;
        console.log(`[PWA] Respuesta del usuario a la instalación: ${outcome}`);
        deferredPrompt = null;
      } else {
        // En Firefox de escritorio o navegadores sin prompt directo
        showModal();
      }
    });
  }

  if (modalClose) modalClose.addEventListener('click', hideModal);
  if (modalOk) modalOk.addEventListener('click', hideModal);
  if (modalBackdrop) modalBackdrop.addEventListener('click', hideModal);

  /* --------------------------------------------------------------------------
     7. MÉTODOS DE LA API CACHÉ (CacheStorage y Cache Interface)
     -------------------------------------------------------------------------- */
  const CACHE_NAME = 'neurosync-cache-v1';
  const CORE_ASSETS = [
    '/',
    '/index.html',
    '/css/styles.css',
    '/js/main.js',
    '/manifest.json',
    '/icons/icon.svg',
    '/icons/icon-192x192.png',
    '/icons/icon-512x512.png',
    '/icons/icon-maskable-512x512.png',
    '/icons/apple-touch-icon.png'
  ];

  const terminalCode = document.getElementById('cache-log-code');
  const cachedCountEl = document.getElementById('cached-count');
  const networkBadge = document.getElementById('network-badge');
  const networkStatusText = document.getElementById('network-status-text');

  // Función para imprimir logs formateados en la terminal visual
  const logTerminal = (cmd, details) => {
    if (!terminalCode) return;
    const time = new Date().toLocaleTimeString();
    const entry = `\n[${time}] > ${cmd}\n${details}\n----------------------------------------`;
    terminalCode.textContent += entry;
    const terminalBody = document.getElementById('cache-terminal-body');
    if (terminalBody) terminalBody.scrollTop = terminalBody.scrollHeight;
  };

  // Monitoreo de conectividad de red (Online / Offline)
  const updateNetworkStatus = () => {
    if (!networkBadge || !networkStatusText) return;
    if (navigator.onLine) {
      networkStatusText.textContent = 'En Línea (Online)';
      networkBadge.style.borderColor = 'var(--border-accent)';
      networkBadge.style.color = 'var(--color-accent)';
    } else {
      networkStatusText.textContent = 'Sin Conexión (Offline)';
      networkBadge.style.borderColor = 'rgba(243, 244, 246, 0.4)';
      networkBadge.style.color = 'var(--color-text)';
    }
  };

  window.addEventListener('online', () => {
    updateNetworkStatus();
    logTerminal('EVENTO DE RED', 'El navegador recuperó la conexión a Internet.');
  });

  window.addEventListener('offline', () => {
    updateNetworkStatus();
    logTerminal('EVENTO DE RED', 'El navegador está Offline. La API Caché está sirviendo los recursos locales.');
  });

  // Actualizar telemetría de la caché en el panel
  const updateCacheTelemetry = async () => {
    if (!('caches' in window)) {
      if (cachedCountEl) cachedCountEl.textContent = 'No soportada';
      return;
    }

    try {
      const hasCache = await caches.has(CACHE_NAME);
      if (!hasCache) {
        if (cachedCountEl) cachedCountEl.textContent = '0 archivos (Vacío)';
        return;
      }
      const cache = await caches.open(CACHE_NAME);
      const keys = await cache.keys();
      if (cachedCountEl) cachedCountEl.textContent = `${keys.length} archivos en caché`;
    } catch (err) {
      console.warn('[Cache API] Error al consultar telemetría:', err);
    }
  };

  // Inicializar estado
  updateNetworkStatus();
  updateCacheTelemetry();

  // 1. Método: cache.keys()
  const btnCacheKeys = document.getElementById('btn-cache-keys');
  if (btnCacheKeys) {
    btnCacheKeys.addEventListener('click', async () => {
      try {
        logTerminal('caches.open() + cache.keys()', 'Consultando lista de recursos almacenados...');
        const cache = await caches.open(CACHE_NAME);
        const requests = await cache.keys();
        if (requests.length === 0) {
          logTerminal('RESULTADO', 'El almacén de caché está vacío.');
        } else {
          const urls = requests.map((req, i) => `  [${i + 1}] ${req.url}`).join('\n');
          logTerminal(`cache.keys() ÉXITO (${requests.length} entradas)`, urls);
        }
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en cache.keys()', err.message);
      }
    });
  }

  // 2. Método: cache.match()
  const btnCacheMatch = document.getElementById('btn-cache-match');
  if (btnCacheMatch) {
    btnCacheMatch.addEventListener('click', async () => {
      try {
        const targetUrl = '/css/styles.css';
        logTerminal(`cache.match('${targetUrl}')`, 'Buscando recurso en el almacén de caché...');
        const cache = await caches.open(CACHE_NAME);
        const matchResponse = await cache.match(targetUrl);
        if (matchResponse) {
          logTerminal('cache.match() COINCIDENCIA ENCONTRADA', 
            `  URL: ${targetUrl}\n  Status: ${matchResponse.status} ${matchResponse.statusText}\n  Type: ${matchResponse.type}\n  Content-Type: ${matchResponse.headers.get('content-type')}\n  Resultado: Servido 100% desde memoria local.`);
        } else {
          logTerminal('cache.match() NO ENCONTRADO', `El recurso ${targetUrl} no se encuentra en el caché.`);
        }
      } catch (err) {
        logTerminal('ERROR en cache.match()', err.message);
      }
    });
  }

  // 3. Método: cache.add()
  const btnCacheAdd = document.getElementById('btn-cache-add');
  if (btnCacheAdd) {
    btnCacheAdd.addEventListener('click', async () => {
      try {
        const targetUrl = '/manifest.json';
        logTerminal(`cache.add('${targetUrl}')`, 'Descargando y almacenando recurso atómicamente...');
        const cache = await caches.open(CACHE_NAME);
        await cache.add(targetUrl);
        logTerminal('cache.add() COMPLETADO', `Recurso ${targetUrl} descargado y guardado en ${CACHE_NAME}.`);
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en cache.add()', err.message);
      }
    });
  }

  // 4. Método: cache.put()
  const btnCachePut = document.getElementById('btn-cache-put');
  if (btnCachePut) {
    btnCachePut.addEventListener('click', async () => {
      try {
        const syntheticUrl = '/api/synthetic-telemetry';
        const syntheticData = {
          sensor: "BCI-EEG-NeuroSync",
          focusScore: 98.4,
          timestamp: new Date().toISOString(),
          state: "Sincronización Cognitiva Óptima"
        };
        const syntheticResponse = new Response(JSON.stringify(syntheticData), {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
          statusText: 'OK'
        });

        logTerminal(`cache.put('${syntheticUrl}', Response)`, 'Inyectando respuesta sintética personalizada en caché...');
        const cache = await caches.open(CACHE_NAME);
        await cache.put(syntheticUrl, syntheticResponse);
        logTerminal('cache.put() INYECCIÓN EXITOSA', 
          `  Endpoint Virtual: ${syntheticUrl}\n  Payload Almacenado:\n${JSON.stringify(syntheticData, null, 2)}`);
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en cache.put()', err.message);
      }
    });
  }

  // 5. Método: cache.delete()
  const btnCacheDelete = document.getElementById('btn-cache-delete');
  if (btnCacheDelete) {
    btnCacheDelete.addEventListener('click', async () => {
      try {
        const targetUrl = '/api/synthetic-telemetry';
        logTerminal(`cache.delete('${targetUrl}')`, 'Eliminando entrada específica del caché...');
        const cache = await caches.open(CACHE_NAME);
        const deleted = await cache.delete(targetUrl);
        if (deleted) {
          logTerminal('cache.delete() ÉXITO', `El recurso ${targetUrl} fue eliminado del caché correctamente.`);
        } else {
          logTerminal('cache.delete() AVISO', `El recurso ${targetUrl} no existía o ya había sido eliminado.`);
        }
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en cache.delete()', err.message);
      }
    });
  }

  // 6. Método: caches.delete() y cache.addAll()
  const btnCachePurge = document.getElementById('btn-cache-purge');
  if (btnCachePurge) {
    btnCachePurge.addEventListener('click', async () => {
      try {
        logTerminal(`caches.delete('${CACHE_NAME}')`, 'Purgando almacén de caché completo...');
        const purged = await caches.delete(CACHE_NAME);
        logTerminal('caches.delete() COMPLETADO', `Almacén ${CACHE_NAME} eliminado: ${purged}`);
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en caches.delete()', err.message);
      }
    });
  }

  const btnCacheRestore = document.getElementById('btn-cache-restore');
  if (btnCacheRestore) {
    btnCacheRestore.addEventListener('click', async () => {
      try {
        logTerminal(`cache.addAll(CORE_ASSETS)`, `Restaurando ${CORE_ASSETS.length} archivos críticos del App Shell...`);
        const cache = await caches.open(CACHE_NAME);
        await cache.addAll(CORE_ASSETS);
        logTerminal('cache.addAll() RESTAURACIÓN EXITOSA', `Se descargaron y guardaron ${CORE_ASSETS.length} archivos.`);
        updateCacheTelemetry();
      } catch (err) {
        logTerminal('ERROR en cache.addAll()', err.message);
      }
    });
  }

  // Botón Limpiar Consola
  const btnClearConsole = document.getElementById('btn-clear-console');
  if (btnClearConsole && terminalCode) {
    btnClearConsole.addEventListener('click', () => {
      terminalCode.textContent = '// Consola de ejecución de la API Caché lista.\n// Selecciona cualquier método arriba para ver su ejecución.';
    });
  }

  /* --------------------------------------------------------------------------
     8. SIMULADOR DE TELEMETRÍA BIOPOTENCIAL EN TIEMPO REAL (CANVAS & SSE)
     -------------------------------------------------------------------------- */
  const canvas = document.getElementById('bci-oscilloscope');
  const hudGamma = document.getElementById('hud-gamma');
  const hudBeta = document.getElementById('hud-beta');
  const hudFocus = document.getElementById('hud-focus');
  const hudLatency = document.getElementById('hud-latency');

  if (canvas) {
    const ctx = canvas.getContext('2d');
    let phase = 0;
    let currentGamma = 40.8;
    let currentBeta = 18.4;
    let currentFocus = 91.6;
    let currentLatency = 11;

    // Conexión opcional a Stream SSE del backend si está disponible
    if (window.EventSource) {
      try {
        const evtSource = new EventSource('/api/telemetry/stream');
        evtSource.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            if (data.waves) {
              currentGamma = data.waves.gamma;
              currentBeta = data.waves.beta;
              currentFocus = data.focusIndex;
              currentLatency = data.latencyMs;
              if (hudGamma) hudGamma.textContent = `${currentGamma} Hz`;
              if (hudBeta) hudBeta.textContent = `${currentBeta} Hz`;
              if (hudFocus) hudFocus.textContent = `${currentFocus}%`;
              if (hudLatency) hudLatency.textContent = `< ${currentLatency}ms`;
            }
          } catch (e) {}
        };
        evtSource.onerror = () => {
          evtSource.close();
        };
      } catch (err) {}
    }

    // Bucle de renderizado continuo del osciloscopio EEG a 60 FPS
    function drawOscilloscope() {
      const width = canvas.width;
      const height = canvas.height;
      const midY = height / 2;

      ctx.fillStyle = '#060910';
      ctx.fillRect(0, 0, width, height);

      // Grilla tenue biométrica
      ctx.strokeStyle = 'rgba(243, 244, 246, 0.05)';
      ctx.lineWidth = 1;
      for (let x = 0; x < width; x += 40) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (let y = 0; y < height; y += 20) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }

      // Trazo de la onda combinada (Gamma + Beta + Alpha)
      ctx.beginPath();
      ctx.strokeStyle = '#00F0FF';
      ctx.lineWidth = 2;
      ctx.shadowColor = '#00F0FF';
      ctx.shadowBlur = 8;

      phase += 0.08;
      for (let x = 0; x < width; x++) {
        const gammaComponent = Math.sin((x * 0.12) + (phase * 3.5)) * 14;
        const betaComponent = Math.sin((x * 0.04) + phase) * 9;
        const alphaComponent = Math.cos((x * 0.015) + (phase * 0.5)) * 5;
        const y = midY + gammaComponent + betaComponent + alphaComponent;

        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
      ctx.shadowBlur = 0;

      // Actualización de indicadores
      if (Math.random() < 0.04) {
        currentLatency = 11 + Math.floor(Math.random() * 3);
        if (hudLatency) hudLatency.textContent = `< ${currentLatency}ms`;
        if (hudGamma) hudGamma.textContent = `${(39.8 + Math.random() * 3.2).toFixed(1)} Hz`;
        if (hudBeta) hudBeta.textContent = `${(17.8 + Math.random() * 2.2).toFixed(1)} Hz`;
        if (hudFocus) hudFocus.textContent = `${(91.0 + Math.random() * 3.0).toFixed(1)}%`;
      }

      requestAnimationFrame(drawOscilloscope);
    }

    requestAnimationFrame(drawOscilloscope);
  }
});


