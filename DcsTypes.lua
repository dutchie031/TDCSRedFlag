--[[

    This file is intended to be used as reference and easy intellisense during lua development in DCS.
    By adding this file into your LUA directory the classes and functions should be recognised by any intellisense tool that supports lua annotations.
    https://luals.github.io/wiki/annotations

    Authored by: Dutchie

    TODO: GetCategory proper types return
    TODO: Description table per type
    TODO: define fields of MissionGroupTable
    TODO: define fields for Controller class
    TODO: AMMO TABLE for CoalitionObject getAmmo
    TODO: SENSORS TABLE for CoalitionObject getSensors

]]

---Vec2 is a 2D-vector for the ground plane as a reference plane.
---@class Vec2
---@field x number
---@field y  number

---Vec3 type is a 3D-vector. It is a table that has following format
---@class Vec3
---@field x number directed to the north
---@field y number directed to the east
---@field z number directed up (away from ground)

---@class Position : Vec3
---@field p Vec3 Point on map

---@class Array<T>: { [number]: T }

---@class MGRS
---@field UTMZone string
---@field MGRSDigraph string
---@field Easting number
---@field Northing number


do -- env
    ---@class env
    ---@field mission table TODO: Mission
    ---@field info fun(log:string, showMessageBox:boolean?) Prints passed log line with prefix 'info'
    ---@field warning fun(log:string, showMessageBox:boolean?) Prints passed log line with prefix 'warning'
    ---@field error fun(log:string, showMessageBox:boolean?) Prints passed log line with prefix 'error'
    ---@field setErrorMessageBoxEnabled fun(toggle:boolean?) Enables or disables the lua error box to show up on a lua error
    ---@field getValueDictByKey fun(value:string) : string Returns a string associated with the passed dictionary key value.
    env = env
end

do -- timer
    ---@class timer
    ---@field getTime fun() : number returns the time in the mission (in seconds. 3 decimals)
    ---@field getAbsTime fun() : number returns the real time in seconds. 0 for midnight, 43200 for noon
    ---@field getTime0 fun() : number returns the mission start time in seconds
    ---@field scheduleFunction fun(functionToCall: function, arguments: table|nil, modelTime: number) : number schedule the function to be run at 'modelTime' and returns the functionID
    ---@field removeFunction fun(functionID:number) removes a scheduled function from the scheduler
    ---@field setFunctionTime fun(functionID:number, modelTime:number) reschedules an scheduled function
    timer = timer
end


do -- land
    ---@class land
    ---@field getHeight fun(position:Vec2) : number returns the distance from the sea-level to the ground alt at point
    ---@field getSurfaceHeightWithSeabed fun(position:Vec2) : sufaceHeight: number, depth: number  returns the surface height and the depth of the seabed respectively.
    ---@field getSurfaceType fun(position: Vec2) : SurfaceType returns the surface type at a certain position
    ---@field isVisible fun(origin: Vec3, target: Vec3) returns whether or not there's line between the two points that's not interrupted by terrain.
    ---@field getIP fun(origin:Vec3, direction:number, distance:number) TODO: Describe
    ---@field profile fun(start:Vec3, end:Vec3) : Array<Vec3> Returns a list of terrain points between two points. Amount is not directly known.
    ---@field getClosestPointOnRoads fun(roadType: RoadType, x : number, y : number) : x: number, y: number return x and y coordinate of the closest point on a road type.
    ---@field findPathOnRoads fun(roadType: RoadType, startX: number, startY: number, endX: number, endY: number) : Array<Vec2> Returns a list of Vec2 points of a road. Can be quite long!
    land = land

    ---@enum SurfaceType
    land.SurfaceType = {
        LAND = 1,
        SHALLOW_WATER = 2,
        WATER = 3,
        ROAD = 4,
        RUNWAY = 5
    }

    ---@alias RoadType
    ---| "roads"
    ---| "railroads"
end

do -- atmosphere
    ---@class atmosphere
    ---@field getWind fun(point:Vec3): Vec3 returns a velocity vector for the wind at a point
    ---@field getWindWithTurbulence fun(point:Vec3): Vec3 return a velocity vector for the wind including turbulent air
    ---@field getTemperatureAndPressure fun(point:Vec3) : temp: number, pressure: number returns temperature and pressure. Kelvins and Pascals.
    atmosphere = atmosphere
end

do -- world
    ---@class Event
    ---@field id world.event
    ---@field time number

    ---@class EventHandler
    ---@field onEvent fun(event: Event)

    ---@class world
    ---@field addEventHandler fun(handler: EventHandler) Adds an event handler that will be called on DCS events.
    ---@field removeEventHandler fun(handler: EventHandler) Removes an event handler from the "to call table"
    ---@field getPlayer fun() : Unit returns the unit object that is specified as "Player" in the mission editor
    ---@field getAirbases  fun(side: CoalitionSide?) : Array<Airbase> returns airbases (ships, bases, farps) of a side, or all if side is not passed
    ---@field searchObjects fun(category: ObjectCategory, searchVolume: Volume, handler: fun(item:Object, value : any?), value: any?) : table searches a volume or space for objects of a specific type and can call the handler function on each found object
    ---@field getMarkPanels fun() : table TODO: describe
    ---@field removeJunk fun(searchVolume: Volume) : number searches a volume for any wrecks, craters or debris and removes it
    ---@field getFogThickness fun() : number returns the global fog thickness. 0 if no fog is present
    ---@field setFogThickness fun(thickness: number) sets the fog thickness. 100 to 5000. 0 to remove fog
    ---@field getFogVisibilityDistance fun() : number returns the visibility distance in mist
    ---@field setFogVisibilityDistance fun(visibility:number) sets the visibility distance. 100 to 100000. If 0 the fog will be removed.
    ---@field setFogAnimation fun(dataTable: Array<Array<number>>) {relative time (seconds), visibility (meters), thickness (meters)}  eg. {5, 1000, 500},
    ---@field weather table TODO: describe weather
    world = world


    do -- Event Types
        ---@enum world.event
        world.event = {
            S_EVENT_INVALID                      = 0,
            S_EVENT_SHOT                         = 1,
            S_EVENT_HIT                          = 2,
            S_EVENT_TAKEOFF                      = 3,
            S_EVENT_LAND                         = 4,
            S_EVENT_CRASH                        = 5,
            S_EVENT_EJECTION                     = 6,
            S_EVENT_REFUELING                    = 7,
            S_EVENT_DEAD                         = 8,
            S_EVENT_PILOT_DEAD                   = 9,
            S_EVENT_BASE_CAPTURED                = 10,
            S_EVENT_MISSION_START                = 11,
            S_EVENT_MISSION_END                  = 12,
            S_EVENT_TOOK_CONTROL                 = 13,
            S_EVENT_REFUELING_STOP               = 14,
            S_EVENT_BIRTH                        = 15,
            S_EVENT_HUMAN_FAILURE                = 16,
            S_EVENT_DETAILED_FAILURE             = 17,
            S_EVENT_ENGINE_STARTUP               = 18,
            S_EVENT_ENGINE_SHUTDOWN              = 19,
            S_EVENT_PLAYER_ENTER_UNIT            = 20,
            S_EVENT_PLAYER_LEAVE_UNIT            = 21,
            S_EVENT_PLAYER_COMMENT               = 22,
            S_EVENT_SHOOTING_START               = 23,
            S_EVENT_SHOOTING_END                 = 24,
            S_EVENT_MARK_ADDED                   = 25,
            S_EVENT_MARK_CHANGE                  = 26,
            S_EVENT_MARK_REMOVED                 = 27,
            S_EVENT_KILL                         = 28,
            S_EVENT_SCORE                        = 29,
            S_EVENT_UNIT_LOST                    = 30,
            S_EVENT_LANDING_AFTER_EJECTION       = 31,
            S_EVENT_PARATROOPER_LENDING          = 32,
            S_EVENT_DISCARD_CHAIR_AFTER_EJECTION = 33,
            S_EVENT_WEAPON_ADD                   = 34,
            S_EVENT_TRIGGER_ZONE                 = 35,
            S_EVENT_LANDING_QUALITY_MARK         = 36,
            S_EVENT_BDA                          = 37,
            S_EVENT_AI_ABORT_MISSION             = 38,
            S_EVENT_DAYNIGHT                     = 39,
            S_EVENT_FLIGHT_TIME                  = 40,
            S_EVENT_PLAYER_SELF_KILL_PILOT       = 41,
            S_EVENT_PLAYER_CAPTURE_AIRFIELD      = 42,
            S_EVENT_EMERGENCY_LANDING            = 43,
            S_EVENT_UNIT_CREATE_TASK             = 44,
            S_EVENT_UNIT_DELETE_TASK             = 45,
            S_EVENT_SIMULATION_START             = 46,
            S_EVENT_WEAPON_REARM                 = 47,
            S_EVENT_WEAPON_DROP                  = 48,
            S_EVENT_UNIT_TASK_COMPLETE           = 49,
            S_EVENT_UNIT_TASK_STAGE              = 50,
            S_EVENT_MAC_EXTRA_SCORE              = 51,
            S_EVENT_MISSION_RESTART              = 52,
            S_EVENT_MISSION_WINNER               = 53,
            S_EVENT_RUNWAY_TAKEOFF               = 54,
            S_EVENT_RUNWAY_TOUCH                 = 55,
            S_EVENT_MAC_LMS_RESTART              = 56,
            S_EVENT_SIMULATION_FREEZE            = 57,
            S_EVENT_SIMULATION_UNFREEZE          = 58,
            S_EVENT_HUMAN_AIRCRAFT_REPAIR_START  = 59,
            S_EVENT_HUMAN_AIRCRAFT_REPAIR_FINISH = 60,
            S_EVENT_MAX                          = 61,
        }
    end

    ---@enum BirthPlace
    world.BirthPlace = {
        wsBirthPlace_Air = 1,
        wsBirthPlace_RunWay = 2,
        wsBirthPlace_Park = 3,
        wsBirthPlace_Heliport_Hot = 4,
        wsBirthPlace_Heliport_Cold = 5,
    }

    do --Volumes
        ---@class Volume
        ---@field id VolumeType

        ---@class Segment
        ---@field params SegmentParams

        ---@class SegmentParams
        ---@field from Vec3
        ---@field to Vec3

        ---@class Box : Volume
        ---@field params BoxParams

        ---@class BoxParams
        ---@field min Vec3
        ---@field max Vec3

        ---@class Sphere
        ---@field params SphereParams

        ---@class SphereParams
        ---@field point Vec3
        ---@field radius number

        ---@class VolumePyramid
        ---@field params VolumePyramidParams

        ---@class VolumePyramidParams
        ---@field pos Vec3
        ---@field length number
        ---@field halfAngleHor number
        ---@field halfAngleVer number
    end

    ---@enum VolumeType
    world.VolumeType = {
        SEGMENT = 1,
        BOX = 2,
        SPHERE = 3,
        PYRAMID = 4
    }
end

do -- coalition
    ---@class coalition
    ---@field addGroup fun(countryID: CountryID, groupCategory: GroupCategory, groupData: MissionGroupTable) : Group Spawn a group. If the name of the group or unit is already present the unit will be replaced.
    ---@field addStaticObject fun(countryID: CountryID, data: MissionStaticObjectTable) : StaticObject Dynamically adds a static object to the mission. Name needs to be unique. UnitID and groupID can be ommitted and will be created automatically
    ---@field getGroups fun(coalitionID : CoalitionSide, category: GroupCategory?) : Array<Group> returns group objects of a specific category (or all if no category is specified)
    ---@field getStaticObjects fun(coalitionID: CoalitionSide) : Array<StaticObject> returns static objects in a coalition
    ---@field getAirbases fun(coalitionID: CoalitionSide) : Array<Airbase> returns airbases belonging to a coalition
    ---@field getPlayers fun(coalitionID: CoalitionSide) : Array<Unit> returns units currently occupied by players
    ---@field getServiceProviders fun(coalitionID: CoalitionSide, serviceType: CoalitionService) : Array<Unit> Returns all units that provide a specific service. (AWACS, Tankers etc.)
    ---@field addRefPoint fun(coalitionID: CoalitionSide, refPoint: RefPoint) adds a new reference point to the coalition
    ---@field getRefPoints fun(coalitionID: CoalitionSide) : table TODO: Ref point return table
    ---@field getMainRefPoint fun(coalitionID: CoalitionSide) : Vec3 returns bullseye location for coalition
    ---@field getCountryCoalition fun(countryID: CountryID) : CoalitionSide returns coalitionID for a specific countryID
    coalition = coalition

    ---@class RefPoint
    ---@field callsign number
    ---@field type number
    ---@field point Vec3


    do -- group tables
        ---@class MissionGroupTable
    end

    do -- static object tables
        ---@class MissionStaticObjectTable
        ---@field heading number
        ---@field groupId number
        ---@field shape_name string
        ---@field type string
        ---@field unitId number
        ---@field rate number
        ---@field name string
        ---@field category string
        ---@field x number
        ---@field y number
        ---@field dead boolean
    end

    ---@enum CoalitionSide
    coalition.side = {
        NEUTRAL = 0,
        RED = 1,
        BLUE = 2,
    }

    ---@enum CoalitionService
    coalition.service = {
        ATC = 0,
        AWACS = 1,
        TANKER = 2,
        FAC = 3
    }
end

do -- trigger
    ---@class Trigger
    ---@field action TriggerActions
    ---@field misc TriggerMisc
    trigger = trigger

    ---@class TriggerMisc
    ---@field getUserFlag fun(flagName: string) : number returns the value of a user flag.
    ---@field getZone fun(zoneName: string) : Array<TriggerZone> returns triggerzones. Only works for cilinders really. For more detailed zone data see: env.mission.triggers.zones
    trigger.misc = trigger.misc

    ---@class TriggerActions : OutText, OutSound, OtherCommands, MarkCommands, AITriggerCommands
    ---@field ctfColorTag fun(unitName: string, smokeColor: SmokePlumeColor, minAlt: number?) Created a smoke plume behind a specified aircraft
    ---@field setUserFlag fun(flagName: string, userFlagValue: boolean|number) Sets a user flag to a specified value
    ---@field explosion fun(point: Vec3, power: number) Creates an explosion at a given point at the specified power.
    ---@field smoke fun(point: Vec3, color: SmokeColor) Creates colored smoke marker at a given point
    ---@field effectSmokeBig fun(point: Vec3, effect: SmokeEffect, density: number, name: string?) Creates a large smoke effect on a vec3 point of a specified type and density.
    ---@field effectSmokeStop fun(name: string) Stop a smoke effect effect of the passsed name
    ---@field illuminationBomb fun(point: Vec3, power: number) Creates an ilumination bomb that will burn for 300 seconds
    ---@field signalFlare fun(point: Vec3, flareColor: FlareColor, azimuth: number) Creates a signal flare at the given point in the specified color. The flare will be launched in the direction of the azimuth variable.
    ---@field radioTransmission fun(fileName: string, point:Vec3, modulation: Modulation, loop: boolean, frequency: number, power: number, name: string?) Transmits an audio file to be broadcast over a specific frequency eneminating from the specified point.
    ---@field stopRadioTransmission fun(name: string) Stops a radio transmission of the passed name
    ---@field setUnitInternalCargo fun(unitName: string, mass: number) Sets the internal cargo for the specified unit at the specified mass
    trigger.action = trigger.action

    ---@class OutSound
    ---@field outSound fun(fileName: string) Plays a sound file to all players.
    ---@field outSoundForCoalition fun(coalitionSide: CoalitionSide, soundFile: string) Plays a sound file to all players on the specified coalition.
    ---@field outSoundForCountry fun(country: CountryID, soundfile: string) Plays a sound file to all players on the specified country.
    ---@field outSoundForGroup fun(groupId: number, soundFile: string) Plays a sound file to all players in the specified group.
    ---@field outSoundForUnit fun(unitId: number, soundFile: string) Plays a sound file to all players in the specified unit.

    ---@class OutText
    ---@field outText fun(text: string, displayTime: number, clearview: boolean?) Displays the passed string of text for the specified time to all players.
    ---@field outTextForCoalition fun(coalitionId: CoalitionSide, text: string, displayTime: number, clearview: boolean?) Displays the passed string of text for the specified time to all players belonging to the specified coalition.
    ---@field outTextForCountry fun(country: CountryID, text: string, displayTime: number, clearview: boolean?) Displays the passed string of text for the specified time to all players belonging to the specified country.
    ---@field outTextForGroup fun(groupId: number, text: string, displayTime: number, clearView: boolean?) Displays the passed string of text for the specified time to all players in the specified group.
    ---@field outTextForUnit fun(unitId: number, text: string, displayTime: number, clearView: boolean?) Displays the passed string of text for the specified time to all players in the specified unit.

    ---@class OtherCommands
    ---@field addOtherCommand fun(name: string, userFlagName: string, userFlagValue: string) Adds a command to the "F10 Other" radio menu allowing players to call commands and set flags within the mission.
    ---@field removeOtherCommand fun(name: string) Removes the command that matches the specified name input variable from the "F10 Other" radio menu.
    ---@field addOtherCommandForCoalition fun(coalitionId: CoalitionSide, name: string, userFlagName: string, userFlagValue: number) Adds a command to the "F10 Other" radio menu allowing players to call commands and set flags within the mission.
    ---@field removeOtherCommandForCoalition fun(coalitionId: CoalitionSide, name: string) Removes the command that matches the specified name input variable from the "F10 Other" radio menu if the command was added for coalition.
    ---@field addOtherCommandForGroup  fun(groupId: number, name: string, userFlagName: string, userFlagValue: number) Adds a command to the "F10 Other" radio menu allowing players to call commands and set flags within the mission.
    ---@field removeOtherCommandForGroup fun(groupId: number, name: string) Removes the command that matches the specified name input variable from the "F10 Other" radio menu if the command exists for the specified group.

    ---@class MarkCommands
    ---@field markToAll fun(id: number, text:string, point:Vec3, readOnly: boolean?, message: string?) Adds a mark point to all on the F10 map with attached text.
    ---@field markToCoalition fun(id: number, text: string, point: Vec3, coalitionID: CoalitionSide, readOnly: boolean?, message: string) Adds a mark point to a coalition on the F10 map with attached text.
    ---@field markToGroup fun(id: number, text: string, point: Vec3, groupID: number, readOnly: boolean?, message: string) Adds a mark point to a group on the F10 map with attached text.
    ---@field removeMark fun(id: number) Removes a mark panel from the f10 map
    ---@field markupToAll fun(shapeID: ShapeId, coalition: DrawCoalition, id: number, ... : any) Complex parameters.  <br/> See: https://wiki.hoggitworld.com/view/DCS_func_markupToAll
    ---@field lineToAll fun(coalition: DrawCoalition, id: number, startPoint:Vec3, endPoint: Vec3, color:table, lineType: LineType, readonly: boolean?, message: string?) Creates a line on the F10 map from one point to another.
    ---@field circleToAll fun(coalition: DrawCoalition, id: number, center: Vec3 , radius: number, color: table , fillColor: table , lineType: LineType , readOnly: boolean?, message: string?) Creates a circle on the map with a given radius, color, fill color, and outline.
    ---@field rectToAll fun(coalition:DrawCoalition, id:number, startPoint: Vec3, endPoint:Vec3, color: table, fillColor: table, lineType: LineType , readOnly: boolean?, message: string?)  	Creates a rectangle on the map from the startpoint in one corner to the endPoint in the opposite corner.
    ---@field quadToAll fun(coalition:DrawCoalition, id:number, point1: Vec3, point2:Vec3, point3:Vec3, point4:Vec3,color: table, fillColor: table, lineType: LineType , readOnly: boolean?, message: string?) Creates a shape defined by the 4 points on the F10 map.
    ---@field textToAll fun(coalition:DrawCoalition, id: number, point:Vec3, color: table, fillColor: table, fontSize:table, readOnly:boolean, text:string) Creates a text imposed on the map at a given point. Text scales with the map.
    ---@field arrowToAll fun(coalition:DrawCoalition, id: number, startPoint:Vec3, endPoint:Vec3, color:table, fillColor:table, lineType:LineType, readonly:boolean?, message: string?) Creates an arrow from the startPoint to the endPoint on the F10 map. The arrow will be "pointing at" the startPoint
    ---@field setMarkupRadius fun(id:number, radius:number) Updates the radius of the specified mark to be the new value.
    ---@field setMarkupText fun(id:number, text: string) Updates the text value of the passed mark to the passed text value.
    ---@field setMarkupFontSize fun(id:number, fontSize:number) Updates the font size of the specified mark to be the new value.
    ---@field setMarkupColor fun(id:number, color:table) Updates the color of the specified mark to be the new value.
    ---@field setMarkupColorFill fun(id: number, color: table) Updates the fill color of the specified mark to be the new value.
    ---@field setMarkupTypeLine fun(id:number, lineType: LineType) Updates the type line of the specified mark to be the new value.
    ---@field setMarkupPositionEnd fun(id: number, end:Vec3) Updates the position of a mark that was defined at the last point given to create it.
    ---@field setMarkupPositionStart fun(id: number, end:Vec3) Updates the position of a mark that was defined at the last point given to create it.

    ---@class AITriggerCommands
    ---@field setAITask fun(group:Group, taskIndex:number) Sets the task of the specified index to be the one and only active task.
    ---@field pushAITask fun(group:Group, taskIndex:number) Pushes the task of the specified index to the front of the tasking queue.
    ---@field activateGroup fun(group:Group) Activates the specified group if it is setup for "late activation." Calls the Group.activate function.
    ---@field deactivateGroup fun(group:Group) Deactivates the specified group. Calls the Group.destroy function.
    ---@field setGroupAIOn fun(group:Group) Turns the specified groups AI on. Calls the Group.getController(setOnOff(true)) function.
    ---@field setGroupAIOff fun(group:Group) Turns the specified groups AI off. Calls the Group.getController(setOnOff(false)) function.
    ---@field groupStopMoving fun(group:Group) Orders the specified group to stop moving. Calls Group.getController(setCommand()) function and sets the stopRoute command to true.
    ---@field groupContinueMoving fun(group:Group) Orders the specified group to resume moving. Calls Group.getController(setCommand()) function and sets the stopRoute command to false.

    ---@enum SmokeColor
    trigger.smokeColor = {
        Green = 0,
        Red = 1,
        White = 2,
        Orange = 3,
        Blue = 4
    }

    ---@enum FlareColor
    trigger.flareColor = {
        Green = 0,
        Red = 1,
        White = 2,
        Yellow = 3
    }

    ---@alias SmokePlumeColor
    ---| 0 Disabled
    ---| 1 Green
    ---| 2 Red
    ---| 3 White
    ---| 4 Orange
    ---| 5 Blue

    ---@alias SmokeEffect
    ---| 1 small smoke and fire
    ---| 2 medium smoke and fire
    ---| 3 large smoke and fire
    ---| 4 huge smoke and fire
    ---| 5 small smoke
    ---| 6 medium smoke
    ---| 7 large smoke
    ---| 8 huge smoke

    ---@alias Modulation
    ---| 0 AM
    ---| 1 FM

    ---@alias ShapeId
    ---| 1 Line
    ---| 2 Circle
    ---| 3 Rect
    ---| 4 Arrow
    ---| 5 Text
    ---| 6 Quad
    ---| 7 Freeform

    ---@alias LineType
    ---| 0  No Line
    ---| 1  Solid
    ---| 2  Dashed
    ---| 3  Dotted
    ---| 4  Dot Dash
    ---| 5  Long Dash
    ---| 6  Two Dash

    ---@alias DrawCoalition
    ---| -1 All
    ---| 0 Neutral
    ---| 1 Red
    ---| 2 Blue

    ---@class TriggerZone
    ---@field point Vec3
    ---@field radius number
end

do --coord
    ---@class Coord
    ---@field LLtoLO fun(lattitude: number, longitude:number, altitude: number?):Vec3 Returns a point from latitude and longitude in the vec3 format.
    ---@field LOtoLL fun(point:Vec3): lattitude:number, longitude:number, altitude:number Returns multiple values of a given vec3 point in latitude, longitude, and altitude
    ---@field LLtoMGRS fun(lattitude: number, longitude:number):MGRS Returns an MGRS table from the latitude and longitude coordinates provided
    ---@field MGRStoLL fun(mgrs:MGRS): lattitude:number, longitude:number, altitude:number Returns multiple values of a given in MGRS coordinates and converts it to latitude, longitude, and altitude
    coord = coord
end

do -- missioncommands
    ---@class MissionCommands
    ---@field addCommand fun(name:string, path: table?, functionToRun: function, argument: any?):table Adds a command to the "F10 Other" radio menu allowing players to run specified scripting functions.
    ---@field addSubMenu fun(name: string, path: table?): table Creates a submenu of a specified name for all players.
    ---@field removeItem fun(path:table?) Removes the item of the specified path from the F10 radio menu for all.
    ---@field addCommandForCoalition fun(coalition: CoalitionSide, name: string, path: table?, functionToRun:function, argument:any?):table Adds a command to the "F10 Other" radio menu allowing players to run specified scripting functions.
    ---@field addSubMenuForCoalition fun(coalition:CoalitionSide, name: string, path:table?):table Creates a submenu of a specified name for the specified coalition. Can be used to create nested sub menues. If the path is not specified, submenu is added to the root menu.
    ---@field removeItemForCoalition fun(coalition:CoalitionSide, path:table?) Removes the item of the specified path from the F10 radio menu for the specified coalition.
    ---@field addCommandForGroup fun(groupId: number, name: string, path: table?, functionToRun:function, argument:any?):table Adds a command to the "F10 Other" radio menu allowing players to run specified scripting functions.
    ---@field addSubMenuForGroup fun(groupId: number, name:string, path:table?): table Creates a submenu of a specified name for the specified group.
    ---@field removeItemForGroup fun(groupId: number, path:table?) Removes the item of the specified path from the F10 radio menu for the specified group.
    missionCommands = missionCommands
end

do -- net
    ---@class Net
    ---@field send_chat fun(message:string, all:boolean?) Sends a chat message.
    ---@field send_chat_to fun(message: string, playerID: number, fromID: number?) Sends a chat message to the player with the passed id.
    ---@field load_mission fun(name:string):boolean Loads the specified mission.
    ---@field load_next_mission fun():boolean Load the next mission from the server mission list.
    ---@field get_player_list fun():table? Returns players currently connected TODO: Document table
    ---@field get_my_player_id fun():number returns playerID
    ---@field get_server_id fun():number returns the playerID for the server (currently always 1)
    ---@field get_player_info fun(playerID: number, attribute? : string) : PlayerInfo Returns a table of attributes for a given playerId. If optional attribute present only that value is returned
    ---@field kick fun(playerID:number, message:string?):boolean Kicks a player from the server. Can display a message to the user.
    ---@field get_stat fun(playeID:number, statID:number?):number
    ---@field get_name fun(playerID:number):string get players name
    ---@field get_slot fun(playerID:number):coalitionID:CoalitionSide,slotID:number gets coalitionID and slotID of a player
    ---@field force_player_slot fun(playerID: number, sideID: CoalitionSide, slotID:number) forces a
    ---@field lua2json fun(luaObject:any):string converts a lua object to a json string
    ---@field json2lua fun(json: string):table converts a json string to a lua object
    ---@field dostring_in fun(state:string, dostring:string):string Executes a lua string in a given lua environment in the game.
    ---@field log fun(text:string) writes INFO log to, recommend using "env" singleton to log as it supports all levels.
    net = net

    ---@class PlayerInfo
    ---@field id number
    ---@field name string
    ---@field side CoalitionSide
    ---@field slotID number
    ---@field ping number
    ---@field ipaddr string
    ---@field ucid string

    -- undocumented
    --@field set_slot
    --@field recv_chat
end

do -- Country
    ---@class CountrySingleton
    ---@field name table<number,string>
    country = country


    ---@enum CountryID
    country.id = {
        RUSSIA = 1,
        UKRAINE = 2,
        USA = 3,
        TURKEY = 4,
        UK = 5,
        FRANCE = 6,
        GERMANY = 7,
        CANADA = 8,
        SPAIN = 9,
        THE_NETHERLANDS = 10,
        BELGIUM = 11,
        NORWAY = 12,
        DENMARK = 13,
        ISRAEL = 14,
        GEORGIA = 15,
        INSURGENTS = 16,
        ABKHAZIA = 17,
        SOUTH_OSETIA = 18,
        ITALY = 19
    }
end

--========================
-- Classes
--========================


do -- Controller
    ---@class Controller
    Controller = Controller


    ---@alias TaskType
    ---| "NoTask"
    ---| "AttackGroup" attack group
    ---|

    ---@class Task
    ---@field id TaskType

    do -- Task Aliases
        AI = AI

        ---@enum WeaponExpend
        AI.Task.WeaponExpend = {

        }
    end

    do --TaskWrapper
        
        ---@class WrapperTask : Task

    end

    do -- Main Tasks
        ---@class MainTask : Task

        ---@class AttackGroup : MainTask
        ---@field params AttackGroupParams

        ---@class AttackGroupParams
        ---@field groupId number
        ---@field weaponType WeaponFlag?
        ---@field expend AI.Task.WeaponExpend?
        ---@field directionEnabled boolean?
        ---@field altitude number?
        ---@field attackQtyLimit boolean?
        ---@field attackQty number?
    
        ---@class AttackUnit : Task
        ---@field params AttackUnitParams
        
        ---@class AttackUnitParams
        ---@field unitId number
        ---@field weaponType WeaponFlag?
        ---@field expend AI.Task.WeaponExpend?
        ---@field direction number?
        ---@field attackQtyLimit boolean?
        ---@field attackQty number?
        ---@field groupAttack number?

        ---@class Bombing : Task 
        ---@field params BombingTaskParams
           
        ---@class BombingTaskParams
        ---@field point Vec2
        ---@field attackQty number
        ---@field weaponType WeaponFlag?
        ---@field expend AI.Task.WeaponExpend?
        ---@field attackQtyLimit boolean?
        ---@field direction number?
        ---@field groupAttack boolean?
        ---@field altitude number?
        ---@field altitudeEnabled boolean?
        ---@field attackType string "DIVE"
        
        ---@class Strafing : Task 
        --[[ 
            TODO
        ]]
            
        ---@class CarpetBombing : Task 
        --[[ 
            TODO
        ]]
            
        ---@class AttackMapObject : Task 
        --[[ 
            TODO
        ]]
            
        ---@class BombingRunway : Task 
        --[[ 
            TODO
        ]]
            
        ---@class orbit : Task 
        --[[ 
            TODO
        ]]
            
        ---@class refueling : Task 
        --[[ 
            TODO
        ]]
            
        ---@class land : Task 
        --[[ 
            TODO
        ]]
            
        ---@class follow : Task 
        --[[ 
            TODO
        ]]
            
        ---@class followBigFormation : Task 
        --[[ 
            TODO
        ]]
            
        ---@class escort : Task 
        --[[ 
            TODO
        ]]
            
        ---@class Embarking : Task 
        --[[ 
            TODO
        ]]
            
        ---@class fireAtPoint : Task 
        --[[ 
            TODO
        ]]
            
        ---@class hold : Task 
        --[[ 
            TODO
        ]]
            
        ---@class FAC_AttackGroup : Task 
        --[[ 
            TODO
        ]]
            
        ---@class EmbarkToTransport : Task 
        --[[ 
            TODO
        ]]
            
        ---@class DisembarkFromTransport : Task 
        --[[ 
            TODO
        ]]
        
        ---@class CargoTransportation : Task 
        --[[ 
            TODO
        ]]
            
        ---@class goToWaypoint : Task 
        --[[ 
            TODO
        ]]
            
        ---@class groundEscort : Task 
        --[[ 
            TODO
        ]]
            
        ---@class RecoveryTanker : Task 
        --[[ 
            TODO
        ]]
            

    end

    ---@class EnrouteTask : Task

    do -- AI
        ---@class AI
        AI = AI
        AI = {
            -- AI.Option
            Option = {
                -- AI.Option.Air
                Air = {

                    ---@enum AI.Option.Air.id
                    id = {
                        JETT_TANKS_IF_EMPTY = "25",
                        SILENCE = "7",
                        ROE = "0",
                        RADAR_USING = "3",
                        OPTION_RADIO_USAGE_ENGAGE = "22",
                        PROHIBIT_AG = "17",
                        ECM_USING = "13",
                        PROHIBIT_WP_PASS_REPORT = "19",
                        PROHIBIT_AA = "14",
                        REACTION_ON_THREAT = "1",
                        PREFER_VERTICAL = "32",
                        FORCED_ATTACK = "26",
                        PROHIBIT_AB = "16",
                        RTB_ON_OUT_OF_AMMO = "10",
                        MISSILE_ATTACK = "18",
                        PROHIBIT_JETT = "15",
                        OPTION_RADIO_USAGE_CONTACT = "21",
                        FLARE_USING = "4",
                        OPTION_RADIO_USAGE_KILL = "23",
                        FORMATION = "5",
                        RTB_ON_BINGO = "6",
                        NO_OPTION = "-1",
                    },

                    val = {
                        ---@enum AI.Option.Air.val.FLARE_USING
                        FLARE_USING = {
                            WHEN_FLYING_NEAR_ENEMIES = "3",
                            WHEN_FLYING_IN_SAM_WEZ = "2",
                            AGAINST_FIRED_MISSILE = "1",
                            NEVER = "0",
                        },

                        ---@enum AI.Option.Air.val.RADAR_USING
                        RADAR_USING = {
                            FOR_ATTACK_ONLY = "1",
                            FOR_SEARCH_IF_REQUIRED = "2",
                            NEVER = "0",
                            FOR_CONTINUOUS_SEARCH = "3",
                        },

                        ---@enum AI.Option.Air.val.REACTION_ON_THREAT
                        REACTION_ON_THREAT = {
                            BYPASS_AND_ESCAPE = "3",
                            EVADE_FIRE = "2",
                            NO_REACTION = "0",
                            PASSIVE_DEFENCE = "1",
                            ALLOW_ABORT_MISSION = "4",
                        },

                        ---@enum AI.Option.Air.val.MISSILE_ATTACK
                        MISSILE_ATTACK = {
                            HALF_WAY_RMAX_NEZ = "2",
                            MAX_RANGE = "0",
                            TARGET_THREAT_EST = "3",
                            RANDOM_RANGE = "4",
                            NEZ_RANGE = "1",
                        },

                        ---@enum AI.Option.Air.val.ECM_USING
                        ECM_USING = {
                            ALWAYS_USE = "3",
                            NEVER_USE = "0",
                            USE_IF_DETECTED_LOCK_BY_RADAR = "2",
                            USE_IF_ONLY_LOCK_BY_RADAR = "1",
                        },

                        ---@enum AI.Option.Air.val.ROE
                        ROE = {
                            WEAPON_FREE = "0",
                            RETURN_FIRE = "3",
                            OPEN_FIRE = "2",
                            WEAPON_HOLD = "4",
                            OPEN_FIRE_WEAPON_FREE = "1",
                        },
                    }
                },
                Ground = {
                    ---@enum AI.Option.Ground.id
                    id = {
                        EVASION_OF_ARM = "31",
                        ALARM_STATE = "9",
                        DISPERSE_ON_ATTACK = "8",
                        ENGAGE_AIR_WEAPONS = "20",
                        AC_ENGAGEMENT_RANGE_RESTRICTION = "24",
                        FORMATION = "5",
                        ROE = "0",
                        NO_OPTION = "-1",
                    },

                    val = {
                        ---@enum AI.Option.Ground.val.ALARM_STATE
                        ALARM_STATE = {
                            AUTO = "0",
                            GREEN = "1",
                            RED = "2",
                        },
                        ---@enum AI.Option.Ground.val.ROE
                        ROE = {
                            OPEN_FIRE = "2",
                            WEAPON_HOLD = "4",
                            RETURN_FIRE = "3"
                        }
                    }
                },
                Naval = {
                    ---@enum AI.Option.Naval.id
                    id = {
                        ROE = "0",
                        NO_OPTION = "-1",
                    },
                    val = {

                        ---@enum AI.Option.Naval.val.ROE
                        ROE = {
                            OPEN_FIRE = "2",
                            WEAPON_HOLD = "4",
                            RETURN_FIRE = "3",
                        },
                    }
                }
            },
            Task = {
                ---@enum AI.Task.OrbitPattern
                OrbitPattern = {
                    RACE_TRACK = "Race-Track",
                    CIRCLE = "Circle",
                },

                ---@enum AI.Task.Designation
                Designation = {
                    WP = "WP",
                    NO = "No",
                    LASER = "Laser",
                    IR_POINTER = "IR-Pointer",
                    AUTO = "Auto",
                },

                ---@enum AI.Task.TurnMethod
                TurnMethod = {
                    FLY_OVER_POINT = "Fly Over Point",
                    FIN_POINT = "Fin Point",
                },

                ---@enum AI.Task.VehicleFormation
                VehicleFormation = {
                    VEE = "Vee",
                    ECHELON_RIGHT = "EchelonR",
                    OFF_ROAD = "Off Road",
                    RANK = "Rank",
                    ECHELON_LEFT = "EchelonL",
                    ON_ROAD = "On Road",
                    CONE = "Cone",
                    DIAMOND = "Diamond",
                },

                ---@enum AI.Task.AltitudeType
                AltitudeType = {
                    RADIO = "RADIO",
                    BARO = "BARO",
                },

                ---@enum AI.Task.WaypointType
                WaypointType = {
                    TAKEOFF = "TakeOff",
                    TAKEOFF_PARKING = "TakeOffParking",
                    TURNING_POINT = "Turning Point",
                    TAKEOFF_PARKING_HOT = "TakeOffParkingHot",
                    LAND = "Land",
                },

                ---@enum AI.Task.WeaponExpend
                WeaponExpend = {
                    QUARTER = "Quarter",
                    TWO = "Two",
                    ONE = "One",
                    FOUR = "Four",
                    HALF = "Half",
                    ALL = "All",
                },
            },
            ---@enum AI.Skill
            Skill = {
                PLAYER = "Player",
                AVERAGE = "Average",
                HIGH = "High",
                EXCELLENT = "Excellent",
                GOOD = "Good",
                CLIENT = "Client"
            }
        }
    end
end

do -- Object
    ---@class Object
    ---@field getName fun(self:Object): string returns the name of the object in the mission environment
    ---@field isExist fun(self:Object): boolean Return a boolean value based on whether the object currently exists in the mission.
    ---@field destroy fun(self:Object) Destroys the object, physically removing it from the game world without creating an event.
    ---@field getCategory fun(self:Object): category: ObjectCategory, subCategory:number Returns an enumerator of the category for the specific object. <br/>!!Dependent on how called. Check docs
    ---@field getTypeName fun(self:Object): string returns the typename of the object
    ---@field getDesc fun(self:Object):table returns description table, which is different for each type and subtype and even object
    ---@field hasAttribute fun(self:Object, attribute:string):boolean Returns a boolean value if the object in question has the passed attribute.
    ---@field getPoint fun(self:Object):Vec3 Returns a vec3 table of the x, y, and z coordinates for the position of the given object in 3D space.
    ---@field getPosition fun(self:Object):Position Returns a Position3 table of the objects current position and orientation in 3D space.
    ---@field getVelocity fun(self:Object):Vec3 Returns a vec3 table of the objects velocity vectors.
    ---@field inAir fun(self:Object):boolean Returns a boolean value if the object in question is in the air.
    Object = Object

    ---@enum ObjectCategory
    Object.Category = {
        UNIT = 1,
        WEAPON = 2,
        STATIC = 3,
        BASE = 4,
        SCENERY = 5,
        Cargo = 6
    }
end

do --SceneryObject
    ---@class SceneryObject : Object
    ---@field getLife fun(self:SceneryObject):number gets the life of a sceneryObject
    ---@field getDescByName fun(typeName:string):table gets the description based on the typename
    SceneryObject = SceneryObject
end

do --CoalitionObject
    ---@class CoalitionObject : Object
    ---@field getCoalition fun(self:CoalitionObject):CoalitionSide Returns an enumerator that defines the coalition that an object currently belongs to.
    ---@field getCountry fun(self:CoalitionObject):CountryID Returns an enumerator that defines the country that an object currently belongs to.
    CoalitionObject = CoalitionObject
end

do --Unit
    ---@class Unit : CoalitionObject
    ---@field Category UnitCategory
    ---@field getByName fun(name: string): Unit?
    ---@field getDescByName fun(typeName: string): table?
    ---@field isActive fun(self:Unit): boolean Returns a boolean value if the unit is activated
    ---@field getPlayerName fun(self:Unit): string? Returns a string value of the name of the player if the unit is currently controlled by a player
    ---@field getID fun(self:Unit): number Returns a number which defines the unique mission id of a given object.
    ---@field getNumber fun(self:Unit):number Returns a numerical value of the default index of the specified unit within the group as defined within the mission editor or addGroup scripting function.
    ---@field getCategoryEx fun(self:Unit):number Returns an enumerator of the category for the specific object.
    ---@field getObjectID fun(self:Unit):number Returns the runtime object Id associated with the unit.
    ---@field getController fun(self:Unit):Controller Returns the controller of the specified object.
    ---@field getGroup fun(self:Unit):Group Gets the group of the unit
    ---@field getCallsign fun(self:Unit): string Returns a localized string of the units callsign
    ---@field getLife fun(self:Unit): number Returns the current "life" of a unit.
    ---@field getLife0 fun(self:Unit):number Returns the initial life value of a unit.
    ---@field getFuel  fun(self:Unit):number Returns a percentage of the current fuel remaining in an aircraft's inventory based on the maximum possible fuel load.
    ---@field getAmmo fun(self:Unit):table returns ammo table TODO: specify table
    ---@field getSensors fun(self:Unit):table returns sensors table TODO: Specify table
    ---@field hasSensors fun(self:Unit, sensorType: SensorType?, subType:OpticType|RadarType|nil) : boolean Returns true if the unit has the specified sensors.
    ---@field getRadar fun(self:Unit) : isOperational:boolean, mostInteresting: Object Returns two values. The first value is a boolean indicating if any radar on the Unit is operational.
    ---@field getDrawArgumentValue fun(self:Unit, arg:number): number Returns the current value for an animation argument on the external model of the given object
    ---@field getNearestCargos fun(self:Unit): table Returns a table of friendly cargo objects indexed numerically and sorted by distance from the helicopter.
    ---@field enableEmission fun(self:Unit, setting:boolean) Sets the passed group or unit objects radar emitters on or off.
    ---@field getDescentCapacity fun(self:Unit):number Returns the number of infantry that can be embark onto the aircraft.
    Unit = Unit

    ---@enum UnitCategory
    Unit.Category = {
        AIRPLANE      = 0,
        HELICOPTER    = 1,
        GROUND_UNIT   = 2,
        SHIP          = 3,
        STRUCTURE     = 4
    }

    ---@enum SensorType
    Unit.SensorType = {
        OPTIC = 0,
        RADAR = 1,
        IRST  = 2,
        RWR   = 3
    }

    ---@enum OpticType
    Unit.OpticType = {
        TV   = 0,   --TV-sensor
        LLTV = 1,   --Low-level TV-sensor
        IR   = 2    --Infra-Red optic sensor
    }

    ---@enum RadarType
    Unit.RadarType = {
        AS = 0,    --air search radar
        SS = 1     --surface/land search radar
    }
end

do --StaticObject
    ---@class StaticObject : CoalitionObject
    ---@field getByName fun(name:string): StaticObject? Returns a static object by name
    ---@field getDescByName fun(typeName: string): table? returns the description of this static object type
    ---@field getID fun(self:StaticObject):number Returns a number which defines the unique mission id of a given object.
    ---@field getLife fun(self:StaticObject) number Returns the current "life" of a static object.
    ---@field getCargoDisplayName fun(self:StaticObject): string Returns a string of a cargo objects mass in the format ' mass kg'
    ---@field getCargoWeight fun(self:StaticObject): number Returns the mass of a cargo object measured in kg.
    ---@field getDrawArgumentValue fun(self:Unit, arg:number): number Returns the current value for an animation argument on the external model of the given object
    StaticObject = StaticObject
end

do -- Airbase
    ---@class Airbase: CoalitionObject
    ---@field getByName fun(name:string): Airbase?  Gets an Airfield by name
    ---@field getDescByName fun(typeName: string): table? Gets airfield description
    ---@field getCallsign fun(self:Airbase): string
    ---@field getUnit fun(self:Airbase): Unit gets the unit associated with the airbase. (eg. Aircraft Carrier)
    ---@field getID fun(self:Airbase): number Returns a number which defines the unique mission id of a given object.
    ---@field getCategoryEx fun(self:Airbase):number Get category type
    ---@field getParking fun(self:Airbase, available:boolean?): Array<ParkingSpot> Returns a table of parking data for a given airbase.
    ---@field getRunways fun(self:Airbase): Array<Runway> Returns a table with runway information like length, width, course, and Name.
    ---@field getTechObjectPos fun(self:Airbase, objectType:number|string): Vec3 Returns a table of vec3 objects corresponding to the passed value.
    ---@field getDispatcherTowerPos fun(self:Airbase): Vec3 Returns the tower position
    ---@field getRadioSilentMode fun(self:Airbase): boolean Returns a boolean value for whether or not the ATC for the passed airbase object has been silenced.
    ---@field setRadioSilentMode fun(self:Airbase, silent:boolean) Sets the ATC belonging to an airbase object to be silent and unresponsive.
    ---@field autoCapture fun(self:Airbase, setting:boolean) Enables or disables the airbase and FARP auto capture game mechanic where ownership of a base can change based on the presence of ground forces or the default setting assigned in the editor.
    ---@field autoCaptureIsOn fun(self:Airbase): boolean Returns the current autoCapture setting for the passed base.
    ---@field setCoalition fun(self:Airbase, side:CoalitionSide) Changes airbase's coalition to the set value.
    ---@field getWarehouse fun(self:Airbase): Warehouse Returns the warehouse object associated with the airbase object.
    Airbase = Airbase

    ---@class ParkingSpot
    ---@field Term_Index number index
    ---@field vTerminalPos Vec3 Position
    ---@field TO_AC boolean
    ---@field Term_Index_0 number
    ---@field Term_Type TerminalType terminal type, see TerminalType
    ---@field fDistToRW number distance to runway

    ---@class Runway
    ---@field course number
    ---@field Name string
    ---@field position Vec3
    ---@field length number
    ---@field width number

    ---@enum AirbaseCategory
    Airbase.Category = {
        AIRDROME = 0,
        HELIPAD = 1,
        SHIP = 2,
    }

    ---@alias TerminalType
    ---| 16  Valid spawn points on runway
    ---| 40  Helicopter only spawn
    ---| 68  Hardened Air Shelter
    ---| 72  Open/Shelter air airplane only
    ---| 100  Small shelter
    ---| 104 Open air spawn
end

do --Warehouse
    ---@class Warehouse
    ---@field getByName fun(name:string):Warehouse Returns an instance of the calling class for the object of a specified name.
    ---@field getCargoAsWarehouse fun(object:StaticObject):Warehouse Returns a warehouse object that exists within the passed Static Object cargo crate.
    ---@field addItem fun(self:Warehouse, itemType:string|table, count:number) Adds the passed amount of a given item to the warehouse.
    ---@field getItemCount fun(self:Warehouse, itemType:string|table): number Returns the number of the passed type of item currently in a warehouse object.
    ---@field setItem fun(self:Warehouse, itemType: string|table, count:number) Sets the passed amount of a given item to the warehouse.
    ---@field removeItem fun(self:Warehouse, itemType:string|table, count:number) Removes the amount of the passed item from the warehouse.
    ---@field addLiquid fun(self:Warehouse, liquidType:LiquidType, count:number) Adds the passed amount of a liquid fuel into the warehouse inventory
    ---@field getLiquidAmount fun(self:Warehouse, liquidType:LiquidType): number Returns the amount of the passed liquid type within a given warehouse.
    ---@field setLiquidAmount fun(self:Warehouse, liquidType:LiquidType, count:number) Sets the passed amount of a liquid fuel into the warehouse inventory
    ---@field removeLiquid fun(self:Warehouse, liquidType:LiquidType, count:number) Removes the set amount of liquid from the inventory in a warehouse.
    ---@field getOwner fun(self:Warehouse): Airbase Returns the airbase object associated with the warehouse object
    ---@field getInventory fun(self:Warehouse, itemType: string|table): table Returns a full itemized list of everything currently in a warehouse.
    Warehouse = Warehouse

    ---@alias LiquidType
    ---|0 jetfuel
    ---|1 Aviation gasoline
    ---|2 MW50
    ---|3 Diesel
end

do -- Weapon
    ---@class Weapon : CoalitionObject
    ---@field getLauncher fun(self:Weapon): Unit Returns the Unit object that had launched the weapon.
    ---@field getTarget fun(self:Weapon): Object? Returns the target object that the weapon is guiding to.
    ---@field getCategoryEx fun(self:Weapon): ObjectCategory Returns an enumerator of the category for the specific object.
    Weapon = Weapon

    ---@enum WeaponCategory
    Weapon.Category = {
        SHELL = 0,
        MISSILE = 1,
        ROCKET = 2,
        BOMB = 3
    }

    do -- WeaponFlag
        ---@alias WeaponFlag
        ---| 0 No Weapon
        ---| 2 LGB
        ---| 4 TvGB
        ---| 8 SNSGB
        ---| 16 HEBomb
        ---| 32 Penetrator
        ---| 64 NapalmBomb
        ---| 128 FAEBomb
        ---| 256 ClusterBomb
        ---| 512 Dispencer
        ---| 1024 CandleBomb
        ---| 2147483648 ParachuteBomb
        ---| 14 GuidedBomb (LGB + TvGB + SNSGB)
        ---| 2147485680 AnyUnguidedBomb (HeBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb)
        ---| 2147485694 AnyBomb (GuidedBomb + AnyUnguidedBomb)
        ---| 2048 LightRocket
        ---| 4096 MarkerRocket
        ---| 8192 CandleRocket
        ---| 16384 HeavyRocket
        ---| 30720 AnyRocket (LightRocket + MarkerRocket + CandleRocket + HeavyRocket)
        ---| 32768 AntiRadarMissile
        ---| 65536 AntiShipMissile
        ---| 131072 AntiTankMissile
        ---| 262144 FireAndForgetASM
        ---| 524288 LaserASM
        ---| 1048576 TeleASM
        ---| 2097152 CruiseMissile
        ---| 1073741824 AntiRadarMissile2
        ---| 8589934592 Decoys
        ---| 1572864 GuidedASM (LaserASM + TeleASM)
        ---| 1835008 TacticalASM (GuidedASM + FireAndForgetASM)
        ---| 4161536 AnyASM (AntiRadarMissile + AntiShipMissile + AntiTankMissile + FireAndForgetASM + GuidedASM + CruiseMissile)
        ---| 4194304 SRAAM
        ---| 8388608 MRAAM
        ---| 16777216 LRAAM
        ---| 33554432 IR_AAM
        ---| 67108864 SAR_AAM
        ---| 134217728 AR_AAM
        ---| 264241152 AnyAMM(IR_AAM + SAR_AAM + AR_AAM + SRAAM + MRAAM + LRAAM)
        ---| 268402688 AnyMissile (ASM + AnyAAM)
        ---| 36012032 AnyAutonomousMissile (IR_AAM + AntiRadarMissile + AntiShipMissile + FireAndForgetASM + CruiseMissile)
        ---| 268435456 GUN_POD
        ---| 536870912 BuiltInCannon
        ---| 805306368 Cannons (GUN_POD + BuiltInCannon)
        ---| 17179869184 SmokeShell
        ---| 34359738368 Illumination Shell
        ---| 51539607552 MarkerShell
        ---| 68719476736 SubmunitionDispenserShell
        ---| 137438953472 GuidedShell
        ---| 206963736576 ConventionalShell
        ---| 258503344128 AnyShell
        ---| 4294967296 Torpedo
        ---| 2956984318 AnyAGWeapon (BuiltInCannon + GUN_POD + AnyBomb + AnyRocket + AnyASM)
        ---| 264241152 AnyAAWeapon (BuiltInCannon + GUN_POD + AnyAAM)
        ---| 2952822768 UnguidedWeapon (Cannons + BuiltInCannon + GUN_POD + AnyUnguidedBomb + AnyRocket)
        ---| 268402702 GuidedWeapon (GuidedBomb + AnyASM + AnyAAM)
        ---| 3221225470 AnyWeapon (AnyBomb + AnyRocket + AnyMissile + Cannons)
        ---| 13312 MarkerWeapon (MarkerRocket + CandleRocket + CandleBomb)
        ---| 209379642366 ArmWeapon (AnyWeapon - MarkerWeapon)
    end

    ---@enum GuidanceType
    Weapon.GuidanceType = {
        INS               = 1,
        IR                = 2,
        RADAR_ACTIVE      = 3,
        RADAR_SEMI_ACTIVE = 4,
        RADAR_PASSIVE     = 5,
        TV                = 6,
        LASER             = 7,
        TELE              = 8
    }

    ---@enum MissileCategory
    Weapon.MissileCategory = {
        AAM       = 1,
        SAM       = 2,
        BM        = 3,
        ANTI_SHIP = 4,
        CRUISE    = 5,
        OTHER     = 6
    }

    ---@enum WarheadType
    Weapon.WarheadType = {
        AP               = 0,
        HE               = 1,
        SHAPED_EXPLOSIVE = 2
    }
end

do --Group
    ---@class Group
    ---@field getByName fun(name:string): Group? gets group by name
    ---@field isExist fun(self:Group) : boolean checks if the Group currently exists
    ---@field activate fun(self:Group) activates the group
    ---@field destroy fun(self:Group) destroys a group
    ---@field getCategory fun(self:Group): objectCategory: ObjectCategory, subCategory:number
    ---@field getCoalition fun(self:Group): CoalitionSide
    ---@field getName fun(self:Group):string
    ---@field getID fun(self:Group):number
    ---@field getUnit fun(self:Group, index:number): Unit?
    ---@field getUnits fun(self:Group): Array<Unit>
    ---@field getSize fun(self:Group): number
    ---@field getInitialSize fun(self:Group): number
    ---@field getController fun(self:Group):Controller
    ---@field enableEmission fun(self:Group, enabled:boolean)
    Group = Group

    ---@enum GroupCategory
    Group.Category = {
        AIRPLANE   = 0,
        HELICOPTER = 1,
        GROUND     = 2,
        SHIP       = 3,
        TRAIN      = 4,
    }
end

do --Spot
    ---@class Spot
    ---@field createInfraRed fun(source:Object, localPoint: Vec3?, targetPoint:Vec3, lasercode:number?):Spot Creates an infrared ray emanating from the given object to a point in 3d space. Can be seen with night vision goggles.
    ---@field createLaser fun(source:Object, localRef: Vec3, targetPoint:Vec3, lasercode:number?):Spot Creates a laser ray emanating from the given object to a point in 3d space.
    ---@field destroy fun(self:Spot) destroys the laser/ir beam
    ---@field getCategory fun(self:Spot) : ObjectCategory
    ---@field getPoint fun(self:Spot): Vec3
    ---@field setPoint fun(self:Spot, point:Vec3) sets the target spot
    ---@field getCode fun(self:Spot): number Returns the number that is used to define the laser code for which laser designation can track.
    ---@field setCode fun(self:Spot, code:number) sets the laster code.
    Spot = Spot
end
