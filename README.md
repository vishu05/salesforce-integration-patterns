# Salesforce Integration Patterns

Reusable Apex integration patterns - outbound callouts with retry and
logging, testable HTTP services, and an inbound REST example - demonstrated
against **fictional** endpoints only.

> Portfolio demo. All endpoints use `https://example.invalid` (a reserved
> domain that never resolves), all payloads are invented, and no code or
> configuration from any employer or client is included.

## Patterns Demonstrated

| Pattern | Where | Idea |
|---|---|---|
| Centralised callout service | `HttpCalloutService` | One place for timeouts/headers; swappable in tests |
| Retry with backoff | `RetryPolicy` | Retry 408/429/5xx only, exponential delays (5s, 10s, 20s...), pure testable logic |
| Integration logging | `IntegrationLogger` + `Integration_Log__c` | Buffered, bulk-safe, append-only log of every attempt |
| Async retry | `IntegrationRetryQueueable` | Re-run failed callouts off the user transaction |
| Callout mocking | `IntegrationMocks` | `HttpCalloutMock` success/error doubles - no real HTTP in tests |
| Inbound REST | `ReferralRestService` | `@RestResource` POST/GET with validation + logging |

## Call Flow (outbound)

```
EligibilityApiClient.checkEligibility(memberKey)
  -> HttpCalloutService.post(example.invalid/eligibility/check)
  -> IntegrationLogger.add(...) + flush()      (every attempt logged)
  -> RetryPolicy.shouldRetry(status, attempt)? -> retry or return
```

## Design Notes

- **Retry only what can heal.** 400/401/403 fail fast; 408, 429 and 5xx retry.
- **Logging never breaks business logic.** Log inserts use
  `Database.insert(rows, false)` and are buffered until `flush()`.
- **Testability first.** Retry decisions are pure functions; HTTP is hidden
  behind `HttpCalloutService` + `HttpCalloutMock`, so tests assert attempt
  counts without any network.
- **Security note:** in a real org the REST resource would sit behind a
  connected app / named credential, enforce CRUD/FLS, and validate payloads
  strictly. Endpoints here intentionally point at `example.invalid`.

## Objects

- `Integration_Log__c` - System, Direction, Status, Status Code, Attempt, Message
- `Support_Referral__c` - minimal fictional record used by the REST demo

## Getting Started

```bash
sf org login web --alias demo
sf project deploy start --target-org demo
sf apex run test --test-level RunLocalTests --target-org demo
```

Try it in Anonymous Apex:

```apex
Test.setMock(HttpCalloutMock.class, new IntegrationMocks.SuccessMock());
System.debug(new EligibilityApiClient().checkEligibility('DEMO-001'));
```

(in a scratch/dev org, run the mock line from a test context.)

## Tests

`IntegrationPatternsTest` covers: mocked success, retry-policy decisions,
log persistence, REST create/get, and retry-exhaustion (3 attempts on 500).

## License

MIT - see [LICENSE](LICENSE).
