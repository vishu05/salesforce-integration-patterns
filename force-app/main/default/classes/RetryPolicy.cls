/**
 * @description Exponential-backoff retry policy (pure logic, fully testable).
 */
public class RetryPolicy {
    public Integer maxAttempts { get; private set; }
    public Integer baseDelaySeconds { get; private set; }

    public RetryPolicy() { this(3, 5); }
    public RetryPolicy(Integer maxAttempts, Integer baseDelaySeconds) {
        this.maxAttempts = Math.max(1, maxAttempts);
        this.baseDelaySeconds = Math.max(0, baseDelaySeconds);
    }

    public Boolean shouldRetry(Integer statusCode, Integer attempt) {
        if (attempt >= maxAttempts) { return false; }
        return statusCode == 0 || statusCode == 408 || statusCode == 429
            || (statusCode >= 500 && statusCode < 600);
    }

    /** Delay before the NEXT attempt: base, base*2, base*4 ... */
    public Integer delaySecondsForAttempt(Integer attempt) {
        Integer multiplier = 1;
        for (Integer i = 1; i < attempt; i++) { multiplier *= 2; }
        return baseDelaySeconds * multiplier;
    }
}
