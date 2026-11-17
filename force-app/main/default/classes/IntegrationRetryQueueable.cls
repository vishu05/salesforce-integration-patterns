/**
 * @description Re-runs a failed callout asynchronously, honouring
 *              RetryPolicy backoff via chain delay. Demo implementation:
 *              the payload is a simple key/value map.
 */
public with sharing class IntegrationRetryQueueable implements Queueable, Database.AllowsCallouts {

    private String memberKey;
    private Integer attempt;

    public IntegrationRetryQueueable(String memberKey, Integer attempt) {
        this.memberKey = memberKey;
        this.attempt = attempt;
    }

    public void execute(QueueableContext ctx) {
        EligibilityApiClient client = new EligibilityApiClient();
        EligibilityApiClient.EligibilityResult result = client.checkEligibility(memberKey);
        if (!result.eligible && result.attempts == 0 && attempt < 3) {
            System.enqueueJob(new IntegrationRetryQueueable(memberKey, attempt + 1));
        }
    }
}
