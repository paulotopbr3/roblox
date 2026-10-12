"""Verify real ranking persistence/sorting logic with substituted Roblox stores."""
from pathlib import Path
import subprocess,sys,tempfile
root=Path(__file__).resolve().parents[1]
def source(path):
 s=(root/path).read_text();assert ']====]' not in s;return '[====['+s+']====]'
code=r'''
local modules={} local stores={} local lookups=0 local unavailable=false
local function getStore(name)
 if unavailable and name:find("Gems") then error("Offline") end
 if stores[name] then return stores[name] end
 local store={Values={}}
 function store:SetAsync(key,value) self.Values[key]=value end
 function store:UpdateAsync(key,callback) self.Values[key]=callback(self.Values[key]) end
 function store:GetSortedAsync()
  local entries={} for key,value in pairs(self.Values) do table.insert(entries,{key=key,value=value}) end
  table.sort(entries,function(a,b) return a.value>b.value end)
  return {GetCurrentPage=function() return entries end}
 end
 stores[name]=store return store
end
local env={game={ReplicatedStorage={UniverseMiner={Config="Config"}},GetService=function(_,name)
 if name=="DataStoreService" then return {GetOrderedDataStore=function(_,key) return getStore(key) end} end
 return {GetNameFromUserIdAsync=function(_,id) lookups+=1 return "TestPlayer"..id end}
end},warn=function() end,require=function(key) return modules[key] end}
setmetatable(env,{__index=getfenv()})
local function load(text) local f=assert(loadstring(text)) setfenv(f,env) return f() end
'''
code+='modules.Config=load('+source('src/shared/Config.luau')+')\nlocal rankings=load('+source('src/server/Rankings.luau')+')\n'
code+=r'''
rankings.write({UserId=1},{TotalCoins=1e12,Rebirths=10,TotalPets=50,Gems=500})
rankings.write({UserId=1},{TotalCoins=100,Rebirths=1,TotalPets=1,Gems=20})
rankings.write({UserId=2},{TotalCoins=1000,Rebirths=2,TotalPets=20,Gems=100})
rankings.refresh()
assert(rankings.Cache.Coins[1].UserId==1 and rankings.Cache.Rebirths[1].UserId==1 and rankings.Cache.Pets[1].UserId==1)
assert(rankings.Cache.Gems[1].UserId==2,"Gem balance should update downward")
assert(math.abs(rankings.Cache.Coins[1].Value/1e12-1)<0.00001,"Large scores remain displayable")
assert(lookups==2,"Resolve each actual user name once, not once per board")
print("PASS historical rankings never decrease from stale writes; Gems use current balance")
print("PASS global rows sort correctly and large values survive encoding")
print("PASS user-name lookup is cached across the four tables")
unavailable=true
-- Reset the mocked cached Gems handle to model a later API failure.
local store=stores[modules.Config.DataStore.."_Rank_Gems"]
store.GetSortedAsync=function() error("Offline") end
rankings.refresh()
assert(rankings.Available.Gems==false and #rankings.Cache.Gems==2 and rankings.Available.Coins)
print("PASS failed global lookup is marked unavailable and preserves last good rows")
'''
with tempfile.TemporaryDirectory(prefix='universe-rankings-') as folder:
 p=Path(folder)/'rankings.luau';p.write_text(code)
 subprocess.run([sys.argv[1],str(p)],check=True)
