@isTest
private class IntegrationPatternsTest {

    @isTest
    static void eligibilitySucceedsWithMock() {
        Test.setMock(HttpCalloutMock.class, new IntegrationMocks.SuccessMock());
        Test.startTest();
        EligibilityApiClient.EligibilityResult r =
            new EligibilityApiClient().checkEligibility('DEMO-001');
        Test.stopTest();
        System.assertEquals(true, r.eligible);
        System.assertEquals(1, r.attempts);
    }

    @isTest
    static void retryPolicyDecisions() {
        RetryPolicy p = new RetryPolicy(3, 5);
        System.assertEquals(true, p.shouldRetry(500, 1));
        System.assertEquals(true, p.shouldRetry(429, 2));
        System.assertEquals(false, p.shouldRetry(400, 1), '4xx (except 408/429) must not retry');
        System.assertEquals(false, p.shouldRetry(500, 3), 'No retry after max attempts');
        System.assertEquals(5, p.delaySecondsForAttempt(1));
        System.assertEquals(10, p.delaySecondsForAttempt(2));
        System.assertEquals(20, p.delaySecondsForAttempt(3));
    }

    @isTest
    static void loggerPersistsEntries() {
        Test.startTest();
        IntegrationLogger.add(new IntegrationLogger.Entry(
            'DemoSystem', 'Outbound', 'Success', 200, 1, 'ok'));
        IntegrationLogger.flush();
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @isTest
    static void restCreateAndGet() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(
            '{"externalKey":"DEMO-9","programme":"Mentoring","status":"Open"}');
        RestContext.request = req;

        Test.startTest();
        Id recId = ReferralRestService.createReferral();
        List<Support_Referral__c> rows = ReferralRestService.getReferrals();
        Test.stopTest();

        System.assertNotEquals(null, recId);
        System.assertEquals(1, rows.size());
    }

    @isTest
    static void eligibilityRetriesThenGivesUp() {
        Test.setMock(HttpCalloutMock.class, new IntegrationMocks.ErrorMock(500));
        Test.startTest();
        EligibilityApiClient.EligibilityResult r =
            new EligibilityApiClient().checkEligibility('DEMO-002');
        Test.stopTest();
        System.assertEquals(false, r.eligible);
        System.assertEquals(3, r.attempts, 'Should attempt 3 times before giving up');
    }
}
