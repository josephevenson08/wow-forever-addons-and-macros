# Warrior macros: WoW Forever and Classic

Macros for PvE (tanking and DPS) and PvP, built around stance dancing. Each
macro is tagged with where it works:

- **Both**: WoW Forever and Classic Era. Written in the two-press style
  that works on Forever (see below).
- **Forever**: uses a Forever-only change, like Thunder Clap in Defensive
  Stance or Victory Rush.
- **Classic**: depends on Classic behaviour, like one-press stance swaps.

None of these have been tested in game yet. They follow the rules the
sources below describe. If one misbehaves, note what it did and we'll fix
it here.

## Making a macro

1. Type `/macro` (or Esc, then **Macros**). Click **New**, pick the
   question-mark icon (it shows the right ability when the macro starts
   with `#showtooltip`), and name it.
2. Paste the macro text. The limit is **255 characters**.
3. Drag it to your action bar.

Stance numbers in `[stance:n]` follow your stance bar: **1 = Battle,
2 = Defensive, 3 = Berserker**. On Forever you get Defensive at level 10
and Berserker at level 30 from class quests.

## The big difference: stance swapping on Forever

In Classic Era, a macro like this swaps stance and casts in **one** press:

```
/cast Battle Stance
/cast Overpower
```

**On Forever it doesn't.** The first press only changes stance; you have to
press again for the ability. Players have reported this since the beta (a
Blizzard forum thread and a bug report about macros not carrying over the
new stance to the next line). There's no fix yet.

So the macros here use the pattern that works the same way in both games:

```
/cast [stance:1] Overpower; Battle Stance
```

In Battle Stance it casts Overpower. In any other stance it switches to
Battle Stance, and the next press casts Overpower. Two quick taps, every
time, no surprises.

**The one exception:** the ability first, then the stance swap, does work
in one press on Forever. Tanks can use that to Charge and land in Defensive
Stance (see [Charge into Defensive](#charge-into-defensive-stance)).

Other things to know:

- **Rage on stance swap:** you lose Rage when you change stance. On Forever,
  Tactical Mastery is trained for free at level 14 and keeps 10 Rage.
  Improved Tactical Mastery (Arms talent) keeps more. In Classic, Tactical
  Mastery is the Arms talent (up to 25 Rage at 5/5).
- **Stance cooldown:** changing stance has its own 1 second cooldown, so a
  macro can't hop into a stance and straight back out.
- **Macros can't see Rage, health or cooldowns.** A line just fails if the
  ability isn't ready, and the next line runs.
- **`/cast !Ability`:** on Forever, macros with `!` are reported as buggy,
  so these macros don't use it.
- **`/startattack`:** Forever starts auto-attack when you use an offensive
  ability anyway. It's kept here because it's harmless and helps in Classic.

## Which stance does each ability need?

| Ability | Classic | Forever |
| --- | --- | --- |
| Charge | Battle, out of combat | Battle, out of combat (Defensive too with the Vanguard talent) |
| Intercept | Berserker | Berserker |
| Overpower | Battle | Battle |
| Mocking Blow, Retaliation | Battle | Battle |
| Sweeping Strikes | Battle | Battle |
| Thunder Clap | Battle | **Battle or Defensive** |
| Rend, Shield Bash | Battle or Defensive | Battle or Defensive |
| Execute, Hamstring | Battle or Berserker | Battle or Berserker |
| Taunt, Disarm, Revenge, Shield Block, Shield Wall | Defensive | Defensive |
| Pummel, Berserker Rage, Whirlwind, Recklessness | Berserker | Berserker |
| Heroic Strike, Cleave, Sunder Armor, Bloodrage, shouts, Intimidating Shout, Slam, Last Stand, Mortal Strike, Bloodthirst, Shield Slam | Any | Any |
| Victory Rush | Not in Classic Era | **New**, any stance, after a kill |

Forever changes worth knowing:

- **Taunt:** 8 second cooldown (Classic 10).
- **Shield Block:** blocks 2 attacks over 7 seconds.
- **Shield Wall:** 60% reduction with a 15 minute cooldown.
- **Retaliation:** 15 minute cooldown.
- **Thunder Clap:** slows 20% on a 6 second cooldown.
- **Cleave:** hits your target plus one more enemy.

## Stance dancing (Both)

### Overpower from any stance

After your target dodges. Tap twice from Defensive or Berserker.

```
#showtooltip Overpower
/startattack
/cast [stance:1] Overpower; Battle Stance
```

### Charge out of combat, Intercept in combat

One gap closer for everything. Out of combat it wants Battle Stance and
Charges. In combat it wants Berserker Stance and Intercepts. In the wrong
stance, the press switches stance first.

```
#showtooltip
/cast [nocombat,stance:1] Charge; [combat,stance:3] Intercept; [nocombat] Battle Stance; Berserker Stance
```

Forever with the **Vanguard** talent: change `[nocombat,stance:1]` to
`[nocombat,stance:1/2]` so you can Charge straight from Defensive Stance.

### Interrupt: Pummel in Berserker, Shield Bash otherwise

Interrupts your focus if you have one, otherwise your target. Shield Bash
needs a shield.

```
#showtooltip
/cast [stance:3,@focus,harm,nodead][stance:3] Pummel; [@focus,harm,nodead][] Shield Bash
```

### Berserker Rage from any stance

Breaks fear (and gives Rage). Tap twice outside Berserker Stance.

```
#showtooltip Berserker Rage
/cast [stance:3] Berserker Rage; Berserker Stance
```

### Execute, leaving Defensive if needed

In Battle or Berserker it Executes. In Defensive it switches to Battle
first.

```
#showtooltip Execute
/startattack
/cast [stance:2] Battle Stance; Execute
```

### Whirlwind from any stance

```
#showtooltip Whirlwind
/startattack
/cast [stance:3] Whirlwind; Berserker Stance
```

### Disarm your mouseover or target

```
#showtooltip Disarm
/cast [stance:2,@mouseover,harm,nodead][stance:2] Disarm; Defensive Stance
```

## PvE tanking

### Charge into Defensive Stance

**Forever.** The ability-first order works in one press on Forever (and in
Classic). Charge from Battle Stance, then drop straight into Defensive.

```
#showtooltip Charge
/cast Charge
/cast Defensive Stance
```

In Classic, put `/cast Bloodrage` between the two lines for an extra 10
Rage: Bloodrage puts you in combat, so it has to come after Charge. On
Forever, Bloodrage no longer puts you in combat.

### Sunder Armor, finding a target

Targets the nearest enemy if you have no living enemy targeted. Works in
every stance. **Both.**

```
#showtooltip Sunder Armor
/targetenemy [noharm][dead]
/startattack
/cast Sunder Armor
```

### Revenge, then Shield Block

Revenge only works after you block, dodge or parry. When it isn't ready,
that line fails and Shield Block goes out instead. Hold Shift to skip
Shield Block. **Both.**

```
#showtooltip Revenge
/startattack
/cast Revenge
/cast [nomod:shift] Shield Block
```

### Taunt your mouseover, Shift for Mocking Blow

Taunts the enemy under your mouse, or your target. Shift uses Mocking Blow
from Battle Stance. Wrong stance means the first press switches. **Both.**

```
#showtooltip
/cast [mod:shift,stance:1] Mocking Blow; [mod:shift] Battle Stance; [stance:2,@mouseover,harm,nodead][stance:2] Taunt; Defensive Stance
```

### Shield Wall, Shift for Last Stand

Shield Wall needs Defensive Stance and a shield. Last Stand is a Protection
talent and works in any stance. **Both.**

```
#showtooltip Shield Wall
/cast [mod:shift] Last Stand; [stance:2] Shield Wall; Defensive Stance
```

### Last Stand and a Healthstone

The emergency button. Change the Healthstone name to the one you carry.
**Both.**

```
#showtooltip Last Stand
/cast Last Stand
/use Major Healthstone
```

### Thunder Clap without leaving Defensive

**Forever.** Thunder Clap works in Defensive Stance on Forever, so this only
switches stance from Berserker. Shift casts Demoralizing Shout.

```
#showtooltip
/cast [mod:shift] Demoralizing Shout; [stance:3] Battle Stance; Thunder Clap
```

**Classic** version (Thunder Clap needs Battle Stance):

```
#showtooltip
/cast [mod:shift] Demoralizing Shout; [stance:1] Thunder Clap; Battle Stance
```

### Bloodrage and Battle Shout

Bloodrage costs no global cooldown, so both go out on one press. **Both.**

```
#showtooltip Battle Shout
/cast Bloodrage
/cast Battle Shout
```

## PvE DPS

### Heroic Strike, Shift for Cleave

Your Rage dump. Both queue on your next swing. **Both.**

```
#showtooltip
/startattack
/cast [mod:shift] Cleave; Heroic Strike
```

### Bloodthirst with a Heroic Strike queue (Fury)

Heroic Strike waits for your next swing and costs no global cooldown, so
it queues behind Bloodthirst on the same press. Only spam it with Rage to
spare. **Both** (Bloodthirst is the 31-point Fury talent).

```
#showtooltip Bloodthirst
/startattack
/cast Bloodthirst
/cast Heroic Strike
```

### Mortal Strike, Shift for Hamstring (Arms)

**Both.**

```
#showtooltip
/startattack
/cast [mod:shift] Hamstring; Mortal Strike
```

### Sweeping Strikes, then Cleave (Arms)

Sweeping Strikes needs Battle Stance. In another stance the first press
switches. **Both.**

```
#showtooltip Sweeping Strikes
/startattack
/cast [stance:1] Sweeping Strikes; Battle Stance
/cast Cleave
```

### Death Wish with both trinkets (Fury)

Uses any on-use trinkets in slots 13 and 14. Trinkets without a use effect
are skipped. **Both.**

```
#showtooltip Death Wish
/cast Death Wish
/use 13
/use 14
```

### Recklessness from any stance

Add your racial on another line if you like: `/cast Blood Fury` (Orc) or
`/cast Berserking` (Troll). **Both.**

```
#showtooltip Recklessness
/cast [stance:3] Recklessness; Berserker Stance
```

## PvP

### Hamstring, leaving Defensive if needed

**Both.**

```
#showtooltip Hamstring
/startattack
/cast [stance:2] Battle Stance; Hamstring
```

### Intimidating Shout

Works in any stance. Shift targets your focus. **Both.**

```
#showtooltip Intimidating Shout
/cast [mod:shift,@focus,harm,nodead][] Intimidating Shout
```

### Swap to sword and board, Shift for your two-hander

For Shield Bash and Shield Wall mid-fight. Weapons can be swapped in
combat; armour can't. Swapping resets your swing timer. Replace the item
names with yours. **Both.**

```
#showtooltip
/equip [mod:shift] Your Two-Hander
/equipslot [nomod] 16 Your One-Hander
/equipslot [nomod] 17 Your Shield
```

### Shield Bash with a shield swap

Puts your shield on if you're holding a two-hander, then Shield Bashes on
the next press (Battle or Defensive Stance). **Both.**

```
#showtooltip Shield Bash
/equipslot [noequipped:Shields] 16 Your One-Hander
/equipslot [noequipped:Shields] 17 Your Shield
/cast [stance:3] Battle Stance; Shield Bash
```

### Victory Rush after a kill

**Forever.** Heals 10% of your health within 20 seconds of a kill (30
second cooldown). Shift casts Execute instead, so one key covers your
finishers.

```
#showtooltip
/startattack
/cast [mod:shift] Execute; Victory Rush
```

## Utility

### Target the nearest enemy and attack

```
#showtooltip
/targetenemy [noharm][dead]
/startattack
```

### Healthstone, then potion

Uses whichever is ready. Change the names to what you carry. **Both.**

```
#showtooltip
/use Major Healthstone
/use Major Healing Potion
```

## One-press stance macros (Classic only)

These work in one press in Classic Era. **On Forever they only change
stance**, so use the two-press versions above there.

```
#showtooltip Overpower
/cast Battle Stance
/cast Overpower
```

```
#showtooltip Pummel
/cast Berserker Stance
/cast Pummel
```

```
#showtooltip Intercept
/cast Berserker Stance
/cast Intercept
```

## Sources

- WoW Forever macro and class data: [FOREVERdb warrior macros](https://foreverdb.net/macros/warrior),
  [ForeverChanges: warrior](https://foreverchanges.pro/class/warrior),
  [Conquest Capped: Forever warrior abilities](https://conquestcapped.com/guides/wow-forever/wow-forever-warrior-abilities/)
- Forever stance swapping: [Blizzard forums: "Warrior Stance Dance now triggers micro GCD"](https://eu.forums.blizzard.com/en/wow/t/warrior-stance-dance-now-triggers-micro-gcd/633220)
- Classic macros: [Noob to Boss: Classic warrior macros](https://noobtoboss.com/wow-classic-warrior-macros/),
  [Warcraft Wiki: Useful macros for warriors](https://warcraft.wiki.gg/wiki/Useful_macros_for_warriors)
