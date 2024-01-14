export type Connection = {
	Disconnect: (self: Connection) -> (),
	Destroy: (self: Connection) -> (),
	Connected: boolean,
}
export type Signal<T...> = {
	Fire: (self: Signal, T...) -> (),
	FireDeferred: (self: Signal, T...) -> (),
	Connect: (self: Signal, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal, fn: (T...) -> ()) -> Connection,
	DisconnectAll: (self: Signal) -> (),
	GetConnections: (self: Signal) -> { Connection },
	Destroy: (self: Signal) -> (),
	Wait: (self: Signal) -> T...,
}
export type Item = {
	ItemID: string | number,
	Quantity: number,
}
export type Recipe = {
	ID: string,
	Input: {Item},
	Output: {Item},
}
export type Inventory = {
	Contents: {Item?},
	Capacity: number,
	_saves: boolean,
	_useCallBacks: boolean,
	_clientCheck: () -> boolean,
	_rawCall: (self: Inventory, eventName: string, ...any) -> (),
	GetQuantity: (self: Inventory, ItemID: string | number) -> number?,
	AddItem: (self: Inventory, ItemID: string | number, Quantity: number) -> (),
	RemoveItem: (self: Inventory, ItemID: string | number, Quantity: number) -> (),
	HasItem: (self: Inventory, ItemID: string | number) -> boolean?,
	ClearInventory: (self: Inventory) -> (),
	Craft: (self: Inventory, Recipe: (string | number) | Recipe) -> (),
	ItemAdded: Signal<string | number> | (ItemID: string |number) -> (...any),
	ItemRemoved: Signal<string | number> | (ItemID: string |number) -> (...any),
	ItemAddFailed: Signal<string | number> | (ItemID: string |number) -> (...any),
	ItemRemoveFailed: Signal<string | number> | (ItemID: string |number) -> (...any),
	ItemCraftFailed: Signal<string | number> | (ItemID: string |number) -> (...any)
}
export type _module = {
	_localRecipeIndex: {Recipe?},
	_localInventoryIndex: {Inventory?},
	SaveFunction: (_player: Player, _inventoryToSave: Inventory) -> (),
	RecipeClass: {(Input: {Item}, Output: {Item}, ID: string | number) -> Recipe},
	ItemClass: {(ID: string | number, Quantity: number) -> Item},
	GetInventory: (Player: Player, Saves: boolean?, UseCallBacks: boolean?) -> Inventory,
	RemoveInventory: (Player: Player) -> (),
	SetCraftingRecipe: (Recipe: Recipe) -> ()
}?
export type _functions = {
	_clientCheck: () -> boolean,
	_rawCall: (self: Inventory, eventName: string, ...any) -> (),
	_getQuantity: (self: Inventory, ItemID: string | number) -> number?,
	_addItem: (self: Inventory, ItemID: string | number, Quantity: number) -> (),
	_removeItem: (self: Inventory, ItemID: string | number, Quantity: number) -> (),
	_hasItem: (self: Inventory, ItemID: string | number) -> boolean?,
	_clearInventory: (self: Inventory) -> (),
	_craft: (self: Inventory, Recipe: (string | number) | Recipe) -> (),
}

return {}