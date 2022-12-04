local L                         = Scorpio("Scorpio")._Locale("zhCN")
if not L then return end

-----------------------------------------------------------
--                      Core System                      --
-----------------------------------------------------------
L["smoothloading"]              = "平滑启动"
L["loglevel"]                   = "日志等级"
L["taskthreshold"]              = "任务耗时阈值"
L["taskfactor"]                 = "任务耗时因子"

L["Trace"]                      = "跟踪"
L["Debug"]                      = "调试"
L["Info"]                       = "信息"
L["Warn"]                       = "警告"
L["Error"]                      = "错误"
L["Fatal"]                      = "致命错误"

-----------------------------------------------------------
--                Macro Condition Dialog                 --
-----------------------------------------------------------
L["Confirm when you finished the key binding"]          = "完成按键绑定后点击确认"

L["Player is in a vehicle and can exit it at will."]    = "玩家在一个载具中并且可以正常退出。"
L["Player is in combat."]                               = "玩家在战斗中。"
L["Conditional target exists and is dead."]             = "条件对象存在并且已死亡。"
L["Conditional target exists."]                         = "条件对象存在。"
L["The player can use a flying mount in this zone (though incorrect in Wintergrasp during a battle)."] = "玩家在当前地区可以飞行（尽管可能因为其它原因不能，比如冬拥湖战斗时）"
L["Mounted or in flight form AND in the air."]          = "玩家飞行中。"
L["The player is in any form."]                         = "玩家处于任意姿态中。类似德鲁伊的变身，战士的防御姿态等。"
L["The player is not in any form."]                     = "玩家不处于任意姿态中。"
L["The player is in form 1."]                           = "玩家处于第一个姿态。"
L["The player is in form 2."]                           = "玩家处于第二个姿态。"
L["The player is in form 3."]                           = "玩家处于第三个姿态。"
L["The player is in form 4."]                           = "玩家处于第四个姿态。"
L["Player is in a party."]                              = "玩家在一个队伍中。"
L["Player is in a raid."]                               = "玩家在一个团队中。"
L["Conditional target exists and can be targeted by harmful spells (e.g.  [Fireball])."] = "条件对象存在并且可以被施以伤害法术。（例如火球术）"
L["Conditional target exists and can be targeted by helpful spells (e.g.  [Heal])."] = "条件对象存在并且可以被施以辅助法术（例如治疗术）"
L["Player is indoors."]                                 = "玩家在室内。"
L["Player is mounted."]                                 = "玩家使用坐骑中。"
L["Player is outdoors."]                                = "玩家在室外。"
L["Conditional target exists and is in your party."]    = "条件对象存在并且在玩家队伍中。"
L["The player has a pet."]                              = "玩家带有宠物。"
L["Currently participating in a pet battle."]           = "玩家正在进行宠物对战。"
L["Conditional target exists and is in your raid/party."] = "条件对象存在并且在玩家的团队中。"
L["Player is currently resting."]                       = "玩家处于休息状态。"
L["Player's active the first specialization group (spec, talents and glyphs)."] = "玩家的第一个专精启用中。"
L["Player's active the second specialization group (spec, talents and glyphs)."] = "玩家的第二个专精启用中。"
L["Player is stealthed."]                               = "玩家处于潜行状态。"
L["Player is swimming."]                                = "玩家处于潜水状态。"
L["Player has vehicle UI."]                             = "玩家正在使用载具。"
L["Player currently has an extra action bar/button."]   = "玩家目前有一个额外动作条/按钮。"
L["Player's main action bar is currently replaced by the override action bar."] = "玩家的主动作条正被override动作覆盖。"
L["Player's main action bar is currently replaced by the possess action bar."] = "玩家的主动作条正被被控制者的动作条覆盖。比如心灵控制"
L["Player's main action bar is currently replaced by a temporary shapeshift action bar."] = "玩家的动作条被一个临时变形动作条覆盖。（玩家被boss变形后）"
L["Player's holding the shift key"]                     = ""
L["Player's holding the ctrl key"]                      = ""
L["Player's holding the alt key"]                       = ""
L["Player's mouse cursor is currently holding an item/ability/macro/etc"] = ""

L["The conditional target :"]                           = "条件对象："
L["The macro conditions :"]                             = "宏条件："

L["Please delete those addons:"]                        = "请删除以下插件:"

-----------------------------------------------------------
--                 Auto-Gen Config Type                  --
-----------------------------------------------------------
L["Key"]                                                = "主键"
L["Value"]                                              = "对应值"
L["Primary Specialization"]                             = "主专精"
L["Secondary Specialization"]                           = "从专精"

-----------------------------------------------------------
--                       Enum Name                       --
-----------------------------------------------------------

-- FramePoint
L["TOPLEFT"]                    = "左上角"
L["TOPRIGHT"]                   = "右上角"
L["BOTTOMLEFT"]                 = "左下角"
L["BOTTOMRIGHT"]                = "左下角"
L["TOP"]                        = "上"
L["BOTTOM"]                     = "下"
L["LEFT"]                       = "左"
L["RIGHT"]                      = "右"
L["CENTER"]                     = "正中"

-- FlyoutDirection
L["UP"]                         = "上"
L["DOWN"]                       = "下"

-- FrameStrata
L["PARENT"]                     = "父元素"
L["BACKGROUND"]                 = "背景"
L["LOW"]                        = "低"
L["MEDIUM"]                     = "中"
L["HIGH"]                       = "高"
L["DIALOG"]                     = "对话框"
L["FULLSCREEN"]                 = "全屏"
L["FULLSCREEN_DIALOG"]          = "全屏对话框"
L["TOOLTIP"]                    = "提示"

-- DrawLayer
L["BORDER"]                     = "边框"
L["ARTWORK"]                    = "绘图"
L["OVERLAY"]                    = "覆盖"
L["HIGHLIGHT"]                  = "高亮"

-- AlphaMode
L["DISABLE"]                    = "忽略Alpha通道"
L["BLEND"]                      = "使用Alpha通道"
L["ALPHAKEY"]                   = "将Alpha解释为透明或不透明"
L["ADD"]                        = "使用Alpha通道并避开白色"
L["MOD"]                        = "忽略Alpha通道并重叠图像"

-- OutlineType
L["NONE"]                       = "无"
L["NORMAL"]                     = "普通"
L["THICK"]                      = "粗"

-- JustifyVType
L["MIDDLE"]                     = "中间"

-- Orientation
L["HORIZONTAL"]                 = "水平方向"
L["VERTICAL"]                   = "竖直方向"

-- FontAlphabet
L["roman"]                      = "罗马"
L["korean"]                     = "韩语"
L["simplifiedchinese"]          = "简体中文"
L["traditionalchinese"]         = "繁体中文"
L["russian"]                    = "俄语"

-- WrapMode
L["CLAMP"]                      = "无限扩展纹理边缘"
L["CLAMPTOBLACK"]               = "用黑色填充溢出"
L["CLAMPTOBLACKADDITIVE"]       = "用透明黑色填充溢出"
L["CLAMPTOWHITE"]               = "用白色填充溢出"
L["REPEAT"]                     = "无限重复整个纹理"
L["MIRROR"]                     = "无限重复整个纹理，镜像相邻的迭代"

-- FilterMode
L["LINEAR"]                     = "双线性滤波"
L["TRILINEAR"]                  = "三线过滤"
L["NEAREST"]                    = "最近邻过滤"

-- AnimLoopType
L["NONE"]                       = "无"
L["REPEAT"]                     = "重复"
L["BOUNCE"]                     = "跳跃"

-- AnimSmoothType
L["IN"]                         = "进"
L["OUT"]                        = "出"
L["IN_OUT"]                     = "进_出"
L["OUT_IN"]                     = "出_进"

-- AnimCurveType
L["SMOOTH"]                     = "平滑"

-- AnchorType
L["ANCHOR_TOPRIGHT"]            = "右上角锚点"
L["ANCHOR_RIGHT"]               = "右侧锚点"
L["ANCHOR_BOTTOMRIGHT"]         = "右下角锚点"
L["ANCHOR_TOPLEFT"]             = "左上角锚点"
L["ANCHOR_LEFT"]                = "左侧锚点"
L["ANCHOR_BOTTOMLEFT"]          = "左下角锚点"
L["ANCHOR_CURSOR"]              = "鼠标锚点"
L["ANCHOR_PRESERVE"]            = "保留锚点"
L["ANCHOR_NONE"]                = "无锚点"

-- ButtonStateType
L["PUSHED"]                     = "按下"

-- VertexIndexType
L["UpperLeft"]                  = "左上"
L["LowerLeft"]                  = "左下"
L["UpperRight"]                 = "右上"
L["LowerRight"]                 = "右下"

-- FillStyle
L["STANDARD"]                   = "标准"
L["STANDARD_NO_RANGE_FILL"]         = "标准无范围填充"
L["REVERSE"]                    = "翻转"


-----------------------------------------------------------
--                  Struct Member Name                   --
-----------------------------------------------------------
-- AtlasType
L["atlas"]                      = "材质集"
L["useAtlasSize"]               = "使用材质原始大小"

-- Dimension & Position
L["x"]                          = "横轴坐标"
L["y"]                          = "纵轴坐标"
L["z"]                          = "枢轴坐标"

-- Size
L["width"]                      = "宽度"
L["height"]                     = "高度"

-- MinMax
L["min"]                        = "最小值"
L["max"]                        = "最大值"

-- Inset
L["left"]                       = "左"
L["right"]                      = "右"
L["top"]                        = "上"
L["bottom"]                     = "下"

-- GradientType
L["orientation"]                = "方向"
L["mincolor"]                   = "颜色最小值"
L["maxcolor"]                   = "颜色最大值"

-- AlphaGradientType
L["start"]                      = "起始"
L["length"]                     = "长度"

-- FontType
L["font"]                       = "字体"
L["height"]                     = "高度"
L["outline"]                    = "轮廓"
L["monochrome"]                 = "单色"

-- BackdropType
L["bgFile"]                     = "背景材质"
L["edgeFile"]                   = "边缘材质"
L["tile"]                       = "平铺"
L["tileEdge"]                   = "平铺边缘"
L["tileSize"]                   = "平铺尺寸"
L["edgeSize"]                   = "边缘尺寸"
L["alphaMode"]                  = "透明度模式"
L["insets"]                     = "偏移"

-- Anchor
L["point"]                      = "锚点"
L["relativeTo"]                 = "关联元素"
L["relativePoint"]              = "关联锚点"

-- RectType
L["ULx"]                        = "左上角横轴坐标"
L["ULy"]                        = "左上角纵轴坐标"
L["LLx"]                        = "左下角横轴坐标"
L["LLy"]                        = "左下角纵轴坐标"
L["URx"]                        = "右上角横轴坐标"
L["URy"]                        = "右上角纵轴坐标"
L["LRx"]                        = "右下角横轴坐标"
L["LRy"]                        = "右下角纵轴坐标"

-- LightType
L["enabled"]                    = "启用"
L["omni"]                       = "全向"
L["dir"]                        = "方向"
L["ambIntensity"]               = "环绕强度"
L["ambColor"]                   = "环绕颜色"
L["dirIntensity"]               = "方向强度"
L["dirColor"]                   = "方向颜色"

-- TextureType
L["file"]                       = "文件"
L["color"]                      = "颜色"

-- FadeoutOption
L["duration"]                   = "为期"
L["delay"]                      = "延迟"
L["stop"]                       = "结束"
L["autohide"]                   = "自动隐藏"

-- AnimateTexCoords
L["textureWidth"]               = "材质宽度"
L["textureHeight"]              = "材质高度"
L["frameWidth"]                 = "界面宽度"
L["frameHeight"]                = "界面高度"
L["numFrames"]                  = "帧数"
L["throttle"]                   = "阀值"