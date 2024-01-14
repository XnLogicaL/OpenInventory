local TypeDefinitions = require(script.Parent.TypeDefinitions)

local Recipe = {}

function Recipe.new(Input: {TypeDefinitions.Item}, Output: {TypeDefinitions.Item}, ID: string): TypeDefinitions.Recipe
    local self = {}

    self.Input = Input
    self.Output = Output
    self.ID = ID

    return self
end

return Recipe