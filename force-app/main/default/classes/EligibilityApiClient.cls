/**
 * @description Example external-system client: eligibility check against a
 *              fictional API. Demonstrates retry + logging around callouts.
 */
public with sharing class EligibilityApiClient {

    public class EligibilityResult {
        @AuraEnabled public Boolean eligible;
        @AuraEnabled public String reason;
        @AuraEnabled public Integer attempts;
    }

    @TestVisible
    private static final String ENDPOINT = 'https://example.invalid/eligibility/check';

    private RetryPolicy policy = new RetryPolicy(3, 5);

    public EligibilityResult checkEligibility(String memberKey) {
        EligibilityResult out = new EligibilityResult();
        out.eligible = false; out.attempts = 0;

        for (Integer attempt = 1; attempt <= policy.maxAttempts; attempt++) {
            out.attempts = attempt;
            HttpCalloutService.CalloutResult res = HttpCalloutService.post(
                ENDPOINT, JSON.serialize(new Map<String, Object>{ 'memberKey' => memberKey }));

            IntegrationLogger.add(new IntegrationLogger.Entry(
                'EligibilityAPI', 'Outbound', res.isSuccess() ? 'Success' : 'Error',
                res.statusCode, attempt, res.status));
            IntegrationLogger.flush();

            if (res.isSuccess()) {
                Map<String, Object> payload =
                    (Map<String, Object>) JSON.deserializeUntyped(res.body);
                out.eligible = (payload.get('eligible') == true);
                out.reason = (String) payload.get('reason');
                return out;
            }
            if (!policy.shouldRetry(res.statusCode, attempt)) {
                break;
            }
            // In production the delay is honoured by a Queueable re-enqueue;
            // kept synchronous here so the pattern stays readable.
        }
        out.reason = 'Eligibility service unavailable after retries.';
        return out;
    }
}
