# Evidence and severity

Security review quality depends on how candidates are disproved, not how many are collected. Keep candidate state explicit and make each reported priority traceable to product evidence.

## Candidate states

| State | Meaning | Action |
| --- | --- | --- |
| Observation | A pattern, tool result, or missing context caught attention | Identify a possible boundary and consequence |
| Candidate | A plausible attacker influence and impact exist | Trace the complete path and seek controls/exemptions |
| Confirmed | Influence, path, control failure, impact, and scope are supported | Report with calibrated severity and confidence |
| Disproved | A premise is false or an effective control breaks the path | Omit; retain private review notes if useful |
| Unverified | Required runtime, configuration, or ownership evidence is unavailable | Put in coverage/residual uncertainty, not findings |

Do not promote an observation directly to confirmed because a scanner assigns it a severity.

## Build the proof chain

For each candidate, answer in order:

1. **Attacker position** — anonymous internet user, authenticated member, another tenant, privileged insider, malicious package, compromised CI job, hostile local app, stolen/unlocked device, or another specific position.
2. **Controlled influence** — exact parameter, identifier, file, link, package, message, configuration, timing, or workflow step.
3. **Reachability** — route, handler, library, platform, deployment, and feature flag through which it travels.
4. **Boundary expectation** — validation, authorization, isolation, integrity, confidentiality, resource, or provenance property required here.
5. **Control assessment** — where the control should be, what is present, and why it fails under the stated conditions.
6. **Result** — exact data, action, privilege, execution, disruption, release, or privacy outcome.
7. **Blast radius** — one object, one tenant, all users, a build environment, signing identity, or another bounded population.
8. **Detection and recovery** — observable signal, reversibility, revocation, rollback, and persistence.

Any claim that jumps across an unknown call, policy, proxy, platform configuration, or operational control remains unverified.

## Evidence strength

Prefer converging evidence:

- direct data/control flow in the reviewed revision;
- effective resolved configuration, not only a sample file;
- policy or framework behavior pinned to the used version;
- existing negative tests and their actual result;
- a focused safe local reproduction with synthetic data;
- deployment or platform evidence supplied within scope;
- authoritative advisory details matched to the lockfile and used feature.

Weak evidence includes names alone, comments, dead code, example environment files, disabled routes, test-only dependencies, hypothetical infrastructure, search snippets, and scanner summaries without trace data.

### Confidence

Confidence is separate from severity:

- **High confidence** — the reviewed artifacts close the proof chain; little runtime uncertainty remains.
- **Moderate confidence** — the chain is supported but one bounded deployment or platform assumption remains and is stated.
- **Low confidence** — material links are inferred. Continue investigating or move it to residual uncertainty.

Only exceptional cases should be reported at low confidence, such as a committed credential whose validity must not be tested. Make the uncertainty explicit and prioritize safe containment based on the known capability.

## Calibrate severity in context

Start with the concrete impact, then adjust for conditions.

### Increase priority when

- no authentication or ordinary low privilege is required;
- the path crosses users or tenants;
- sensitive data, funds, privileged control, signing/release, or irreversible actions are affected;
- exploitation is reliable, quiet, repeatable, or automatable;
- blast radius is broad or compromise persists;
- detection is weak and revocation/rollback is difficult;
- the exposed system is internet-facing or sits on a highly trusted path.

### Decrease priority when

- meaningful privileges, physical access, rare timing, or multiple independent preconditions are required;
- impact is limited to the attacker's own data or a reversible low-value action;
- a control limits blast radius or persistence but does not fully remove the path;
- the affected feature is disabled in all supported deployments with enforceable configuration;
- detection and recovery substantially reduce realized impact.

Never lower severity solely because a fix seems easy or raise it because a fix seems difficult. Remediation effort is not security impact.

### Avoid multiplying one risk

Group repeated manifestations under one root cause when they share:

- the same missing mandatory policy;
- the same unsafe helper or data-access layer;
- the same secret or build identity;
- the same parser/configuration;
- the same flawed state transition.

Split findings when ownership, remediation, boundary, impact, or release decision differs materially.

## Vet scanner and advisory results

For every result:

1. Record tool/database version, rule or advisory identifier, and scanned revision.
2. Locate the exact resolved artifact or code path.
3. Confirm scope: runtime versus development, client versus server, platform, environment, and build stage.
4. Read the primary rule/advisory and affected conditions.
5. Establish reachability and attacker prerequisites.
6. Search for framework, configuration, network, sandbox, or application controls.
7. Reproduce safely or verify statically when possible.
8. Assign product severity independently from the tool.

Common false-positive sources:

- unreachable transitive dependency;
- patched backport with unchanged version shape;
- vulnerable optional feature not included or invoked;
- source pattern escaped or constrained before the sink;
- secret-like fixture or public identifier;
- development-only endpoint absent from production build;
- platform behavior different from the scanner's assumption;
- generated/minified code reported without source mapping.

A suppression should state why the result is not exploitable in this scope, the evidence, owner, and when the decision expires or must be revisited.

## Choose the report location

Point to the narrowest line that demonstrates the violated boundary, usually:

- the unconstrained object lookup;
- the missing policy invocation;
- the dangerous interpreter call;
- the sensitive serialization/log call;
- the dependency or workflow declaration;
- the unsafe exported component or link configuration;
- the production configuration that enables exposure.

Do not point only to the input source when the defect is at the sink, and do not use a broad file range. If the control is absent, choose the line where it must have been enforced and explain the absence.

## Write an actionable correction outcome

Describe the security invariant to restore:

- bind the object lookup to the authenticated tenant;
- derive writable fields from a server-owned schema;
- preserve parameter separation at the interpreter;
- constrain and revalidate every outbound redirect/destination;
- move the credential to a scoped secret store and rotate/revoke it;
- verify artifact identity before deployment;
- add a negative regression at the trusted boundary.

Avoid prescribing a large rewrite when several designs could restore the invariant. Name required tests and operational work when code alone is insufficient.

## Handle secrets safely

- Never paste a full secret into a finding, command, test, or chat.
- Identify by file/location, type, environment if known, and a short irreversible fingerprint only when needed.
- Do not call an external service to see whether a credential works without explicit authorization.
- If repository evidence shows a likely production-capable credential, recommend immediate revocation/rotation and history/consumer review while clearly stating unverified validity.
- Treat removal from the current tree as insufficient; assess history, caches, artifacts, logs, forks, and downstream systems within scope.

## Separate findings from coverage

Coverage statements answer what the review did and could not do:

- runtime configuration was unavailable;
- iOS behavior was inspected but not exercised on a physical device;
- no production traffic or user data was accessed;
- active testing was outside scope;
- a private package or infrastructure module was not available;
- dependency advisory data was current as of a named date/source.

These are not vulnerabilities. Promote one only when evidence establishes a required control is absent or ineffective.

## Final quality gate

Before returning a finding, verify:

- [ ] It belongs to the requested scope and reviewed revision.
- [ ] The attacker position and preconditions are explicit.
- [ ] The complete path reaches a meaningful boundary.
- [ ] Compensating controls and exemptions were checked.
- [ ] Impact is concrete and blast radius is bounded.
- [ ] Severity follows product impact, not a tool label.
- [ ] Location is tight and useful to the owner.
- [ ] Remediation restores an invariant and includes necessary regression/operational action.
- [ ] Evidence is redacted and non-weaponized.
- [ ] Uncertainty is visible rather than smuggled into certainty.

If any essential box fails, investigate further or omit the finding.
