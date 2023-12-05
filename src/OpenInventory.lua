--[[

	Author: @XnLogicaL (@CE0_OfTrolling)
  Licensed under the MIT License.

]]--
local Config = {
	ClientCheck = true, -- Heavily recommended
	Manager = require(script.Manager),
	Signal = require(script.Signal)
}
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
	Clone: () -> {Item},
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
export type Module = {
	GetInventory: (Player) -> Inventory,
	RemoveInventory: (Player) -> (),
	SetCraftingRecipe: (CraftInfo: Recipe) -> (),
	OverwriteCraftingRecipe: (oldRecipe: Recipe, newRecipe: Recipe) -> ()
}

local EXPECTED_GOT = "%s expected, got %s"
local FAILED_TO = "could not %s, %s"
local ATTEMPT_TO = "attempt to %s"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local function String(...: string)
	return ("[INVENTORYSERVICE] ▶ %s"):format(...)
end

local function client_check()
	if Config.ClientCheck then
		if game:GetService("RunService"):IsClient() then
			Players.LocalPlayer:Kick(ATTEMPT_TO:format("run server-only module on client"))
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
		assert(target_item, String(FAILED_TO:format("process item removal", "item quantity is 0")))

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
		if self.Contents[ItemID] ~= nil then
			return true
		end
		return false
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

	function new_inventory:Clone(): () -> {any}
		client_check()
		return self.Contents
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
		warn(String(("Could not remove inventory of %s, likely due to not being initialized"):format(Player.Name)))
	end
end               

function Module:SetCraftingRecipe(CraftInfo: Recipe): Recipe
	client_check()
	local RecipeType: Recipe = {}
	assert(typeof(CraftInfo) == typeof(RecipeType), String(EXPECTED_GOT:format("CraftInfo", typeof(CraftInfo))))
	assert(self._local[CraftInfo.ID] == nil, String("Recipe ID already exists; use :OverwriteRecipe()"))

	self._local[CraftInfo.ID] = CraftInfo
end

function Module:OverwriteCraftingRecipe(Recipe: Recipe, NewRecipe: Recipe)
	client_check()
	assert(typeof(NewRecipe) == typeof(Recipe), String(EXPECTED_GOT:format("CraftInfo", typeof(NewRecipe))))
	assert(self._local[Recipe] ~= nil, String(FAILED_TO:format("overwrite", "recipe is missing or nil")))
	self._local[Recipe] = NewRecipe
end


return Module :: Module
