DROP TABLE IF EXISTS "__EFMigrationsHistory";

CREATE TABLE "__EFMigrationsHistory" (
    migration_id character varying(150) NOT NULL,
    product_version character varying(32) NOT NULL,
    CONSTRAINT pk___ef_migrations_history PRIMARY KEY (migration_id)
);

INSERT INTO "__EFMigrationsHistory" (migration_id, product_version)
VALUES ('20260917053010_InitialSchema', '8.0.11');
