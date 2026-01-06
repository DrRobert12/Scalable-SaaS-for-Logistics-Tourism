
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: obtener_semana_natural(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.obtener_semana_natural(fecha date) RETURNS TABLE("año" integer, mes integer, semana_mes integer, fecha_inicio date, fecha_fin date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    inicio_semana DATE;
    fin_semana DATE;
    semana_num INTEGER;
BEGIN
    -- Calcular inicio de semana (Lunes)
    -- PostgreSQL: 0=Domingo, 1=Lunes, ..., 6=Sábado
    inicio_semana := fecha - (EXTRACT(DOW FROM fecha)::INTEGER - 1);
    IF EXTRACT(DOW FROM fecha) = 0 THEN -- Domingo
        inicio_semana := fecha - 6;
    END IF;
    
    -- Calcular fin de semana (Domingo)
    fin_semana := inicio_semana + 6;
    
    -- Calcular semana del mes (1-4 o 5)
    semana_num := CEIL(EXTRACT(DAY FROM inicio_semana) / 7.0)::INTEGER;
    
    RETURN QUERY SELECT 
        EXTRACT(YEAR FROM inicio_semana)::INTEGER,
        EXTRACT(MONTH FROM inicio_semana)::INTEGER,
        semana_num,
        inicio_semana,
        fin_semana;
END;
$$;


ALTER FUNCTION public.obtener_semana_natural(fecha date) OWNER TO postgres;

--
-- Name: procesar_datos_historicos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.procesar_datos_historicos() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    cupon_record RECORD;
    semana_info RECORD;
    total_procesados INTEGER := 0;
BEGIN
    -- Procesar todos los cupones existentes
    FOR cupon_record IN 
        SELECT DISTINCT DATE(created_at) as fecha_cupon
        FROM cupones
        ORDER BY fecha_cupon
    LOOP
        -- Obtener información de la semana para esta fecha
        SELECT * INTO semana_info 
        FROM obtener_semana_natural(cupon_record.fecha_cupon);
        
        -- Insertar o actualizar resumen semanal
        INSERT INTO resumen_semanas (
            año, mes, semana_mes, fecha_inicio_semana, fecha_fin_semana,
            total_cupones, monto_total_semana, monto_parcial_semana,
            cupones_usados, cupones_pendientes
        )
        SELECT 
            semana_info.año,
            semana_info.mes,
            semana_info.semana_mes,
            semana_info.fecha_inicio,
            semana_info.fecha_fin,
            COUNT(*) as total_cupones,
            SUM(monto_total) as monto_total_semana,
            SUM(monto_parcial) as monto_parcial_semana,
            COUNT(CASE WHEN estado = 'usado' THEN 1 END) as cupones_usados,
            COUNT(CASE WHEN estado = 'nuevo' THEN 1 END) as cupones_pendientes
        FROM cupones
        WHERE DATE(created_at) >= semana_info.fecha_inicio 
          AND DATE(created_at) <= semana_info.fecha_fin
        GROUP BY semana_info.año, semana_info.mes, semana_info.semana_mes
        ON CONFLICT (año, mes, semana_mes) 
        DO UPDATE SET
            total_cupones = EXCLUDED.total_cupones,
            monto_total_semana = EXCLUDED.monto_total_semana,
            monto_parcial_semana = EXCLUDED.monto_parcial_semana,
            cupones_usados = EXCLUDED.cupones_usados,
            cupones_pendientes = EXCLUDED.cupones_pendientes,
            updated_at = CURRENT_TIMESTAMP;
        
        total_procesados := total_procesados + 1;
    END LOOP;
    
    RETURN total_procesados;
END;
$$;


ALTER FUNCTION public.procesar_datos_historicos() OWNER TO postgres;

--
-- Name: procesar_semana_actual(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.procesar_semana_actual() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    semana_info RECORD;
    fecha_hoy DATE := CURRENT_DATE;
BEGIN
    -- Obtener información de la semana actual
    SELECT * INTO semana_info 
    FROM obtener_semana_natural(fecha_hoy);
    
    -- Insertar o actualizar resumen de la semana actual
    INSERT INTO resumen_semanas (
        año, mes, semana_mes, fecha_inicio_semana, fecha_fin_semana,
        total_cupones, monto_total_semana, monto_parcial_semana,
        cupones_usados, cupones_pendientes
    )
    SELECT 
        semana_info.año,
        semana_info.mes,
        semana_info.semana_mes,
        semana_info.fecha_inicio,
        semana_info.fecha_fin,
        COUNT(*) as total_cupones,
        SUM(monto_total) as monto_total_semana,
        SUM(monto_parcial) as monto_parcial_semana,
        COUNT(CASE WHEN estado = 'usado' THEN 1 END) as cupones_usados,
        COUNT(CASE WHEN estado = 'nuevo' THEN 1 END) as cupones_pendientes
    FROM cupones
    WHERE DATE(created_at) >= semana_info.fecha_inicio 
      AND DATE(created_at) <= semana_info.fecha_fin
    GROUP BY semana_info.año, semana_info.mes, semana_info.semana_mes
    ON CONFLICT (año, mes, semana_mes) 
    DO UPDATE SET
        total_cupones = EXCLUDED.total_cupones,
        monto_total_semana = EXCLUDED.monto_total_semana,
        monto_parcial_semana = EXCLUDED.monto_parcial_semana,
        cupones_usados = EXCLUDED.cupones_usados,
        cupones_pendientes = EXCLUDED.cupones_pendientes,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;


ALTER FUNCTION public.procesar_semana_actual() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agencias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agencias (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.agencias OWNER TO postgres;

--
-- Name: agencias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agencias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.agencias_id_seq OWNER TO postgres;

--
-- Name: agencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agencias_id_seq OWNED BY public.agencias.id;


--
-- Name: cupones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cupones (
    id integer NOT NULL,
    codigo_alfanumerico character varying(6) NOT NULL,
    nombre character varying(255) NOT NULL,
    apellido character varying(255) NOT NULL,
    vendedor character varying(255),
    dni_pasaporte character varying(50) NOT NULL,
    fecha_visita date NOT NULL,
    agencia_id integer,
    deposito character varying(20) NOT NULL,
    monto_total numeric(10,2) NOT NULL,
    monto_parcial numeric(10,2) DEFAULT 0.00,
    actividades_tour text[] DEFAULT '{}'::text[],
    actividades_extras text[] DEFAULT '{}'::text[],
    telefono character varying(20),
    telefono_vendedor character varying(20),
    estado character varying(20) DEFAULT 'nuevo'::character varying,
    fecha_uso timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    empleado_id integer
);


ALTER TABLE public.cupones OWNER TO postgres;

--
-- Name: cupones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cupones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cupones_id_seq OWNER TO postgres;

--
-- Name: cupones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cupones_id_seq OWNED BY public.cupones.id;


--
-- Name: resumen_semanas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resumen_semanas (
    id integer NOT NULL,
    "año" integer NOT NULL,
    mes integer NOT NULL,
    semana_mes integer NOT NULL,
    fecha_inicio_semana date NOT NULL,
    fecha_fin_semana date NOT NULL,
    total_cupones integer DEFAULT 0,
    monto_total_semana numeric(10,2) DEFAULT 0.00,
    monto_parcial_semana numeric(10,2) DEFAULT 0.00,
    cupones_usados integer DEFAULT 0,
    cupones_pendientes integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.resumen_semanas OWNER TO postgres;

--
-- Name: resumen_semanas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.resumen_semanas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resumen_semanas_id_seq OWNER TO postgres;

--
-- Name: resumen_semanas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.resumen_semanas_id_seq OWNED BY public.resumen_semanas.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    rol character varying(20) NOT NULL,
    activo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuarios_rol_check CHECK (((rol)::text = ANY ((ARRAY['empleado'::character varying, 'administrador'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO postgres;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: vista_reportes_semanales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_reportes_semanales AS
 SELECT r.id,
    r."año",
    r.mes,
    r.semana_mes,
    r.fecha_inicio_semana,
    r.fecha_fin_semana,
    r.total_cupones,
    r.monto_total_semana,
    r.monto_parcial_semana,
    r.cupones_usados,
    r.cupones_pendientes,
        CASE
            WHEN (r.cupones_usados > 0) THEN round((((r.cupones_usados)::numeric / (r.total_cupones)::numeric) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS tasa_conversion,
        CASE
            WHEN (r.total_cupones > 0) THEN round((r.monto_total_semana / (r.total_cupones)::numeric), 2)
            ELSE (0)::numeric
        END AS ticket_promedio,
    ((to_char((r.fecha_inicio_semana)::timestamp with time zone, 'DD/MM'::text) || ' - '::text) || to_char((r.fecha_fin_semana)::timestamp with time zone, 'DD/MM'::text)) AS periodo_semana,
        CASE r.mes
            WHEN 1 THEN 'Enero'::text
            WHEN 2 THEN 'Febrero'::text
            WHEN 3 THEN 'Marzo'::text
            WHEN 4 THEN 'Abril'::text
            WHEN 5 THEN 'Mayo'::text
            WHEN 6 THEN 'Junio'::text
            WHEN 7 THEN 'Julio'::text
            WHEN 8 THEN 'Agosto'::text
            WHEN 9 THEN 'Septiembre'::text
            WHEN 10 THEN 'Octubre'::text
            WHEN 11 THEN 'Noviembre'::text
            WHEN 12 THEN 'Diciembre'::text
            ELSE NULL::text
        END AS nombre_mes
   FROM public.resumen_semanas r
  ORDER BY r."año" DESC, r.mes DESC, r.semana_mes DESC;


ALTER TABLE public.vista_reportes_semanales OWNER TO postgres;

--
-- Name: agencias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agencias ALTER COLUMN id SET DEFAULT nextval('public.agencias_id_seq'::regclass);


--
-- Name: cupones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cupones ALTER COLUMN id SET DEFAULT nextval('public.cupones_id_seq'::regclass);


--
-- Name: resumen_semanas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumen_semanas ALTER COLUMN id SET DEFAULT nextval('public.resumen_semanas_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: agencias agencias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agencias
    ADD CONSTRAINT agencias_nombre_key UNIQUE (nombre);


--
-- Name: agencias agencias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agencias
    ADD CONSTRAINT agencias_pkey PRIMARY KEY (id);


--
-- Name: cupones cupones_codigo_alfanumerico_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_codigo_alfanumerico_key UNIQUE (codigo_alfanumerico);


--
-- Name: cupones cupones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_pkey PRIMARY KEY (id);


--
-- Name: resumen_semanas resumen_semanas_año_mes_semana_mes_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumen_semanas
    ADD CONSTRAINT "resumen_semanas_año_mes_semana_mes_key" UNIQUE ("año", mes, semana_mes);


--
-- Name: resumen_semanas resumen_semanas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resumen_semanas
    ADD CONSTRAINT resumen_semanas_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: idx_cupones_empleado_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cupones_empleado_id ON public.cupones USING btree (empleado_id);


--
-- Name: idx_resumen_semanas_año_mes; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "idx_resumen_semanas_año_mes" ON public.resumen_semanas USING btree ("año", mes);


--
-- Name: idx_resumen_semanas_fecha_fin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resumen_semanas_fecha_fin ON public.resumen_semanas USING btree (fecha_fin_semana);


--
-- Name: idx_resumen_semanas_fecha_inicio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resumen_semanas_fecha_inicio ON public.resumen_semanas USING btree (fecha_inicio_semana);


--
-- Name: idx_usuarios_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuarios_email ON public.usuarios USING btree (email);


--
-- Name: idx_usuarios_rol; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuarios_rol ON public.usuarios USING btree (rol);


--
-- Name: usuarios update_usuarios_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: cupones cupones_agencia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_agencia_id_fkey FOREIGN KEY (agencia_id) REFERENCES public.agencias(id);


--
-- Name: cupones cupones_empleado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cupones
    ADD CONSTRAINT cupones_empleado_id_fkey FOREIGN KEY (empleado_id) REFERENCES public.usuarios(id);



