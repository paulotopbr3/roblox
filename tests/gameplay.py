"""Run authoritative game/content logic with explicit Roblox API substitutes."""
from pathlib import Path
import subprocess
import sys
import tempfile
root=Path(__file__).resolve().parents[1]
def source(name):
    text=(root/name).read_text()
    assert ']====]' not in text
    return '[====['+text+']====]'

code=r'''
local modules={}
local guid=0
local messages={}
local prompted=0
local services={
 DataStoreService={GetDataStore=function() error("Unpublished") end},
 RunService={IsStudio=function() return true end},
 HttpService={GenerateGUID=function() guid+=1 return "uid-"..guid end},
 MessagingService={},
 MarketplaceService={GetProductInfoAsync=function() return {PriceInRobux=79,IsForSale=true} end,UserOwnsGamePassAsync=function() return true end,PromptGamePassPurchase=function() prompted+=1 end},
 Players={},
}
local environment={
 game={JobId="",ReplicatedStorage={UniverseMiner={Config="Config",Balance="Balance",Economy="Economy",Progression="Progression"}},GetService=function(_,key) return assert(services[key],key) end},
 script={Parent={Data="Data",Map="Map",Content="Content",Game="Game"}},
 require=function(key) return assert(modules[key],key) end,
 Random={new=function() return {NextNumber=function() return 0.5 end} end},
 Enum={InfoType={GamePass="GamePass",Product="Product"}},
 task={spawn=function() end,wait=function() end},warn=function() end,
}
setmetatable(environment,{__index=getfenv()})
local function load(text) local fn=assert(loadstring(text)) setfenv(fn,environment) return fn() end
local tests=0
local function test(name,fn) fn() tests+=1 print("PASS "..name) end
'''
for key,name in [('Config','shared/Config'),('Balance','shared/Balance'),('Economy','shared/Economy'),('Progression','shared/Progression'),('Data','server/Data'),('Content','server/Content')]:
    code+='\nmodules.'+key+'=load('+source('src/'+name+'.luau')+')\n'
code+=r'''
modules.Map={Crystals={},near=function(player) return player.Near~=false end,teleport=function(player,id) player.Teleported=id end,hit=function(c,damage) c.Health=math.max(0,c.Health-damage) return c.Health==0 end}
'''
code+='\nmodules.Game=load('+source('src/server/Game.luau')+')\n'
code+='\nmodules.Commerce=load('+source('src/server/Commerce.luau')+')\n'
code+=r'''
local G,D,C,P,B=modules.Game,modules.Data,modules.Config,modules.Progression,modules.Balance
G.init({FireClient=function(_,player,kind,value) table.insert(messages,{Player=player,Kind=kind,Value=value}) end})
G.event=function() return {Active=false,Kind="Coins"} end
local function player(id)
 local p={UserId=id,DisplayName="Tester",Near=true}
 local s=D.load(p) assert(s and s.Temporary) G.join(p) return p,s.Data
end
local p,d=player(1)
test("welcome pet and discoveries granted once",function()
 assert(#d.Pets==1 and d.Pets[1].Id=="starter" and d.Discoveries.starter and P.value(d,"WorldCount")==1)
 G.join(p) assert(#d.Pets==1)
end)
test("late client sync always receives full inventory",function()
 G.snapshot(p) G.snapshot(p)
 G.action(p,"Sync")
 local latest=messages[#messages]
 assert(latest.Kind=="State" and latest.Value.Pets and latest.Value.Equipped)
end)
test("tutorial cannot skip or duplicate reward",function()
 local gems=d.Gems G.action(p,"Tutorial") assert(d.Tutorial==1 and d.Gems==gems)
 d.Crystals=5 G.action(p,"Tutorial") assert(d.Tutorial==2 and d.Gems==gems+15)
 G.action(p,"Tutorial") assert(d.Tutorial==2 and d.Gems==gems+15)
end)
test("login gift cannot be claimed twice",function()
 G.action(p,"LoginGift") local gems=d.Gems local credits=d.EggCredits
 G.action(p,"LoginGift") assert(d.Gems==gems and d.EggCredits==credits)
 assert(d.Login.Streak==1)
end)
test("gem upgrades charge exactly and obey bounds",function()
 d.Gems=29 G.action(p,"Upgrade","Damage") assert(d.Upgrades.Damage==0 and d.Gems==29)
 d.Gems=30 G.action(p,"Upgrade","Damage") assert(d.Upgrades.Damage==1 and d.Gems==0)
 d.Upgrades.Damage=C.GemUpgrades.Damage.Max d.Gems=1000 G.action(p,"Upgrade","Damage") assert(d.Gems==1000)
 G.action(p,"Upgrade","fake") assert(d.Gems==1000)
end)
test("fusion uses three unequipped matches and preserves equipped pets",function()
 d.Pets={} d.Equipped={} d.Gems=500
 local equipped=G.pet(d,"w1r1")
 local group={} for i=1,3 do local pet=G.pet(d,"w1r1") table.insert(group,pet) end
 d.Equipped={equipped.Uid}
 G.action(p,"Fuse",group[1].Uid)
 assert(#d.Pets==2 and d.Gems==450)
 assert(d.Pets[1].Uid==equipped.Uid and d.Pets[2].Tier==1)
 local gems=d.Gems G.action(p,"Fuse",group[1].Uid) assert(d.Gems==gems and #d.Pets==2)
end)
test("fusion rejects insufficient gems without consuming inventory",function()
 d.Pets={} d.Equipped={} for i=1,3 do G.pet(d,"w1r2") end d.Equipped={} d.Gems=49
 G.action(p,"Fuse",d.Pets[1].Uid) assert(#d.Pets==3 and d.Gems==49)
end)
test("collection and achievements claim once",function()
 d.Gems=0 G.action(p,"Discovery","starter") assert(d.Gems==10)
 G.action(p,"Discovery","starter") assert(d.Gems==10)
 G.action(p,"Discovery","w14r7") assert(d.Gems==10)
 d.Crystals=50 G.action(p,"Achievement",1) assert(d.Gems==60)
 G.action(p,"Achievement",1) assert(d.Gems==60)
end)
test("playtime gifts require server time and reject replay",function()
 d.Gems=0 G.action(p,"PlayGift",1) assert(d.Gems==0)
 G.Runtime[p].JoinedAt=os.clock()-121 G.action(p,"PlayGift",1) assert(d.Gems==15)
 G.action(p,"PlayGift",1) assert(d.Gems==15)
end)
test("backpack upgrades apply before damage and combo rewards cap",function()
 d.Pets={} d.Equipped={} d.Tool=1 d.Upgrades.Damage=0 d.Upgrades.Backpack=1 d.Upgrades.Coins=0 d.BagCount=30 d.Bag=0 d.World=1
 local c={World=1,Health=1,MaxHealth=1,Part={Position="position"},Rare=false}
 modules.Map.Crystals[101]=c G.Runtime[p].LastHit=-100 G.mine(p,101)
 assert(d.BagCount==31 and c.Health==0 and d.Bag>0)
 d.BagCount=45 c.Health=1 G.Runtime[p].LastHit=-100 G.mine(p,101) assert(c.Health==1)
 assert(P.combo(1000)==1.5)
end)
test("distant mining and unknown crystal do not reward",function()
 local coins=d.Coins local crystals=d.Crystals
 p.Near=false G.mine(p,101) G.mine(p,999999)
 assert(d.Coins==coins and d.Crystals==crystals) p.Near=true
end)
test("cooperative boss pays connected contributors once",function()
 local p2,d2=player(2)
 d.Pets={} d.Equipped={} d.Upgrades.Damage=0 d.BagCount=45 d.Bag=0 d.Tool=1 d.World=1
 d2.Pets={} d2.Equipped={} d2.Tool=1
 local c={Boss=true,World=1,Health=6,MaxHealth=6,Part={Position="boss"},Contributors={}}
 modules.Map.Crystals[199]=c
 G.Runtime[p].LastHit=-100 G.mine(p,199) assert(c.Health==3)
 G.Runtime[p2].LastHit=-100 G.mine(p2,199)
 assert(c.Health==0 and d.BossWins==1 and d2.BossWins==1 and d2.Coins>0)
 local coins=d2.Coins G.Runtime[p2].LastHit=-100 G.mine(p2,199) assert(d2.Coins==coins)
end)
test("rebirth preserves gem upgrades and collection",function()
 d.Coins=B.rebirthCost(d.Rebirths) d.Upgrades.Slots=2 d.Upgrades.Backpack=3 d.Unlocked["2"]=true d.VisitedWorlds["2"]=true
 G.rebirth(p)
 assert(d.Tool==1 and d.World==1 and not d.Unlocked["2"] and d.Upgrades.Slots==2 and d.Upgrades.Backpack==3 and d.Discoveries.starter and P.value(d,"WorldCount")==2)
 assert(B.petSlots(d)==5)
end)
test("fusion boundaries, variant power and streak wrap",function()
 assert(P.variant(0)==1 and P.variant(1)==2.5 and P.variant(2)==6.25)
 assert(P.streak(10,7,11)==1 and P.streak(10,6,11)==7 and P.streak(10,6,12)==1 and P.streak(10,6,10)==nil)
 assert(P.fusion({{Uid="a",Id="x",Tier=2}},{},"a")==nil)
end)
test("store metadata uses Roblox price and owned passes do not reprompt",function()
 C.Passes.DoubleCoins=42 modules.Commerce.loadCatalog()
 assert(modules.Commerce.Catalog.Passes.DoubleCoins.Price==79 and not modules.Commerce.Catalog.Passes.AutoMine.Configured)
 d.Passes.DoubleCoins=true modules.Commerce.prompt(p,{Type="Pass",Key="DoubleCoins"}) assert(prompted==0)
 d.Passes.DoubleCoins=false modules.Commerce.prompt(p,{Type="Pass",Key="DoubleCoins"}) assert(prompted==1)
 C.Passes.DoubleCoins=0
end)
test("graphics preferences persist without changing economy",function()
 local coins,gems,tool=d.Coins,d.Gems,d.Tool
 G.action(p,"Graphics","Low") assert(d.Settings.Graphics=="Low")
 G.action(p,"Graphics","Ultra") assert(d.Settings.Graphics=="Low")
 G.action(p,"Graphics","Auto") assert(d.Settings.Graphics=="Auto")
 assert(d.Coins==coins and d.Gems==gems and d.Tool==tool)
end)
test("legacy profile gains new fields without losing progress",function()
 local legacy={Version=1,Coins=250,Gems=45,Rebirths=5,Tool=3,World=2,Unlocked={["1"]=true,["2"]=true},Pets={{Uid="old-pet",Id="w1r2"}},Codes={WELCOME=true}}
 services.DataStoreService.GetDataStore=function() return {UpdateAsync=function(_,key,transform) return transform({Data=legacy}) end} end
 local migrated=assert(D.load({UserId=99}))
 local value=migrated.Data
 assert(not migrated.Temporary and value.Coins==250 and value.Gems==45 and value.Tool==3 and value.Rebirths==5)
 assert(value.Upgrades.Slots==0 and value.Pets[1].Tier==0 and value.Discoveries.w1r2 and value.VisitedWorlds["2"] and value.Codes.WELCOME)
end)
print(tests.." gameplay checks passed with simulated Roblox services")
'''
with tempfile.TemporaryDirectory(prefix='universe-gameplay-') as folder:
    p=Path(folder)/'gameplay.luau';p.write_text(code)
    subprocess.run([sys.argv[1],str(p)],check=True)
