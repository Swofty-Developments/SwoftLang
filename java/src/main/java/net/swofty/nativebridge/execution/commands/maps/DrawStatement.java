package net.swofty.nativebridge.execution.commands.maps;

import net.swofty.ScriptError;
import net.swofty.maps.MapCanvas;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * draw pixel/rect/text on &lt;canvas&gt; ... (design 6D): one node for the
 * three draw ops; every execution pushes the buffer to the map holders.
 * Rects are corner-to-corner (x1,y1)-(x2,y2) per the emitter; the
 * loader also accepts width/height form (translated to a far corner).
 */
public class DrawStatement extends AbstractAstNode implements Statement {
    public enum Op {
        PIXEL, RECT, TEXT
    }

    private final Op op;
    private final Expression canvas;
    private final Expression x;
    private final Expression y;
    private final Expression x2;      // RECT far corner
    private final Expression y2;      // RECT far corner
    private final Expression width;   // RECT size form
    private final Expression height;  // RECT size form
    private final Expression text;    // TEXT
    private final Expression color;

    public DrawStatement(Op op, Expression canvas, Expression x, Expression y,
            Expression x2, Expression y2, Expression width, Expression height,
            Expression text, Expression color) {
        this.op = op;
        this.canvas = canvas;
        this.x = x;
        this.y = y;
        this.x2 = x2;
        this.y2 = y2;
        this.width = width;
        this.height = height;
        this.text = text;
        this.color = color;
    }

    public static MapCanvas requireCanvas(Object value, String what) {
        if (value instanceof MapCanvas resolved) {
            return resolved;
        }
        throw new ScriptError(what + " expects a canvas (map_canvas()), got: "
                + Values.displayString(value));
    }

    @Override
    public void execute(ExecutionContext context) {
        MapCanvas target = requireCanvas(context.evaluate(canvas), "draw");
        int px = intOf(context, x, "x");
        int py = intOf(context, y, "y");
        byte colorId = color != null
                ? MapCanvas.resolveColor(context.evaluate(color))
                : MapCanvas.resolveColor("white");

        switch (op) {
            case PIXEL -> target.setPixel(px, py, colorId);
            case RECT -> {
                int left;
                int top;
                int rectWidth;
                int rectHeight;
                if (x2 != null || y2 != null) {
                    int farX = intOf(context, x2, "x2");
                    int farY = intOf(context, y2, "y2");
                    left = Math.min(px, farX);
                    top = Math.min(py, farY);
                    rectWidth = Math.abs(farX - px) + 1;
                    rectHeight = Math.abs(farY - py) + 1;
                } else {
                    left = px;
                    top = py;
                    rectWidth = intOf(context, width, "width");
                    rectHeight = intOf(context, height, "height");
                }
                target.fillRect(left, top, rectWidth, rectHeight, colorId);
            }
            case TEXT -> target.drawText(px, py, context.evaluateString(text), colorId);
        }
        target.pushAll();
    }

    private static int intOf(ExecutionContext context, Expression expression, String what) {
        if (expression == null) {
            throw new ScriptError("draw is missing its '" + what + "' value");
        }
        return Coercions.requireNumber(context.evaluate(expression),
                "the draw " + what).intValue();
    }
}
