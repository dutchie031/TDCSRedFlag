
TDCS Red Flag is meant to create an environment where players can practice and fly without having to respawn like one would in a RED Flag event. 
It is meant so a full mission can be flown and debriefed. Flying the way back even when being "hit" when rolling into the target area.

The script still aims to reflect realism, crashing into the ground is still being detected for instance. 

## __Disclaimer__

The goal of this script is to be generic. This does mean it does cover multiple use cases and can be altered by changing settings. 
However, this does not mean it covers all use cases one can think of. 
Sometimes the default or minimal implementation does not fit a specific use case. 
However in some cases the implementation chosen might not be configurable as for 90% of the use cases it will be the same. 
If indeed you need to have the implementation for the 10% please reach out to talk about it.

## __How to use__

Add the script `TDCSRedFlag.lua` to your mission. <br/>

See all versions here: https://github.com/dutchie032/TDCSRedFlag/releases

There is configuration values at the top of the script. Part of them are explained here. <br/>
Be careful when changing those as the lua table needs to stay in tact. 

## __Currently Implemented:__ 

### __Crash Detection__

You hit the ground or buildings too hard you will still explode. 

### __AA Missile Tracking__

Missiles being fired are tracked and the units are being updated on their status. 
"PK Miss" and "PK Hit" to indicate effectiveness of the fired missilse.
    
### __Unit kill events__

If a unit does get hit by a missile (SAM, AA, etc.) the unit itself will receive a message. (Configurable through `Config.Messages.PlayersMessages`).
When a unit is dead the unit is set to "invisible". This will inhibit AI to be able to fire on it.
If the unit is AI it will also be set to "HOLD FIRE", "INHIBIT RADAR" and will flow away from the action. 
Players will have to be instructed themselves to flow away. 

If LotATC (or another controller) clients are connected they will receive seperate message. (Configurable through `Config.Messages.ControllerMessages`)
This way controllers will be 

### __Dead units don't kill__

Fireballs don't shoot missiles, however there's been a few different implementations created of which you can pick and choose.
The logic is split up in AA munitions and AG munitions to make it as tunable as possible.

Note: This is for weapons that are launched or dropped AFTER the unit was marked dead. 
Weapons that were dropped or launched before the "kill" event are unaffected by these settings

#### __Air-to-Air Munitions__

Configurable in `Config.DeadUnitWeapons.AAWeaponsBehaviour`.

Behaviours: 

__0: Remove All (default)__

For A2A weapons the default behaviour is to remove the weapon and notify the user the shot is denied. 
The missile is deleted entirely from the mission environment.

__1: No Action__

Missiles will not be removed. Hits and misses will be registered.

#### __Air-to-Ground Munitions__

Configurable in `Config.DeadUnitWeapons.AGWeaponsBehaviour`.

__0: Remove All (default)__

For A2G weapons the default behaviour is to remove the weapon and notify the user the shot is denied. 
The weapon is deleted entirely from the mission environment. Of course a unit can still fly it's intended route.

__1: Remove Just in Time__

In the case flying the mission is just as important as practicing the drop, but you don't want any noticeable effects (so your BDA after the fact takes the dead unit into account) this option is best.
The bomb is deleted just before it impacts the ground.

__2: No action__

Weapons will not be removed. Explosions will take place just like they would hadn't the unit died. 


## __To be implemented:__

### __Mad Dog logic__

NOTE: MAD DOG BEHAVIOUR IS NOT IMPLEMENTED YET

"Mad Dogging" missiles is firing a missile without initial guidance. 

Different behaviours will be available in this red flag script. 
Place the "number" of the needed behaviour in the tab below.

Before choosing: 
    - In non "Mad Dog" circumstances the "Intended Target" is known when off the rails. 
        A Fox3 Missile will still have a "target" even when the target is fed by the host aircraft.

__0 Allow (default)__

Does allow for maddog shots. Will keep tracking missiles until it impacts a missile. 
"HIT" will be called when a missile does indeed hit a target. 

"MISS" will be called after 30 seconds of no target or the missile hits the ground before that.
If the missile does gain a target the first target will be used as intended target. 
All subsequent targets will be disregarded. (target swapping not possible)
If it does swap targets the missile will be deleted and a 10 seconds delayed "MISS" call will be triggered. 
    
__1 Automatic Miss__

If a missile is fired without an intended target the missile will always be called a miss.
This mode doesn't allow for pilots to be lucky, but still makes them think they have a chance. 
"Copy Shot" will be called. 
The missile will be tracked. When a hit is detected the kill is denied and "PK MISS" is called. 
When the missile does indeed miss "PK MISS" is called just like it does normally.

__2 Decline Shots__

All shots that do not have a target off the rails will be deleted and a message will be displayed that the shot was denied. 
Players do lose their missile if unlimited weapons were not enabled.


### __Respawn Zones__

When player units die, they can be "reset". 
For instance when a player refuels, lands or flies in a pre-designated zone.
If a zone starts with "respawnzone_" (Not case sensitive) and a unit flies through it for long enough the unit will be mar

### __Unlimited Weapons support__

Better logic and support for unlimited weapons might be added. 
Tracking weapon usage and having "REARM ZONES". 
Sadly DCS doesn't have scripting possibilities to make this easier.

### __High G load detection__

Invinsibility also makes G straining damage be ignored. 
In the future the script might be able to lend a hand in calculating this (and ripping wings off) 
