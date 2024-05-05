--!strict
--[=[

	Author: @XnLogicaL (@CE0_OfTrolling)
	Licensed under the MIT License.
	
	OpenInventory v2.0
	
	Docs: https://github.com/XnLogicaL/OpenInventory/wiki/

	What has changed:
	- OpenInventory now uses stringified tables instead of table objects (performant in terms of memory)
	- Completely rewritten architecture
	- Divided the module into smaller segments

]=]

if game:GetService("RunService"):IsClient() then
	return nil;
end

local HTTPService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local Database = DataStoreService:GetDataStore("_openInventory")

local Components = script.Components

local Manager = require(script.Manager)
local Signal = require(script.Signal)
local Promise = require(script.Promise)
local TypeDefinitions = require(Components.TypeDefinitions)
local assert = require(Components.Assert)
local Tag = require(Components.Tag)

-- Errors
local COULD_NOT_FETCH_INVENTORY = "could not fetch inventory of %s, likely due to not being initialized"
local COULD_NOT_REMOVE_INVENTORY = "could not remove inventory of %s, likely due to not being initialized"
local EXPECTED_RECIPE_GOT = "recipe type expected, got %s"

-- Type objects for type checking
local _InventoryType: TypeDefinitions.Inventory = nil
local _RecipeType: TypeDefinitions.Recipe = nil
local _ItemType: TypeDefinitions.Item = nil

local Class = {  }
Class.__index = Class
Class._localInventoryIndex = Manager
Class._localRecipeIndex = {  }

Class.RecipeClass = require(Components.RecipeClass)
Class.ItemClass = require(Components.ItemClass)

Class.SaveFunction = function(_player: Player, _inventoryToSave: TypeDefinitions.Inventory)
	-- TODO: ADD SAVE FUNCTIONALITY WITH YOUR PREFERED DATASTORE SERVICE.
	for i=1, 5 do
		local success, err = pcall(function()
			Database:SetAsync(("PLAYER_%s"):format(tostring(_player.UserId)), HTTPService:JSONEncode(_inventoryToSave.Contents))
		end)

		if success then
			break;
		else
			warn(Tag(("data save attempt %s error: %s"):format(tostring(i), err)))
		end
	end
end

local function newInventory(Player: Player, Saves: boolean?, UseCallBacks: boolean?): TypeDefinitions.Inventory
	local functions: TypeDefinitions._functions = require(Components.InventoryFunctions)
	local self = setmetatable({}, Class)

	self._saves = Saves or true -- Default: true
	self._useCallBacks = UseCallBacks or false
	self.Contents = {} -- Default: {}
	self.Capacity = 15 -- Default: 15

	if self._useCallBacks then
		self.ItemAdded = function(ItemID: string | number) end
		self.ItemRemoving = function(ItemID: string | number) end
		self.ItemAddFailed = function(ItemID: string | number) end
		self.ItemRemoveFailed = function(ItemID: string | number) end
		self.ItemCraftFailed = function(ItemID: string | number) end
	else
		self.ItemAdded = Signal.new()
		self.ItemRemoving = Signal.new()
		self.ItemAddFailed = Signal.new()
		self.ItemRemoveFailed = Signal.new()
		self.ItemCraftFailed = Signal.new()
	end

	self._clientCheck = functions._clientCheck
	self._rawCall = functions._rawCall
	self.AddItem = functions._addItem
	self.RemoveItem = functions._removeItem
	self.GetQuantity = functions._getQuantity
	self.HasItem = functions._hasItem
	self.ClearInventory = functions._clearInventory
	self.Craft = functions._craft

	Class._localInventoryIndex[Player] = self

	return self :: TypeDefinitions.Inventory
end

function Class:GetInventory(Player: Player, Saves: boolean?, UseCallBacks: boolean?): TypeDefinitions.Inventory?
	local inventory = self._localInventoryIndex[Player]
	assert(inventory, Tag(COULD_NOT_FETCH_INVENTORY:format(Player.Name)))

	if inventory ~= nil then return inventory end

	self._localInventoryIndex[Player] = newInventory(Player, Saves, UseCallBacks)
	return self._localInventoryIndex[Player] :: TypeDefinitions.Inventory
end

function Class:RemoveInventory(Player: Player): ()
	local inventory = self._localInventoryIndex[Player]
	assert(inventory, Tag(COULD_NOT_REMOVE_INVENTORY:format(Player.Name)))

	if self._saves then
		Promise.new(function()
			local result = self.SaveFunction(Player, inventory)

			if result == true then
				print("saved inventory successfully")
			else
				print("could not save inventory")
			end
		end):andThen(function()
			self._localInventoryIndex[Player] = nil
		end)
	end
end

function Class:SetCraftingRecipe(Recipe: TypeDefinitions.Recipe): ()
	assert(typeof(Recipe) == typeof(_RecipeType), Tag(EXPECTED_RECIPE_GOT:format(typeof(Recipe))))
	local TempContents = HTTPService:JSONDecode(self._localRecipeIndex)
	TempContents[Recipe.ID] = Recipe
	self._localInventoryIndex = HTTPService:JSONEncode(TempContents)
end

return Class :: TypeDefinitions._module
