/**
 * @description Thin wrapper over Http for testable outbound callouts.
 *              Endpoints use https://example.invalid - a reserved domain
 *              that never resolves - so this demo can never call a real API.
 */
public with sharing class HttpCalloutService {

    public class CalloutResult {
        public Integer statusCode; public String body; public String status;
        public Boolean isSuccess() { return statusCode >= 200 && statusCode < 300; }
    }

    @TestVisible
    private static HttpCalloutMock mockInstance;

    public static CalloutResult get(String url, Map<String, String> headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url); req.setMethod('GET'); req.setTimeout(10000);
        if (headers != null) {
            for (String k : headers.keySet()) { req.setHeader(k, headers.get(k)); }
        }
        return send(req);
    }

    public static CalloutResult post(String url, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url); req.setMethod('POST'); req.setTimeout(10000);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        return send(req);
    }

    private static CalloutResult send(HttpRequest req) {
        HttpResponse res;
        if (Test.isRunningTest() && mockInstance != null) {
            res = mockInstance.respond(req);
        } else {
            res = new Http().send(req);
        }
        CalloutResult out = new CalloutResult();
        out.statusCode = res.getStatusCode();
        out.body = res.getBody();
        out.status = res.getStatus();
        return out;
    }
}
