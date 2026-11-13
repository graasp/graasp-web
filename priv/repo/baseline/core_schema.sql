-- Core schema baseline, cut from a production dump by scripts/generate_core_baseline.sh.
-- Executed by the CoreBaseline migration on empty databases only. Do not edit.


CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

CREATE TYPE public.account_type_enum AS ENUM (
    'individual',
    'guest'
);

CREATE TYPE public.action_request_export_format_enum AS ENUM (
    'json',
    'csv'
);

CREATE TYPE public.action_view_enum AS ENUM (
    'builder',
    'player',
    'library',
    'account',
    'analytics',
    'home',
    'auth',
    'unknown'
);

CREATE TYPE public.chat_mention_status_enum AS ENUM (
    'unread',
    'read'
);

CREATE TYPE public.item_export_request_type_enum AS ENUM (
    'raw',
    'graasp'
);

CREATE TYPE public.item_login_schema_status AS ENUM (
    'active',
    'freeze',
    'disabled'
);

CREATE TYPE public.item_login_schema_type AS ENUM (
    'username',
    'username+password',
    'anonymous',
    'anonymous+password'
);

CREATE TYPE public.item_validation_process AS ENUM (
    'bad-words-detection',
    'image-classification'
);

CREATE TYPE public.item_validation_status AS ENUM (
    'success',
    'failure',
    'pending',
    'pending-manual'
);

CREATE TYPE public.item_visibility_type AS ENUM (
    'public',
    'hidden'
);

CREATE TYPE public.permission_enum AS ENUM (
    'read',
    'write',
    'admin'
);

CREATE TYPE public.short_link_platform_enum AS ENUM (
    'builder',
    'player',
    'library'
);

CREATE TYPE public.tag_category_enum AS ENUM (
    'level',
    'discipline',
    'resource-type'
);

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = (NOW() AT TIME ZONE 'utc');
  RETURN NEW;
END;
$$;

CREATE TABLE public.account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_agreements_date timestamp with time zone,
    enable_save_actions boolean DEFAULT true,
    last_authenticated_at timestamp with time zone,
    is_validated boolean DEFAULT false,
    item_login_schema_id uuid,
    extra jsonb DEFAULT '{}'::jsonb NOT NULL,
    type public.account_type_enum DEFAULT 'individual'::public.account_type_enum NOT NULL,
    marketing_emails_subscribed_at timestamp with time zone DEFAULT now(),
    CONSTRAINT "CHK_account_email" CHECK (((email IS NOT NULL) OR ((type)::text <> 'individual'::text))),
    CONSTRAINT "CHK_account_enable_save_actions" CHECK (((enable_save_actions IS NOT NULL) OR ((type)::text <> 'individual'::text))),
    CONSTRAINT "CHK_account_extra" CHECK (((extra IS NOT NULL) OR ((type)::text <> 'individual'::text))),
    CONSTRAINT "CHK_account_is_validated" CHECK (((is_validated IS NOT NULL) OR ((type)::text <> 'individual'::text)))
);

CREATE TABLE public.action (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    account_id uuid,
    item_id uuid,
    extra jsonb DEFAULT '{}'::jsonb NOT NULL,
    geolocation jsonb,
    view public.action_view_enum DEFAULT 'unknown'::public.action_view_enum NOT NULL
);

CREATE TABLE public.action_request_export (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid NOT NULL,
    item_path public.ltree,
    format public.action_request_export_format_enum DEFAULT 'json'::public.action_request_export_format_enum NOT NULL
);

CREATE TABLE public.admins (
    id uuid NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255),
    confirmed_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);

CREATE TABLE public.admins_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    authenticated_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone NOT NULL
);

CREATE TABLE public.app_action (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    item_id uuid NOT NULL,
    type character varying(25) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE public.app_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    item_id uuid NOT NULL,
    type character varying(25) NOT NULL,
    creator_id uuid,
    visibility character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE public.app_setting (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    creator_id uuid,
    name character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE public.apps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(250) NOT NULL,
    description character varying(250) NOT NULL,
    url character varying(250) NOT NULL,
    publisher_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    thumbnail character varying(255) DEFAULT ''::character varying NOT NULL
);

CREATE TABLE public.category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL,
    type character varying NOT NULL
);

CREATE TABLE public.chat_mention (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_id uuid NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status public.chat_mention_status_enum DEFAULT 'unread'::public.chat_mention_status_enum NOT NULL
);

CREATE TABLE public.chat_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    creator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    body character varying(500) NOT NULL
);

CREATE TABLE public.guest_password (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    password character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    guest_id uuid
);

CREATE VIEW public.guests_view AS
 SELECT id,
    name,
    extra,
    type,
    created_at,
    updated_at,
    last_authenticated_at,
    is_validated,
    item_login_schema_id
   FROM public.account
  WHERE ((type = 'guest'::public.account_type_enum) AND (item_login_schema_id IS NOT NULL));

CREATE TABLE public.invitation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    creator_id uuid,
    item_path public.ltree NOT NULL,
    name character varying(100),
    email character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    permission public.permission_enum DEFAULT 'read'::public.permission_enum NOT NULL
);

CREATE TABLE public.item (
    id uuid NOT NULL,
    name character varying(500) NOT NULL,
    type character varying DEFAULT 'folder'::character varying NOT NULL,
    description character varying(5000),
    path public.ltree NOT NULL,
    creator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    lang character varying DEFAULT 'en'::character varying NOT NULL,
    "order" numeric,
    extra jsonb DEFAULT '{}'::jsonb NOT NULL,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL
)
WITH (autovacuum_enabled='on');

CREATE TABLE public.item_category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    creator_id uuid,
    item_path public.ltree NOT NULL,
    category_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.item_export_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid,
    item_id uuid,
    type public.item_export_request_type_enum NOT NULL
);

CREATE TABLE public.item_favorite (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid NOT NULL,
    item_id uuid NOT NULL
);

CREATE TABLE public.item_flag (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying NOT NULL,
    creator_id uuid,
    item_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.item_geolocation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    country character varying(4),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    item_path public.ltree NOT NULL,
    "addressLabel" character varying(300),
    "helperLabel" character varying(300)
);

CREATE TABLE public.item_like (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid NOT NULL,
    item_id uuid NOT NULL
);

CREATE TABLE public.item_login_schema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.item_login_schema_type NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    item_path public.ltree NOT NULL,
    status public.item_login_schema_status DEFAULT 'active'::public.item_login_schema_status NOT NULL
);

CREATE TABLE public.item_membership (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    permission public.permission_enum NOT NULL,
    item_path public.ltree NOT NULL,
    creator_id uuid,
    account_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.item_tag (
    tag_id uuid NOT NULL,
    item_id uuid NOT NULL
);

CREATE TABLE public.item_validation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    process public.item_validation_process NOT NULL,
    status public.item_validation_status NOT NULL,
    result character varying,
    item_validation_group_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.item_validation_group (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.item_validation_review (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_validation_id uuid NOT NULL,
    reviewer_id uuid,
    status character varying NOT NULL,
    reason character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE VIEW public.item_view AS
 SELECT id,
    name,
    type,
    description,
    path,
    creator_id,
    extra,
    settings,
    created_at,
    updated_at,
    lang,
    "order"
   FROM public.item
  WHERE (deleted_at IS NULL);

CREATE TABLE public.item_visibility (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.item_visibility_type NOT NULL,
    item_path public.ltree NOT NULL,
    creator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.maintenance (
    slug character varying(100) NOT NULL,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL
);

CREATE TABLE public.member_password (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    password character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid
);

CREATE TABLE public.member_profile (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bio character varying(5000),
    visibility boolean DEFAULT false NOT NULL,
    "facebookId" character varying(100),
    "linkedinId" character varying(100),
    "twitterId" character varying(100),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid NOT NULL
);

CREATE VIEW public.members_view AS
 SELECT id,
    name,
    email,
    extra,
    type,
    created_at,
    updated_at,
    user_agreements_date,
    enable_save_actions,
    last_authenticated_at,
    is_validated,
    marketing_emails_subscribed_at
   FROM public.account
  WHERE ((type = 'individual'::public.account_type_enum) AND (email IS NOT NULL));

CREATE TABLE public.membership_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    member_id uuid NOT NULL,
    item_id uuid NOT NULL
);

CREATE TABLE public.page_update (
    item_id uuid NOT NULL,
    update bytea NOT NULL,
    clock integer NOT NULL
);

CREATE TABLE public.publication_removal_notices (
    id uuid NOT NULL,
    publication_name character varying(255),
    reason text,
    item_id uuid,
    creator_id uuid,
    created_at timestamp(0) without time zone NOT NULL
);

CREATE TABLE public.published_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid,
    item_path public.ltree NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.publishers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(250) NOT NULL,
    origins text[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.recycled_item_data (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid,
    item_path public.ltree NOT NULL
);

CREATE TABLE public.short_link (
    alias character varying(255) NOT NULL,
    platform public.short_link_platform_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    item_id uuid NOT NULL,
    CONSTRAINT "CHK_200ef28b2168aaf1e36b6896fc" CHECK (((length((alias)::text) >= 6) AND (length((alias)::text) <= 255) AND ((alias)::text ~ '^[a-zA-Z0-9-]*$'::text)))
);

CREATE TABLE public.tag (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    category public.tag_category_enum NOT NULL
);

ALTER TABLE ONLY public.member_profile
    ADD CONSTRAINT "PK_157ca6e25e9cbd657a2302fb12d" PRIMARY KEY (id);

ALTER TABLE ONLY public.action
    ADD CONSTRAINT "PK_2d9db9cf5edfbbae74eb56e3a39" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_like
    ADD CONSTRAINT "PK_3cca97fd246db52b4a34049b6a1" PRIMARY KEY (id);

ALTER TABLE ONLY public.published_items
    ADD CONSTRAINT "PK_3f196048ad22161a430250561f9" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_membership
    ADD CONSTRAINT "PK_4697b5e1247909f5c884cc12ec3" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_favorite
    ADD CONSTRAINT "PK_495675cec4fb09666704e4f610f" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_visibility
    ADD CONSTRAINT "PK_5cff999fc1b42609c37d868dc8a" PRIMARY KEY (id);

ALTER TABLE ONLY public.guest_password
    ADD CONSTRAINT "PK_603c36c6f9e303e1dd847366731" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_geolocation
    ADD CONSTRAINT "PK_86f80fb0e15a1df2526d2f69865" PRIMARY KEY (id);

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT "PK_8e4052373c579afc1471f526760" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_category
    ADD CONSTRAINT "PK_91ba90f150e8804bdaad7b17ff8" PRIMARY KEY (id);

ALTER TABLE ONLY public.short_link
    ADD CONSTRAINT "PK_9adc7fa5e363de1e6bf79195f92" PRIMARY KEY (alias);

ALTER TABLE ONLY public.item_tag
    ADD CONSTRAINT "PK_a04bb2298e37d95233a0c92347e" PRIMARY KEY (tag_id, item_id);

ALTER TABLE ONLY public.membership_request
    ADD CONSTRAINT "PK_ab282071990a6efd6967ec4111f" PRIMARY KEY (id);

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT "PK_beb994737756c0f18a1c1f8669c" PRIMARY KEY (id);

ALTER TABLE ONLY public.item_login_schema
    ADD CONSTRAINT "PK_ccc0ff5b7c575e40d57b48e77b7" PRIMARY KEY (id);

ALTER TABLE ONLY public.item
    ADD CONSTRAINT "PK_ccc0ff5b7c575e40d57b48e77b8" PRIMARY KEY (id);

ALTER TABLE ONLY public.action_request_export
    ADD CONSTRAINT "PK_cce524d4aa89d5a2e8eff55f980" PRIMARY KEY (id);

ALTER TABLE ONLY public.recycled_item_data
    ADD CONSTRAINT "PK_d6f781e5054e98174c35c87c225" PRIMARY KEY (id);

ALTER TABLE ONLY public.account
    ADD CONSTRAINT "PK_dcc0ff5b7c575e40d57b48e77b8" PRIMARY KEY (id);

ALTER TABLE ONLY public.member_password
    ADD CONSTRAINT "PK_ff1a1183c81e78eaaa038f05a35" PRIMARY KEY (id);

ALTER TABLE ONLY public.short_link
    ADD CONSTRAINT "UQ_859a3384cadaa460b84e04e5375" UNIQUE (item_id, platform);

ALTER TABLE ONLY public.account
    ADD CONSTRAINT "UQ_account_name_item_login_schema_id" UNIQUE (name, item_login_schema_id);

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT "UQ_f36adbb7b096ceeb6f3e80ad14c" UNIQUE (name);

ALTER TABLE ONLY public.guest_password
    ADD CONSTRAINT "UQ_guest_password_guest_id" UNIQUE (guest_id);

ALTER TABLE ONLY public.item_tag
    ADD CONSTRAINT "UQ_item_tag" UNIQUE (item_id, tag_id);

ALTER TABLE ONLY public.item_visibility
    ADD CONSTRAINT "UQ_item_visibility_item_type" UNIQUE (item_path, type);

ALTER TABLE ONLY public.maintenance
    ADD CONSTRAINT "UQ_maintenance_slug" PRIMARY KEY (slug);

ALTER TABLE ONLY public.membership_request
    ADD CONSTRAINT "UQ_membership_request_item-member" UNIQUE (item_id, member_id);

ALTER TABLE ONLY public.tag
    ADD CONSTRAINT "UQ_tag_name_category" UNIQUE (name, category);

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_unique UNIQUE (email);

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.admins_tokens
    ADD CONSTRAINT admins_tokens_context_token_index UNIQUE (context, token);

ALTER TABLE ONLY public.admins_tokens
    ADD CONSTRAINT admins_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.app_action
    ADD CONSTRAINT app_action_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.app_data
    ADD CONSTRAINT app_data_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT app_key_key UNIQUE (key);

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT app_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.app_setting
    ADD CONSTRAINT app_setting_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT app_url_key UNIQUE (url);

ALTER TABLE ONLY public.item_category
    ADD CONSTRAINT "category-item" UNIQUE (category_id, item_path);

ALTER TABLE ONLY public.category
    ADD CONSTRAINT "category-name-type" UNIQUE (name, type);

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_mention
    ADD CONSTRAINT chat_mention_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.item_favorite
    ADD CONSTRAINT favorite_key UNIQUE (member_id, item_id);

ALTER TABLE ONLY public.item_like
    ADD CONSTRAINT id UNIQUE (creator_id, item_id);

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT "item-email" UNIQUE (item_path, email);

ALTER TABLE ONLY public.item_flag
    ADD CONSTRAINT "item-flag-creator" UNIQUE (item_id, type, creator_id);

ALTER TABLE ONLY public.item_login_schema
    ADD CONSTRAINT "item-login-schema" UNIQUE (item_path);

ALTER TABLE ONLY public.item_export_request
    ADD CONSTRAINT item_export_request_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.item_flag
    ADD CONSTRAINT item_flag_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.item_geolocation
    ADD CONSTRAINT item_geolocation_unique_item UNIQUE (item_path);

ALTER TABLE ONLY public.item_membership
    ADD CONSTRAINT "item_membership-item-member" UNIQUE (item_path, account_id);

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_path_key1 UNIQUE (path);

ALTER TABLE ONLY public.item_validation_group
    ADD CONSTRAINT item_validation_group_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.item_validation
    ADD CONSTRAINT item_validation_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.item_validation_review
    ADD CONSTRAINT item_validation_review_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.member_password
    ADD CONSTRAINT "member-password" UNIQUE (member_id);

ALTER TABLE ONLY public.member_profile
    ADD CONSTRAINT "member-profile" UNIQUE (member_id);

ALTER TABLE ONLY public.account
    ADD CONSTRAINT member_email_key1 UNIQUE (email);

ALTER TABLE ONLY public.publication_removal_notices
    ADD CONSTRAINT publication_removal_notices_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.published_items
    ADD CONSTRAINT "published-item" UNIQUE (item_path);

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publisher_name_key UNIQUE (name);

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publisher_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY public.recycled_item_data
    ADD CONSTRAINT "recycled-item-data" UNIQUE (item_path);

CREATE INDEX "IDX_1214f6f4d832c402751617361c" ON public.action USING btree (item_id);

CREATE INDEX "IDX_43c8a0471d5e58f99fc9c36b99" ON public.short_link USING btree (item_id);

CREATE INDEX "IDX_5ac5bdde333fca6bbeaf177ef9" ON public.item_membership USING btree (permission);

CREATE INDEX "IDX_6079b3bb63c13f815f7dd8d8a2" ON public.app_data USING btree (type);

CREATE INDEX "IDX_61546c650608c1e68789c64915" ON public.app_setting USING btree (item_id, name);

CREATE INDEX "IDX_91fa43bc5482dc6b00892baf01" ON public.member_profile USING btree (member_id);

CREATE INDEX "IDX_account_type" ON public.account USING btree (type);

CREATE INDEX "IDX_action_account_id" ON public.action USING btree (account_id);

CREATE INDEX "IDX_app_action_account_id" ON public.app_action USING btree (account_id);

CREATE INDEX "IDX_app_action_item_id" ON public.app_action USING btree (item_id);

CREATE INDEX "IDX_app_data_account_id" ON public.app_data USING btree (account_id);

CREATE INDEX "IDX_app_data_item_id" ON public.app_data USING btree (item_id);

CREATE INDEX "IDX_bdc46717fadc2f04f3093e51fd" ON public.item USING btree (creator_id);

CREATE INDEX "IDX_d935785e7ecc015ed3ca048ff0" ON public.item_membership USING btree (item_path);

CREATE INDEX "IDX_gist_item_membership_path" ON public.item_membership USING gist (item_path);

CREATE INDEX "IDX_gist_item_path" ON public.item USING gist (path);

CREATE INDEX "IDX_gist_item_path_deleted_at" ON public.item USING gist (path) WHERE (deleted_at IS NULL);

CREATE INDEX "IDX_gist_item_published_path" ON public.published_items USING gist (item_path);

CREATE INDEX "IDX_gist_item_visibility_path" ON public.item_visibility USING gist (item_path);

CREATE INDEX "IDX_invitation_item_path" ON public.invitation USING gist (item_path);

CREATE INDEX "IDX_item_category_item_path" ON public.item_category USING gist (item_path);

CREATE INDEX "IDX_item_deleted_at" ON public.item USING btree (deleted_at);

CREATE INDEX "IDX_item_like_item" ON public.item_like USING btree (item_id);

CREATE INDEX "IDX_item_membership_account_id" ON public.item_membership USING btree (account_id);

CREATE INDEX "IDX_item_membership_account_id_permission" ON public.item_membership USING btree (account_id, permission);

CREATE INDEX "IDX_item_membership_creator_id" ON public.item_membership USING btree (creator_id);

CREATE INDEX "IDX_item_tag_item" ON public.item_tag USING btree (item_id);

CREATE INDEX "IDX_item_validation_group_item_id" ON public.item_validation_group USING btree (item_id);

CREATE INDEX "IDX_item_validation_item_id" ON public.item_validation USING btree (item_id);

CREATE INDEX "IDX_item_validation_item_validation_group_id" ON public.item_validation USING btree (item_validation_group_id);

CREATE INDEX "IDX_item_validation_review_item_validation_id" ON public.item_validation_review USING btree (item_validation_id);

CREATE INDEX "IDX_page_item_id" ON public.page_update USING btree (item_id);

CREATE INDEX "IDX_recycled_item_data_created_at" ON public.recycled_item_data USING btree (created_at DESC NULLS LAST);

CREATE INDEX "IDX_recycled_item_data_item_path" ON public.recycled_item_data USING gist (item_path);

CREATE INDEX admins_email_index ON public.admins USING btree (email);

CREATE INDEX admins_tokens_user_id_index ON public.admins_tokens USING btree (user_id);

CREATE INDEX publication_removal_notices_item_id_index ON public.publication_removal_notices USING btree (item_id);

ALTER TABLE ONLY public.item_favorite
    ADD CONSTRAINT "FK_10ea93bde287762010695378f94" FOREIGN KEY (item_id) REFERENCES public.item(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.action
    ADD CONSTRAINT "FK_1214f6f4d832c402751617361c0" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_like
    ADD CONSTRAINT "FK_159827eb667d019dc71372d7463" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_tag
    ADD CONSTRAINT "FK_16ab8afb42f763f7cbaa4bff66a" FOREIGN KEY (tag_id) REFERENCES public.tag(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.app_setting
    ADD CONSTRAINT "FK_22d3d051ee6f94932c1373a3d09" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.app_data
    ADD CONSTRAINT "FK_27cb180cb3f372e4cf55302644a" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_tag
    ADD CONSTRAINT "FK_39b492fda03c7ac846afe164b58" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.recycled_item_data
    ADD CONSTRAINT "FK_3e3650ebd5c49843013429d510a" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.short_link
    ADD CONSTRAINT "FK_43c8a0471d5e58f99fc9c36b991" FOREIGN KEY (item_id) REFERENCES public.item(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.item_validation_review
    ADD CONSTRAINT "FK_44bf14fee580ae08702d70e622e" FOREIGN KEY (reviewer_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_like
    ADD CONSTRAINT "FK_4a56eba1ce30dc93f118a51ff26" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_category
    ADD CONSTRAINT "FK_5681d1785eea699e9cae8818fe0" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.item_validation_review
    ADD CONSTRAINT "FK_59fd000835c70c728e525d82950" FOREIGN KEY (item_validation_id) REFERENCES public.item_validation(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_category
    ADD CONSTRAINT "FK_638552fc7d9a2035c2b53182d8a" FOREIGN KEY (category_id) REFERENCES public.category(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_geolocation
    ADD CONSTRAINT "FK_66d4b13df4e7765068c8268d719" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT "FK_71fdcb9038eca1b903102bdfd17" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT "FK_7ad4a490d5b9f79a677827b641c" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.app_data
    ADD CONSTRAINT "FK_8c3e2463c67d9865658941c9e2d" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.member_profile
    ADD CONSTRAINT "FK_91fa43bc5482dc6b00892baf016" FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_category
    ADD CONSTRAINT "FK_9a34a079b5b24f4396462546d26" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_favorite
    ADD CONSTRAINT "FK_a169d350392956511697f7e7d38" FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_validation_group
    ADD CONSTRAINT "FK_a9e83cf5f53c026b774b53d3c60" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.action
    ADD CONSTRAINT "FK_action_account_id" FOREIGN KEY (account_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.app_action
    ADD CONSTRAINT "FK_app_action_account_id" FOREIGN KEY (account_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.app_data
    ADD CONSTRAINT "FK_app_data_account_id" FOREIGN KEY (account_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_flag
    ADD CONSTRAINT "FK_b04d0adf4b73d82537c92fa55ea" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT "FK_b31e627ea7a4787672e265a1579" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.action_request_export
    ADD CONSTRAINT "FK_bc85ef3298df8c7974b33081b47" FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item
    ADD CONSTRAINT "FK_bdc46717fadc2f04f3093e51fd5" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_flag
    ADD CONSTRAINT "FK_bde9b9ab1da1483a71c9b916dd2" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.app_action
    ADD CONSTRAINT "FK_c415fc186dda51fa260d338d776" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_mention
    ADD CONSTRAINT "FK_chat_mention_account_id" FOREIGN KEY (account_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_validation
    ADD CONSTRAINT "FK_d60969d5e478e7c844532ac4e7f" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_mention
    ADD CONSTRAINT "FK_e5199951167b722215127651e7c" FOREIGN KEY (message_id) REFERENCES public.chat_message(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_validation
    ADD CONSTRAINT "FK_e92da280941f666acf87baedc65" FOREIGN KEY (item_validation_group_id) REFERENCES public.item_validation_group(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.app_setting
    ADD CONSTRAINT "FK_f5922b885e2680beab8add96008" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.recycled_item_data
    ADD CONSTRAINT "FK_f8a4db4476e3d81e18de5d63c42" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.action_request_export
    ADD CONSTRAINT "FK_fea823c4374f507a68cf8f926a4" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.guest_password
    ADD CONSTRAINT "FK_guest_password_guest_id" FOREIGN KEY (guest_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT "FK_invitation_item_path" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.item_visibility
    ADD CONSTRAINT "FK_item_visibility_creator" FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_visibility
    ADD CONSTRAINT "FK_item_visibility_item" FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.membership_request
    ADD CONSTRAINT "FK_membership_request_item_id" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.membership_request
    ADD CONSTRAINT "FK_membership_request_member_id" FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.page_update
    ADD CONSTRAINT "FK_page_update_item_id" FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_item_login_schema_id_item_login_schema_id_fk FOREIGN KEY (item_login_schema_id) REFERENCES public.item_login_schema(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admins_tokens
    ADD CONSTRAINT admins_tokens_user_id_admins_id_fk FOREIGN KEY (user_id) REFERENCES public.admins(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_publisher_id_fk FOREIGN KEY (publisher_id) REFERENCES public.publishers(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.chat_mention
    ADD CONSTRAINT chat_mention_account_id_account_id_fk FOREIGN KEY (account_id) REFERENCES public.account(id);

ALTER TABLE ONLY public.chat_mention
    ADD CONSTRAINT chat_mention_message_id_chat_message_id_fk FOREIGN KEY (message_id) REFERENCES public.chat_message(id);

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_creator_id_account_id_fk FOREIGN KEY (creator_id) REFERENCES public.account(id);

ALTER TABLE ONLY public.item_export_request
    ADD CONSTRAINT item_export_request_item_id_item_id_fk FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_export_request
    ADD CONSTRAINT item_export_request_member_id_account_id_fk FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_login_schema
    ADD CONSTRAINT item_login_schema_item_path_item_path_fk FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.item_membership
    ADD CONSTRAINT item_membership_account_id_account_id_fk FOREIGN KEY (account_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.item_membership
    ADD CONSTRAINT item_membership_creator_id_account_id_fk FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.item_membership
    ADD CONSTRAINT item_membership_item_path_item_path_fk FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY public.member_password
    ADD CONSTRAINT member_password_member_id_account_id_fk FOREIGN KEY (member_id) REFERENCES public.account(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.member_profile
    ADD CONSTRAINT member_profile_member_id_account_id_fk FOREIGN KEY (member_id) REFERENCES public.account(id);

ALTER TABLE ONLY public.publication_removal_notices
    ADD CONSTRAINT publication_removal_notices_creator_id_users_id_fk FOREIGN KEY (creator_id) REFERENCES public.admins(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.publication_removal_notices
    ADD CONSTRAINT publication_removal_notices_item_id_item_id_fk FOREIGN KEY (item_id) REFERENCES public.item(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.published_items
    ADD CONSTRAINT published_items_creator_id_account_id_fk FOREIGN KEY (creator_id) REFERENCES public.account(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.published_items
    ADD CONSTRAINT published_items_item_path_item_path_fk FOREIGN KEY (item_path) REFERENCES public.item(path) ON UPDATE CASCADE ON DELETE CASCADE;

