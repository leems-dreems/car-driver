# title: Tipman Dialogue Tree

VAR items_in_skip = 0
VAR has_met_tipman = false

-> standard_dialogue

=== standard_dialogue ===

{not has_met_tipman:
    Pleased to meet you. I look after the rubbish at this dump. I can also summon cars, if you need one.
    ~ has_met_tipman = true
}

What do you need? There are {items_in_skip} items in the skip.

+ {items_in_skip < 25}
    [What should I do?]
    It would be good if you could pick up at least 25 bits of rubbish from around the island, and put them in this skip.
    To make things easier, you can use bins to consolidate rubbish into binbags.
    -> DONE
+ {items_in_skip >= 25}
    [I collected {items_in_skip} bits of rubbish]
    I am overjoyed to see this. Congratulations on completing this demo.
    -> DONE
+ [Where should I look for rubbish?]
    There are 10 bits of rubbish around this dump, 10 around the cafe in town and 10 around the big T-Pose statue.
    -> DONE
+ [Please summon a car for me]
    Very well. # SUMMON_CAR

-> END