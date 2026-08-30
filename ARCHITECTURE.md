# ManaTools persistence architecture

ManaTools uses one SavedVariables global: `ManaToolsDB`.

`Bootstrap.lua` is the sole owner of the relationship between the WoW SavedVariables global and the addon namespace. It exposes the persistent table as `ManaTools.DB` and creates the `NoWasteCoin` namespace before feature code runs.

Feature settings live only under their namespace, for example:

```text
ManaToolsDB
└── NoWasteCoin
    ├── allowHeroicRaid
    └── allowMythicPlus
```

No feature declares or maintains a separate SavedVariables global. In particular, the legacy `NoWasteCoinDB` architecture is intentionally not retained or aliased.

The current repository version is early enough that no migration from `NoWasteCoinDB` is implemented; existing settings from that legacy global are therefore not imported. A future migration, if needed before release, should be a one-time bootstrap migration with the legacy global removed afterward.