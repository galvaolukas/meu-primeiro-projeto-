# Security review catalog

Use only the sections touched by the review. Each entry names a candidate, the evidence that can confirm it, and evidence that commonly disproves it. The catalog expands coverage; it does not lower the finding threshold.

## Authentication and recovery

| Candidate | Confirm with | Common exemption or compensating control |
| --- | --- | --- |
| Account enumeration | Distinguishable public response, timing, status, or side effect for existing accounts | Product intentionally exposes membership; response is normalized at the observable boundary |
| Session fixation | Attacker-chosen/pre-auth session remains valid after login or privilege change | Identity system rotates the identifier and invalidates the old session |
| Weak recovery | Recovery grants access through a weaker, replayable, long-lived, or enumerable path | Single-use, short expiry, bound purpose/account, equivalent verification, session response |
| Token confusion | Endpoint accepts wrong issuer, audience, client, token type, or unsigned/unverified claims | Maintained verifier pins all contextual claims before authorization |
| Missing step-up | Existing low-assurance session can perform an explicitly high-impact operation contrary to product policy | Risk has been accepted or provider enforces recent/high-assurance authentication |

Confirm the complete request-to-identity path. A call site that reads `user.id` may inherit verification from middleware; a decoded token is not necessarily a verified principal.

## Session and browser boundary

Review cookie scope and attributes, token storage, CSRF exposure, session lifetime and revocation, logout, cross-origin policy, caches, and credentialed requests.

Do not report a missing cookie attribute without proving that the cookie exists, carries security authority, and reaches a relevant deployment. Do not report CSRF on an endpoint that cannot be invoked with ambient authority or where a robust origin/token control is enforced.

## Authorization and tenancy

| Candidate | Confirm with | Common exemption or compensating control |
| --- | --- | --- |
| Object-level authorization failure | Lower-trust principal controls identifier; lookup/action lacks effective ownership or policy constraint | Data layer or mandatory policy constrains every path using trusted identity |
| Function-level authorization failure | Protected route/action is reachable without required role/capability | Central route policy is mandatory and correctly maps this operation |
| Tenant escape | Tenant comes from request or object without binding to authenticated membership | Database isolation, scoped repository, or policy engine enforces authenticated tenant |
| Mass assignment | Request body can write a sensitive field that changes authority, ownership, price, status, or tenant | Explicit field selection/schema strips it before persistence and tests cover the boundary |
| Stale privilege | Revoked membership or policy change is not reflected for material action | Short-lived entitlement plus revocation/invalidation meets the stated risk policy |

Check reads and writes, but also lists, search, counts, exports, shares, batch operations, notifications, queues, caches, and support/admin paths. Report one root cause when several endpoints inherit the same defective policy, naming the affected surface.

## Injection and rendering

Trace data to the actual interpreter and encoding context.

- Database query: parameter binding must cover values; dynamic identifiers and query fragments need constrained construction.
- Shell/process: structured argument APIs help, but attacker-controlled executable, environment, working directory, or option-like arguments may remain dangerous.
- HTML/DOM: framework escaping protects text interpolation, not raw HTML, unsafe URL schemes, direct DOM sinks, or third-party rendering paths.
- Templates/expressions: confirm whether user influence selects or supplies executable syntax.
- Logs: confirm the downstream parser or viewer and the consequence of delimiter/control injection.
- Serialization: confirm the format, parser mode, allowed types, and whether attacker-controlled data can instantiate behavior.

A string concatenation is not automatically exploitable. Prove both the interpreter and the missing contextual control.

## Files, archives, and documents

Review upload authorization, server-side size/type/content decisions, filename use, storage location, public serving behavior, executable permissions, transformation, malware/content policy, metadata, and lifecycle.

For archives, prove whether extraction prevents absolute paths, parent traversal, link escape, duplicate collisions, excessive entries, and decompression exhaustion. For processed documents or media, identify the real parser and sandbox/update posture.

Do not rely on client MIME type or extension as proof of content. Conversely, do not claim remote execution merely because uploads exist; show execution or an equivalent harmful serving/processing path.

## Outbound requests, redirects, and webhooks

For server-side requests, follow URL parsing, scheme/host/port policy, DNS resolution, redirects, proxies, credentials, response size/time, and destination network reach. Confirm the deployed network path before claiming access to metadata or internal services.

For redirects, identify the security impact: credential/token leakage, trusted-domain phishing, or policy bypass. A user-controlled navigation destination with no protected data or trust signal may be product behavior rather than a vulnerability.

For webhooks, check raw-payload signature verification, secret selection, constant-time library behavior where relevant, timestamp/nonce/replay handling, destination ownership, idempotency, and authorization of the resulting action.

## Resource and business-logic abuse

Look beyond malformed input:

- repeated purchase, refund, invitation, coupon, recovery, or transfer;
- conflicting concurrent state transitions;
- skipped workflow steps;
- negative, zero, precision, rounding, currency, and boundary values;
- unbounded search, export, pagination, recursion, fan-out, retries, or uploads;
- per-account, tenant, device, destination, and global abuse limits;
- idempotency and rollback after partial failure.

Confirm an invariant and a reachable harmful sequence. “No rate limiter visible” is not enough without a resource or abuse consequence and without checking upstream enforcement.

## Sensitive data and privacy

Trace fields, not labels such as `payload` or `metadata`. Review collection, access, transport, caches, logs, analytics, crash reports, exports, support tools, backups, deletion, and client surfaces.

Confirm whether redaction runs before serialization and transmission. Check identifiers embedded in URLs, push notifications, screenshots, clipboard, browser/mobile storage, backups, and error responses. Distinguish secret material from public identifiers and intentionally public configuration.

## Secrets and cryptography

A credential-looking string must be validated safely before it becomes a finding:

- Is it real rather than a placeholder, fixture, checksum, or public key?
- Is it active or accepted by a reachable system? Never test it against a service without authorization.
- What capability and environment does it grant?
- Is it already excluded from the distributed artifact and history?
- Can repository evidence establish validity without revealing it?

For cryptography, inspect primitive, mode, nonce/IV generation and reuse, key derivation, password hashing, key source and separation, integrity, rotation, and error behavior. Avoid prescribing parameters without matching the maintained library and current platform guidance.

## Mobile platform boundary

Inspect:

- secure versus general local storage and backup behavior;
- deep/universal/app links, intent filters, exported components, and redirect ownership;
- permission timing, denial, revocation, limited grants, and stale cached state;
- screenshots/app-switcher previews and notification content;
- WebViews, injected bridges, navigation allowlists, and mixed content;
- native-module validation and bridge assumptions;
- release signing, build profiles, runtime/version compatibility, and update channels;
- behavior on both supported platforms and physical devices where the claim depends on OS behavior.

Root/jailbreak detection and certificate pinning are risk decisions, not universal findings. Evaluate bypass cost, operational failure modes, and the actual threat model.

## Dependencies and delivery

An advisory becomes a finding only after confirming:

1. the lockfile resolves an affected package/version;
2. the advisory applies to the used component, platform, and configuration;
3. the vulnerable feature is reachable or otherwise affects the artifact/build;
4. an attacker can meet the prerequisites;
5. no effective mitigation exists;
6. impact and upgrade/remediation path are understood.

Also inspect package source changes, lookalike names, install scripts, native/build code, registry configuration, untrusted pull-request workflows, CI token scope, secret interpolation, mutable actions/images, artifact handoff, signing keys, provenance, production debug defaults, network exposure, and rollback.

## Logging, errors, and response

Confirm both omission and leakage against an operational need. High-risk changes and denials may need actor, action, object class, result, time, and correlation without protected content. Errors should not disclose internals to users, but protected diagnostics must remain useful.

Check whether the product can revoke sessions/credentials, rotate secrets, identify affected versions/tenants, preserve relevant evidence, contain a release, and roll back safely. Missing incident machinery is a finding only when tied to a concrete requirement and material inability to respond.

## Standards as coverage maps

Use versioned controls to check breadth and describe verified requirements:

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) for application controls;
- [OWASP MASVS](https://mas.owasp.org/MASVS/) for mobile controls;
- [OWASP Top 10:2025](https://owasp.org/Top10/2025/) for broad application risk awareness;
- [NIST SSDF](https://csrc.nist.gov/projects/ssdf) for development practices.

Do not infer compliance from a source review. Record the exact version and identifiers used.
