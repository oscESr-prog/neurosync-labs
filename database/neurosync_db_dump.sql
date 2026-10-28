--
-- PostgreSQL database dump
--

\restrict fdcUAU9leujZdY6YwC8jrLTSNvSYgeGoxthAdQiD1kdQGvUrLMq8laNG1JoWHxM

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: access_status; Type: TYPE; Schema: public; Owner: estradaoscar419
--

CREATE TYPE public.access_status AS ENUM (
    'EN_ESPERA',
    'PRIORITARIO',
    'INVITADO',
    'ACTIVO',
    'REVOCADO'
);


ALTER TYPE public.access_status OWNER TO estradaoscar419;

--
-- Name: message_status; Type: TYPE; Schema: public; Owner: estradaoscar419
--

CREATE TYPE public.message_status AS ENUM (
    'PENDIENTE',
    'NOTIFICADO',
    'EN_REVISION',
    'RESPONDIDO',
    'ARCHIVADO'
);


ALTER TYPE public.message_status OWNER TO estradaoscar419;

--
-- Name: session_state; Type: TYPE; Schema: public; Owner: estradaoscar419
--

CREATE TYPE public.session_state AS ENUM (
    'EN_CURSO',
    'COMPLETADA',
    'INTERRUMPIDA'
);


ALTER TYPE public.session_state OWNER TO estradaoscar419;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: estradaoscar419
--

CREATE TYPE public.user_role AS ENUM (
    'INVESTIGADOR',
    'DESARROLLADOR',
    'BIOHACKER',
    'INVERSOR',
    'OTRO'
);


ALTER TYPE public.user_role OWNER TO estradaoscar419;

--
-- Name: trg_calculate_waitlist_priority(); Type: FUNCTION; Schema: public; Owner: estradaoscar419
--

CREATE FUNCTION public.trg_calculate_waitlist_priority() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.trg_calculate_waitlist_priority() OWNER TO estradaoscar419;

--
-- Name: trg_flag_investor_contact(); Type: FUNCTION; Schema: public; Owner: estradaoscar419
--

CREATE FUNCTION public.trg_flag_investor_contact() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF LOWER(NEW.interest_area) LIKE '%invest%' OR LOWER(NEW.message) LIKE '%capital%' OR LOWER(NEW.message) LIKE '%inversión%' OR LOWER(NEW.message) LIKE '%inversion%' THEN
        NEW.is_high_priority_investor := TRUE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_flag_investor_contact() OWNER TO estradaoscar419;

--
-- Name: trg_update_user_profile_metrics(); Type: FUNCTION; Schema: public; Owner: estradaoscar419
--

CREATE FUNCTION public.trg_update_user_profile_metrics() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.trg_update_user_profile_metrics() OWNER TO estradaoscar419;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: beta_waitlist; Type: TABLE; Schema: public; Owner: estradaoscar419
--

CREATE TABLE public.beta_waitlist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    full_name character varying(120) NOT NULL,
    role public.user_role DEFAULT 'OTRO'::public.user_role NOT NULL,
    institution_or_company character varying(150),
    use_case text,
    priority_score integer DEFAULT 0 NOT NULL,
    access_token uuid DEFAULT gen_random_uuid() NOT NULL,
    status public.access_status DEFAULT 'EN_ESPERA'::public.access_status NOT NULL,
    ip_address inet,
    invited_at timestamp with time zone,
    activated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.beta_waitlist OWNER TO estradaoscar419;

--
-- Name: contact_messages; Type: TABLE; Schema: public; Owner: estradaoscar419
--

CREATE TABLE public.contact_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(120) NOT NULL,
    email character varying(255) NOT NULL,
    interest_area character varying(80) NOT NULL,
    message text NOT NULL,
    is_high_priority_investor boolean DEFAULT false NOT NULL,
    telegram_dispatched boolean DEFAULT false NOT NULL,
    telegram_dispatch_id character varying(100),
    status public.message_status DEFAULT 'PENDIENTE'::public.message_status NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.contact_messages OWNER TO estradaoscar419;

--
-- Name: telemetry_snapshots; Type: TABLE; Schema: public; Owner: estradaoscar419
--

CREATE TABLE public.telemetry_snapshots (
    id bigint NOT NULL,
    session_id uuid NOT NULL,
    recorded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    alpha_power numeric(6,3) NOT NULL,
    beta_power numeric(6,3) NOT NULL,
    gamma_power numeric(6,3) NOT NULL,
    theta_power numeric(6,3) NOT NULL,
    focus_index numeric(5,2) NOT NULL,
    fatigue_index numeric(5,2) NOT NULL,
    latency_ms integer NOT NULL,
    CONSTRAINT telemetry_snapshots_latency_ms_check CHECK ((latency_ms > 0))
);


ALTER TABLE public.telemetry_snapshots OWNER TO estradaoscar419;

--
-- Name: telemetry_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: estradaoscar419
--

CREATE SEQUENCE public.telemetry_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telemetry_snapshots_id_seq OWNER TO estradaoscar419;

--
-- Name: telemetry_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: estradaoscar419
--

ALTER SEQUENCE public.telemetry_snapshots_id_seq OWNED BY public.telemetry_snapshots.id;


--
-- Name: training_sessions; Type: TABLE; Schema: public; Owner: estradaoscar419
--

CREATE TABLE public.training_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_title character varying(120) DEFAULT 'Entrenamiento Deep Work'::character varying,
    started_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ended_at timestamp with time zone,
    duration_seconds integer DEFAULT 0 NOT NULL,
    initial_focus_score numeric(5,2) DEFAULT 0.00 NOT NULL,
    final_focus_score numeric(5,2) DEFAULT 0.00 NOT NULL,
    improvement_percentage numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN (initial_focus_score > (0)::numeric) THEN round((((final_focus_score - initial_focus_score) / initial_focus_score) * (100)::numeric), 2)
    ELSE 0.00
END) STORED,
    avg_alpha_hz numeric(5,2) DEFAULT 10.50,
    avg_beta_hz numeric(5,2) DEFAULT 18.20,
    avg_gamma_hz numeric(5,2) DEFAULT 40.10,
    avg_latency_ms numeric(5,2) DEFAULT 12.40,
    status public.session_state DEFAULT 'COMPLETADA'::public.session_state NOT NULL
);


ALTER TABLE public.training_sessions OWNER TO estradaoscar419;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: estradaoscar419
--

CREATE TABLE public.user_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    waitlist_id uuid,
    email character varying(255) NOT NULL,
    full_name character varying(120) NOT NULL,
    paired_hardware_model character varying(100) DEFAULT 'NeuroSync Graphene Headband v2'::character varying,
    hardware_mac_address character varying(30),
    cognitive_baseline_score numeric(5,2) DEFAULT 60.00 NOT NULL,
    current_cognitive_score numeric(5,2) DEFAULT 85.20 NOT NULL,
    total_focus_minutes integer DEFAULT 0 NOT NULL,
    streak_days integer DEFAULT 0 NOT NULL,
    last_session_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.user_profiles OWNER TO estradaoscar419;

--
-- Name: view_user_cognitive_dashboard; Type: VIEW; Schema: public; Owner: estradaoscar419
--

CREATE VIEW public.view_user_cognitive_dashboard AS
 SELECT u.id AS user_id,
    u.full_name,
    u.email,
    u.current_cognitive_score,
    u.cognitive_baseline_score,
    round((((u.current_cognitive_score - u.cognitive_baseline_score) / u.cognitive_baseline_score) * (100)::numeric), 2) AS overall_growth_percentage,
    u.total_focus_minutes,
    count(s.id) AS total_sessions_completed,
    round(avg(s.avg_latency_ms), 2) AS average_bci_latency_ms,
    max(s.started_at) AS last_trained_at
   FROM (public.user_profiles u
     LEFT JOIN public.training_sessions s ON (((u.id = s.user_id) AND (s.status = 'COMPLETADA'::public.session_state))))
  GROUP BY u.id, u.full_name, u.email, u.current_cognitive_score, u.cognitive_baseline_score, u.total_focus_minutes;


ALTER VIEW public.view_user_cognitive_dashboard OWNER TO estradaoscar419;

--
-- Name: view_waitlist_priority_queue; Type: VIEW; Schema: public; Owner: estradaoscar419
--

CREATE VIEW public.view_waitlist_priority_queue AS
 SELECT id,
    full_name,
    email,
    role,
    priority_score,
    status,
    access_token,
    created_at,
    rank() OVER (ORDER BY priority_score DESC, created_at) AS queue_position
   FROM public.beta_waitlist
  WHERE (status = ANY (ARRAY['EN_ESPERA'::public.access_status, 'PRIORITARIO'::public.access_status]));


ALTER VIEW public.view_waitlist_priority_queue OWNER TO estradaoscar419;

--
-- Name: telemetry_snapshots id; Type: DEFAULT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.telemetry_snapshots ALTER COLUMN id SET DEFAULT nextval('public.telemetry_snapshots_id_seq'::regclass);


--
-- Data for Name: beta_waitlist; Type: TABLE DATA; Schema: public; Owner: estradaoscar419
--

COPY public.beta_waitlist (id, email, full_name, role, institution_or_company, use_case, priority_score, access_token, status, ip_address, invited_at, activated_at, created_at, updated_at) FROM stdin;
a0000000-0000-0000-0000-000000000001	elena.morales@mit.edu	Dra. Elena Morales	INVESTIGADOR	MIT Media Lab - NeuroTech	Investigación de patrones gamma en microestados de enfoque	95	b38e66e3-1e29-4e30-b077-63c63716a85c	PRIORITARIO	\N	\N	\N	2026-10-28 15:10:02.557206-06	2026-10-28 15:10:02.557206-06
a0000000-0000-0000-0000-000000000002	carlos.venture@capitalneuro.vc	Carlos Méndez	INVERSOR	Apex DeepTech Ventures	Evaluación para inversión Serie Seed en NeuroSync Labs	110	c2311663-9117-43a7-8e84-ff0f711d8b9a	PRIORITARIO	\N	\N	\N	2026-10-28 15:10:02.557206-06	2026-10-28 15:10:02.557206-06
a0000000-0000-0000-0000-000000000003	mateo.dev@synapse.io	Mateo Silva	DESARROLLADOR	Synapse SDK Open Source	Integración de API WebSockets con diadema OpenBCI Cyton	85	0f822ddf-0ea6-42e1-9864-982fa93689b9	PRIORITARIO	\N	\N	\N	2026-10-28 15:10:02.557206-06	2026-10-28 15:10:02.557206-06
a0000000-0000-0000-0000-000000000004	sofia.bio@quantifiedself.com	Sofía Valdés	BIOHACKER	Comunidad Biohacking Latam	Optimización circadiana y reducción de fatiga cognitiva en jornadas laborales	75	07d098d6-7550-4d09-aec3-613ad609ac76	EN_ESPERA	\N	\N	\N	2026-10-28 15:10:02.557206-06	2026-10-28 15:10:02.557206-06
a0000000-0000-0000-0000-000000000005	estudiante.lab@universidad.edu	Lucas Benítez	OTRO	Universidad Tecnológica	Proyecto de grado en interfaces cerebro-computadora	50	200f3917-e0cb-4b4c-9bdf-dc5ed6ca10a8	EN_ESPERA	\N	\N	\N	2026-10-28 15:10:02.557206-06	2026-10-28 15:10:02.557206-06
\.


--
-- Data for Name: contact_messages; Type: TABLE DATA; Schema: public; Owner: estradaoscar419
--

COPY public.contact_messages (id, full_name, email, interest_area, message, is_high_priority_investor, telegram_dispatched, telegram_dispatch_id, status, created_at) FROM stdin;
44e5d4e4-35e0-4528-8bc2-9e087a6fee12	Carlos Méndez	carlos.venture@capitalneuro.vc	investment	Interesados en agendar una llamada con los fundadores para evaluar ronda de inversión en neurotecnología médica.	t	f	\N	PENDIENTE	2026-10-28 15:10:02.575357-06
c8c7aff5-c4b0-4c84-8f3d-66b8eec080ca	Dra. Arisbe Silva	arisbe.neuro@hospital.org	research	Propuesta de protocolo clínico para validar el casco NeuroSync con pacientes con TDAH.	f	f	\N	PENDIENTE	2026-10-28 15:10:02.575357-06
\.


--
-- Data for Name: telemetry_snapshots; Type: TABLE DATA; Schema: public; Owner: estradaoscar419
--

COPY public.telemetry_snapshots (id, session_id, recorded_at, alpha_power, beta_power, gamma_power, theta_power, focus_index, fatigue_index, latency_ms) FROM stdin;
1	c0000000-0000-0000-0000-000000000003	2026-10-28 15:10:02.571894-06	14.250	22.800	42.100	8.400	88.50	12.30	11
2	c0000000-0000-0000-0000-000000000003	2026-10-28 15:10:02.571894-06	13.900	24.100	44.500	7.800	91.20	11.80	12
3	c0000000-0000-0000-0000-000000000003	2026-10-28 15:10:02.571894-06	14.800	23.500	43.900	8.100	90.40	12.00	11
\.


--
-- Data for Name: training_sessions; Type: TABLE DATA; Schema: public; Owner: estradaoscar419
--

COPY public.training_sessions (id, user_id, session_title, started_at, ended_at, duration_seconds, initial_focus_score, final_focus_score, avg_alpha_hz, avg_beta_hz, avg_gamma_hz, avg_latency_ms, status) FROM stdin;
c0000000-0000-0000-0000-000000000001	b0000000-0000-0000-0000-000000000001	Calibración Matutina Gamma	2026-10-25 15:10:02.567064-06	2026-10-25 15:35:02.567064-06	1500	60.00	78.50	10.20	17.50	38.40	12.10	COMPLETADA
c0000000-0000-0000-0000-000000000002	b0000000-0000-0000-0000-000000000001	Sesión Deep Work - Algoritmos	2026-10-26 15:10:02.567064-06	2026-10-26 15:55:02.567064-06	2700	62.00	84.00	9.80	19.10	41.20	11.80	COMPLETADA
c0000000-0000-0000-0000-000000000003	b0000000-0000-0000-0000-000000000001	Sincronización Pre-Exposición	2026-10-27 15:10:02.567064-06	2026-10-27 15:40:02.567064-06	1800	64.00	90.88	10.50	21.40	43.50	11.20	COMPLETADA
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: estradaoscar419
--

COPY public.user_profiles (id, waitlist_id, email, full_name, paired_hardware_model, hardware_mac_address, cognitive_baseline_score, current_cognitive_score, total_focus_minutes, streak_days, last_session_at, created_at, updated_at) FROM stdin;
b0000000-0000-0000-0000-000000000001	a0000000-0000-0000-0000-000000000001	elena.morales@mit.edu	Dra. Elena Morales	NeuroSync Graphene Headband Pro v2	\N	60.00	90.88	100	14	2026-10-27 15:40:02.567064-06	2026-10-28 15:10:02.563908-06	2026-10-28 15:10:02.567064-06
\.


--
-- Name: telemetry_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: estradaoscar419
--

SELECT pg_catalog.setval('public.telemetry_snapshots_id_seq', 3, true);


--
-- Name: beta_waitlist beta_waitlist_email_key; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.beta_waitlist
    ADD CONSTRAINT beta_waitlist_email_key UNIQUE (email);


--
-- Name: beta_waitlist beta_waitlist_pkey; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.beta_waitlist
    ADD CONSTRAINT beta_waitlist_pkey PRIMARY KEY (id);


--
-- Name: contact_messages contact_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.contact_messages
    ADD CONSTRAINT contact_messages_pkey PRIMARY KEY (id);


--
-- Name: telemetry_snapshots telemetry_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.telemetry_snapshots
    ADD CONSTRAINT telemetry_snapshots_pkey PRIMARY KEY (id);


--
-- Name: training_sessions training_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.training_sessions
    ADD CONSTRAINT training_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_email_key; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_email_key UNIQUE (email);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: idx_contact_status; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_contact_status ON public.contact_messages USING btree (status, created_at DESC);


--
-- Name: idx_profiles_email; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_profiles_email ON public.user_profiles USING btree (email);


--
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_sessions_user ON public.training_sessions USING btree (user_id, started_at DESC);


--
-- Name: idx_telemetry_session_time; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_telemetry_session_time ON public.telemetry_snapshots USING btree (session_id, recorded_at);


--
-- Name: idx_waitlist_email; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_waitlist_email ON public.beta_waitlist USING btree (email);


--
-- Name: idx_waitlist_priority; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_waitlist_priority ON public.beta_waitlist USING btree (priority_score DESC, created_at);


--
-- Name: idx_waitlist_token; Type: INDEX; Schema: public; Owner: estradaoscar419
--

CREATE INDEX idx_waitlist_token ON public.beta_waitlist USING btree (access_token);


--
-- Name: contact_messages trg_contact_investor_check; Type: TRIGGER; Schema: public; Owner: estradaoscar419
--

CREATE TRIGGER trg_contact_investor_check BEFORE INSERT ON public.contact_messages FOR EACH ROW EXECUTE FUNCTION public.trg_flag_investor_contact();


--
-- Name: training_sessions trg_session_finished_update_profile; Type: TRIGGER; Schema: public; Owner: estradaoscar419
--

CREATE TRIGGER trg_session_finished_update_profile AFTER INSERT OR UPDATE OF status ON public.training_sessions FOR EACH ROW EXECUTE FUNCTION public.trg_update_user_profile_metrics();


--
-- Name: beta_waitlist trg_waitlist_scoring_before_insert; Type: TRIGGER; Schema: public; Owner: estradaoscar419
--

CREATE TRIGGER trg_waitlist_scoring_before_insert BEFORE INSERT OR UPDATE OF role, institution_or_company ON public.beta_waitlist FOR EACH ROW EXECUTE FUNCTION public.trg_calculate_waitlist_priority();


--
-- Name: telemetry_snapshots telemetry_snapshots_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.telemetry_snapshots
    ADD CONSTRAINT telemetry_snapshots_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.training_sessions(id) ON DELETE CASCADE;


--
-- Name: training_sessions training_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.training_sessions
    ADD CONSTRAINT training_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_waitlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: estradaoscar419
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_waitlist_id_fkey FOREIGN KEY (waitlist_id) REFERENCES public.beta_waitlist(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict fdcUAU9leujZdY6YwC8jrLTSNvSYgeGoxthAdQiD1kdQGvUrLMq8laNG1JoWHxM

