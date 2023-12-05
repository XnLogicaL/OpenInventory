--[[

	Author: @XnLogicaL (@CE0_OfTrolling)
	Licensed under the MIT License.
	
	OpenInventory@v1.1
	
	Please refer to: 
	https://github.com/XnLogicaL/OpenInventory/wiki/
	For documentation.

]]--
export type Item = {
	ItemID: string?,
	Quantity: number,
	Rarity: number,
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

built_in_signal = {
	new = function()
		local newSignal: signalType = {
			_connections = {},
			Fire = built_in_signal.Fire,
			Connect = built_in_signal.Connect,
			Wait = built_in_signal.Wait,
			Destroy = built_in_signal.Destroy
		}

		return newSignal
	end,
	Connect = function(self, handler: (any) -> (any))
		local self: signalType = self

		local numConnections: number = #self._connections

		local newConnection: connectionType = {
			_signal = self,
			_handler = handler,
			_connectionIndex = (numConnections + 1),
			Disconnect = built_in_signal.Disconnect
		}

		table.insert(self._connections, (numConnections + 1), newConnection)

		return newConnection
	end,
	Disconnect = function(self): nil
		local self: connectionType = self

		local currentSignal: signalType = self._signal

		currentSignal._connections[self._connectionIndex] = nil

		table.clear(self)
		self = nil :: any

		return nil
	end,
	Wait = function(self): any
		local self: signalType = self

		local thread: thread = coroutine.running()

		local c: connectionType; c = self:Connect(function(...)
			c:Disconnect()
			coroutine.resume(thread, ...)
		end)

		return coroutine.yield()
	end,
	Fire = function(self, ...: any): nil
		local self: signalType = self

		for index: number, connection: connectionType in pairs(self._connections) do
			connection._handler(...)
		end

		return nil
	end,
	Destroy = function(self): nil
		local self: signalType = self

		for index: number, connection: connectionType in pairs(self._connections) do
			connection:Disconnect()
		end

		table.clear(self)
		self = nil :: any

		return nil
	end
}

local Config = {
	ClientCheck = true, -- Heavily recommended
	Manager = {},
	Signal = built_in_signal
}

local function String(...: string)
	return "[INVENTORYSERVICE] ▶ ".. ...
end

local function client_check()
	if Config.ClientCheck then
		if game:GetService("RunService"):IsClient() then
			Players.LocalPlayer:Kick("attempt to run server-only module on client")
		end
	end
end

local function assert_string(condition: boolean, str: string): string | nil
	if condition == (false or nil) then
		return str
	end
	return nil
end

local Module = {_manager = Config.Manager, _local = {}}
Module.__index = Module
Module.SaveFunction = function(Player: Player, InventoryToSave: Inventory)
	-- TODO: ADD SAVE FUNCTIONALITY WITH YOUR PREFERED DATASTORE SERVICE.
end

function newInventory(Player: Player, Saves: boolean): Inventory
	client_check()
	local new_inventory: Inventory = {}
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

	function new_inventory:GetQuantity(ItemID: string): (string) -> number
		client_check()
		local target_item: number = self.Contents[ItemID]

		if target_item ~= nil then
			return target_item
		else
			return 0
		end
	end

	function new_inventory:AddItem(ItemID, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemID]
		if #self.Contents >= self.Capacity then self._add_fail:Fire("inventory_full") return end
		if target_item ~= nil then
			self.Contents[ItemID] += quantity
		else
			self.Contents[ItemID] = quantity
		end
		self.ItemAdded:Fire(ItemID)
	end

	function new_inventory:RemoveItem(ItemID, quantity): (string, number) -> () 
		client_check()
		local target_item = self.Contents[ItemID]
		assert(target_item, String(`Attempt to remove Item with quantity 0`))

		if quantity ~= nil then
			if target_item == 0 then
				self.Contents[ItemID] = nil
				return
			end
			self.Contents[ItemID] -= quantity
		else
			self.Contents[ItemID] = nil
		end
		self.ItemRemoving:Fire(ItemID)
	end

	function new_inventory:HasItem(ItemID): () -> boolean
		return self.Contents[ItemID] ~= nil
	end 

	function new_inventory:ClearInventory(): () -> ()
		client_check()
		table.clear(self.Contents)
		self.InventoryCleared:Fire()
	end

	function new_inventory:Release(): () -> ()
		client_check()
		if self._saves then
			Module.SaveFunction(Player, new_inventory)
			task.wait()
		end
		table.clear(self)
	end

	function new_inventory:Craft(Recipe: Recipe): (Recipe) -> ()
		client_check()
		for _, v in pairs(Recipe.Input) do
			if self.Contents[v.ItemID] < v.Quantity then
				self._craft_fail:Fire("insufficient_quantity")
				return
			end
		end

		for _, v in pairs(Recipe.Input) do
			self:RemoveItem(v.ItemID, v.Quantity)
		end
		for _, v in pairs(Recipe.Output) do
			self:AddItem(v.ItemID, v.Quantity)
		end
	end

	table.insert(Module._manager, new_inventory)

	return new_inventory :: Inventory
end

function Module:GetInventory(Player: Player): (Player) -> Inventory
	client_check()
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then 
		return target_inventory
	else
		self._manager[Player] = newInventory(Player)
	end

	return target_inventory
end

function Module:RemoveInventory(Player: Player): (Player) -> ()
	client_check()
	local target_inventory = self._manager[Player]
	if target_inventory ~= nil then
		target_inventory:Release()
		self._manager[Player] = nil
	else
		error(`[INVENTORYSERVICE] ▶ Attempt to remove inventory before initializing ({Player.Name})`)
	end
end

function Module:SetCraftingRecipe(CraftInfo: Recipe): Recipe
	client_check()
	local RecipeType: Recipe = {}
	assert(typeof(CraftInfo) == typeof(RecipeType), String(`CraftInfo expected; got {typeof(CraftInfo)}`))
	assert(self._local[CraftInfo.ID] == nil, String(`Recipe ID already exists; use :OverwriteRecipe()`))

	self._local[CraftInfo.ID] = CraftInfo
end

function Module:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	client_check()
	assert(typeof(NewRecipe) == typeof(Recipe), String(`CraftInfo expected; got {typeof(NewRecipe)}`))
	assert(self._local[Recipe] ~= nil, String("Could not overwrite; recipe is nil"))
	self._local[Recipe] = NewRecipe
end


return Module
