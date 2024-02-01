# OpenInventory v2.0

OpenInventory is a back-end form of inventory managment for general use.
This provides which many open-source inventory systems don't, *Customizability*.
With OpenInventory, you're not just limited to player inventories, you can make shared storages, private storages, chests, loot containers, etc. with a rather simple and self-explanatory API.

# Change Log

- Rewrote the entire module
- Made types more consistent
- Further table memory optimizations using ```:JSONEncode() and :JSONDecode()```
- Switched to a more reliable signal class
- Added asynchronization using the promise class