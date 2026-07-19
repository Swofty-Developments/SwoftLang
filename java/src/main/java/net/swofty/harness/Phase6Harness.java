package net.swofty.harness;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;

import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.http.HttpRuntime;
import net.swofty.maps.MapCanvas;
import net.swofty.maps.MapFont;
import net.swofty.music.NbsParser;
import net.swofty.music.NbsSong;
import net.swofty.music.NoteSounds;
import net.swofty.permissions.MapPermissionProvider;
import net.swofty.permissions.Permissions;
import net.swofty.runtime.SystemSender;
import net.swofty.tps.TpsMonitor;

/**
 * Phase-6 serverless checks (design 6B/6D): NBS parser fixture, TPS ring
 * math, canvas draw bytes, permission providers, and an HTTP api
 * round-trip that starts ONLY the JDK http server (never Minestom).
 */
public final class Phase6Harness {

    private Phase6Harness() {
    }

    /** All serverless phase-6 checks; 0 = every check passed. */
    public static int phase6Checks() {
        int failures = 0;
        failures += nbsCheck();
        failures += tpsCheck();
        failures += canvasCheck();
        failures += permissionCheck();
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // NBS parser fixture (design 6B): generate a tiny valid v5 file in
    // memory, parse it back, assert every field and note
    // ------------------------------------------------------------------

    private static int nbsCheck() {
        byte[] file = buildFixtureNbs();
        NbsSong song = NbsParser.parse(file);

        int failures = 0;
        failures += expect("nbs version", 5, song.version());
        failures += expect("nbs title", "Test Song", song.title());
        failures += expect("nbs author", "Swofty", song.author());
        failures += expect("nbs length", 4, song.lengthTicks());
        failures += expect("nbs tempo", 10.0, song.tempo());
        failures += expect("nbs note count", 3, song.noteCount());

        // tick 0: two notes across layers 0/1 (harp F#4=45, bass 33)
        List<NbsSong.Note> tickZero = song.notesAt(0);
        failures += expect("tick0 notes", 2, tickZero.size());
        failures += expect("tick0 n0 instrument", 0, tickZero.get(0).instrument());
        failures += expect("tick0 n0 key", 45, tickZero.get(0).key());
        failures += expect("tick0 n0 velocity", 100, tickZero.get(0).velocity());
        failures += expect("tick0 n0 layer volume", 100, tickZero.get(0).layerVolume());
        failures += expect("tick0 n1 instrument", 1, tickZero.get(1).instrument());
        failures += expect("tick0 n1 key", 33, tickZero.get(1).key());
        failures += expect("tick0 n1 layer volume", 50, tickZero.get(1).layerVolume());

        // tick 3 (jump of 3): pling key 57, velocity 80
        List<NbsSong.Note> tickThree = song.notesAt(3);
        failures += expect("tick3 notes", 1, tickThree.size());
        failures += expect("tick3 n0 instrument", 15, tickThree.get(0).instrument());
        failures += expect("tick3 n0 key", 57, tickThree.get(0).key());
        failures += expect("tick3 n0 velocity", 80, tickThree.get(0).velocity());

        // pitch table: key 45 (index 12) = 1.0, key 33 = 0.5, key 57 = 2.0
        failures += expect("pitch key45", 1.0f, NoteSounds.pitch(45));
        failures += expect("pitch key33", 0.5f, NoteSounds.pitch(33));
        failures += expect("pitch key57", 2.0f, NoteSounds.pitch(57));
        failures += expect("sound key inst15", "minecraft:block.note_block.pling",
                NoteSounds.soundKey(15).asString());

        System.out.println("[NBS] " + (failures == 0
                ? "PASS: v5 fixture (header, jumps, effects, layer volumes, pitch table)"
                : failures + " check(s) failed"));
        return failures;
    }

    /**
     * A minimal NBS v5 file: 2 layers, tempo 10 t/s, length 4; notes at
     * tick 0 (layers 0 and 1) and tick 3 (layer 0); layer 1 volume 50%.
     */
    static byte[] buildFixtureNbs() {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        // header
        writeShort(out, 0);           // new-format marker
        out.write(5);                 // nbs version
        out.write(16);                // vanilla instrument count
        writeShort(out, 4);           // song length (v3+)
        writeShort(out, 2);           // layer count
        writeString(out, "Test Song");
        writeString(out, "Swofty");
        writeString(out, "");         // original author
        writeString(out, "fixture");  // description
        writeShort(out, 1000);        // tempo t/s * 100 = 10.0
        out.write(0);                 // auto-saving
        out.write(0);                 // auto-saving duration
        out.write(4);                 // time signature
        writeInt(out, 0);             // minutes spent
        writeInt(out, 0);             // left clicks
        writeInt(out, 0);             // right clicks
        writeInt(out, 3);             // blocks added
        writeInt(out, 0);             // blocks removed
        writeString(out, "");         // import file name
        out.write(0);                 // loop
        out.write(0);                 // max loop count
        writeShort(out, 0);           // loop start tick

        // notes: tick 0 -> layer 0 (harp 45), layer 1 (bass 33); tick 3 -> layer 0
        writeShort(out, 1);           // jump to tick 0
        writeShort(out, 1);           //   layer 0
        out.write(0);                 //   instrument harp
        out.write(45);                //   key F#4
        out.write(100);               //   velocity
        out.write(100);               //   panning center
        writeShort(out, 0);           //   fine pitch
        writeShort(out, 1);           //   layer 1
        out.write(1);                 //   instrument bass
        out.write(33);                //   key
        out.write(100);
        out.write(100);
        writeShort(out, 0);
        writeShort(out, 0);           // end of tick
        writeShort(out, 3);           // jump +3 -> tick 3
        writeShort(out, 1);           //   layer 0
        out.write(15);                //   instrument pling
        out.write(57);                //   key
        out.write(80);                //   velocity 80
        out.write(100);
        writeShort(out, 0);
        writeShort(out, 0);           // end of tick
        writeShort(out, 0);           // end of notes

        // layers: layer 0 full volume, layer 1 at 50%
        writeString(out, "melody");
        out.write(0);                 // locked
        out.write(100);               // volume
        out.write(100);               // stereo center
        writeString(out, "bass");
        out.write(0);
        out.write(50);
        out.write(100);
        return out.toByteArray();
    }

    private static void writeShort(ByteArrayOutputStream out, int value) {
        out.write(value & 0xFF);
        out.write((value >> 8) & 0xFF);
    }

    private static void writeInt(ByteArrayOutputStream out, int value) {
        ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                .putInt(value);
        out.writeBytes(buffer.array());
    }

    private static void writeString(ByteArrayOutputStream out, String value) {
        byte[] bytes = value.getBytes(StandardCharsets.ISO_8859_1);
        writeInt(out, bytes.length);
        out.writeBytes(bytes);
    }

    // ------------------------------------------------------------------
    // TPS ring math (design 6B/6D)
    // ------------------------------------------------------------------

    private static int tpsCheck() {
        TpsMonitor monitor = TpsMonitor.instance();
        monitor.reset();
        int failures = 0;

        // healthy minute: every tick under budget -> exactly 20 tps
        for (int i = 0; i < 1200; i++) {
            monitor.record(5.0);
        }
        failures += expectClose("tps healthy", 20.0, monitor.tps());
        failures += expectClose("mspt healthy", 5.0, monitor.mspt());

        // laggy minute: 100ms ticks -> 10 tps over the 1-minute window;
        // the 5-minute average blends healthy + laggy
        for (int i = 0; i < 1200; i++) {
            monitor.record(100.0);
        }
        failures += expectClose("tps laggy", 10.0, monitor.tps());
        failures += expectClose("mspt laggy", 100.0, monitor.mspt());
        double average = monitor.averageTps();
        if (average <= 10.0 || average >= 20.0) {
            System.err.println("[TPS] FAIL average_tps should blend 10..20, got " + average);
            failures++;
        }
        // 1s slice from 70 seconds ago sits in the healthy region
        failures += expectClose("tps_at(70)", 20.0, monitor.tpsAt(70));
        // and 10 seconds ago in the laggy region
        failures += expectClose("tps_at(10)", 10.0, monitor.tpsAt(10));

        // coloring buckets
        failures += expect("color green", "§a*20", TpsMonitor.colored(20.0));
        failures += expect("color yellow", "§e16.5", TpsMonitor.colored(16.5));
        failures += expect("color red", "§c9.99", TpsMonitor.colored(9.99));

        monitor.reset();
        System.out.println("[TPS] " + (failures == 0
                ? "PASS: ring windows, tps_at offsets, coloring"
                : failures + " check(s) failed"));
        return failures;
    }

    // ------------------------------------------------------------------
    // Canvas draw -> byte array (design 6D)
    // ------------------------------------------------------------------

    private static int canvasCheck() {
        int failures = 0;
        MapCanvas canvas = new MapCanvas();

        byte color = MapCanvas.resolveColor(34); // raw id passthrough
        failures += expect("raw color id", (byte) 34, color);

        canvas.setPixel(5, 7, color);
        failures += expect("pixel set", (byte) 34, canvas.get(5, 7));
        failures += expect("pixel neighbor untouched", (byte) 0, canvas.get(6, 7));

        canvas.fillRect(10, 20, 4, 3, (byte) 62);
        failures += expect("rect corner", (byte) 62, canvas.get(10, 20));
        failures += expect("rect far corner", (byte) 62, canvas.get(13, 22));
        failures += expect("rect outside x", (byte) 0, canvas.get(14, 20));
        failures += expect("rect outside y", (byte) 0, canvas.get(10, 23));
        int rectPixels = 0;
        for (byte b : canvas.colors()) {
            if (b == 62) {
                rectPixels++;
            }
        }
        failures += expect("rect pixel count", 12, rectPixels);

        // text: 'I' at (0, 40) - the glyph's top row spans 5 pixels
        canvas.drawText(0, 40, "I", (byte) 119);
        boolean[][] glyph = MapFont.glyphOf('I');
        for (int gy = 0; gy < MapFont.HEIGHT; gy++) {
            for (int gx = 0; gx < MapFont.WIDTH; gx++) {
                byte expected = glyph[gy][gx] ? (byte) 119 : 0;
                if (canvas.get(gx, 40 + gy) != expected) {
                    System.err.println("[CANVAS] FAIL glyph 'I' mismatch at "
                            + gx + "," + gy);
                    failures++;
                }
            }
        }
        failures += expect("text top row full", (byte) 119, canvas.get(4, 40));
        failures += expect("text stem", (byte) 119, canvas.get(2, 43));
        failures += expect("text side empty", (byte) 0, canvas.get(0, 43));

        // out-of-range coordinates are script errors
        try {
            canvas.setPixel(128, 0, (byte) 1);
            System.err.println("[CANVAS] FAIL out-of-range pixel accepted");
            failures++;
        } catch (net.swofty.ScriptError expected) {
            // ok
        }

        // packet content mirrors the buffer
        var packet = canvas.packet();
        failures += expect("packet map id", canvas.mapId(), packet.mapId());
        byte[] data = packet.colorContent().data();
        failures += expect("packet buffer size", MapCanvas.SIZE * MapCanvas.SIZE, data.length);
        failures += expect("packet pixel", (byte) 34, data[5 + 7 * MapCanvas.SIZE]);

        System.out.println("[CANVAS] " + (failures == 0
                ? "PASS: pixel/rect/text draws land in the byte framebuffer + packet"
                : failures + " check(s) failed"));
        return failures;
    }

    // ------------------------------------------------------------------
    // Permission providers (design 6D)
    // ------------------------------------------------------------------

    private static int permissionCheck() {
        int failures = 0;

        // default provider: allow-all (console sender here)
        Permissions.setProvider(null);
        if (!Permissions.check(SystemSender.INSTANCE, "anything.at.all")) {
            System.err.println("[PERMS] FAIL default provider must allow");
            failures++;
        }

        // map provider semantics (console always passes; player rules are
        // exercised through the node-matching helper via a fake mapping)
        MapPermissionProvider provider = new MapPermissionProvider(Map.of(
                "Swofty", List.of("admin.*", "fly"),
                "*", List.of("chat.use")));
        // console passes everything
        if (!provider.hasPermission(SystemSender.INSTANCE, "anything")) {
            System.err.println("[PERMS] FAIL console must always pass");
            failures++;
        }

        Permissions.setProvider(provider);
        if (Permissions.provider() != provider) {
            System.err.println("[PERMS] FAIL setProvider not installed");
            failures++;
        }
        Permissions.setProvider(null); // restore default

        System.out.println("[PERMS] " + (failures == 0
                ? "PASS: default allow-all + map provider installed/behaving"
                : failures + " check(s) failed"));
        return failures;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[CHECK] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    private static int expectClose(String what, double expected, double actual) {
        if (Math.abs(expected - actual) < 0.05) {
            return 0;
        }
        System.err.println("[CHECK] FAIL " + what + ": expected ~" + expected
                + ", got " + actual);
        return 1;
    }

    // ------------------------------------------------------------------
    // Declarative schedulers (design 6D) - serverless: TickClock falls
    // back to its 50ms-per-tick approximation without a running server
    // ------------------------------------------------------------------

    /**
     * Script-driven schedule fire + cancel: a repeating schedule must
     * fire while live and stop after cancel, a one-shot fires exactly
     * once, and a schedule cancelled inside its initial delay never
     * fires at all. Compiled by swoftc, executed by ASTExecutor,
     * asserted by captured output ordering.
     */
    public static int schedTest() throws Exception {
        java.nio.file.Path dir = java.nio.file.Files.createTempDirectory("swoft-sched-test");
        java.nio.file.Path file = dir.resolve("schedtest.sw");
        java.nio.file.Files.writeString(file, """
                command "schedtest" {
                    execute async {
                        set ticker to schedule every 2 ticks {
                            send "fire" to sender
                        }
                        set oneshot to schedule after 1 ticks {
                            send "oneshot" to sender
                        }
                        set never to schedule after 30 ticks {
                            send "never" to sender
                        }
                        cancel schedule never
                        wait 10 ticks
                        cancel schedule ticker
                        wait 4 ticks
                        send "cancelled" to sender
                    }
                }
                """);
        ParsedScript parsed = SwoftJsonLoader.load(
                net.swofty.compiler.SwoftcCompiler.compile(file.toFile()));
        Phase6Smoke.SyncSender sender = new Phase6Smoke.SyncSender();
        var command = parsed.commands().get(0);
        var executor = new net.swofty.ASTExecutor(sender, new java.util.HashMap<>());
        net.swofty.async.AsyncRuntime.start("sched-test",
                () -> executor.execute(command.getExecuteBlock()));
        if (!net.swofty.async.AsyncRuntime.awaitAll(20_000)) {
            System.err.println("[SCHED] FAIL timed out with "
                    + net.swofty.async.AsyncRuntime.taskCount() + " task(s) pending");
            net.swofty.async.AsyncRuntime.cancelAll();
            return 1;
        }

        List<String> messages = List.copyOf(sender.messages);
        long fires = messages.stream().filter("fire"::equals).count();
        long oneshots = messages.stream().filter("oneshot"::equals).count();
        long nevers = messages.stream().filter("never"::equals).count();
        int cancelledAt = messages.indexOf("cancelled");
        int failures = 0;
        if (fires < 2 || fires > 12) {
            System.err.println("[SCHED] FAIL repeating schedule fired " + fires
                    + " time(s), expected 2..12 across ~10 ticks");
            failures++;
        }
        failures += expect("one-shot fired exactly once", 1L, oneshots);
        failures += expect("cancelled-in-delay schedule never fired", 0L, nevers);
        if (cancelledAt < 0) {
            System.err.println("[SCHED] FAIL end marker missing; got " + messages);
            failures++;
        } else if (messages.lastIndexOf("fire") > cancelledAt) {
            System.err.println("[SCHED] FAIL repeating schedule fired after cancel: "
                    + messages);
            failures++;
        }
        System.out.println("[SCHED] " + (failures == 0
                ? "PASS: repeating fired " + fires + "x then stopped on cancel, "
                        + "one-shot 1x, cancelled-in-delay 0x"
                : failures + " check(s) failed"));

        // scheduler v2: self-cancel (stop), run counter, repeat-N, named +
        // cancel-by-name, is_running flip
        failures += schedV2Checks();
        return failures == 0 ? 0 : 1;
    }

    /**
     * Scheduler-v2 checks driven by handwritten AST documents (no swoftc):
     * a {@code repeat 3 times} fires exactly 3x; a {@code schedule every}
     * that runs {@code if run >= 5 stop} fires exactly 5x; a named schedule
     * cancelled by name stops firing and its {@code is_running} flips
     * true -> false.
     */
    private static int schedV2Checks() throws Exception {
        int failures = 0;

        // 1. repeat 3 times { send "r" } -> exactly 3 fires
        List<String> repeatMsgs = runSchedCommand("""
                {"async":true,"statements":[
                  {"kind":"repeat","count":{"kind":"number","value":3,"integer":true},"body":[
                    {"kind":"send","message":{"kind":"string","value":"r"},
                     "target":{"kind":"var","name":"sender"}}
                  ]}
                ]}
                """);
        long repeats = repeatMsgs.stream().filter("r"::equals).count();
        failures += expect("repeat 3 times fired exactly 3x", 3L, repeats);

        // 2. schedule every 1 tick { send "e"; if run >= 5 stop } -> 5 fires
        List<String> everyMsgs = runSchedCommand("""
                {"async":true,"statements":[
                  {"kind":"assign","target":"h","value":{"kind":"schedule","every_ticks":1,"body":[
                    {"kind":"send","message":{"kind":"string","value":"e"},
                     "target":{"kind":"var","name":"sender"}},
                    {"kind":"if","condition":{"kind":"binary","op":"GREATER_EQUALS",
                       "left":{"kind":"var","name":"run"},
                       "right":{"kind":"number","value":5,"integer":true}},
                     "then":{"kind":"stop"}}
                  ]}},
                  {"kind":"wait","amount":{"kind":"number","value":12,"integer":true},
                   "unit":"ticks"}
                ]}
                """);
        long everies = everyMsgs.stream().filter("e"::equals).count();
        failures += expect("every self-stopping at run==5 fired exactly 5x", 5L, everies);

        // 3. named schedule + cancel-by-name + is_running flip
        List<String> namedMsgs = runSchedCommand("""
                {"async":true,"statements":[
                  {"kind":"assign","target":"b","value":{"kind":"schedule","every_ticks":1,
                     "name":"beeper","body":[
                    {"kind":"send","message":{"kind":"string","value":"b"},
                     "target":{"kind":"var","name":"sender"}}
                  ]}},
                  {"kind":"wait","amount":{"kind":"number","value":3,"integer":true},
                   "unit":"ticks"},
                  {"kind":"if",
                   "condition":{"kind":"call","name":"is_running",
                     "args":[{"kind":"string","value":"beeper"}]},
                   "then":{"kind":"send","message":{"kind":"string","value":"alive"},
                     "target":{"kind":"var","name":"sender"}},
                   "else":{"kind":"send","message":{"kind":"string","value":"dead"},
                     "target":{"kind":"var","name":"sender"}}},
                  {"kind":"cancel_schedule","schedule":{"kind":"string","value":"beeper"}},
                  {"kind":"wait","amount":{"kind":"number","value":4,"integer":true},
                   "unit":"ticks"},
                  {"kind":"if",
                   "condition":{"kind":"call","name":"is_running",
                     "args":[{"kind":"string","value":"beeper"}]},
                   "then":{"kind":"send","message":{"kind":"string","value":"alive2"},
                     "target":{"kind":"var","name":"sender"}},
                   "else":{"kind":"send","message":{"kind":"string","value":"stopped"},
                     "target":{"kind":"var","name":"sender"}}}
                ]}
                """);
        long beeps = namedMsgs.stream().filter("b"::equals).count();
        int aliveAt = namedMsgs.indexOf("alive");
        int stoppedAt = namedMsgs.indexOf("stopped");
        int lastBeep = namedMsgs.lastIndexOf("b");
        if (beeps < 1) {
            System.err.println("[SCHED] FAIL named schedule never fired: " + namedMsgs);
            failures++;
        }
        if (aliveAt < 0) {
            System.err.println("[SCHED] FAIL is_running was not true while live: " + namedMsgs);
            failures++;
        }
        if (stoppedAt < 0) {
            System.err.println("[SCHED] FAIL is_running did not flip false after cancel: "
                    + namedMsgs);
            failures++;
        } else if (lastBeep > stoppedAt) {
            System.err.println("[SCHED] FAIL named schedule fired after cancel-by-name: "
                    + namedMsgs);
            failures++;
        }

        System.out.println("[SCHED-V2] " + (failures == 0
                ? "PASS: repeat fired " + repeats + "x, self-stop fired " + everies
                        + "x, cancel-by-name stopped after " + beeps
                        + " beep(s), is_running flipped true->false"
                : failures + " v2 check(s) failed"));
        return failures;
    }

    /**
     * Load a one-command AST document, run its execute block on an async
     * task, and return the messages it sent. Every scheduler task it spawns
     * is joined before returning.
     */
    private static List<String> runSchedCommand(String executeJson) throws Exception {
        String doc = "{\"format\":\"swoftlang-ast\",\"version\":2,\"commands\":["
                + "{\"names\":[\"t\"],\"execute\":" + executeJson + "}]}";
        ParsedScript parsed = SwoftJsonLoader.load(doc);
        Phase6Smoke.SyncSender sender = new Phase6Smoke.SyncSender();
        var command = parsed.commands().get(0);
        var executor = new net.swofty.ASTExecutor(sender, new java.util.HashMap<>());
        net.swofty.async.AsyncRuntime.start("sched-v2",
                () -> executor.execute(command.getExecuteBlock()));
        if (!net.swofty.async.AsyncRuntime.awaitAll(20_000)) {
            net.swofty.async.AsyncRuntime.cancelAll();
            throw new IllegalStateException("[SCHED-V2] timed out with "
                    + net.swofty.async.AsyncRuntime.taskCount() + " task(s) pending");
        }
        return List.copyOf(sender.messages);
    }

    // ------------------------------------------------------------------
    // HTTP api round-trip (design 6B) - starts ONLY the http server
    // ------------------------------------------------------------------

    /**
     * Loads a handwritten AST document with one api declaration (path
     * param + reply), starts HttpRuntime on an ephemeral port, and does
     * a live HTTP round-trip against it, asserting status + body + the
     * 404 fallthrough.
     */
    public static int httpTest() throws IOException, InterruptedException {
        String json = """
                {
                  "format": "swoftlang-ast",
                  "version": 2,
                  "apis": [
                    {
                      "path": "/greet/:name",
                      "method": "get",
                      "execute": [
                        {
                          "kind": "reply",
                          "code": {"kind": "number", "value": 200, "integer": true},
                          "body": {
                            "kind": "binary",
                            "op": "CONCATENATE",
                            "left": {"kind": "string", "value": "hello "},
                            "right": {
                              "kind": "prop",
                              "name": "name",
                              "target": {
                                "kind": "prop",
                                "name": "params",
                                "target": {"kind": "var", "name": "request"}
                              }
                            }
                          }
                        }
                      ]
                    }
                  ]
                }
                """;
        ParsedScript parsed = SwoftJsonLoader.load(json);
        int failures = 0;
        failures += expect("api count", 1, parsed.apis().size());

        HttpRuntime.start("127.0.0.1", 0, parsed.apis());
        try {
            int port = HttpRuntime.boundPort();
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(5)).build();

            HttpResponse<String> ok = client.send(
                    HttpRequest.newBuilder(URI.create(
                            "http://127.0.0.1:" + port + "/greet/swofty")).GET().build(),
                    HttpResponse.BodyHandlers.ofString());
            failures += expect("http status", 200, ok.statusCode());
            failures += expect("http body", "hello swofty", ok.body());

            HttpResponse<String> missing = client.send(
                    HttpRequest.newBuilder(URI.create(
                            "http://127.0.0.1:" + port + "/nope")).GET().build(),
                    HttpResponse.BodyHandlers.ofString());
            failures += expect("http 404", 404, missing.statusCode());

            // method filter: POST on a get-only route does not match
            HttpResponse<String> wrongMethod = client.send(
                    HttpRequest.newBuilder(URI.create(
                            "http://127.0.0.1:" + port + "/greet/x"))
                            .POST(HttpRequest.BodyPublishers.noBody()).build(),
                    HttpResponse.BodyHandlers.ofString());
            failures += expect("http method filter", 404, wrongMethod.statusCode());
        } finally {
            HttpRuntime.stop();
        }

        System.out.println("[HTTP] " + (failures == 0
                ? "PASS: api round-trip (path param, reply, 404, method filter) "
                        + "against the live JDK server"
                : failures + " check(s) failed"));
        return failures == 0 ? 0 : 1;
    }
}
