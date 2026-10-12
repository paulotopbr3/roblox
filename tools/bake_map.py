"""Run the actual map generator in a geometry-only harness and bake its scene.

This validates map construction and exports static preview geometry, not physics,
Roblox rendering, networking or ProximityPrompt behavior. Runtime rebuilds the map.
"""
from pathlib import Path
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
def literal(path):
    s=path.read_text()
    assert ']====]' not in s
    return '[====['+s+']====]'

HARNESS=r'''
local vectorMethods={}
local vectorMeta={__index=vectorMethods}
local function vector(x,y,z) return setmetatable({Type="Vector3",X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
vectorMeta.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
local colorMethods={}
local colorMeta={__index=colorMethods}
local function color(r,g,b) return setmetatable({Type="Color3",R=r,G=g,B=b},colorMeta) end
function colorMethods:Lerp(b,t) return color(self.R+(b.R-self.R)*t,self.G+(b.G-self.G)*t,self.B+(b.B-self.B)*t) end
local function cf(pos,r) return {Type="CFrame",Position=pos,R=r or {1,0,0,0,1,0,0,0,1}} end
local cfMeta={}
local function cframe(pos,r) return setmetatable(cf(pos,r),cfMeta) end
cfMeta.__mul=function(a,b)
 local r={} for row=0,2 do for col=0,2 do local total=0 for k=0,2 do total+=a.R[row*3+k+1]*b.R[k*3+col+1] end r[row*3+col+1]=total end end
 local v=b.Position local transformed=vector(a.R[1]*v.X+a.R[2]*v.Y+a.R[3]*v.Z,a.R[4]*v.X+a.R[5]*v.Y+a.R[6]*v.Z,a.R[7]*v.X+a.R[8]*v.Y+a.R[9]*v.Z)
 return cframe(a.Position+transformed,r)
end
local CF={new=function(pos) return cframe(pos or vector()) end}
function CF.Angles(x,y,z)
 local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
 return cframe(vector(),{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
end
local methods={}
function methods:FindFirstChild(name) for _,child in ipairs(self.Children) do if child.Name==name then return child end end return nil end
function methods:SetAttribute(key,value) self.Attributes[key]=value end
function methods:GetAttribute(key) return self.Attributes[key] end
function methods:Destroy() if self.Parent then for i,c in ipairs(self.Parent.Children) do if c==self then table.remove(self.Parent.Children,i) break end end end end
local function instance(class)
 local item={Class=class,Properties={},Children={},Attributes={}}
 return setmetatable(item,{
  __index=function(self,key)
   if key=="Triggered" then return {Connect=function() end} end
   return methods[key] or self.Properties[key]
  end,
  __newindex=function(self,key,value)
   if key=="Parent" then
    if self.Properties.Parent then self:Destroy() end
    self.Properties.Parent=value if value then table.insert(value.Children,self) end
   else
    self.Properties[key]=value
    if key=="CFrame" then self.Properties.Position=value.Position end
    if key=="Position" then self.Properties.CFrame=cframe(value,(self.Properties.CFrame or cf(vector())).R) end
   end
  end,
 })
end
local world=instance("Workspace") local lighting=instance("Lighting")
local enum=setmetatable({},{__index=function(_,name) return setmetatable({},{__index=function(_,value) return {Type="Enum",Name=name.."."..value} end}) end})
local env={workspace=world,Instance={new=instance},Vector3={new=vector},Color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end,fromHSV=function(h,s,v)
 local i=math.floor(h*6) local f=h*6-i local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s) local colors={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}} return color(table.unpack(colors[i%6+1])) end},
 CFrame=CF,UDim2={fromOffset=function(x,y) return {Type="UDim2",XS=0,XO=x,YS=0,YO=y} end,fromScale=function(x,y) return {Type="UDim2",XS=x,XO=0,YS=y,YO=0} end},Enum=enum,
 Random={new=function() return {NextNumber=function() return 0.5 end} end},game={ReplicatedStorage={UniverseMiner={Config="Config"}},GetService=function(_,key) assert(key=="Lighting") return lighting end},
}
setmetatable(env,{__index=getfenv()})
local function load(source) local fn=assert(loadstring(source)) setfenv(fn,env) return fn() end
'''

# Numeric enum values verified against the Roblox API dump. No external assets.
ENUMS={
    'SurfaceType.Smooth':0,'PartType.Ball':0,'PartType.Cylinder':2,
    'Material.SmoothPlastic':272,'Material.Neon':288,'Material.Sand':1296,
    'Material.Slate':800,'Material.Ice':1536,'Material.Metal':1088,
    'Font.GothamBold':19,'KeyCode.E':101,'KeyCode.ButtonX':1000,
}

def bake(place, luau, rojo):
    code=HARNESS+'\nlocal config=load('+literal(ROOT/'src/shared/Config.luau')+')\nenv.require=function() return config end\n'
    code+='local map=load('+literal(ROOT/'src/server/Map.luau')+')\nmap.build()\n'
    code+=r'''
local count,bosses=0,0 for _,c in pairs(map.Crystals) do count+=1 if c.Boss then bosses+=1 end end
assert(count==#config.Worlds*21 and bosses==#config.Worlds,"Every world must have 20 deposits and a boss")
assert(#map.Spawns==#config.Worlds and #map.AFK==2)
local function escape(s) return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
local function json(v)
 if type(v)=="string" then return escape(v) end
 if type(v)=="number" then return string.format("%.17g",v) end
 if type(v)=="boolean" then return tostring(v) end
 local array=#v>0 local out={}
 if array then for _,x in ipairs(v) do table.insert(out,json(x)) end return '['..table.concat(out,',')..']' end
 for k,x in pairs(v) do table.insert(out,escape(k)..':'..json(x)) end return '{'..table.concat(out,',')..'}'
end
local function export(item)
 local props={} for k,v in pairs(item.Properties) do if k~="Parent" and k~="Position" then props[k]=v end end
 local children={} for _,c in ipairs(item.Children) do table.insert(children,export(c)) end
 return {Class=item.Class,Properties=props,Children=children}
end
print(json(export(assert(world:FindFirstChild("UniverseMap")))))
'''
    with tempfile.TemporaryDirectory(prefix='universe-map-') as temp:
        path=Path(temp)/'map.luau';path.write_text(code)
        run=subprocess.run([luau,str(path)],capture_output=True,text=True,check=True)
        scene=json.loads(run.stdout)
    next_ref=10000
    def item(node):
        nonlocal next_ref
        next_ref+=1
        out=ET.Element('Item',{'class':node['Class'],'referent':str(next_ref)})
        props=ET.SubElement(out,'Properties')
        for name,v in node['Properties'].items():
            if node['Class'] in ('Part','WedgePart','SpawnLocation') and name in ('Size','Shape'): name=name.lower()
            if isinstance(v,bool): ET.SubElement(props,'bool',name=name).text=str(v).lower()
            elif isinstance(v,str): ET.SubElement(props,'string',name=name).text=v
            elif isinstance(v,(float,int)): ET.SubElement(props,'float',name=name).text=str(v)
            elif v['Type']=='Enum': ET.SubElement(props,'token',name=name).text=str(ENUMS[v['Name']])
            elif v['Type']=='Vector3':
                p=ET.SubElement(props,'Vector3',name=name)
                for key in ('X','Y','Z'): ET.SubElement(p,key).text=str(v[key])
            elif v['Type']=='Color3':
                if name=='Color' and node['Class'] in ('Part','WedgePart','SpawnLocation'):
                    r,g,b=(max(0,min(255,int(v[key]*255))) for key in ('R','G','B'))
                    ET.SubElement(props,'Color3uint8',name='Color3uint8').text=str(r*65536+g*256+b)
                else:
                    p=ET.SubElement(props,'Color3',name=name)
                    for key in ('R','G','B'): ET.SubElement(p,key).text=str(v[key])
            elif v['Type']=='CFrame':
                p=ET.SubElement(props,'CoordinateFrame',name=name)
                for key in ('X','Y','Z'): ET.SubElement(p,key).text=str(v['Position'][key])
                for i in range(9): ET.SubElement(p,f'R{i//3}{i%3}').text=str(v['R'][i])
            elif v['Type']=='UDim2':
                p=ET.SubElement(props,'UDim2',name=name)
                for key in ('XS','XO','YS','YO'): ET.SubElement(p,key).text=str(v[key])
            else: raise ValueError((name,v))
        for c in node['Children']:
            out.append(item(c))
        return out
    tree=ET.parse(place)
    world=next(x for x in tree.getroot().findall('Item') if x.attrib['class']=='Workspace')
    world.append(item(scene))
    # Import through Rojo's native Roblox XML reader to check serialization aliases.
    with tempfile.TemporaryDirectory(prefix='universe-map-import-') as temp:
        folder=Path(temp)
        model=ET.Element('roblox',version='4');model.append(item(scene))
        ET.ElementTree(model).write(folder/'preview.rbxmx',encoding='utf-8')
        project={'name':'MapImportValidation','tree':{'$className':'DataModel','Workspace':{'$className':'Workspace','UniverseMap':{'$path':str(folder/'preview.rbxmx')}}}}
        (folder/'default.project.json').write_text(json.dumps(project))
        subprocess.run([rojo,'build',str(folder/'default.project.json'),'-o',str(folder/'roundtrip.rbxlx')],capture_output=True,check=True)
        imported=ET.parse(folder/'roundtrip.rbxlx')
        assert len(list(imported.iter('Item'))) >= 1935
    tree.write(place,encoding='utf-8',xml_declaration=True)
    parts=sum(1 for n in tree.iter('Item') if n.attrib['class'] in ('Part','WedgePart','SpawnLocation'))
    print(f'PASS: actual map generator exports 14 islands, 294 deposits/titans and {parts} preview parts')
