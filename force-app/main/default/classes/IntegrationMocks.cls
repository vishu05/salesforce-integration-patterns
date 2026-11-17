/**
 * @description HttpCalloutMock implementations for tests. All fictional.
 */
@isTest
public class IntegrationMocks {

    public class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200); res.setStatus('OK');
            res.setBody('{"eligible": true, "reason": "Demo approval"}');
            return res;
        }
    }

    public class ErrorMock implements HttpCalloutMock {
        private Integer code;
        public ErrorMock(Integer code) { this.code = code; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code); res.setStatus('Error');
            res.setBody('{"error": "demo failure"}');
            return res;
        }
    }
}
