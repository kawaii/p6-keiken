CREATE TABLE public.paradoxum_keiken_users (
    "guild-id" bigint NOT NULL,
    "user-id" bigint NOT NULL,
    "experience-points" numeric DEFAULT 0 NOT NULL,
    "last-updated" timestamp with time zone,
    PRIMARY KEY ("guild-id", "user-id")
);

CREATE TABLE public.paradoxum_keiken_configuration (
    "guild-id" bigint NOT NULL,
    "administrator-role" bigint DEFAULT NULL,
    "noexp-role" bigint,
    "noexp-channels" jsonb,
    "level-roles" jsonb,
    PRIMARY KEY ("guild-id")
);
