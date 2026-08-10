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
