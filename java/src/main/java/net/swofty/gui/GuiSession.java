package net.swofty.gui;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextDecoration;
import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.inventory.InventoryPreClickEvent;
import net.minestom.server.inventory.Inventory;
import net.minestom.server.inventory.InventoryType;
import net.minestom.server.inventory.click.Click;
import net.minestom.server.component.DataComponents;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.timer.Scheduler;
import net.minestom.server.timer.Task;
import net.minestom.server.timer.TaskSchedule;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.TextFormat;
import net.swofty.model.GuiClickHandlerModel;
import net.swofty.model.GuiEditableModel;
import net.swofty.model.GuiModel;
import net.swofty.model.GuiPaginateModel;
import net.swofty.model.GuiSlotModel;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.Coercions;

/**
 * One open gui for one player. Renders the declaration into a Minestom
 * Inventory as a pure function of (state, player), diffs re-renders, cancels
 * every non-editable click, batches editable diffs on the next tick, and
 * owns the per-slot/whole-view refresh timers.
 */
public final class GuiSession {
    public enum CloseReason {
        PLAYER_EXITED,
        SERVER_EXITED,
        REPLACED;

        String key() {
            return name().toLowerCase(Locale.ROOT);
        }
    }

    /**
     * Live state map handed to handlers; any write marks the view dirty
     */
    static final class StateMap extends LinkedHashMap<String, Object> {
        private boolean dirty;

        @Override
        public Object put(String key, Object value) {
            dirty = true;
            return super.put(key, value);
        }

        @Override
        public Object remove(Object key) {
            dirty = true;
            return super.remove(key);
        }

        void putSilent(String key, Object value) {
            super.put(key, value);
        }

        boolean consumeDirty() {
            boolean was = dirty;
            dirty = false;
            return was;
        }
    }

    private final Player player;
    private final GuiModel model;
    private final StateMap state = new StateMap();
    private final Inventory inventory;
    private final int size;
    private final GuiSlotModel[] components;
    private final GuiEditableModel[] editables;
    private final int[] paginateIndex;
    private final boolean hasEditables;
    private final ItemStack[] rendered;
    private final ItemStack[] tracked;
    private final List<Task> timers = new ArrayList<>();
    private Component lastTitle;
    private boolean flushScheduled;
    private boolean closed;

    GuiSession(Player player, GuiModel model, Map<String, Object> initialState) {
        this.player = player;
        this.model = model;
        this.size = model.rows() * 9;
        for (Map.Entry<String, Object> entry : initialState.entrySet()) {
            state.putSilent(entry.getKey(), entry.getValue());
        }

        this.components = new GuiSlotModel[size];
        for (GuiSlotModel component : model.slots()) {
            for (int slot : component.slots()) {
                if (slot >= 0 && slot < size) {
                    components[slot] = component;
                }
            }
        }
        this.editables = new GuiEditableModel[size];
        boolean anyEditable = false;
        for (GuiEditableModel region : model.editable()) {
            for (int slot : region.slots()) {
                if (slot >= 0 && slot < size) {
                    editables[slot] = region;
                    anyEditable = true;
                }
            }
        }
        this.hasEditables = anyEditable;
        this.paginateIndex = new int[size];
        Arrays.fill(paginateIndex, -1);
        if (model.paginate() != null) {
            List<Integer> slots = model.paginate().slots();
            for (int i = 0; i < slots.size(); i++) {
                int slot = slots.get(i);
                if (slot >= 0 && slot < size) {
                    paginateIndex[slot] = i;
                }
            }
        }

        this.rendered = new ItemStack[size];
        this.tracked = new ItemStack[size];
        Arrays.fill(rendered, ItemStack.AIR);
        Arrays.fill(tracked, ItemStack.AIR);

        this.lastTitle = GuiItems.component(exec(Map.of()), model.title());
        this.inventory = new Inventory(
                InventoryType.valueOf("CHEST_" + model.rows() + "_ROW"), lastTitle);
    }

    Inventory inventory() {
        return inventory;
    }

    Player player() {
        return player;
    }

    String modelName() {
        return model.name();
    }

    Map<String, Object> stateCopy() {
        return new LinkedHashMap<>(state);
    }

    void open() {
        render();
        player.openInventory(inventory);
        Scheduler scheduler = MinecraftServer.getSchedulerManager();
        if (model.refreshTicks() != null) {
            timers.add(scheduler.buildTask(this::render)
                    .repeat(TaskSchedule.tick(model.refreshTicks())).schedule());
        }
        for (GuiSlotModel component : model.slots()) {
            if (component.refreshTicks() != null) {
                timers.add(scheduler.buildTask(() -> renderComponentSlots(component))
                        .repeat(TaskSchedule.tick(component.refreshTicks())).schedule());
            }
        }
        if (model.onOpen() != null) {
            dispatch(model.onOpen(), Map.of());
        }
    }

    /**
     * Flush pending editable diffs, cancel timers, fire on_close — mirrors
     * ViewSession.close ordering
     */
    void close(CloseReason reason) {
        if (closed) {
            return;
        }
        flushEditable();
        closed = true;
        timers.forEach(Task::cancel);
        timers.clear();
        if (model.onClose() != null) {
            dispatch(model.onClose(), Map.of("reason", reason.key()));
        }
    }

    void render() {
        if (closed) {
            return;
        }
        Component title = GuiItems.component(exec(Map.of()), model.title());
        if (!title.equals(lastTitle)) {
            inventory.setTitle(title);
            lastTitle = title;
        }

        ItemStack[] desired = new ItemStack[size];
        Arrays.fill(desired, ItemStack.AIR);
        if (model.fill() != null) {
            ItemStack item = evalItem(model.fill());
            Arrays.fill(desired, item);
        }
        if (model.border() != null) {
            ItemStack item = evalItem(model.border());
            for (int col = 0; col < 9; col++) {
                desired[col] = item;
                desired[size - 9 + col] = item;
            }
            for (int row = 1; row < model.rows() - 1; row++) {
                desired[row * 9] = item;
                desired[row * 9 + 8] = item;
            }
        }
        if (model.paginate() != null) {
            renderPaginate(desired);
        }
        for (GuiSlotModel component : model.slots()) {
            for (int slot : component.slots()) {
                if (slot >= 0 && slot < size) {
                    desired[slot] = buildComponentItem(component, slot);
                }
            }
        }

        for (int slot = 0; slot < size; slot++) {
            if (editables[slot] != null) {
                continue;
            }
            if (!desired[slot].equals(rendered[slot])) {
                inventory.setItemStack(slot, desired[slot]);
                rendered[slot] = desired[slot];
            }
        }
    }

    private void renderComponentSlots(GuiSlotModel component) {
        if (closed) {
            return;
        }
        for (int slot : component.slots()) {
            if (slot < 0 || slot >= size || editables[slot] != null) {
                continue;
            }
            ItemStack item = buildComponentItem(component, slot);
            if (!item.equals(rendered[slot])) {
                inventory.setItemStack(slot, item);
                rendered[slot] = item;
            }
        }
    }

    private void renderPaginate(ItemStack[] desired) {
        GuiPaginateModel paginate = model.paginate();
        List<Object> items = sourceItems(paginate);
        int perPage = paginate.slots().size();
        if (perPage == 0) {
            return;
        }
        int totalPages = Math.max(1, (items.size() + perPage - 1) / perPage);
        int page = clampPage(totalPages);
        int start = page * perPage;
        for (int i = 0; i < perPage && start + i < items.size(); i++) {
            int slot = paginate.slots().get(i);
            if (slot < 0 || slot >= size) {
                continue;
            }
            int index = start + i;
            desired[slot] = GuiItems.build(paginate.render(),
                    exec(Map.of("item", items.get(index), "index", index)));
        }
        if (paginate.prevSlot() >= 0 && paginate.prevSlot() < size && page > 0) {
            desired[paginate.prevSlot()] = arrow("Previous Page", page, totalPages);
        }
        if (paginate.nextSlot() >= 0 && paginate.nextSlot() < size && page < totalPages - 1) {
            desired[paginate.nextSlot()] = arrow("Next Page", page + 2, totalPages);
        }
    }

    private ItemStack arrow(String label, int targetPage, int totalPages) {
        return ItemStack.builder(Material.ARROW)
                .set(DataComponents.CUSTOM_NAME, stripItalic(TextFormat.component("<green>" + label)))
                .set(DataComponents.LORE, List.of(stripItalic(
                        TextFormat.component("<gray>Page " + targetPage + " of " + totalPages))))
                .build();
    }

    private static Component stripItalic(Component component) {
        return component.decorationIfAbsent(TextDecoration.ITALIC, TextDecoration.State.FALSE);
    }

    private List<Object> sourceItems(GuiPaginateModel paginate) {
        Object value = exec(Map.of()).evaluateExpression(paginate.source());
        if (value instanceof java.util.Collection<?> collection) {
            return new ArrayList<>(collection);
        }
        return List.of();
    }

    private int clampPage(int totalPages) {
        Object value = state.get("page");
        int page = value instanceof Number number ? number.intValue() : 0;
        page = Math.clamp(page, 0, totalPages - 1);
        state.putSilent("page", page);
        return page;
    }

    private ItemStack buildComponentItem(GuiSlotModel component, int slot) {
        return GuiItems.build(component.item(), exec(Map.of("slot", slot)));
    }

    private ItemStack evalItem(Expression expression) {
        return (ItemStack) Coercions.toItemStack(exec(Map.of()).evaluateExpression(expression));
    }

    /**
     * Non-editable slots are always cancelled; editable slots pass through
     * and queue a next-tick diff. Only primary click types dispatch handlers.
     */
    void onPreClick(InventoryPreClickEvent event) {
        if (closed) {
            return;
        }
        if (event.getInventory() != inventory) {
            // Click in the player's own inventory: allowed only when the gui
            // has editable regions (shift-moves land in editable slots only)
            if (hasEditables) {
                scheduleFlush();
            } else {
                event.setCancelled(true);
            }
            return;
        }
        int slot = event.getSlot();
        if (slot >= 0 && slot < size && editables[slot] != null) {
            scheduleFlush();
            return;
        }
        event.setCancelled(true);
        String filter = filterFor(event.getClick());
        if (filter == null || slot < 0 || slot >= size) {
            return;
        }
        dispatchClick(slot, filter);
    }

    private static String filterFor(Click click) {
        // The click enum became a sealed Click hierarchy; preserve the prior
        // model where middle clicks don't filter and shift left/right are
        // indistinguishable (both map to "shift_left").
        if (click instanceof Click.Left) {
            return "left";
        }
        if (click instanceof Click.Right) {
            return "right";
        }
        if (click instanceof Click.LeftShift || click instanceof Click.RightShift) {
            return "shift_left";
        }
        if (click instanceof Click.Double) {
            return "double";
        }
        return null;
    }

    private void dispatchClick(int slot, String filter) {
        GuiSlotModel component = components[slot];
        if (component != null) {
            ExecuteBlock handler = handlerFor(component, filter);
            if (handler != null) {
                dispatch(handler, Map.of("slot", slot, "click_type", filter));
            }
            return;
        }
        GuiPaginateModel paginate = model.paginate();
        if (paginate != null) {
            if (slot == paginate.prevSlot()) {
                turnPage(-1);
                return;
            }
            if (slot == paginate.nextSlot()) {
                turnPage(1);
                return;
            }
            int position = paginateIndex[slot];
            if (position >= 0) {
                dispatchPaginateClick(paginate, position);
                return;
            }
        }
        if (model.onClickFallback() != null) {
            dispatch(model.onClickFallback(), Map.of("slot", slot, "click_type", filter));
        }
    }

    private ExecuteBlock handlerFor(GuiSlotModel component, String filter) {
        for (GuiClickHandlerModel handler : component.clickHandlers()) {
            if (matches(handler.filter(), filter)) {
                return handler.body();
            }
        }
        return null;
    }

    private static boolean matches(String declared, String actual) {
        if (declared.equals("any") || declared.equals(actual)) {
            return true;
        }
        return actual.equals("shift_left") && declared.equals("shift_right");
    }

    private void dispatchPaginateClick(GuiPaginateModel paginate, int position) {
        if (paginate.onClick() == null) {
            return;
        }
        List<Object> items = sourceItems(paginate);
        int perPage = paginate.slots().size();
        int totalPages = Math.max(1, (items.size() + perPage - 1) / perPage);
        int index = clampPage(totalPages) * perPage + position;
        if (index < items.size()) {
            dispatch(paginate.onClick(), Map.of("item", items.get(index), "index", index));
        }
    }

    private void turnPage(int delta) {
        Object value = state.get("page");
        int page = value instanceof Number number ? number.intValue() : 0;
        state.put("page", Math.max(0, page + delta));
        renderIfDirty();
    }

    private void scheduleFlush() {
        if (flushScheduled) {
            return;
        }
        flushScheduled = true;
        MinecraftServer.getSchedulerManager().scheduleNextTick(() -> {
            flushScheduled = false;
            if (!closed) {
                flushEditable();
            }
        });
    }

    private void flushEditable() {
        for (int slot = 0; slot < size; slot++) {
            if (editables[slot] == null) {
                continue;
            }
            ItemStack now = inventory.getItemStack(slot);
            if (now.equals(tracked[slot])) {
                continue;
            }
            ItemStack old = tracked[slot];
            tracked[slot] = now;
            if (editables[slot].onChange() != null) {
                dispatch(editables[slot].onChange(),
                        Map.of("slot", slot, "old_item", old, "new_item", now));
            }
        }
        renderIfDirty();
    }

    private void dispatch(ExecuteBlock body, Map<String, Object> extras) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("player", player);
        vars.put("state", state);
        vars.putAll(extras);
        try {
            new ASTExecutor(player, vars).execute(body);
        } catch (ScriptError e) {
            System.err.println("Gui '" + model.name() + "' handler failed: " + e);
        }
        renderIfDirty();
    }

    private void renderIfDirty() {
        if (!closed && state.consumeDirty()) {
            render();
        }
    }

    private ASTExecutor exec(Map<String, Object> extras) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("player", player);
        vars.put("state", state);
        vars.putAll(extras);
        return new ASTExecutor(player, vars);
    }
}
