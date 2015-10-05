//
// Flump - Copyright 2013 Flump Authors

package flump.executor {

/**
 * A Future that provides interfaces to succeed or fail directly, or based
 * on the result of Function call.
 */
public class FutureTask extends Future
{
    public function FutureTask (onCompletion :Function=null) {
        super(onCompletion);
    }

    /** Succeed immediately */
    public function succeed (...result) :void {
        // Sigh, where's your explode operator, ActionScript?
        if (result.length == 0) super.onSuccess();
        else super.onSuccess(result[0]);
    }

    /** Fail immediately */
    public function fail (error :Object) :void { super.onFailure(error); }

    /** Returns a callback Function that behaves like #monitor */
    public function monitoredCallback (callback :Function) :Function {
        return function (...args) :void {
            if (isComplete) return;
            callback.apply(this, args);
        };
    }
}
}
