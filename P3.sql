CREATE EXTENSION IF NOT EXISTS cube;

DROP TABLE IF EXISTS dry_beans;
DROP TABLE IF EXISTS dry_beans_staging;

--Crear tabla base sobre el cual cargar los datosd
CREATE TABLE dry_beans_staging (
    id_original INTEGER,
    class TEXT,
    f1 DOUBLE PRECISION,
    f2 DOUBLE PRECISION,
    f3 DOUBLE PRECISION,
    f4 DOUBLE PRECISION,
    f5 DOUBLE PRECISION,
    f6 DOUBLE PRECISION,
    f7 DOUBLE PRECISION,
    f8 DOUBLE PRECISION,
    f9 DOUBLE PRECISION,
    f10 DOUBLE PRECISION,
    f11 DOUBLE PRECISION,
    f12 DOUBLE PRECISION,
    f13 DOUBLE PRECISION,
    f14 DOUBLE PRECISION,
    f15 DOUBLE PRECISION,
    f16 DOUBLE PRECISION
);


--Crear tabla para consultas con cube y vector
CREATE TABLE dry_beans (
    id SERIAL PRIMARY KEY,
    id_original INTEGER,
    class TEXT,
    features_seq cube,
    features_idx cube
);

--Pasar los datos a tabla
INSERT INTO dry_beans (id_original, class, features_seq, features_idx)
SELECT
    id_original,
    class,
    cube(ARRAY[
        f1, f2, f3, f4,
        f5, f6, f7, f8,
        f9, f10, f11, f12,
        f13, f14, f15, f16
    ]) AS features_seq,
    cube(ARRAY[
        f1, f2, f3, f4,
        f5, f6, f7, f8,
        f9, f10, f11, f12,
        f13, f14, f15, f16
    ]) AS features_idx
FROM dry_beans_staging;



--Crear Indice 
CREATE INDEX idx_dry_beans_features_gist
ON dry_beans
USING gist (features_idx);

ANALYZE dry_beans;


--Consultas 

--SIN Indice 

--K = 2
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_seq <-> q.features_seq
LIMIT 2;

--K = 4
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_seq <-> q.features_seq
LIMIT 4;

--K = 8
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_seq <-> q.features_seq
LIMIT 8;

--K = 16
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_seq <-> q.features_seq
LIMIT 16;

--K = 32
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_seq <-> q.features_seq
LIMIT 32;




--CON Indice

--K = 2
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_idx <-> q.features_idx
LIMIT 2;

--K = 4
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_idx <-> q.features_idx
LIMIT 4;

--K = 8
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_idx <-> q.features_idx
LIMIT 8;

--K = 16
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_idx <-> q.features_idx
LIMIT 16;

--K = 32
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id_original = 15
) q
WHERE db.id_original <> 15
ORDER BY db.features_idx <-> q.features_idx
LIMIT 32;



--Replicar el 50% de los datos
INSERT INTO dry_beans (id_original, class, features_seq, features_idx)
SELECT
    id_original,
    class,
    features_seq,
    features_idx
FROM dry_beans
ORDER BY random()
LIMIT (
    SELECT FLOOR(COUNT(*) * 0.5)::INTEGER
    FROM dry_beans
);

SELECT COUNT(*) FROM dry_beans;


----------------------------------------
--CONSULTAS CON DATOS REPLICADOS

--SIN INDICE 

--K = 2
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_seq <-> q.features_seq
LIMIT 2;

--K = 4
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_seq <-> q.features_seq
LIMIT 4;

--K = 8
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_seq <-> q.features_seq
LIMIT 8;

--K = 16
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_seq <-> q.features_seq
LIMIT 16;

--K = 32
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_seq <-> q.features_seq AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_seq
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_seq <-> q.features_seq
LIMIT 32;

--CON INDICE 

--K = 2
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_idx <-> q.features_idx
LIMIT 2;

--K = 4
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_idx <-> q.features_idx
LIMIT 4;

--K = 8
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_idx <-> q.features_idx
LIMIT 8;

--K = 16
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_idx <-> q.features_idx
LIMIT 16;

--K = 32
EXPLAIN ANALYZE
SELECT
    db.id,
    db.id_original,
    db.class,
    db.features_idx <-> q.features_idx AS distancia
FROM dry_beans db
CROSS JOIN (
    SELECT features_idx
    FROM dry_beans
    WHERE id = 10000
) q
WHERE db.id <> 10000
ORDER BY db.features_idx <-> q.features_idx
LIMIT 32;



--Generacion de tablas con data sintetica

DROP TABLE IF EXISTS synthetic_vectors;

CREATE TABLE synthetic_vectors (
    id SERIAL PRIMARY KEY,
    dim INTEGER,
    vector_seq cube,
    vector_idx cube
);

--Se crea hasta 100 por que dio erro con 128 con CUBE
INSERT INTO synthetic_vectors (dim, vector_seq, vector_idx)
SELECT
    d AS dim,
    cube(v) AS vector_seq,
    cube(v) AS vector_idx
FROM generate_series(2, 100) AS d
CROSS JOIN generate_series(1, 5000) AS r
CROSS JOIN LATERAL (
    SELECT array_agg(random()) AS v
    FROM generate_series(1, d)
) AS vector_data;

CREATE INDEX idx_synthetic_vectors_gist
ON synthetic_vectors
USING gist (vector_idx);



--Consultas para dimension 2

--D = 2, sin índice, K = 10
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_seq <-> cube(ARRAY[0.5, 0.5]) AS distancia
FROM synthetic_vectors
WHERE dim = 2
ORDER BY vector_seq <-> cube(ARRAY[0.5, 0.5])
LIMIT 10;

--D = 2, con índice, K = 10
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_idx <-> cube(ARRAY[0.5, 0.5]) AS distancia
FROM synthetic_vectors
WHERE dim = 2
ORDER BY vector_idx <-> cube(ARRAY[0.5, 0.5])
LIMIT 10;

--D = 2, sin índice, K = 40
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_seq <-> cube(ARRAY[0.5, 0.5]) AS distancia
FROM synthetic_vectors
WHERE dim = 2
ORDER BY vector_seq <-> cube(ARRAY[0.5, 0.5])
LIMIT 40;

--D = 2, con índice, K = 40
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_idx <-> cube(ARRAY[0.5, 0.5]) AS distancia
FROM synthetic_vectors
WHERE dim = 2
ORDER BY vector_idx <-> cube(ARRAY[0.5, 0.5])
LIMIT 40;


--D = 100, K = 10, sin índice
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_seq <-> cube(array_fill(0.5::double precision, ARRAY[100])) AS distancia
FROM synthetic_vectors
WHERE dim = 100
ORDER BY vector_seq <-> cube(array_fill(0.5::double precision, ARRAY[100]))
LIMIT 10;


--D = 100, K = 10, con índice GiST
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_idx <-> cube(array_fill(0.5::double precision, ARRAY[100])) AS distancia
FROM synthetic_vectors
WHERE dim = 100
ORDER BY vector_idx <-> cube(array_fill(0.5::double precision, ARRAY[100]))
LIMIT 10;


--D = 100, K = 40, sin índice
EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_seq <-> cube(array_fill(0.5::double precision, ARRAY[100])) AS distancia
FROM synthetic_vectors
WHERE dim = 100
ORDER BY vector_seq <-> cube(array_fill(0.5::double precision, ARRAY[100]))
LIMIT 40;


--D = 100, K = 40, con índice GiST

EXPLAIN ANALYZE
SELECT
    id,
    dim,
    vector_idx <-> cube(array_fill(0.5::double precision, ARRAY[100])) AS distancia
FROM synthetic_vectors
WHERE dim = 100
ORDER BY vector_idx <-> cube(array_fill(0.5::double precision, ARRAY[100]))
LIMIT 40;
