-- ==============================================================================
-- NEUROSYNC LABS - DATOS SEMILLA (SEED DATA)
-- Carga registros realistas para pruebas del Embudo, Telemetría y Dashboard
-- ==============================================================================

-- 1. Inserción en el Embudo de Acceso Exclusivo (Waitlist Inteligente)
INSERT INTO beta_waitlist (id, email, full_name, role, institution_or_company, use_case) VALUES
('a0000000-0000-0000-0000-000000000001', 'elena.morales@mit.edu', 'Dra. Elena Morales', 'INVESTIGADOR', 'MIT Media Lab - NeuroTech', 'Investigación de patrones gamma en microestados de enfoque'),
('a0000000-0000-0000-0000-000000000002', 'carlos.venture@capitalneuro.vc', 'Carlos Méndez', 'INVERSOR', 'Apex DeepTech Ventures', 'Evaluación para inversión Serie Seed en NeuroSync Labs'),
('a0000000-0000-0000-0000-000000000003', 'mateo.dev@synapse.io', 'Mateo Silva', 'DESARROLLADOR', 'Synapse SDK Open Source', 'Integración de API WebSockets con diadema OpenBCI Cyton'),
('a0000000-0000-0000-0000-000000000004', 'sofia.bio@quantifiedself.com', 'Sofía Valdés', 'BIOHACKER', 'Comunidad Biohacking Latam', 'Optimización circadiana y reducción de fatiga cognitiva en jornadas laborales'),
('a0000000-0000-0000-0000-000000000005', 'estudiante.lab@universidad.edu', 'Lucas Benítez', 'OTRO', 'Universidad Tecnológica', 'Proyecto de grado en interfaces cerebro-computadora')
ON CONFLICT (email) DO NOTHING;

-- 2. Creación de Perfil de Usuario para el Dashboard
INSERT INTO user_profiles (id, waitlist_id, email, full_name, paired_hardware_model, cognitive_baseline_score, current_cognitive_score, streak_days) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'elena.morales@mit.edu', 'Dra. Elena Morales', 'NeuroSync Graphene Headband Pro v2', 60.00, 85.20, 14)
ON CONFLICT (email) DO NOTHING;

-- 3. Historial de Sesiones de Entrenamiento Cognitivo
INSERT INTO training_sessions (id, user_id, session_title, started_at, ended_at, duration_seconds, initial_focus_score, final_focus_score, avg_alpha_hz, avg_beta_hz, avg_gamma_hz, avg_latency_ms, status) VALUES
('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Calibración Matutina Gamma', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '25 minutes', 1500, 60.00, 78.50, 10.2, 17.5, 38.4, 12.1, 'COMPLETADA'),
('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Sesión Deep Work - Algoritmos', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '45 minutes', 2700, 62.00, 84.00, 9.8, 19.1, 41.2, 11.8, 'COMPLETADA'),
('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'Sincronización Pre-Exposición', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '30 minutes', 1800, 64.00, 90.88, 10.5, 21.4, 43.5, 11.2, 'COMPLETADA')
ON CONFLICT (id) DO NOTHING;

-- 4. Snapshots de Telemetría Biométrica en Tiempo Real (Muestras de ejemplo)
INSERT INTO telemetry_snapshots (session_id, alpha_power, beta_power, gamma_power, theta_power, focus_index, fatigue_index, latency_ms) VALUES
('c0000000-0000-0000-0000-000000000003', 14.25, 22.80, 42.10, 8.40, 88.50, 12.30, 11),
('c0000000-0000-0000-0000-000000000003', 13.90, 24.10, 44.50, 7.80, 91.20, 11.80, 12),
('c0000000-0000-0000-0000-000000000003', 14.80, 23.50, 43.90, 8.10, 90.40, 12.00, 11);

-- 5. Mensajes de Contacto Institucional y Alerta Inversor
INSERT INTO contact_messages (full_name, email, interest_area, message, is_high_priority_investor, status) VALUES
('Carlos Méndez', 'carlos.venture@capitalneuro.vc', 'investment', 'Interesados en agendar una llamada con los fundadores para evaluar ronda de inversión en neurotecnología médica.', TRUE, 'PENDIENTE'),
('Dra. Arisbe Silva', 'arisbe.neuro@hospital.org', 'research', 'Propuesta de protocolo clínico para validar el casco NeuroSync con pacientes con TDAH.', FALSE, 'PENDIENTE');
