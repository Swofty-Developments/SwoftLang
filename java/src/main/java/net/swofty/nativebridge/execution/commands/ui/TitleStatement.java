package net.swofty.nativebridge.execution.commands.ui;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;
import net.swofty.ui.UiRuntime;

/**
 * title "..." [subtitle "..."] to <target> [fade in/stay/fade out];
 * times are ticks, null = vanilla defaults
 */
public class TitleStatement extends AbstractAstNode implements Statement {
    private final Expression title;
    private final Expression subtitle;
    private final Expression target;
    private final Integer fadeInTicks;
    private final Integer stayTicks;
    private final Integer fadeOutTicks;

    public TitleStatement(Expression title, Expression subtitle, Expression target,
                          Integer fadeInTicks, Integer stayTicks, Integer fadeOutTicks) {
        this.title = title;
        this.subtitle = subtitle;
        this.target = target;
        this.fadeInTicks = fadeInTicks;
        this.stayTicks = stayTicks;
        this.fadeOutTicks = fadeOutTicks;
    }

    public Expression getTitle() {
        return title;
    }

    public Expression getSubtitle() {
        return subtitle;
    }

    public Expression getTarget() {
        return target;
    }

    public Integer getFadeInTicks() {
        return fadeInTicks;
    }

    public Integer getStayTicks() {
        return stayTicks;
    }

    public Integer getFadeOutTicks() {
        return fadeOutTicks;
    }

    @Override
    public void execute(ExecutionContext context) {
        UiRuntime.showTitle(context.evaluate(target), context.evaluateString(title),
                subtitle != null ? context.evaluateString(subtitle) : null,
                fadeInTicks, stayTicks, fadeOutTicks);
    }
}
