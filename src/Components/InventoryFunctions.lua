--!strict
local HTTPService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local TypeDefinitions = require(script.Parent.TypeDefinitions)
local Tag = require(script.Parent.Tag)

local functions = {}

function functions._rawCall(self: TypeDefinitions.Inventory, eventName: string, ...): ()
    if self._clientCheck() then return end
    if self._useCallBacks then
        self[eventName](...)
    else
        self[eventName]:Fire(...)
    end
end

function functions._clientCheck(): boolean
    if RunService:IsClient() then
        warn(Tag("do not call from client!"))
        return true
    else
        return false
    end
end

function functions._getQuantity(self: TypeDefinitions.Inventory, ItemID: string | number): number? -- Returns the quantity of the provided ItemID inside the contents table. Returns 0 if the item doesn't exist
    if self._clientCheck() then return end
    return HTTPService:JSONDecode(self.Contents)[ItemID] or 0
end

function functions._addItem(self: TypeDefinitions.Inventory, ItemID: string | number, quantity: number): () -- Appends the provided item into the contents table safely
    if self._clientCheck() then return end
    local TempContents = HTTPService:JSONDecode(self.Contents)
    local item = TempContents[ItemID]
    if #HTTPService:JSONDecode(self.Contents) >= self.Capacity then
        self:_rawCall("ItemAddFailed", ItemID)
        return
    end
    if item ~= nil then
        TempContents[ItemID] += quantity
    else
        TempContents[ItemID] = quantity
    end
    self.Contents = TempContents
    self:_rawCall("ItemAdded", ItemID)
end

function functions._removeItem(self: TypeDefinitions.Inventory, ItemID: string | number, quantity: number): () -- Removes the provided item from the contents table
    if self._clientCheck() then return end
    local TempContents = HTTPService:JSONDecode(self.Contents)
    local item = TempContents[ItemID]
    assert(item, Tag("attempt to remove item with quantity"))

    if quantity ~= nil then
        if item == 0 then
            TempContents[ItemID] = nil
            return nil
        end
        TempContents[ItemID] -= quantity
    else
        TempContents[ItemID] = nil
    end
    self.Contents = HTTPService:JSONEncode(TempContents)
    self:_rawCall("ItemRemoving", ItemID)
end

function functions._hasItem(self: TypeDefinitions.Inventory, ItemID: string | number): boolean? -- Returns a boolean value representing the presence of the provided item id inside the contents table
    if self._clientCheck() then return end
    return HTTPService:JSONDecode(self.Contents)[ItemID] ~= nil
end 

function functions._clearInventory(self: TypeDefinitions.Inventory): () -- Wipes the contents table
    if self._clientCheck() then return end
    self.Contents = HTTPService:JSONEncode({})
end

function functions._craft(self: TypeDefinitions.Inventory, Recipe: (string | number) | TypeDefinitions.Recipe): () -- Crafts the provided recipe if possible
    if self._clientCheck() then return end
    local _recipe: TypeDefinitions.Recipe = HTTPService:JSONDecode(getmetatable(self)._localRecipeIndex)[Recipe] or Recipe
    assert(_recipe, "could not fetch requested recipe")

    for _, item in _recipe.Input do
        if HTTPService:JSONDecode(self.Contents)[item.ItemID] < item.Quantity then
            self:_rawCall("ItemCraftFailed", _recipe.ID)
            return
        end
        self:RemoveItem(item.ItemID, item.Quantity)
    end
    for _, item in _recipe.Output do
        self:AddItem(item.ItemID, item.Quantity)
    end
end

return functions :: TypeDefinitions._functions