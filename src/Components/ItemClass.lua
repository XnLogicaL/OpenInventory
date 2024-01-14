local TypeDefinitions = require(script.Parent.TypeDefinitions)

local Item = {}

function Item.new(ID: string, Quantity: number): TypeDefinitions.Item
    local self = {}

    self.Quantity = Quantity
    self.ID = ID

    return self
end

return Item