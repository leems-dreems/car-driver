# Quests

Schema:
- Quest
	- Giver: NPC
	- Subquests: Array[Quest]
	- Item types to bring: Array[Item_Type]
	- Specific items to bring: Array[Item]
	- Actions to perform: Array[Action]
	- Target destinations: Array[InteractMarker]
	- Target NPCs: Array[NPC]


## How quests work

Quests are used to outline tasks for both the player and NPCs to carry out.

A quest defines a task, or sequence of tasks, at the abstract level. This can be used for display on
the HUD, and to set up listeners in the scene to check when a task has been completed.

For NPCs, a quest can be used to generate the appropriate nodes in an NPC's behaviour tree to direct
them to complete the defined task. E.g. for the quest 'Collect Egg', an NPC would break this down
into a number of LimboHSM states that cover travelling to where the egg is (possibly using a
vehicle, depending on distance), dropping any currently held items, and then picking up the egg.

### QuestManager

The global QuestManager keeps a list of all active quests. Players, NPCs, items etc will call
functions in QuestManager to report any events that may complete or fail quests.

For example: when the player picks up a can, the player class calls eg. ItemPickedUp() in
QuestManager, which then iterates over its list of quests to see if any are of the PickupQuest type
and point to the item in question. If so, that quest is marked complete and we move onto its next
sibling, or the next sibling of its parent node, and so on.
