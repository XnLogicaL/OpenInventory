# OpenInventory

OpenInventory is a back-end form of inventory managment for general use.

# Change Log

- Dependencies are now built-in
- Fixed more bugs

# How to Use

## Module
### Used by requiring the module.

- ```module:GetInventory(Player Player)```
	gets the targeted player's inventory, if it doesn't exist, creates a new one
	```@returns InventoryInstance```

- ```module:RemoveInventory(Player Player)```
	removes the player's inventory from module._manager
	```@returns nil```

- ```module:SetCraftingRecipe(Recipe CraftInfo)```
	sets the module._local[CraftInfo.ID] to the provided recipe
	```@returns nil```

- ```module:OverwriteCraftingRecipe(Recipe OldRecipe, Recipe NewRecipe)```
	replaces @OldRecipe's key with @NewRecipe's key
	```@returns nil```

## InventoryInstance
InventoryInstance is a custom instance type created using ```:GetInventory()```

- ```InventoryInstance:GetQuantity(string ItemID)```
	returns the targeted items quantity
	```@returns number```

- ```InventoryInstance:AddItem(string ItemID, number Quantity)```
	inserts the provided item to the InventoryInstance.Contents, if it does exist adds quantity to the key.
	```@returns nil```

- ```InventoryInstance:RemoveItem(string ItemID, number Quantity)```
	@optional quantity
	if no quantity is provided, removes all the itesm under ItemID, if provided, subtracts quantity from the ItemID
	```@returns nil```

- ```InventoryInstance:HasItem(string ItemID)```
	checks if the InventoryInstance[ItemID] is valid
	```@returns boolean```

- ```InventoryInstance:Clear()```
	sets all the keys of InventoryInstance.Contents to nil, essentially removes eveerything from the inventory.
	```@returns nil```

- ```InventoryInstance:Clone()```
	safely clones the contents of the inventory
	```@returns table @containing item```

- ```InventoryInstance:Craft(Recipe Recipe)```
	Crafts the provided recipe, if an ingredient is insufficient fires the InventoryInstance._craft_fail event
	```@returns nil```
