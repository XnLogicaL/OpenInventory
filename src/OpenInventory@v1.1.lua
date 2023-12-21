--[[

	Author: @XnLogicaL (@CE0_OfTrolling)
	Licensed under the MIT License.
	
	OpenInventory@v1.3 HOTFIX
	
	Please refer to: 
	https://github.com/XnLogicaL/OpenInventory/wiki/
	For documentation.
	
	How to use:
	Step 1: call InventoryInstance = module:GetInventory(Player)
		- If the player has an inventory, it will return a table with all items.
		- If the player does not have an inventory, it will create one and return an empty table.
	Step 1.5: Set the module.SaveFunction to your own data saver (Optional)
	Step 2: Use InventoryInstance:AddItem(ItemID, Quantity) to add items to the players inventory.
	Step 3: Use InventoryInstance:RemoveItem(ItemID, Quantity) to remove items from the players inventory.
	
]]--
-- Types
export type Item = {
	ItemID: string?,
	Quantity: number,
	Rarity: number, -- Not used at the moment
}
export type Inventory = {
	Contents: {Item},
	Capacity: number,
	_saves: boolean,
	GetItemQuantity: (ItemID: string) -> number,
	AddItem: (ItemID: string, Quantity: number) -> (),
	RemoveItem: (ItemID: string, Quantity: number) -> (),
	ClearInventory: () -> (),
	Release: () -> (),
	Clone: () -> {any},
	ItemAdded: RBXScriptSignal,
	ItemRemoved: RBXScriptSignal,
	InventoryCleared: RBXScriptSignal,
	_add_fail: RBXScriptSignal,
	_remove_fail: RBXScriptSignal,
	_craft_fail: RBXScriptSignal
}
export type Recipe = {
	ID: string,
	Input: {Item},
	Output: {Item},
}
export type SignalType = {
	_connections: {RBXScriptConnection},
	_bindable: BindableEvent,
	Fire: (self: SignalType, ...any) -> (...any),
	Connect: (self: SignalType, _handler: (any) -> (any)) -> RBXScriptConnection,
	Once: (self: SignalType, _handler: (any) -> (any)) -> RBXScriptConnection,
	Wait: (self: SignalType) -> (),
	DisconnectAll: (self: SignalType) -> (),
}

-- Constants
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local built_in_signal = {}
built_in_signal = { -- Standard signal module, uses bindables
	_signals = setmetatable(built_in_signal, {}),
	new = function(): SignalType
		local new_sig = {
			_connections = {},
			_bindable = Instance.new("BindableEvent"),
			Fire = function(self: SignalType, ...)
				return self._bindable:Fire(...)
			end,
			Connect = function(self: SignalType, _handler: ((any) -> any))
				local connection = self._bindable.Event:Connect(_handler)
				table.insert(self._connections, connection)
				return {
					Disconnect = function(_self: RBXScriptConnection)
						table.remove(
							getmetatable(built_in_signal)._connections, 
							table.find(
								getmetatable(built_in_signal)._connections, 
								connection
							)
						)
						return _self:Disconnect()
					end,
				}
			end,
			Once = function(self: SignalType, _handler: ((any) -> any))
				return self._bindable.Event:Once(_handler)
			end,
			Wait = function(self: SignalType)
				local waitingCoroutine = coroutine.running()
				local done = false
				self:Once(function(...)
					if done then
						return
					end
					done = true
					task.spawn(waitingCoroutine, ...)
				end)
				return coroutine.yield()
			end,
			Destroy = function(self: SignalType)
				self:DisconnectAll()
				self._bindable:Destroy()
				table.clear(self)
				return nil
			end,
			DisconnectAll = function(self: SignalType)
				for _, v in self._connections do
					v:Disconnect()
				end
				table.clear(self._connections)
				return nil
			end,
		}
		
		table.insert(built_in_signal._signals, new_sig)
		
		return built_in_signal._signals[#built_in_signal._signals]
	end,
}

-- Formatted strings
local EXPECTED_GOT = "%s expected, got %s"
local COULD_NOT = "could not %s, %s"
local ALREADY_EXISTS = "%s already exists, %s"
local ATTEMPT_TO = "attempt to %s"

-- Config/Priv functions
local Config = {
	ClientCheck = true, -- Heavily recommended
	Manager = {},
	Signal = built_in_signal
}

local function tag(...)
	return ("[INVENTORYSERVICE] ▶ %s"):format(...)
end

-- Module part
local Module = {_manager = Config.Manager, _local = {}}
Module.__index = Module
Module.SaveFunction = function(_player: Player, _inventoryToSave: Inventory)
	-- TODO: ADD SAVE FUNCTIONALITY WITH YOUR PREFERED DATASTORE SERVICE.
end

function newInventory(Player: Player, Saves: boolean): Inventory
	
	local new_inventory = {}
	new_inventory._saves = Saves or true -- Default: true
	new_inventory.Contents = {} -- Default: {}
	new_inventory.Capacity = 15 -- Default: 15
	new_inventory.ItemAdded = Config.Signal.new()
	new_inventory.ItemRemoving = Config.Signal.new()
	new_inventory.InventoryCleared = Config.Signal.new()
	---- DEBUGGING ----
	new_inventory._add_fail = Config.Signal.new()
	new_inventory._remove_fail = Config.Signal.new()
	new_inventory._craft_fail = Config.Signal.new()

	function new_inventory:GetQuantity(ItemID: string) -- Returns the quantity of the provided ItemID
		
		local target_item: number = self.Contents[ItemID]

		if target_item ~= nil then -- If the item exists, returns it's table value
			return target_item
		else
			return 0 -- Returns 0 if the item's index is nil
		end
	end

	function new_inventory:AddItem(ItemID, quantity)
		
		local target_item = self.Contents[ItemID]
		if #self.Contents >= self.Capacity then -- checks if the inventory is full
			self._add_fail:Fire("inventory_full")
			return 
		end
		if target_item ~= nil then
			self.Contents[ItemID] += quantity -- adds the amount of items to the inventory
		else
			self.Contents[ItemID] = quantity
		end
		self.ItemAdded:Fire(ItemID)
	end

	function new_inventory:RemoveItem(ItemID, quantity)
		
		local target_item = self.Contents[ItemID]
		assert( -- Checks if target item is nil or not
			target_item,
			tag(
				ATTEMPT_TO:format(
					"remove item with with quantity 0"
				)
			)
		)

		if quantity ~= nil then -- Checks if a quantity argument is provided
			if target_item == 0 then
				self.Contents[ItemID] = nil -- Clears the item's key
				return
			end
			self.Contents[ItemID] -= quantity -- Subtracts the items from the inventory
		else
			self.Contents[ItemID] = nil
		end
		self.ItemRemoving:Fire(ItemID)
	end

	function new_inventory:HasItem(ItemID) -- Returns true if the inventory has an Item with the provided ID
		return self.Contents[ItemID] ~= nil
	end 

	function new_inventory:ClearInventory() -- Sets all the item's keys to nil, essentially removing them
		
		table.clear(self.Contents)
		self.InventoryCleared:Fire()
	end

	function new_inventory:Release()
		
		if self._saves then -- Checks if the inventory saves or not
			Module.SaveFunction(Player, new_inventory) -- Executes the save function
			task.wait()
		end
		table.clear(self)
	end

	function new_inventory:Craft(RecipeID: string?)
		
		local r = self._local[RecipeID]
		
		for _, v in pairs(r.Input) do -- Loops through the input property of the recipe
			if self.Contents[v.ItemID] < v.Quantity then -- Checks if the inventory has a sufficient amount of the required item
				self._craft_fail:Fire("insufficient_quantity")
				return
			end
		end

		for _, v in pairs(r.Input) do -- Loops through the input again, removes all the required items
			self:RemoveItem(v.ItemID, v.Quantity)
		end
		for _, v in pairs(r.Output) do -- Loops through the output of the recipe, adds the specified items
			self:AddItem(v.ItemID, v.Quantity)
		end
	end

	Module._manager[Player] = new_inventory

	return new_inventory
end

function Module:GetInventory(Player: Player): (Player) -> Inventory
	
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then -- Checks if the target inventory is nil or not
		return target_inventory -- If it's not, returns it
	else
		self._manager[Player] = newInventory(Player) -- If it is, generates a new one and appends it into the manager
	end

	return target_inventory
end

function Module:RemoveInventory(Player: Player): (Player) -> ()
	
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then -- Checks if the Inventory you're attempting to remove is nil or not
		target_inventory:Release() -- Saves and dumps the inventory
		self._manager[Player] = nil -- Cleanup
	else -- The target inventory is nil, therefore throws an error
		error(
			tag(
				COULD_NOT:format(
					("remove inventory of %s"):format(Player.Name), 
					"likely due to not being initialized"
				)
			)
		)
	end
end

function Module:SetCraftingRecipe(CraftInfo: Recipe): Recipe
	
	local RecipeType: Recipe = {} -- Just an empty value with a type, thank roblox for making types inconsistent af
	assert(
		typeof(CraftInfo) == typeof(RecipeType), -- Checks if the provided recipe is actually a recipe or not
		tag(
			EXPECTED_GOT:format(
				"Recipe",
				typeof(CraftInfo)
			)
		)
	)
	assert( -- Checks if the recipe already exists
		self._local[CraftInfo.ID] == nil, 
		tag(
			ALREADY_EXISTS:format(
				"RecipeID",
				"use :OverwriteRecipe()"
			)
		)
	)

	self._local[CraftInfo.ID] = CraftInfo -- Appends the recipe to local recipes
end

function Module:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	
	assert( -- Checks if the provided recipe is acutally a recipe or not
		typeof(NewRecipe) == typeof(Recipe), 
		tag(
			EXPECTED_GOT:format(
				"Recipe",
				typeof(NewRecipe)
			)
		)
	)
	assert( -- Checks if the recipe already exits
		self._local[Recipe] ~= nil,
		tag(
			COULD_NOT:format(
				"overwrite recipe",
				"recipe already exists"
			)
		)
	)
	
	self._local[Recipe.ID] = NewRecipe -- Appends the recipe to local recipes
end

return setmetatable({}, {
	__index = function(index, _, _)
		if RunService:IsClient() and Config.ClientCheck then
			return error(
				ATTEMPT_TO:format(
					"index from client while client check is enabled."
				)
			)
		end
		if Module[index] then
			return Module[index]
		else
			return error(
				COULD_NOT:format(
					"fetch index",
					"are you sure the index is correct?"
				)
			)
		end
	end,
	__newindex = function(_, _)
		return error(
			ATTEMPT_TO:format(
				"add new index during run time, please edit source instead."
			)
		)
	end
})