/**
 * @description Central, bulk-safe writer for Integration_Log__c.
 *              Failures to log must never break the business transaction,
 *              so inserts are allOrNone=false and exceptions are swallowed
 *              after a System.debug (documented demo trade-off).
 */
public with sharing class IntegrationLogger {

    public class Entry {
        public String systemName; public String direction;
        public String status; public Integer statusCode;
        public Integer attempt; public String message;
        public Entry(String s, String d, String st, Integer code, Integer a, String m) {
            systemName = s; direction = d; status = st; statusCode = code; attempt = a; message = m;
        }
    }

    private static List<Entry> buffer = new List<Entry>();

    public static void add(Entry e) { buffer.add(e); }
    public static Integer pendingCount() { return buffer.size(); }

    public static void flush() {
        if (buffer.isEmpty()) { return; }
        List<Integration_Log__c> rows = new List<Integration_Log__c>();
        for (Entry e : buffer) {
            rows.add(new Integration_Log__c(
                System_Name__c = e.systemName, Direction__c = e.direction,
                Status__c = e.status, Status_Code__c = e.statusCode,
                Attempt__c = e.attempt,
                Message__c = (e.message == null ? null : e.message.left(2000))
            ));
        }
        buffer.clear();
        Database.insert(rows, false);
    }

    public static void logCallout(String systemName, HttpResponse res, Integer attempt) {
        add(new Entry(systemName, 'Outbound',
            (res.getStatusCode() >= 200 && res.getStatusCode() < 300) ? 'Success' : 'Error',
            res.getStatusCode(), attempt, res.getStatus()));
        flush();
    }
}
