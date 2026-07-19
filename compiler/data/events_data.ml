(* GENERATED from events.json (source of truth) by compiler/data/GenMinestomCatalogs.java
   — see the header of that file for the regeneration command. Do not edit by hand.
   Minestom 2026.07.12-26.2. *)

type gen_event_prop = {
  p_name : string;        (* snake_case property name *)
  p_java_type : string;   (* generic Java type of the getter *)
  p_settable : bool;      (* a matching public setter exists *)
  p_accessor : string;    (* Java accessor method name *)
}

type gen_event = {
  ev_class : string;       (* fully-qualified Java class *)
  ev_short : string;       (* class name minus trailing "Event" *)
  ev_cancellable : bool;
  ev_props : gen_event_prop list;
}

let generated_events : gen_event list = [
  { ev_class = "net.minestom.server.event.book.EditBookEvent";
    ev_short = "EditBook";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "pages"; p_java_type = "java.util.List<java.lang.String>"; p_settable = false; p_accessor = "getPages" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "signed"; p_java_type = "boolean"; p_settable = false; p_accessor = "isSigned" };
      { p_name = "title"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getTitle" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityAttackEvent";
    ev_short = "EntityAttack";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityDamageEvent";
    ev_short = "EntityDamage";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "damage"; p_java_type = "net.minestom.server.entity.damage.Damage"; p_settable = false; p_accessor = "getDamage" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.LivingEntity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "sound"; p_java_type = "net.minestom.server.sound.SoundEvent"; p_settable = true; p_accessor = "getSound" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityDeathEvent";
    ev_short = "EntityDeath";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityDespawnEvent";
    ev_short = "EntityDespawn";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityFireExtinguishEvent";
    ev_short = "EntityFireExtinguish";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "natural"; p_java_type = "boolean"; p_settable = false; p_accessor = "isNatural" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityItemMergeEvent";
    ev_short = "EntityItemMerge";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.ItemEntity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "merged"; p_java_type = "net.minestom.server.entity.ItemEntity"; p_settable = false; p_accessor = "getMerged" };
      { p_name = "result"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = true; p_accessor = "getResult" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityPotionAddEvent";
    ev_short = "EntityPotionAdd";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "potion"; p_java_type = "net.minestom.server.potion.Potion"; p_settable = false; p_accessor = "getPotion" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityPotionRemoveEvent";
    ev_short = "EntityPotionRemove";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "potion"; p_java_type = "net.minestom.server.potion.Potion"; p_settable = false; p_accessor = "getPotion" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntitySetFireEvent";
    ev_short = "EntitySetFire";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "fire_ticks"; p_java_type = "int"; p_settable = true; p_accessor = "getFireTicks" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityShootEvent";
    ev_short = "EntityShoot";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "power"; p_java_type = "double"; p_settable = true; p_accessor = "getPower" };
      { p_name = "projectile"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getProjectile" };
      { p_name = "spread"; p_java_type = "double"; p_settable = true; p_accessor = "getSpread" };
      { p_name = "to"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getTo" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntitySpawnEvent";
    ev_short = "EntitySpawn";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "spawn_instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getSpawnInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityTeleportEvent";
    ev_short = "EntityTeleport";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "new_position"; p_java_type = "net.minestom.server.coordinate.Pos"; p_settable = false; p_accessor = "getNewPosition" };
      { p_name = "relative_flags"; p_java_type = "int"; p_settable = false; p_accessor = "getRelativeFlags" };
      { p_name = "teleport_position"; p_java_type = "net.minestom.server.coordinate.Pos"; p_settable = false; p_accessor = "getTeleportPosition" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityTickEvent";
    ev_short = "EntityTick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.EntityVelocityEvent";
    ev_short = "EntityVelocity";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "velocity"; p_java_type = "net.minestom.server.coordinate.Vec"; p_settable = true; p_accessor = "getVelocity" }
    ] };
  { ev_class = "net.minestom.server.event.entity.projectile.ProjectileCollideWithBlockEvent";
    ev_short = "ProjectileCollideWithBlock";
    ev_cancellable = true;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.entity.projectile.ProjectileCollideWithEntityEvent";
    ev_short = "ProjectileCollideWithEntity";
    ev_cancellable = true;
    ev_props = [
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.entity.projectile.ProjectileUncollideEvent";
    ev_short = "ProjectileUncollide";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.AddEntityToInstanceEvent";
    ev_short = "AddEntityToInstance";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceBlockUpdateEvent";
    ev_short = "InstanceBlockUpdate";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceChunkLoadEvent";
    ev_short = "InstanceChunkLoad";
    ev_cancellable = false;
    ev_props = [
      { p_name = "chunk"; p_java_type = "net.minestom.server.instance.Chunk"; p_settable = false; p_accessor = "getChunk" };
      { p_name = "chunk_x"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkX" };
      { p_name = "chunk_z"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkZ" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceChunkUnloadEvent";
    ev_short = "InstanceChunkUnload";
    ev_cancellable = false;
    ev_props = [
      { p_name = "chunk"; p_java_type = "net.minestom.server.instance.Chunk"; p_settable = false; p_accessor = "getChunk" };
      { p_name = "chunk_x"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkX" };
      { p_name = "chunk_z"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkZ" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceRegisterEvent";
    ev_short = "InstanceRegister";
    ev_cancellable = false;
    ev_props = [
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceSectionInvalidateEvent";
    ev_short = "InstanceSectionInvalidate";
    ev_cancellable = false;
    ev_props = [
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceTickEvent";
    ev_short = "InstanceTick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "duration"; p_java_type = "int"; p_settable = false; p_accessor = "getDuration" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.InstanceUnregisterEvent";
    ev_short = "InstanceUnregister";
    ev_cancellable = false;
    ev_props = [
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.instance.RemoveEntityFromInstanceEvent";
    ev_short = "RemoveEntityFromInstance";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.CreativeInventoryActionEvent";
    ev_short = "CreativeInventoryAction";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "clicked_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = true; p_accessor = "getClickedItem" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "slot"; p_java_type = "int"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryBundleItemSelectEvent";
    ev_short = "InventoryBundleItemSelect";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "selected_item_index"; p_java_type = "int"; p_settable = false; p_accessor = "getSelectedItemIndex" };
      { p_name = "slot"; p_java_type = "int"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryButtonClickEvent";
    ev_short = "InventoryButtonClick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "button_id"; p_java_type = "int"; p_settable = false; p_accessor = "getButtonId" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryClickEvent";
    ev_short = "InventoryClick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "click_type"; p_java_type = "net.minestom.server.inventory.click.ClickType"; p_settable = false; p_accessor = "getClickType" };
      { p_name = "clicked_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getClickedItem" };
      { p_name = "cursor_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getCursorItem" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "slot"; p_java_type = "int"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryCloseEvent";
    ev_short = "InventoryClose";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "from_client"; p_java_type = "boolean"; p_settable = false; p_accessor = "isFromClient" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "new_inventory"; p_java_type = "net.minestom.server.inventory.Inventory"; p_settable = true; p_accessor = "getNewInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryItemChangeEvent";
    ev_short = "InventoryItemChange";
    ev_cancellable = false;
    ev_props = [
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "new_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getNewItem" };
      { p_name = "previous_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getPreviousItem" };
      { p_name = "slot"; p_java_type = "int"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryOpenEvent";
    ev_short = "InventoryOpen";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = true; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.inventory.InventoryPreClickEvent";
    ev_short = "InventoryPreClick";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "click"; p_java_type = "net.minestom.server.inventory.click.Click"; p_settable = true; p_accessor = "getClick" };
      { p_name = "clicked_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getClickedItem" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.AbstractInventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "slot"; p_java_type = "int"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.item.EntityEquipEvent";
    ev_short = "EntityEquip";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "equipped_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = true; p_accessor = "getEquippedItem" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "slot"; p_java_type = "net.minestom.server.entity.EquipmentSlot"; p_settable = false; p_accessor = "getSlot" }
    ] };
  { ev_class = "net.minestom.server.event.item.ItemDropEvent";
    ev_short = "ItemDrop";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.item.PickupExperienceEvent";
    ev_short = "PickupExperience";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "experience_count"; p_java_type = "short"; p_settable = true; p_accessor = "getExperienceCount" };
      { p_name = "experience_orb"; p_java_type = "net.minestom.server.entity.ExperienceOrb"; p_settable = false; p_accessor = "getExperienceOrb" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.item.PickupItemEvent";
    ev_short = "PickupItem";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_entity"; p_java_type = "net.minestom.server.entity.ItemEntity"; p_settable = false; p_accessor = "getItemEntity" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "living_entity"; p_java_type = "net.minestom.server.entity.LivingEntity"; p_settable = false; p_accessor = "getLivingEntity" }
    ] };
  { ev_class = "net.minestom.server.event.item.PlayerBeginItemUseEvent";
    ev_short = "PlayerBeginItemUse";
    ev_cancellable = true;
    ev_props = [
      { p_name = "animation"; p_java_type = "net.minestom.server.item.ItemAnimation"; p_settable = false; p_accessor = "getAnimation" };
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "item_use_duration"; p_java_type = "long"; p_settable = true; p_accessor = "getItemUseDuration" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.item.PlayerCancelItemUseEvent";
    ev_short = "PlayerCancelItemUse";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "riptide_spin_attack"; p_java_type = "boolean"; p_settable = true; p_accessor = "isRiptideSpinAttack" };
      { p_name = "use_duration"; p_java_type = "long"; p_settable = false; p_accessor = "getUseDuration" }
    ] };
  { ev_class = "net.minestom.server.event.item.PlayerFinishItemUseEvent";
    ev_short = "PlayerFinishItemUse";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "riptide_spin_attack"; p_java_type = "boolean"; p_settable = true; p_accessor = "isRiptideSpinAttack" };
      { p_name = "use_duration"; p_java_type = "long"; p_settable = false; p_accessor = "getUseDuration" }
    ] };
  { ev_class = "net.minestom.server.event.player.AdvancementTabEvent";
    ev_short = "AdvancementTab";
    ev_cancellable = false;
    ev_props = [
      { p_name = "action"; p_java_type = "net.minestom.server.advancements.AdvancementAction"; p_settable = false; p_accessor = "getAction" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "tab_id"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getTabId" }
    ] };
  { ev_class = "net.minestom.server.event.player.AsyncPlayerConfigurationEvent";
    ev_short = "AsyncPlayerConfiguration";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "feature_flags"; p_java_type = "java.util.Set<net.minestom.server.FeatureFlag>"; p_settable = false; p_accessor = "getFeatureFlags" };
      { p_name = "first_config"; p_java_type = "boolean"; p_settable = false; p_accessor = "isFirstConfig" };
      { p_name = "hardcore"; p_java_type = "boolean"; p_settable = true; p_accessor = "isHardcore" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "spawning_instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = true; p_accessor = "getSpawningInstance" }
    ] };
  { ev_class = "net.minestom.server.event.player.AsyncPlayerPreLoginEvent";
    ev_short = "AsyncPlayerPreLogin";
    ev_cancellable = false;
    ev_props = [
      { p_name = "connection"; p_java_type = "net.minestom.server.network.player.PlayerConnection"; p_settable = false; p_accessor = "getConnection" };
      { p_name = "game_profile"; p_java_type = "net.minestom.server.network.player.GameProfile"; p_settable = true; p_accessor = "getGameProfile" };
      { p_name = "player_uuid"; p_java_type = "java.util.UUID"; p_settable = false; p_accessor = "getPlayerUuid" };
      { p_name = "username"; p_java_type = "java.lang.String"; p_settable = true; p_accessor = "getUsername" }
    ] };
  { ev_class = "net.minestom.server.event.player.OutgoingTransferEvent";
    ev_short = "OutgoingTransfer";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "host"; p_java_type = "java.lang.String"; p_settable = true; p_accessor = "getHost" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "port"; p_java_type = "int"; p_settable = true; p_accessor = "getPort" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerAnvilInputEvent";
    ev_short = "PlayerAnvilInput";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "input"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getInput" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "inventory"; p_java_type = "net.minestom.server.inventory.Inventory"; p_settable = false; p_accessor = "getInventory" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerBlockBreakEvent";
    ev_short = "PlayerBlockBreak";
    ev_cancellable = true;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_face"; p_java_type = "net.minestom.server.instance.block.BlockFace"; p_settable = false; p_accessor = "getBlockFace" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "result_block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = true; p_accessor = "getResultBlock" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerBlockInteractEvent";
    ev_short = "PlayerBlockInteract";
    ev_cancellable = true;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_face"; p_java_type = "net.minestom.server.instance.block.BlockFace"; p_settable = false; p_accessor = "getBlockFace" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "blocking_item_use"; p_java_type = "boolean"; p_settable = true; p_accessor = "isBlockingItemUse" };
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "cursor_position"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getCursorPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerBlockPlaceEvent";
    ev_short = "PlayerBlockPlace";
    ev_cancellable = true;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = true; p_accessor = "getBlock" };
      { p_name = "block_face"; p_java_type = "net.minestom.server.instance.block.BlockFace"; p_settable = false; p_accessor = "getBlockFace" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "cursor_position"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getCursorPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerCancelDiggingEvent";
    ev_short = "PlayerCancelDigging";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerChangeHeldSlotEvent";
    ev_short = "PlayerChangeHeldSlot";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_in_new_slot"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemInNewSlot" };
      { p_name = "item_in_old_slot"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemInOldSlot" };
      { p_name = "new_slot"; p_java_type = "byte"; p_settable = true; p_accessor = "getNewSlot" };
      { p_name = "old_slot"; p_java_type = "byte"; p_settable = false; p_accessor = "getOldSlot" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerChatEvent";
    ev_short = "PlayerChat";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "formatted_message"; p_java_type = "net.kyori.adventure.text.Component"; p_settable = true; p_accessor = "getFormattedMessage" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "raw_message"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getRawMessage" };
      { p_name = "recipients"; p_java_type = "java.util.Collection<net.minestom.server.entity.Player>"; p_settable = false; p_accessor = "getRecipients" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerChunkLoadEvent";
    ev_short = "PlayerChunkLoad";
    ev_cancellable = false;
    ev_props = [
      { p_name = "chunk_x"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkX" };
      { p_name = "chunk_z"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkZ" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerChunkUnloadEvent";
    ev_short = "PlayerChunkUnload";
    ev_cancellable = false;
    ev_props = [
      { p_name = "chunk_x"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkX" };
      { p_name = "chunk_z"; p_java_type = "int"; p_settable = false; p_accessor = "getChunkZ" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerCommandEvent";
    ev_short = "PlayerCommand";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "command"; p_java_type = "java.lang.String"; p_settable = true; p_accessor = "getCommand" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerConfigCustomClickEvent";
    ev_short = "PlayerConfigCustomClick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "key"; p_java_type = "net.kyori.adventure.key.Key"; p_settable = false; p_accessor = "getKey" };
      { p_name = "payload"; p_java_type = "net.kyori.adventure.nbt.BinaryTag"; p_settable = false; p_accessor = "getPayload" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerCustomClickEvent";
    ev_short = "PlayerCustomClick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "key"; p_java_type = "net.kyori.adventure.key.Key"; p_settable = false; p_accessor = "getKey" };
      { p_name = "payload"; p_java_type = "net.kyori.adventure.nbt.BinaryTag"; p_settable = false; p_accessor = "getPayload" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerDeathEvent";
    ev_short = "PlayerDeath";
    ev_cancellable = false;
    ev_props = [
      { p_name = "chat_message"; p_java_type = "net.kyori.adventure.text.Component"; p_settable = true; p_accessor = "getChatMessage" };
      { p_name = "death_text"; p_java_type = "net.kyori.adventure.text.Component"; p_settable = true; p_accessor = "getDeathText" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerDebugSubscriptionsRequestEvent";
    ev_short = "PlayerDebugSubscriptionsRequest";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "subscriptions"; p_java_type = "java.util.Set<net.minestom.server.network.debug.DebugSubscription<?>>"; p_settable = false; p_accessor = "getSubscriptions" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerDisconnectEvent";
    ev_short = "PlayerDisconnect";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerEditSignEvent";
    ev_short = "PlayerEditSign";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "front_text"; p_java_type = "boolean"; p_settable = false; p_accessor = "isFrontText" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "lines"; p_java_type = "java.util.List<java.lang.String>"; p_settable = false; p_accessor = "getLines" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerEntityInteractEvent";
    ev_short = "PlayerEntityInteract";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "interact_position"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getInteractPosition" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerFinishDiggingEvent";
    ev_short = "PlayerFinishDigging";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = true; p_accessor = "getBlock" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerGameModeChangeEvent";
    ev_short = "PlayerGameModeChange";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "new_game_mode"; p_java_type = "net.minestom.server.entity.GameMode"; p_settable = true; p_accessor = "getNewGameMode" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerGameModeRequestEvent";
    ev_short = "PlayerGameModeRequest";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "requested_game_mode"; p_java_type = "net.minestom.server.entity.GameMode"; p_settable = false; p_accessor = "getRequestedGameMode" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerGameRulesRequestEvent";
    ev_short = "PlayerGameRulesRequest";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerHandAnimationEvent";
    ev_short = "PlayerHandAnimation";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerInputEvent";
    ev_short = "PlayerInput";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "holding_backward_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingBackwardKey" };
      { p_name = "holding_forward_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingForwardKey" };
      { p_name = "holding_jump_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingJumpKey" };
      { p_name = "holding_left_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingLeftKey" };
      { p_name = "holding_right_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingRightKey" };
      { p_name = "holding_shift_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingShiftKey" };
      { p_name = "holding_sprint_key"; p_java_type = "boolean"; p_settable = false; p_accessor = "isHoldingSprintKey" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerLeaveBedEvent";
    ev_short = "PlayerLeaveBed";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerLoadedEvent";
    ev_short = "PlayerLoaded";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerMoveEvent";
    ev_short = "PlayerMove";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "new_position"; p_java_type = "net.minestom.server.coordinate.Pos"; p_settable = true; p_accessor = "getNewPosition" };
      { p_name = "on_ground"; p_java_type = "boolean"; p_settable = false; p_accessor = "isOnGround" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerPacketEvent";
    ev_short = "PlayerPacket";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "packet"; p_java_type = "net.minestom.server.network.packet.client.ClientPacket"; p_settable = false; p_accessor = "getPacket" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerPacketOutEvent";
    ev_short = "PlayerPacketOut";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "packet"; p_java_type = "net.minestom.server.network.packet.server.ServerPacket"; p_settable = false; p_accessor = "getPacket" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerPickBlockEvent";
    ev_short = "PlayerPickBlock";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "include_data"; p_java_type = "boolean"; p_settable = false; p_accessor = "isIncludeData" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerPickEntityEvent";
    ev_short = "PlayerPickEntity";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "include_data"; p_java_type = "boolean"; p_settable = false; p_accessor = "isIncludeData" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerPluginMessageEvent";
    ev_short = "PlayerPluginMessage";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "identifier"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getIdentifier" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "message"; p_java_type = "byte[]"; p_settable = false; p_accessor = "getMessage" };
      { p_name = "message_string"; p_java_type = "java.lang.String"; p_settable = false; p_accessor = "getMessageString" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerResourcePackStatusEvent";
    ev_short = "PlayerResourcePackStatus";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "pack_uuid"; p_java_type = "java.util.UUID"; p_settable = false; p_accessor = "getPackUuid" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "status"; p_java_type = "net.kyori.adventure.resource.ResourcePackStatus"; p_settable = false; p_accessor = "getStatus" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerRespawnEvent";
    ev_short = "PlayerRespawn";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "respawn_position"; p_java_type = "net.minestom.server.coordinate.Pos"; p_settable = true; p_accessor = "getRespawnPosition" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSetGameRulesEvent";
    ev_short = "PlayerSetGameRules";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "requested_rules"; p_java_type = "java.util.List<net.minestom.server.network.packet.client.play.ClientSetGameRulesPacket$Entry>"; p_settable = false; p_accessor = "getRequestedRules" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSettingsChangeEvent";
    ev_short = "PlayerSettingsChange";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSkinInitEvent";
    ev_short = "PlayerSkinInit";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "skin"; p_java_type = "net.minestom.server.entity.PlayerSkin"; p_settable = true; p_accessor = "getSkin" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSpawnEvent";
    ev_short = "PlayerSpawn";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "first_spawn"; p_java_type = "boolean"; p_settable = false; p_accessor = "isFirstSpawn" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "spawn_instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getSpawnInstance" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSpectateEntityEvent";
    ev_short = "PlayerSpectateEntity";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStabEvent";
    ev_short = "PlayerStab";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStartDiggingEvent";
    ev_short = "PlayerStartDigging";
    ev_cancellable = true;
    ev_props = [
      { p_name = "block"; p_java_type = "net.minestom.server.instance.block.Block"; p_settable = false; p_accessor = "getBlock" };
      { p_name = "block_face"; p_java_type = "net.minestom.server.instance.block.BlockFace"; p_settable = false; p_accessor = "getBlockFace" };
      { p_name = "block_position"; p_java_type = "net.minestom.server.coordinate.BlockVec"; p_settable = false; p_accessor = "getBlockPosition" };
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStartFlyingEvent";
    ev_short = "PlayerStartFlying";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStartFlyingWithElytraEvent";
    ev_short = "PlayerStartFlyingWithElytra";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStartSprintingEvent";
    ev_short = "PlayerStartSprinting";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStopFlyingEvent";
    ev_short = "PlayerStopFlying";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStopFlyingWithElytraEvent";
    ev_short = "PlayerStopFlyingWithElytra";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerStopSprintingEvent";
    ev_short = "PlayerStopSprinting";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerSwapItemEvent";
    ev_short = "PlayerSwapItem";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "main_hand_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = true; p_accessor = "getMainHandItem" };
      { p_name = "off_hand_item"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = true; p_accessor = "getOffHandItem" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerTeleportToEntityEvent";
    ev_short = "PlayerTeleportToEntity";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "target"; p_java_type = "net.minestom.server.entity.Entity"; p_settable = false; p_accessor = "getTarget" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerTickEndEvent";
    ev_short = "PlayerTickEnd";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerTickEvent";
    ev_short = "PlayerTick";
    ev_cancellable = false;
    ev_props = [
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerUseItemEvent";
    ev_short = "PlayerUseItem";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "item_use_time"; p_java_type = "long"; p_settable = true; p_accessor = "getItemUseTime" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" }
    ] };
  { ev_class = "net.minestom.server.event.player.PlayerUseItemOnBlockEvent";
    ev_short = "PlayerUseItemOnBlock";
    ev_cancellable = false;
    ev_props = [
      { p_name = "block_face"; p_java_type = "net.minestom.server.instance.block.BlockFace"; p_settable = false; p_accessor = "getBlockFace" };
      { p_name = "cursor_position"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getCursorPosition" };
      { p_name = "entity"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getEntity" };
      { p_name = "hand"; p_java_type = "net.minestom.server.entity.PlayerHand"; p_settable = false; p_accessor = "getHand" };
      { p_name = "instance"; p_java_type = "net.minestom.server.instance.Instance"; p_settable = false; p_accessor = "getInstance" };
      { p_name = "item_stack"; p_java_type = "net.minestom.server.item.ItemStack"; p_settable = false; p_accessor = "getItemStack" };
      { p_name = "player"; p_java_type = "net.minestom.server.entity.Player"; p_settable = false; p_accessor = "getPlayer" };
      { p_name = "position"; p_java_type = "net.minestom.server.coordinate.Point"; p_settable = false; p_accessor = "getPosition" }
    ] };
  { ev_class = "net.minestom.server.event.server.ClientPingServerEvent";
    ev_short = "ClientPingServer";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "connection"; p_java_type = "net.minestom.server.network.player.PlayerConnection"; p_settable = false; p_accessor = "getConnection" };
      { p_name = "delay"; p_java_type = "java.time.Duration"; p_settable = true; p_accessor = "getDelay" };
      { p_name = "payload"; p_java_type = "long"; p_settable = true; p_accessor = "getPayload" }
    ] };
  { ev_class = "net.minestom.server.event.server.ServerListPingEvent";
    ev_short = "ServerListPing";
    ev_cancellable = true;
    ev_props = [
      { p_name = "cancelled"; p_java_type = "boolean"; p_settable = true; p_accessor = "isCancelled" };
      { p_name = "connection"; p_java_type = "net.minestom.server.network.player.PlayerConnection"; p_settable = false; p_accessor = "getConnection" };
      { p_name = "ping_type"; p_java_type = "net.minestom.server.ping.ServerListPingType"; p_settable = false; p_accessor = "getPingType" };
      { p_name = "status"; p_java_type = "net.minestom.server.ping.Status"; p_settable = true; p_accessor = "getStatus" }
    ] };
  { ev_class = "net.minestom.server.event.server.ServerTickMonitorEvent";
    ev_short = "ServerTickMonitor";
    ev_cancellable = false;
    ev_props = [
      { p_name = "tick_monitor"; p_java_type = "net.minestom.server.monitoring.TickMonitor"; p_settable = false; p_accessor = "getTickMonitor" }
    ] };
]
