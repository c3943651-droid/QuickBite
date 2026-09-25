# Canonical Decisions and Simplifications - QuickBite v1.0

**Version:** 4.1 | **Date:** 2026-09-14 | **Status:** Approved

---

## 1. Purpose

This document is the single source of truth for QuickBite's cross-cutting decisions. Every decision has a stable identifier (`D-NN`), context, decision, rationale, affected documents, and implementation consequences.

### Change rule

1. Update this document first.
2. Update the affected architecture, API, frontend, security, deployment, testing, and user-guide documents.
3. Keep the decision identifier unchanged unless the decision is intentionally retired.
4. Do not implement a future extension merely because it is listed in Section 12.

---

## 2. Decision Index

| ID | Decision | Category |
|---|---|---|
| D-01 | Polling replaces push notifications | Update mechanism |
| D-02 | Keep `dispositivos_push` unused | Data model |
| D-03 | Two delivery-assignment flows | Business logic |
| D-04 | Differentiated user-enumeration behavior | Security |
| D-05 | Critical logic in PostgreSQL triggers | Architecture |
| D-06 | Supabase Storage and Resend as external services | External services |
| D-07 | Signed APK distribution | Mobile distribution |
| D-08 | Simulated payments | Business model |
| D-09 | Single-branch model | Business model |
| D-10 | Synchronize EF Core migrations with Supabase | Operations |
| D-11 | Redundant anti-cold-start cron jobs | Operations |
| D-12 | `AssignmentOrigin` enumeration | Domain model |
| D-13 | Local search-history storage | Scope |

---

## 3. D-01 — Polling Replaces Push Notifications

### Context

Customers need order-status updates, while administrators and delivery people need fresh operational lists. Push notifications would require Firebase configuration, credentials, device registration, and additional failure modes.

### Decision

Use polling as the only real-time update mechanism. Do not implement Firebase Cloud Messaging or any other push service.

| Client | Endpoint | Frequency |
|---|---|---:|
| Customer mobile (RN) app | `GET /orders/{id}/status` | 10 seconds |
| Admin dashboard | `GET /admin/dashboard` | 30 seconds |
| Admin order list | `GET /admin/orders` | 30 seconds |
| Delivery mobile (RN) app | `GET /delivery/available` | 30 seconds |

### Lifecycle rules

- Start when the relevant screen becomes visible.
- Stop when the screen is left.
- Pause while the app or browser is in the background.
- Resume when it returns to the foreground and the screen remains visible.
- Stop permanently when an order reaches `entregado` or `cancelado`.
- Use exponential backoff after errors, with at most three retries.
- Apply endpoint-specific rate limits.

### Consequences

- No device-registration endpoint.
- No `dispositivos_push` service, repository, entity, or DTO.
- Mobile and web clients own polling lifecycle.
- The API exposes read-only, current-state endpoints.
- The UI displays a subtle `Actualizando...` indicator without blocking interaction.

### Rationale

Lower integration complexity, works in emulators, reduces demo risk, and avoids external credentials.

### Affected documents

`00`, `01`, `02`, `04`, `06`, `07`, `07.1`, `08`, `08.1`, `10`, `11`, `12`, `13`.

---

## 4. D-02 — Keep `dispositivos_push` Unused

### Context

The conceptual database model includes a future push-device table, but v1.0 intentionally excludes push notifications.

### Decision

The `dispositivos_push` table remains in the PostgreSQL schema, but:

- It is not mapped by EF Core.
- It is never populated by normal application behavior.
- It has no repository, domain entity, service, or API endpoint.
- No application code references it.

### Consequences

- The table is a reserved extension point only.
- Database migrations must preserve it.
- Tests verify that the push-registration endpoint does not exist.
- Future push work must explicitly revise this decision.

### Rationale

Preserves the conceptual model and avoids an unnecessary migration when push support is eventually considered, while keeping the active codebase focused.

### Affected documents

`00`, `03`, `04`, `06`, `08`, `11`, `12`.

---

## 5. D-03 — Two Delivery-Assignment Flows

### Context

A ready order can be assigned in two ways:

1. A delivery person accepts it from the mobile app.
2. An administrator manually assigns an available delivery person from the admin panel.

Both flows produce the same order and delivery-person state but have different authorization and audit origins.

### Decision

Implement two endpoints that call one shared application-service method:

| Endpoint | Role | Origin |
|---|---|---|
| `POST /delivery/accept/{orderId}` | Repartidor | Auto-acceptance |
| `PATCH /admin/orders/{id}/assign` | Administrador | Assisted assignment |

Shared method signature:

```text
AssignDeliveryPersonAsync(orderId, deliveryPersonId, origin)
```

The method performs these operations in one transaction:

1. Validate order state `listo`.
2. Validate delivery-person state `disponible`.
3. Validate that the delivery person has no active order.
4. Set order state to `en_camino`.
5. Set `repartidor_id`.
6. Set delivery-person state to `ocupado`.
7. Record the assignment audit event.

Authorization is enforced at the controller layer. The shared service does not re-check the role.

### Audit events

- `Auto` → `asignacion_auto`, attributed to the delivery person.
- `Assisted` → `asignacion_asistida`, attributed to the administrator.

### Rationale

One implementation prevents business-rule divergence; the origin remains traceable.

### Affected documents

`00`, `01`, `03`, `04`, `06`, `08.1`, `10`, `12`.

---

## 6. D-04 — Differentiated User-Enumeration Behavior

### Context

Strict anti-enumeration behavior would return indistinguishable responses for existing and non-existing emails. The project makes a deliberate, endpoint-specific trade-off.

### Decision

| Endpoint | Behavior |
|---|---|
| `POST /auth/register` | Reveals an existing email with `409 Conflict`. |
| `POST /auth/forgot-password` | Always returns the same generic success message. |
| `POST /auth/login` | Always returns a generic credential error. |

The registration timing difference is an accepted residual risk because the HTTP status already reveals existence.

### Rationale

Registration feedback improves usability and is common practice; password recovery is the higher-risk enumeration surface and therefore uses a generic response.

### Affected documents

`01`, `04`, `06`, `07.1`, `08.1`, `10`, `12`, `13`.

---

## 7. D-05 — Critical Logic in PostgreSQL Triggers

### Context

Order transitions, stock changes, order numbering, delivery counters, and other integrity rules must remain correct regardless of which client or access path changes data.

### Decision

Keep critical integrity rules in PostgreSQL functions and triggers. Do not duplicate them in C#.

### Rules owned by the database

- Validate order-state transitions and populate timestamps.
- Register order-state history.
- Validate stock before confirmation.
- Deduct stock on confirmation.
- Restore stock on cancellation.
- Increment delivery counters and release delivery people.
- Prevent a delivery person with an active order from becoming available.
- Generate unique order numbers.
- Update timestamps.
- Validate delivery-person role.
- Update cart access timestamps.

### Testing consequence

- C# unit tests exclude trigger logic.
- PostgreSQL integration tests use a real schema in a container.
- Every critical trigger has at least one dedicated integration test.
- Coverage is measured as critical triggers covered / critical triggers total, with a target of 100%.

### Rationale

Guarantees integrity, atomicity, and defense in depth; avoids dead or divergent duplicate logic.

### Affected documents

`02`, `03`, `06`, `10`, `11`, `12`.

---

## 8. D-06 — Supabase Storage and Resend as External Services

### Context

Render's free tier has ephemeral storage, and the system needs durable product images and transactional email.

### Decision

Integrate exactly two external services:

| Service | Purpose |
|---|---|
| Supabase Storage | Product-image storage, optimization, and CDN delivery |
| Resend | Welcome and password-recovery email |

Supabase Storage URLs are stored in `productos.imagen_url`. Resend sending is asynchronous and must not block API responses.

### Consequences

- No local image persistence in the API.
- No Firebase, SendGrid, or payment-gateway dependency.
- Product deletion does not automatically delete the Supabase Storage asset.
- External credentials live only in environment variables/secrets.
- Integration tests use mocks or test accounts.

### Affected documents

`00`, `01`, `02`, `03`, `04`, `06`, `07`, `07.1`, `08`, `08.1`, `10`, `11`, `12`.

---

## 9. D-07 — Signed APK Distribution

### Context

The mobile app (React Native CLI, no Expo) is Android-only and is intended for evaluation and demonstration rather than public store distribution.

### Decision

Distribute a signed release APK directly to evaluators and test users. Do not publish to Google Play.

### Consequences

- Enable release obfuscation.
- Store the signing keystore outside the repository.
- Use semantic versioning for APK releases.
- Keep a versioned copy of the signed APK as an operational artifact.
- The manual explains manual installation.

### Affected documents

`00`, `01`, `07`, `11`, `12`, `13`.

---

## 10. D-08 — Simulated Payments

### Context

A complete checkout demonstration is required, but a real payment integration would add legal, security, and operational complexity.

### Decision

Support two simulated methods:

- Cash on delivery.
- Card (simulated; no card data is collected or processed).

### Consequences

- No payment gateway integration.
- No stored card data.
- Checkout records the selected method and order totals only.
- The UI clearly labels card payment as simulated.

### Affected documents

`00`, `01`, `03`, `04`, `07.1`, `10`, `12`, `13`.

---

## 11. D-09 — Single-Branch Model

### Context

QuickBite could be modeled as a marketplace, multi-branch system, or single-branch restaurant system.

### Decision

QuickBite is a single-branch restaurant order-management system. It is neither a marketplace nor a multi-branch platform.

### Consequences

- No `sucursales` table.
- No `sucursal_id` fields.
- One catalog, one inventory, one configuration set, and one administrator role.
- No branch selector or branch filters in clients.
- Future multi-branch work requires a new model and migration strategy.

### Affected documents

`00`, `01`, `02`, `03`, `04`, `07`, `07.1`, `08`, `08.1`, `10`, `13`.

---

## 12. D-10 — Synchronize EF Core Migrations with Supabase

### Context

Supabase already contains manually created tables, triggers, functions, and views. Applying an EF Core initial migration would attempt to recreate existing objects and fail.

### Decision

Choose one controlled synchronization strategy:

| Option | Description | Recommendation |
|---|---|---|
| Baseline | Create an initial migration without applying it; mark it as already applied in `__EFMigrationsHistory`. | Preferred when EF Core should manage future schema changes. |
| Reverse scaffold | Generate entities and `DbContext` from the existing database; disable migrations initially. | Preferred for a small team with a stable schema. |
| Disable migrations | Apply versioned SQL scripts manually. | Last resort. |

Triggers, functions, and views remain in versioned SQL and are not managed by EF Core.

### Affected documents

`05`, `06`, `11`, `12`.

---

## 13. D-11 — Redundant Anti-Cold-Start Cron Jobs

### Context

Render's free Web Service suspends after 15 minutes of inactivity, causing a 30–60 second cold start.

### Decision

Configure two independent cron jobs against the API health endpoint:

| Service | Frequency | Role |
|---|---:|---|
| Cron-job.org | Every 5 minutes | Primary |
| UptimeRobot | Every 6 minutes, offset | Backup |

### Plan B

1. Wake the API manually five minutes before a demonstration.
2. Use the recorded backup video if the API does not respond.
3. Temporarily purchase a paid Render plan only as a last resort.

### Affected documents

`02`, `10`, `11`, `12`.

---

## 14. D-12 — `AssignmentOrigin` Enumeration

### Context

The shared assignment method is invoked by two endpoints and must record why an assignment occurred.

### Decision

Define:

```text
enum AssignmentOrigin
{
    Auto,
    Assisted
}
```

Mapping:

| Value | Endpoint | Audit action |
|---|---|---|
| `Auto` | `POST /delivery/accept/{orderId}` | `asignacion_auto` |
| `Assisted` | `PATCH /admin/orders/{id}/assign` | `asignacion_asistida` |

The audit `usuario_id` is the authenticated user's ID in both flows.

### Affected documents

`03`, `04`, `06`, `10`, `12`.

---

## 15. D-13 — Local Search-History Storage

### Context

The mobile app needs recent searches, but server persistence would require a new table and endpoints for low-value data.

### Decision

Store only the latest searches locally on the device, with a suggested limit of 10. Do not persist them on the server.

### Rules

- Stored in local device storage.
- Not synchronized between devices.
- User can clear the complete history.
- Logout does not automatically clear it.
- If another account is used on the same device, the old local history may be visible; this is a documented limitation.

### Affected documents

`01`, `04`, `07`, `07.1`, `10`, `12`, `13`.

---

## 16. Summary Matrix

| ID | Decision | Primary impact |
|---|---|---|
| D-01 | Polling | Client update mechanism and rate-limit planning |
| D-02 | Unused push table | ORM and endpoint exclusions |
| D-03 | Two assignment flows | Shared service + differentiated audit |
| D-04 | User enumeration | Auth response behavior |
| D-05 | Database triggers | Integrity and integration-test strategy |
| D-06 | Supabase Storage/Resend | External-service boundaries |
| D-07 | Signed APK | Mobile release process |
| D-08 | Simulated payments | Checkout scope and compliance |
| D-09 | Single branch | Data model and client scope |
| D-10 | Migration synchronization | Database deployment process |
| D-11 | Redundant cron jobs | Availability and demo contingency |
| D-12 | Assignment origin | Audit traceability |
| D-13 | Local search history | Mobile storage and no endpoint |

---

## 17. Future Extensions (Not In Scope)

The following are reference options only. They are not pending work:

- Firebase Cloud Messaging and device registration.
- Firebase Crashlytics.
- Google Play publication.
- Real payment gateways and saved payment methods.
- Multi-branch or marketplace architecture.
- iOS application.
- Multi-language support.
- Loyalty, promotions, coupons, AI recommendations.
- Map-based live tracking and customer-driver chat.
- POS/ERP integration.
- PDF report export.
- A dedicated right-to-forget endpoint.
- SSL pinning and database row-level security.
- HttpOnly cookies for the admin panel.
- WebSockets or SignalR.
- Onboarding, admin-managed users, favorites, product comparison, and extended access history.

---

## 18. Related Documents

- `docs/05 — Decisiones Canónicas y Simplificaciones.md` — authoritative Spanish source.
- `docs/architecture/system-architecture.md`
- `docs/architecture/database-model.md`
- `docs/api/rest-contract.md`
- `docs/design/ui-ux-system.md`
- `docs/manuals/deployment.md`
- `docs/manuals/testing-qa.md`
- `docs/manuals/user-guide.md`
