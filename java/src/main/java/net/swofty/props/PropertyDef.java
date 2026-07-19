package net.swofty.props;

import java.util.function.BiConsumer;
import java.util.function.BiFunction;
import java.util.function.Function;

/**
 * One row of the property whitelist. getter null = write-only; setter null =
 * read-only or immutable owner; wither non-null on immutable owners and
 * returns a new owner value. Coercion converts the script value (validating,
 * throwing ScriptError on failure) before setter/wither application.
 * passThroughOnly marks wither rows that exist purely so deeper writes can
 * propagate (item.tags.key) while the row itself is not an assignment
 * target (set item.tags to ... is illegal).
 */
public record PropertyDef(
        String name,
        Class<?> owner,
        Function<Object, Object> getter,
        BiConsumer<Object, Object> setter,
        BiFunction<Object, Object, Object> wither,
        Function<Object, Object> coercion,
        ThreadPolicy thread,
        boolean passThroughOnly) {

    @SuppressWarnings("unchecked")
    public static <O, V> PropertyDef of(String name, Class<O> owner,
                                        Function<O, V> getter,
                                        BiConsumer<O, Object> setter,
                                        BiFunction<O, Object, O> wither,
                                        Function<Object, Object> coercion,
                                        ThreadPolicy thread) {
        return new PropertyDef(name, owner,
                getter == null ? null : o -> getter.apply((O) o),
                setter == null ? null : (o, v) -> setter.accept((O) o, v),
                wither == null ? null : (o, v) -> wither.apply((O) o, v),
                coercion,
                thread,
                false);
    }

    /** A wither hop that only propagates deeper writes, never terminal ones. */
    @SuppressWarnings("unchecked")
    public static <O, V> PropertyDef passThroughHop(String name, Class<O> owner,
                                                    Function<O, V> getter,
                                                    BiFunction<O, Object, O> wither,
                                                    Function<Object, Object> coercion) {
        return new PropertyDef(name, owner,
                o -> getter.apply((O) o),
                null,
                (o, v) -> wither.apply((O) o, v),
                coercion,
                ThreadPolicy.ANY,
                true);
    }

    public static <O, V> PropertyDef readOnly(String name, Class<O> owner, Function<O, V> getter) {
        return of(name, owner, getter, null, null, null, ThreadPolicy.ANY);
    }

    public boolean isSettable() {
        return setter != null;
    }

    public boolean isCopyHop() {
        return wither != null;
    }
}
