# title: NPC Basic Example Dialogue Tree

VAR has_met_npc_basic_example = false

-> standard_dialogue

=== standard_dialogue ===

{has_met_npc_basic_example:
    Hello again.
}
{not has_met_npc_basic_example:
    Pleased to meet you.
    ~ has_met_npc_basic_example = true
}

+ [Tell me something interesting.]
    No.
    -> DONE
+ [Goodbye.]
    Bye.
    -> DONE

-> END