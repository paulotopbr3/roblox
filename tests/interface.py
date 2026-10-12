"""Exercise actual client menu construction with substituted Roblox objects.

This catches nil fields and invalid text values; it does not render Roblox UI.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools'))
from bake_map import HARNESS,literal
code=HARNESS+r'''
local function signal()
 local s={Handlers={}}
 function s:Connect(fn) table.insert(self.Handlers,fn) return {Disconnect=function() end} end
 function s:Fire(...) for _,fn in ipairs(self.Handlers) do fn(...) end end
 return s
end
local signals={Activated=true,InputBegan=true,InputEnded=true,TouchTapInWorld=true,RenderStepped=true,OnClientEvent=true}
local function object(class)
 local item=instance(class) local meta=getmetatable(item) local previous=meta.__index local setter=meta.__newindex
 rawset(item,"Events",{})
 meta.__index=function(self,key)
  if signals[key] then if not self.Events[key] then self.Events[key]=signal() end return self.Events[key] end
  if key=="AbsoluteSize" or key=="AbsoluteContentSize" then return {X=600,Y=300} end
  return previous(self,key) or self:FindFirstChild(key)
 end
 meta.__newindex=function(self,key,value)
  if key=="Text" or key=="Image" then assert(type(value)=="string",class.."."..key.." must be a string") end
  setter(self,key,value)
 end
 if class=="ScrollingFrame" then item.CanvasPosition={X=0,Y=0} end
 return item
end
function methods:GetDescendants() local all={} for _,c in ipairs(self.Children) do table.insert(all,c) for _,d in ipairs(c:GetDescendants()) do table.insert(all,d) end end return all end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function methods:FindFirstChildWhichIsA(class)
 for _,c in ipairs(self.Children) do if c:IsA(class) then return c end end
end
function methods:FindFirstChild(name,recursive)
 for _,c in ipairs(self.Children) do if c.Name==name then return c end if recursive then local found=c:FindFirstChild(name,true) if found then return found end end end
end
function methods:IsA(class)
 return self.Class==class or class=="BasePart" and (self.Class=="Part" or self.Class=="WedgePart") or class=="GuiButton" and self.Class=="TextButton"
end
function methods:GetPropertyChangedSignal(key)
 if not self.Events[key] then self.Events[key]=signal() end return self.Events[key]
end
function methods:Play() end
local function count(parent,class)
 local n=parent.Class==class and 1 or 0 for _,c in ipairs(parent.Children) do n+=count(c,class) end return n
end
local user=object("Player") user.Name="Tester" user.UserId=1
local playerGui=object("PlayerGui") playerGui.Name="PlayerGui" playerGui.Parent=user
local shared=object("Folder") shared.Name="UniverseMiner"
local client=object("Folder")
local replicated=object("ReplicatedStorage") shared.Parent=replicated
local remotes=object("Folder") remotes.Name="Remotes" remotes.Parent=shared
local outbound=object("RemoteEvent") outbound.Name="Update" outbound.Parent=remotes
local inbound=object("RemoteEvent") inbound.Name="Action" inbound.Parent=remotes
local intents={}
function methods:FireServer(key,arg) table.insert(intents,{Key=key,Arg=arg}) end
local camera=object("Camera") camera.ViewportSize={X=1366,Y=900} world.CurrentCamera=camera
local guiService={SelectedObject=nil}
local input={InputBegan=signal(),InputEnded=signal(),TouchTapInWorld=signal(),GamepadEnabled=false,GetFocusedTextBox=function() return nil end}
local services={Players={LocalPlayer=user},UserInputService=input,ContextActionService={BindAction=function() end},RunService={RenderStepped=signal()},Debris={AddItem=function() end},SoundService=object("SoundService"),GuiService=guiService,SocialService={},StarterGui={SetCoreGuiEnabled=function() end},TweenService={Create=function() return {Play=function() end} end},ReplicatedStorage=replicated,Lighting=object("Lighting")}
env.game.GetService=function(_,key) return assert(services[key],key) end
env.game.ReplicatedStorage=replicated env.Instance.new=object
function methods:PivotTo(value) self.PrimaryPart.CFrame=value end
local cfMethods={}
function cfMethods:Lerp(other) return other end
cfMeta.__index=cfMethods
local originalCF=CF.new
CF.new=function(x,y,z) return originalCF(x,type(y)=="table" and nil or y,z) end
env.Vector2={new=function(x,y) return {X=x,Y=y} end}
env.UDim={new=function(scale,offset) return {Scale=scale,Offset=offset} end}
env.UDim2.new=function(xs,xo,ys,yo) return {Type="UDim2",XS=xs,XO=xo,YS=ys,YO=yo} end
env.ColorSequence={new=function() return {} end}
env.NumberRange={new=function() return {} end}
env.TweenInfo={new=function() return {} end}
env.task={delay=function() end,spawn=function() end,wait=function() end}
local modules={}
env.require=function(key) return assert(modules[type(key)=="table" and key.Name or key],tostring(key)) end
local function module(name,source,parent)
 local marker=object("ModuleScript") marker.Name=name marker.Parent=parent env.script={Parent=parent}
 modules[name]=load(source) return modules[name]
end
'''
for name,path,parent in [('Config','shared/Config','shared'),('Balance','shared/Balance','shared'),('Progression','shared/Progression','shared'),('Art','shared/Art','shared'),('Presentation','shared/Presentation','shared'),('Models','shared/Models','shared'),('UI','client/UI','client'),('Graphics','client/Graphics','client'),('Visuals','client/Visuals','client')]:
    code+='\nmodule("'+name+'",'+literal(root/('src/'+path+'.luau'))+','+parent+')\n'
code+='env.script={Parent=client}\nload('+literal(root/'src/client/Main.client.luau')+')\n'
code+=r'''
local snapshot={Coins=100000,Gems=1000,Rebirths=2,Tool=5,World=1,Unlocked={["1"]=true,["2"]=true},VisitedWorlds={["1"]=true,["2"]=true},
 Pets={{Uid="a",Id="w1r1"},{Uid="b",Id="w1r2",Tier=1},{Uid="c",Id="starter"}},Equipped={"a"},Passes={},Settings={},Boosts={},Bag=100,BagCount=5,EggCredits=2,Crystals=100,TotalCoins=10000,TotalPets=3,Daily={Crystals=100,Coins=10000,Eggs=15,Claimed={}},Level=4,CoinMultiplier=1.5,DamageMultiplier=1.5,LuckMultiplier=1,RebirthCost=10000,Store={Passes={},Products={}},
 Content={Tutorial=1,TutorialProgress=5,Upgrades={Damage=0,Coins=0,Backpack=0,Slots=0},Login={LastDay=-1,Streak=0},CanLogin=true,PlaySeconds=180,PlayClaimed={},Achievements={},Discoveries={w1r1=true,w1r2=true,starter=true},DiscoveryClaims={},Hatched=15,BossWins=1,Capacity=30,Combo=0},Event={Active=false,Kind="Coins",Ends=0,Next=9999999999}}
outbound.OnClientEvent:Fire("State",snapshot)
assert(count(playerGui,"ScreenGui")==1)
local checks=0
for _,name in ipairs({"More","Guide","Tools","Upgrades","Eggs","Inventory","Pets","Collection","Worlds","Rewards","Quests","Rebirth","Shop","Events","Rankings","Codes","Settings"}) do
 outbound.OnClientEvent:Fire("Open",name)
 assert(count(playerGui,"TextButton")>=6)
 if name=="Pets" or name=="Collection" or name=="Eggs" or name=="Tools" or name=="Worlds" then assert(count(playerGui,"ViewportFrame")>0,name.." must include actual portraits") end
 checks+=1
end
outbound.OnClientEvent:Fire("Open","Rankings")
outbound.OnClientEvent:Fire("Rankings",{Rows={Coins={{Name="RealPlayer",UserId=1,Value=1000}}},Available={Coins=true}})
assert(count(playerGui,"ImageLabel")>0,"Top global includes player portraits")
camera.ViewportSize={X=375,Y=812} camera:GetPropertyChangedSignal("ViewportSize"):Fire()
for _,name in ipairs({"Pets","Tools","Worlds","More"}) do outbound.OnClientEvent:Fire("Open",name) end
local map=object("Folder") map.Name="UniverseMap" map.Parent=world
local biome=object("Folder") biome:SetAttribute("WorldIndex",1) biome.Parent=map
local details=object("Folder") details.Name="GraphicsDetails" details.Parent=biome
local leaf=object("Part") leaf.Parent=details
snapshot.Settings.Graphics="Low" outbound.OnClientEvent:Fire("State",snapshot)
assert(leaf.LocalTransparencyModifier==1 and modules.Graphics.Effective=="Low")
snapshot.Settings.Graphics="High" outbound.OnClientEvent:Fire("State",snapshot)
assert(leaf.LocalTransparencyModifier==0 and modules.Graphics.Effective=="High")
print("PASS quality changes hide only the cosmetic detail layer")
print("PASS "..checks.." actual client menus construct with substituted Roblox services")
print("PASS visual galleries include portrait viewports, and global table includes avatars")
print("PASS phone resize executes without errors (rendering still requires Studio)")
'''
with tempfile.TemporaryDirectory(prefix='universe-interface-') as folder:
    p=Path(folder)/'interface.luau';p.write_text(code)
    subprocess.run([sys.argv[1],str(p)],check=True)
