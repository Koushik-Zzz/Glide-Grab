"""Author editable Roblox JSON shells. Run from the repository root; no runtime UI factory."""
import json
from pathlib import Path

INK=(16,38,52); PANEL=(21,55,71); WHITE=(255,255,255); GOLD=(255,172,19)
GREEN=(97,233,35); SKY=(32,189,242); YELLOW=(255,224,50); RED=(240,68,59); PURPLE=(166,89,238)
art_manifest=json.loads(Path('assets/ui/manifest.json').read_text(encoding='utf-8-sig'))
ART={item['id']:item.get('robloxAssetId') for item in art_manifest['assets']}
def c(rgb): return {'Color3':[v/255 for v in rgb]}
def u(x=0,y=0,sx=0,sy=0): return {'UDim2':[[sx,x],[sy,y]]}
def n(name, cls='Frame', props=None, children=None):
    return {'Name':name,'ClassName':cls,'Properties':props or {},'Children':children or []}
def corner(r=6): return n('Corner','UICorner',{'CornerRadius':{'UDim':[0,r]}})
def stroke(width=3,color=INK,border=True):
    return n('Outline','UIStroke',{'Thickness':width,'Color':c(color),'ApplyStrokeMode':'Border' if border else 'Contextual'})
def text(name,value,size=18,pos=None,dim=None,color=WHITE,bold=True):
    return n(name,'TextLabel',{'Text':value,'TextSize':size,'TextScaled':True,'TextWrapped':True,'Font':'FredokaOne' if bold else 'GothamMedium','TextColor3':c(color),'BackgroundTransparency':1,'Position':pos or u(),'Size':dim or u(0,24,1,0),'TextXAlignment':'Left','ZIndex':4},
        [n('TextLimit','UITextSizeConstraint',{'MinTextSize':10,'MaxTextSize':size})]+([stroke(2,INK,False)] if bold else []))
def panel(name,color=PANEL,pos=None,dim=None,stud=False,button=False):
    obj=n(name,'TextButton' if button else 'Frame',{'BackgroundColor3':c(color),'BorderSizePixel':0,'Position':pos or u(),'Size':dim or u(100,50),'ZIndex':2},[corner(),stroke()])
    if button: obj['Properties'].update(Text='',AutoButtonColor=False)
    if stud:
        obj['Children'].append(n('Studs','ImageLabel',{'BackgroundTransparency':1,'Size':u(0,0,1,1),'Image':'rbxassetid://18878365966','ScaleType':'Tile','TileSize':u(64,64),'ImageTransparency':0.85,'ZIndex':2},[corner()]))
    obj['Children'] += [n('Highlight',props={'Position':u(7,4),'Size':u(-14,2,1,0),'BackgroundColor3':c(WHITE),'BackgroundTransparency':0.62,'BorderSizePixel':0,'ZIndex':3}),n('Lip',props={'Position':u(5,-5,0,1),'Size':u(-10,3,1,0),'BackgroundColor3':c(INK),'BackgroundTransparency':0.35,'BorderSizePixel':0,'ZIndex':3})]
    return obj
def shape(name,x,y,w,h,color,rot=0,roundness=0):
    obj=n(name,props={'Position':u(0,0,x/64,y/64),'Size':u(0,0,w/64,h/64),'BackgroundColor3':c(color),'BorderSizePixel':0,'Rotation':rot,'ZIndex':5},children=[stroke(2)])
    if roundness: obj['Children'].append(n('Round','UICorner',{'CornerRadius':{'UDim':[roundness,0]}}))
    return obj
def icon(kind,name='Icon',pos=None,dim=None):
    root=n(name,props={'BackgroundTransparency':1,'Position':pos or u(),'Size':dim or u(48,48),'ZIndex':5},children=[n('Square','UIAspectRatioConstraint',{'AspectRatio':1})])
    s=[]
    if kind=='Coin':
        s=[shape('Coin',5,5,54,54,GOLD,0,.5),shape('Face',12,12,40,40,YELLOW,0,.5),text('Mark','$',30,u(0,0,.3,.2),u(0,0,.4,.6),GOLD)]
    elif kind=='Bat':
        s=[shape('Grip',25,34,10,23,(168,85,38),25,.35),shape('Barrel',31,3,17,38,(239,164,79),25,.45),shape('Knob',17,53,17,7,GOLD,25,.4)]
    elif kind=='Slap':
        s=[shape('Palm',17,26,31,30,(255,213,158),0,.3),shape('Cuff',21,53,23,9,SKY,0,.15)]
        for i in range(4): s.append(shape('Finger'+str(i),15+i*9,9-abs(i-1)*-3,9,28,(255,213,158),0,.5))
        s.append(shape('Thumb',9,29,12,23,(255,213,158),-35,.4))
    elif kind=='Shield':
        s=[shape('Tip',17,27,30,30,SKY,45,.1),shape('Top',12,8,40,35,SKY,0,.18),shape('Gleam',20,14,10,31,(151,237,255),0,.1)]
    elif kind in ('Boost','Upgrades'):
        s=[shape('Upper',25,5,18,32,SKY,-25,.1),shape('Lower',20,27,18,32,YELLOW,-25,.1)]
    elif kind=='Shop':
        s=[shape('Handle',22,4,23,23,GOLD,0,.25),shape('Basket',9,24,47,31,(255,140,36),0,.1),shape('Rim',5,21,55,8,YELLOW,0,.1)]
        for i in range(3): s.append(shape('Slat'+str(i),19+i*11,32,5,15,YELLOW,0,.25))
    elif kind=='Rebirth':
        s=[shape('Top',12,12,37,9,PURPLE,0,.2), shape('Right',43,15,9,20,PURPLE,0,.2), shape('RightArrowA',34,29,20,8,PURPLE,35,.15), shape('RightArrowB',47,29,16,8,PURPLE,-35,.15), shape('Bottom',15,44,37,9,PURPLE,0,.2), shape('Left',12,29,9,20,PURPLE,0,.2), shape('LeftArrowA',3,26,16,8,PURPLE,-35,.15), shape('LeftArrowB',15,26,20,8,PURPLE,35,.15)]
    elif kind=='Glider':
        s=[shape('LeftWing',5,28,35,15,(57,139,255),-30,.1),shape('RightWing',27,28,35,15,(42,101,247),30,.1),shape('Spine',29,13,6,35,WHITE,0,.1)]
    elif kind=='Steal':
        s=[shape('Egg',21,5,27,38,(255,239,195),-15,.5),text('Arrow','→',46,u(0,0,.05,.4),u(0,0,.9,.6),PURPLE)]
    for child in s:
        if child['ClassName']=='TextLabel': child['Properties']['ZIndex']=6
    root['Attributes']={'IconKind':kind}
    asset=ART.get('boost' if kind=='Upgrades' else kind.lower())
    if asset:
        root['Children'] += [n('VectorFallback',props={'Size':u(0,0,1,1),'BackgroundTransparency':1,'ZIndex':5},children=s),
            n('Illustration','ImageLabel',{'BackgroundTransparency':1,'Size':u(0,0,1,1),'Image':'rbxassetid://'+asset,'ScaleType':'Fit','Visible':True,'ZIndex':7})]
    else:
        root['Children']+=s
    return root
def save(path,obj):
    obj.pop('Name', None)
    Path(path).write_text(json.dumps(obj,ensure_ascii=True,indent=2)+'\n',encoding='utf-8')
def find(node,name):
    if node.get('Name')==name: return node
    for child in node.get('Children',[]):
        result=find(child,name)
        if result: return result
def replace_child(parent,obj):
    parent['Children']=[x for x in parent['Children'] if x.get('Name')!=obj['Name']]+[obj]

# Preserve controller paths in the existing authored HUD.
flight=json.loads(Path('ui/FlightHUD.model.json').read_text(encoding='utf-8-sig'))
coins=find(flight,'Coins')
coins['Properties']['Size']=u(280,112)
replace_child(coins,icon('Coin',pos=u(12,22),dim=u(56,56)))
for name,pos,dim,maxsize in [('Caption',u(78,10),u(-90,19,1,0),15),('Amount',u(78,29),u(-90,40,1,0),36),('Income',u(14,-32,0,1),u(-28,24,1,0),16)]:
    obj=find(coins,name); obj['Properties'].update(Position=pos,Size=dim);find(obj,'TextLimit')['Properties']['MaxTextSize']=maxsize
find(coins,'Caption')['Properties']['Text']='COINS'
find(coins,'Amount')['Properties']['TextColor3']=c(GREEN)
replace_child(coins,text('SaveHint','',10,u(12,-12,0,1),u(-24,10,1,0),(170,199,210),False))
save('ui/FlightHUD.model.json',flight)
combat=json.loads(Path('ui/SkyCombatHUD.model.json').read_text(encoding='utf-8-sig'))
for kind in ('Slap','Bat','Steal','Shield'):
    b=find(combat,kind)
    replace_child(b,icon(kind,pos=u(-14,4,.5,0),dim=u(28,28)))
    find(b,'Key')['Properties'].update(Position=u(5,3),Size=u(17,15))
    find(b,'ActionName')['Properties'].update(Position=u(3,33),Size=u(-6,20,1,0))
    find(b,'Cooldown')['Properties'].update(Position=u(3,-19,0,1),Size=u(-6,15,1,0))
save('ui/SkyCombatHUD.model.json',combat)
boost=json.loads(Path('ui/GliderBoostHUD.model.json').read_text(encoding='utf-8-sig'))
b=find(boost,'BoostButton');replace_child(b,icon('Boost',pos=u(9,8),dim=u(40,40)))
find(b,'Status')['Properties'].update(Position=u(55,10),Size=u(-67,25,1,0))
find(b,'Hint')['Properties'].update(Position=u(55,37),Size=u(-67,20,1,0))
save('ui/GliderBoostHUD.model.json',boost)

# Shared templates are plain authored Instances; only repeated rows/prompts/FX clone at runtime.
assets=n('UIAssets','Folder')
icons=n('Icons','Folder',children=[icon(k,k,dim=u(64,64)) for k in ('Coin','Bat','Slap','Shield','Boost','Shop','Upgrades','Rebirth','Glider','Steal')])
assets['Children'].append(icons)
row=panel('ShopRow',PANEL,dim=u(0,118,1,0))
row['Children'] += [panel('Art',(26,77,95),u(12,12),u(94,94),True),text('Title','Item',25,u(122,12),u(-305,30,1,0)),text('Description','Description',15,u(122,44),u(-305,38,1,0),(215,237,242),False),text('Detail','',14,u(122,86),u(-305,20,1,0),SKY)]
action=panel('Action',GREEN,u(-174,18,1,0),u(160,82),True,True)
action['Children'] += [text('Price','$5K',23,u(8,8),u(-16,28,1,0)),text('Label','Buy',21,u(8,42),u(-16,27,1,0))]
for x in action['Children']:
    if x['ClassName']=='TextLabel': x['Properties']['TextXAlignment']='Center'
row['Children'].append(action);assets['Children'].append(row)
prompt=n('WorldPrompt','BillboardGui',{'Size':u(300,74),'AlwaysOnTop':True,'Active':True,'ResetOnSpawn':False,'StudsOffsetWorldSpace':{'Vector3':[0,1.6,0]}})
body=panel('Body',PANEL,u(3,3),u(-6,-6,1,1),False,True)
key=panel('Key',SKY,u(9,10),u(46,46),True)
key['Children'].append(text('Glyph','E',24,u(2,2),u(-4,-4,1,1)))
find(key,'Glyph')['Properties']['TextXAlignment']='Center'
body['Children'] += [key,text('Action','Grab egg',18,u(66,9),u(-77,27,1,0)),text('Detail','Common egg',12,u(66,38),u(-77,20,1,0),(204,228,237),False),n('Progress',props={'Position':u(6,-5,0,1),'Size':u(0,3),'BackgroundColor3':c(GREEN),'BorderSizePixel':0,'ZIndex':6})]
prompt['Children'].append(body);assets['Children'].append(prompt)
reward=text('Reward','+$100',25,u(),u(145,34),GREEN)
reward['Properties'].update(Visible=False,ZIndex=30,TextXAlignment='Center')
reward['Children'].append(n('Pop','UIScale',{'Scale':1}))
assets['Children'].append(reward)
save('ui/UIAssets.model.json',assets)

gui=n('CampMenu','ScreenGui',{'ResetOnSpawn':False,'ScreenInsets':'CoreUISafeInsets','DisplayOrder':30,'ZIndexBehavior':'Sibling'})
safe=n('SafeScreen',props={'Size':u(0,0,1,1),'BackgroundTransparency':1})
rail=n('Rail',props={'BackgroundTransparency':1,'Position':u(18,145),'Size':u(156,170)},children=[])
for i,(name,col) in enumerate([('Shop',GOLD),('Upgrades',SKY),('Rebirth',PURPLE)]):
    btn=panel(name,col,u(0,i*56),u(156,48),True,True)
    btn['Children'] += [icon(name,pos=u(5,4),dim=u(38,38)),text('Label',name,20,u(48,7),u(-55,34,1,0))]
    rail['Children'].append(btn)
toggle=panel('MenuToggle',GOLD,u(16,138),u(110,42),True,True)
toggle['Properties']['Visible']=False; toggle['Children'].append(text('Label','Menu',18,u(8,5),u(-16,-10,1,1)))
slot=panel('GliderSlot',PANEL,u(-42,-88,.5,1),u(84,76),False,True)
slot['Children'] += [icon('Glider',pos=u(17,3),dim=u(50,44)),text('Label','Glider',14,u(6,-24,0,1),u(-12,20,1,0)),text('Key','1',12,u(6,4),u(18,16))]
find(slot,'Label')['Properties']['TextXAlignment']='Center'
layer=n('Overlay',props={'Size':u(0,0,1,1),'BackgroundTransparency':1,'Visible':False,'ZIndex':10})
dim=n('Dim','TextButton',{'Text':'','AutoButtonColor':False,'Size':u(0,0,1,1),'BackgroundColor3':c((4,15,24)),'BackgroundTransparency':.25,'BorderSizePixel':0,'ZIndex':10,'Modal':True,'Selectable':False})
modal=panel('Modal',PANEL,u(0,0,.5,.5),u(760,450))
modal['Properties'].update(AnchorPoint={'Vector2':[.5,.5]},ZIndex=11,SelectionGroup=True,SelectionBehaviorUp='Stop',SelectionBehaviorDown='Stop',SelectionBehaviorLeft='Stop',SelectionBehaviorRight='Stop')
header=panel('Header',GOLD,u(0,0),u(0,72,1,0),True)
header['Children'] += [icon('Shop',pos=u(12,7),dim=u(57,57)),text('Title','Glider & Gear Shop',32,u(82,9),u(-158,36,1,0)),text('Subtitle','Gear for the journey. Keep your glider equipped.',14,u(82,44),u(-158,18,1,0),WHITE,False)]
close=panel('Close',RED,u(-62,10,1,0),u(50,48),True,True)
close['Children'].append(text('Label','X',31,u(5,3),u(-10,-6,1,1)));find(close,'Label')['Properties']['TextXAlignment']='Center';header['Children'].append(close)
tabs=n('Tabs',props={'Position':u(14,83),'Size':u(-28,42,1,0),'BackgroundTransparency':1})
for i,(name,col) in enumerate([('Gear',SKY),('Boost',PURPLE)]):
    tab=panel(name,col,u(i*172,0),u(160,38),True,True);tab['Children'].append(text('Label',name,20,u(10,5),u(-20,-10,1,1)));find(tab,'Label')['Properties']['TextXAlignment']='Center';tabs['Children'].append(tab)
items=n('Items','ScrollingFrame',{'Position':u(14,137),'Size':u(-28,-190,1,1),'BackgroundTransparency':1,'BorderSizePixel':0,'CanvasSize':u(),'AutomaticCanvasSize':'Y','ScrollBarThickness':5,'ScrollBarImageColor3':c(SKY),'ScrollingDirection':'Y','ZIndex':3},[n('List','UIListLayout',{'Padding':{'UDim':[0,10]},'SortOrder':'LayoutOrder'}),n('Padding','UIPadding',{'PaddingLeft':{'UDim':[0,4]},'PaddingRight':{'UDim':[0,10]},'PaddingTop':{'UDim':[0,4]},'PaddingBottom':{'UDim':[0,10]}})])
footer=text('Feedback','Purchases available in Base Camp.',14,u(20,-45,0,1),u(-40,36,1,0),(211,235,242),False)
modal['Children'] += [header,tabs,items,footer,n('OpenFeedback','UIScale')];layer['Children'] += [dim,modal]
safe['Children'] += [rail,toggle,slot,layer];gui['Children'].append(safe)
save('ui/CampMenu.model.json',gui)
print('Authored HUD, shared templates, and CampMenu.')
