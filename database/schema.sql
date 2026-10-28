-- ==============================================================================
-- NEUROSYNC LABS - ESQUEMA DE BASE DE DATOS POSTGRESQL (PRODUCCIÓN / ACADÉMICO)
-- Arquitectura:
--   1. Embudo de Acceso Exclusivo (Waitlist Inteligente con scoring automatizado)
--   2. Motor de Telemetría Biométrica en Tiempo Real (Ondas EEG & Latencia)
--   3. Panel de Control del Usuario (Dashboard, Evolución Cognitiva y Sesiones)
--   4. Módulo de Contacto Institucional & Gestión de Inversores
-- ==============================================================================

-- Extensiones para UUIDs criptográficos y funciones hash
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- TIPOS ENUM PERSONALIZADOS
-- ==============================================================================

-- Perfil o rol del usuario para el embudo de prioridad
CREATE TYPE user_role AS ENUM (
    'INVESTIGADOR',       -- Máxima prioridad técnica / académica
    'DESARROLLADOR',      -- Acceso a SDKs y APIs de hardware BCI
    'BIOHACKER',          -- Usuario intensivo de neurofeedback
    'INVERSOR',           -- Capital semilla y alianzas estratégicas
    'OTRO'
);

-- Estado del usuario en el embudo de admisión
CREATE TYPE access_status AS ENUM (
    'EN_ESPERA',          -- Registrado en lista de espera
    'PRIORITARIO',        -- Calificado por el algoritmo para acceso temprano
    'INVITADO',           -- Token de acceso enviado por correo
    'ACTIVO',             -- Cuenta validada en el SaaS
    'REVOCADO'            -- Acceso suspendido
);

-- Estado de una sesión de neuroestimulación / biofeedback
CREATE TYPE session_state AS ENUM (
    'EN_CURSO',
    'COMPLETADA',
    'INTERRUMPIDA'
);

-- Estado del mensaje institucional o de inversión
CREATE TYPE message_status AS ENUM (
    'PENDIENTE',          -- Mensaje recién recibido
    'NOTIFICADO',         -- Reenviado a Telegram / Email del fundador
    'EN_REVISION',
    'RESPONDIDO',
    'ARCHIVADO'
);

-- ==============================================================================
-- TABLA 1: EL EMBUDO DE ACCESO EXCLUSIVO (LA WAITLIST INTELIGENTE)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS beta_waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    role user_role NOT NULL DEFAULT 'OTRO',
    institution_or_company VARCHAR(150),
    use_case TEXT,
    
    -- Calificación calculada automáticamente por trigger según el rol e impacto
    priority_score INT NOT NULL DEFAULT 0,
    
    -- Llave de acceso única y segura generada para la beta privada
    access_token UUID NOT NULL DEFAULT gen_random_uuid(),
    
    status access_status NOT NULL DEFAULT 'EN_ESPERA',
    
    -- Metadatos de auditoría y fechas
    ip_address INET,
    invited_at TIMESTAMPTZ,
    activated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_waitlist_email ON beta_waitlist(email);
CREATE INDEX idx_waitlist_token ON beta_waitlist(access_token);
CREATE INDEX idx_waitlist_priority ON beta_waitlist(priority_score DESC, created_at ASC);

-- ==============================================================================
-- TABLA 2: PERFILES DE USUARIO (DASHBOARD & IDENTIDAD BIOMÉTRICA)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    waitlist_id UUID REFERENCES beta_waitlist(id) ON DELETE SET NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    
    -- Identificador del hardware BCI vinculado (ej. Diadema de Grafeno v2)
    paired_hardware_model VARCHAR(100) DEFAULT 'NeuroSync Graphene Headband v2',
    hardware_mac_address VARCHAR(30),
    
    -- Métricas base de calibración cognitiva
    cognitive_baseline_score NUMERIC(5,2) NOT NULL DEFAULT 60.00,
    current_cognitive_score NUMERIC(5,2) NOT NULL DEFAULT 85.20,
    
    -- Estadísticas acumuladas
    total_focus_minutes INT NOT NULL DEFAULT 0,
    streak_days INT NOT NULL DEFAULT 0,
    last_session_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_profiles_email ON user_profiles(email);

-- ==============================================================================
-- TABLA 3: HISTORIAL DE SESIONES DE ENTRENAMIENTO (EVOLUCIÓN COGNITIVA)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS training_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    session_title VARCHAR(120) DEFAULT 'Entrenamiento Deep Work',
    
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    duration_seconds INT NOT NULL DEFAULT 0,
    
    -- Puntajes de rendimiento
    initial_focus_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    final_focus_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    
    -- Porcentaje de mejora obtenido (+42% esperado según la propuesta de valor)
    improvement_percentage NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN initial_focus_score > 0 
            THEN ROUND(((final_focus_score - initial_focus_score) / initial_focus_score) * 100, 2)
            ELSE 0.00 
        END
    ) STORED,
    
    -- Promedios biométricos de la sesión
    avg_alpha_hz NUMERIC(5,2) DEFAULT 10.50, -- 8-12 Hz (Relajación alerta)
    avg_beta_hz NUMERIC(5,2) DEFAULT 18.20,  -- 13-30 Hz (Concentración activa)
    avg_gamma_hz NUMERIC(5,2) DEFAULT 40.10, -- 30-100 Hz (Procesamiento cognitivo alto)
    avg_latency_ms NUMERIC(5,2) DEFAULT 12.40, -- Latencia de inferencia BCI (< 15 ms)
    
    status session_state NOT NULL DEFAULT 'COMPLETADA'
);

CREATE INDEX idx_sessions_user ON training_sessions(user_id, started_at DESC);

-- ==============================================================================
-- TABLA 4: TELEMETRÍA EN TIEMPO REAL (SNAPSHOTS PARA STREAMING WEBSOCKETS)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS telemetry_snapshots (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Potencia de bandas espectrales EEG en microvoltios (uV)
    alpha_power NUMERIC(6,3) NOT NULL, -- Ondas Alfa
    beta_power NUMERIC(6,3) NOT NULL,  -- Ondas Beta
    gamma_power NUMERIC(6,3) NOT NULL, -- Ondas Gamma
    theta_power NUMERIC(6,3) NOT NULL, -- Ondas Theta
    
    -- Indicadores analíticos en tiempo real (0 - 100)
    focus_index NUMERIC(5,2) NOT NULL,
    fatigue_index NUMERIC(5,2) NOT NULL,
    
    -- Latencia de transporte en milisegundos
    latency_ms INT NOT NULL CHECK (latency_ms > 0)
);

CREATE INDEX idx_telemetry_session_time ON telemetry_snapshots(session_id, recorded_at);

-- ==============================================================================
-- TABLA 5: AVISOS Y MENSAJES INSTITUCIONALES / INVERSORES
-- ==============================================================================
CREATE TABLE IF NOT EXISTS contact_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL,
    interest_area VARCHAR(80) NOT NULL, -- 'beta', 'research', 'dev', 'investment'
    message TEXT NOT NULL,
    
    -- Detección automatizada de inversores para alerta de alta prioridad
    is_high_priority_investor BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Bandera de despacho inmediato a webhook de Telegram o Email
    telegram_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
    telegram_dispatch_id VARCHAR(100),
    
    status message_status NOT NULL DEFAULT 'PENDIENTE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contact_status ON contact_messages(status, created_at DESC);

-- ==============================================================================
-- FUNCIONES Y TRIGGERS AUTOMATIZADOS
-- ==============================================================================

-- Trigger 1: Cálculo automático del puntaje de prioridad en la Waitlist Inteligente
CREATE OR REPLACE FUNCTION trg_calculate_waitlist_priority()
RETURNS TRIGGER AS $$
BEGIN
    -- Asignación de puntos basada en el perfil estratégico
    NEW.priority_score := CASE 
        WHEN NEW.role = 'INVERSOR' THEN 100
        WHEN NEW.role = 'INVESTIGADOR' THEN 85
        WHEN NEW.role = 'DESARROLLADOR' THEN 75
        WHEN NEW.role = 'BIOHACKER' THEN 65
        ELSE 40
    END;

    -- Bonificación si especifica una institución o caso de uso relevante
    IF NEW.institution_or_company IS NOT NULL AND LENGTH(TRIM(NEW.institution_or_company)) > 2 THEN
        NEW.priority_score := NEW.priority_score + 10;
    END IF;

    -- Clasificación automática: Si supera 80 puntos, pasa a estado PRIORITARIO
    IF NEW.priority_score >= 80 THEN
        NEW.status := 'PRIORITARIO';
    ELSE
        NEW.status := 'EN_ESPERA';
    END IF;

    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_waitlist_scoring_before_insert
BEFORE INSERT OR UPDATE OF role, institution_or_company ON beta_waitlist
FOR EACH ROW
EXECUTE FUNCTION trg_calculate_waitlist_priority();

-- Trigger 2: Detección automática de mensajes de inversión y marca de prioridad
CREATE OR REPLACE FUNCTION trg_flag_investor_contact()
RETURNS TRIGGER AS $$
BEGIN
    IF LOWER(NEW.interest_area) LIKE '%invest%' OR LOWER(NEW.message) LIKE '%capital%' OR LOWER(NEW.message) LIKE '%inversión%' OR LOWER(NEW.message) LIKE '%inversion%' THEN
        NEW.is_high_priority_investor := TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contact_investor_check
BEFORE INSERT ON contact_messages
FOR EACH ROW
EXECUTE FUNCTION trg_flag_investor_contact();

-- Trigger 3: Actualización automática de acumulados en el perfil de usuario al cerrar sesión
CREATE OR REPLACE FUNCTION trg_update_user_profile_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'COMPLETADA' AND (OLD.status IS NULL OR OLD.status != 'COMPLETADA') THEN
        UPDATE user_profiles
        SET total_focus_minutes = total_focus_minutes + CEIL(NEW.duration_seconds / 60.0),
            current_cognitive_score = NEW.final_focus_score,
            last_session_at = NEW.ended_at,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_session_finished_update_profile
AFTER INSERT OR UPDATE OF status ON training_sessions
FOR EACH ROW
EXECUTE FUNCTION trg_update_user_profile_metrics();

-- ==============================================================================
-- VISTAS ANALÍTICAS PARA EL DASHBOARD
-- ==============================================================================

-- Vista 1: Resumen de Evolución Cognitiva del Usuario
CREATE OR REPLACE VIEW view_user_cognitive_dashboard AS
SELECT 
    u.id AS user_id,
    u.full_name,
    u.email,
    u.current_cognitive_score,
    u.cognitive_baseline_score,
    ROUND(((u.current_cognitive_score - u.cognitive_baseline_score) / u.cognitive_baseline_score) * 100, 2) AS overall_growth_percentage,
    u.total_focus_minutes,
    COUNT(s.id) AS total_sessions_completed,
    ROUND(AVG(s.avg_latency_ms), 2) AS average_bci_latency_ms,
    MAX(s.started_at) AS last_trained_at
FROM user_profiles u
LEFT JOIN training_sessions s ON u.id = s.user_id AND s.status = 'COMPLETADA'
GROUP BY u.id, u.full_name, u.email, u.current_cognitive_score, u.cognitive_baseline_score, u.total_focus_minutes;

-- Vista 2: Embudo de Admisión Waitlist (Cola Priorizada)
CREATE OR REPLACE VIEW view_waitlist_priority_queue AS
SELECT 
    id,
    full_name,
    email,
    role,
    priority_score,
    status,
    access_token,
    created_at,
    RANK() OVER (ORDER BY priority_score DESC, created_at ASC) AS queue_position
FROM beta_waitlist
WHERE status IN ('EN_ESPERA', 'PRIORITARIO');
