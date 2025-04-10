# title: Dumpmeister Dialogue Tree

VAR has_met_dumpmeister = false

{not has_met_dumpmeister:
    Pleased to meet you. I look after the rubbish at this dump. I can also summon cars, if you need one.
    ~ has_met_dumpmeister = true
}

What do you need?

* [What should I do?]
    It would be good if you could pick up any rubbish you see you around the island, and put it in this skip.
    To make things easier, you can use bins to consolidate rubbish into binbags.
* [Please summon a car for me]
    Very well. # SUMMON_CAR

-> END
