/**
 * @description Inbound REST example: create/query fictional referrals.
 *              URL: /services/apexrest/referrals/*
 *              Never expose this pattern without authentication, sharing
 *              checks and input validation in a real org (see README).
 */
@RestResource(urlMapping='/referrals/*')
global with sharing class ReferralRestService {

    global class ReferralRequest {
        public String externalKey;
        public String programme;
        public String status;
    }

    @HttpPost
    global static Id createReferral() {
        RestRequest req = RestContext.request;
        ReferralRequest body = (ReferralRequest) JSON.deserialize(
            req.requestBody.toString(), ReferralRequest.class);
        if (String.isBlank(body.externalKey)) {
            throw new IllegalArgumentException('externalKey is required');
        }
        Support_Referral__c rec = new Support_Referral__c(
            Programme__c = body.programme,
            Status__c = String.isBlank(body.status) ? 'Open' : body.status
        );
        insert rec;
        IntegrationLogger.add(new IntegrationLogger.Entry(
            'ReferralREST', 'Inbound', 'Success', 201, 1,
            'Created referral for key ' + body.externalKey));
        IntegrationLogger.flush();
        return rec.Id;
    }

    @HttpGet
    global static List<Support_Referral__c> getReferrals() {
        return [
            SELECT Id, Name, Status__c, Programme__c, Referral_Date__c
            FROM Support_Referral__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
