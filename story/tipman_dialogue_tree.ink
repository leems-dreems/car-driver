# title: Tipman Dialogue Tree

VAR items_in_skip = 0
VAR has_met_tipman = false

=== standard_dialogue ===

{not has_met_tipman:
    Pleased to meet you. I look after the rubbish at this dump. I can also summon cars, if you need one.
    ~ has_met_tipman = true
}

What do you need? There are {items_in_skip} items in the skip.

+ [What should I do?]
    It would be good if you could pick up any rubbish you see you around the island, and put it in this skip.
    To make things easier, you can use bins to consolidate rubbish into binbags.
    -> DONE
+ [Please summon a car for me]
    Very well. # SUMMON_CAR

-> END