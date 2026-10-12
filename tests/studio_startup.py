"""Exercise actual modules with unavailable Studio DataStores, without Roblox."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
def source(relative):
    text = (root / relative).read_text()
    delimiter = '===='
    assert ']' + delimiter + ']' not in text
    return '[' + delimiter + '[' + text + ']' + delimiter + ']'

harness = r'''
local studio = true
local storeCalls = 0
local warnings = 0
local built = false
local function connect() end
local event = {Connect = connect}
local services = {
 DataStoreService = {
  GetDataStore = function() storeCalls+=1 error("You must publish this place to the web to access DataStore") end,
  GetOrderedDataStore = function() storeCalls+=1 error("You must publish this place to the web to access DataStore") end,
 },
 RunService = {IsStudio = function() return studio end},
 HttpService = {GenerateGUID = function() return "test-session" end},
 Players = {PlayerAdded=event,PlayerRemoving=event,GetPlayers=function() return {} end},
}
local modules = {}
local environment = {
 game = {JobId="",ReplicatedStorage={UniverseMiner={Config="Config"}},GetService=function(_,name) return assert(services[name],name) end,BindToClose=function() end},
 script = {Parent={Data="Data",Map="Map",Game="Game",Commerce="Commerce",Rankings="Rankings",Gear="Gear"}},
 Instance = {new=function() return {OnServerEvent=event} end},
 task = {spawn=function() end,wait=function() end},
 warn = function() warnings+=1 end,
 require = function(key) return assert(modules[key],"Unknown module "..tostring(key)) end,
}
setmetatable(environment,{__index=getfenv()})
local function load(source)
 local fn=assert(loadstring(source)) setfenv(fn,environment) return fn()
end
'''
harness += '\nmodules.Config=load(' + source('src/shared/Config.luau') + ')\n'
harness += '\nmodules.Data=load(' + source('src/server/Data.luau') + ')\n'
harness += '\nmodules.Rankings=load(' + source('src/server/Rankings.luau') + ')\n'
harness += r'''
assert(storeCalls==0,"Loading modules must not acquire inaccessible stores")
print("PASS unpublished modules load without DataStore access")
local player={UserId=42,Kick=function() error("Studio player should not be kicked") end}
local session=modules.Data.load(player)
assert(session and session.Temporary and session.Data.Coins==0)
assert(modules.Data.writable(player) and modules.Data.save(player,false))
modules.Data.release(player)
assert(modules.Data.Sessions[player]==nil)
print("PASS unpublished Studio falls back to a playable temporary session")
studio=false
local productionPlayer={UserId=43}
local denied,reason=modules.Data.load(productionPlayer)
assert(denied==nil and type(reason)=="string" and modules.Data.Sessions[productionPlayer]==nil)
print("PASS production cannot replace unavailable profiles with temporary data")
modules.Rankings.refresh()
assert(not modules.Rankings.Busy and modules.Rankings.Updated>0)
modules.Rankings.write(player,{TotalCoins=10,Rebirths=0,TotalPets=0,Gems=0})
assert(warnings>=10)
print("PASS unavailable rankings remain nonfatal")
modules.Map={build=function() built=true end}
modules.Game={init=function() end,subscribe=function() end}
modules.Commerce={init=function() end}
modules.Gear={update=function() end,swing=function() end}
'''
harness += '\nload(' + source('src/server/Main.server.luau') + ')\n'
harness += 'assert(built,"Server must reach map generation")\nprint("PASS server bootstrap reaches map generation with unavailable DataStores")\n'
with tempfile.TemporaryDirectory(prefix='universe-startup-') as folder:
    file = Path(folder) / 'startup.luau'
    file.write_text(harness)
    subprocess.run([sys.argv[1], str(file)], check=True)
