local L                         = Scorpio("Scorpio")._Locale("zhTW")
if not L then return end

-----------------------------------------------------------
--                      Core System                      --
-----------------------------------------------------------
L["smoothloading"]              = "平滑啟動"
L["loglevel"]                   = "日誌等級"
L["taskthreshold"]              = "任務耗時閾值"
L["taskfactor"]                 = "任務耗時因子"

L["Trace"]                      = "跟踪"
L["Debug"]                      = "調試"
L["Info"]                       = "信息"
L["Warn"]                       = "警告"
L["Error"]                      = "錯誤"
L["Fatal"]                      = "致命錯誤"

-----------------------------------------------------------
--                Macro Condition Dialog                 --
-----------------------------------------------------------
L["Confirm when you finished the key binding"]          = "完成按鍵綁定後點擊確認"

L["Player is in a vehicle and can exit it at will."]    = "玩家在一個載具中並且可以正常退出。"
L["Player is in combat."]                               = "玩家在戰鬥中。"
L["Conditional target exists and is dead."]             = "條件對象存在並且已死亡。"
L["Conditional target exists."]                         = "條件對象存在。"
L["The player can use a flying mount in this zone (though incorrect in Wintergrasp during a battle)."] = "玩家在當前地區可以飛行（儘管可能因為其它原因不能，比如冬擁湖戰鬥時）"
L["Mounted or in flight form AND in the air."]          = "玩家飛行中。"
L["The player is in any form."]                         = "玩家處於任意姿態中。類似德魯伊的變身，戰士的防禦姿態等。"
L["The player is not in any form."]                     = "玩家不處於任意姿態中。"
L["The player is in form 1."]                           = "玩家處於第一個姿態。"
L["The player is in form 2."]                           = "玩家處於第二個姿態。"
L["The player is in form 3."]                           = "玩家處於第三個姿態。"
L["The player is in form 4."]                           = "玩家處於第四個姿態。"
L["Player is in a party."]                              = "玩家在一個隊伍中。"
L["Player is in a raid."]                               = "玩家在一個團隊中。"
L["Conditional target exists and can be targeted by harmful spells (e.g.  [Fireball])."] = "條件對象存在並且可以被施以傷害法術。（例如火球術）"
L["Conditional target exists and can be targeted by helpful spells (e.g.  [Heal])."] = "條件對象存在並且可以被施以輔助法術（例如治療術）"
L["Player is indoors."]                                 = "玩家在室內。"
L["Player is mounted."]                                 = "玩家使用坐騎中。"
L["Player is outdoors."]                                = "玩家在室外。"
L["Conditional target exists and is in your party."]    = "條件對象存在並且在玩家隊伍中。"
L["The player has a pet."]                              = "玩家帶有寵物。"
L["Currently participating in a pet battle."]           = "玩家正在進行寵物對戰。"
L["Conditional target exists and is in your raid/party."] = "條件對象存在並且在玩家的團隊中。"
L["Player is currently resting."]                       = "玩家處於休息狀態。"
L["Player's active the first specialization group (spec, talents and glyphs)."] = "玩家的第一個專精啟用中。"
L["Player's active the second specialization group (spec, talents and glyphs)."] = "玩家的第二個專精啟用中。"
L["Player is stealthed."]                               = "玩家處於潛行狀態。"
L["Player is swimming."]                                = "玩家處於潛水狀態。"
L["Player has vehicle UI."]                             = "玩家正在使用載具。"
L["Player currently has an extra action bar/button."]   = "玩家目前有一個額外動作條/按鈕。"
L["Player's main action bar is currently replaced by the override action bar."] = "玩家的主動作條正被override動作覆蓋。"
L["Player's main action bar is currently replaced by the possess action bar."] = "玩家的主動作條正被被控制者的動作條覆蓋。比如心靈控制"
L["Player's main action bar is currently replaced by a temporary shapeshift action bar."] = "玩家的動作條被一個臨時變形動作條覆蓋。（玩家被boss變形後）"
L["Player's holding the shift key"]                     = ""
L["Player's holding the ctrl key"]                      = ""
L["Player's holding the alt key"]                       = ""
L["Player's mouse cursor is currently holding an item/ability/macro/etc"] = ""

L["The conditional target :"]                           = "條件對象："
L["The macro conditions :"]                             = "宏條件："

L["Please delete those addons:"]                        = "請刪除以下插件:"

-----------------------------------------------------------
--                 Auto-Gen Config Type                  --
-----------------------------------------------------------
L["Key"]                                                = "主鍵"
L["Value"]                                              = "對應值"
L["Primary Specialization"]                             = "主專精"
L["Secondary Specialization"]                           = "從專精"

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
L["LEFT"]= "左"
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
L["DIALOG"]                     = "對話框"
L["FULLSCREEN"]                 = "全屏"
L["FULLSCREEN_DIALOG"]          = "全屏對話框"
L["TOOLTIP"]                    = "提示"

-- DrawLayer
L["BORDER"]                     = "邊框"
L["ARTWORK"]                    = "繪圖"
L["OVERLAY"]                    = "覆蓋"
L["HIGHLIGHT"]                  = "高亮"

-- AlphaMode
L["DISABLE"]                    = "忽略Alpha通道"
L["BLEND"]                      = "使用Alpha通道"
L["ALPHAKEY"]                   = "將Alpha解釋為透明或不透明"
L["ADD"]                        = "使用Alpha通道並避開白色"
L["MOD"]                        = "忽略Alpha通道並重疊圖像"

-- OutlineType
L["NONE"]                       = "無"
L["NORMAL"]                     = "普通"
L["THICK"]                      = "粗"

-- JustifyVType
L["MIDDLE"]                     = "中間"

-- Orientation
L["HORIZONTAL"]                 = "水平方向"
L["VERTICAL"]                   = "豎直方向"

-- FontAlphabet
L["roman"]                      = "羅馬"
L["korean"]                     = "韓語"
L["simplifiedchinese"]          = "簡體中文"
L["traditionalchinese"]         = "繁體中文"
L["russian"]                    = "俄語"

-- WrapMode
L["CLAMP"]                      = "無限擴展紋理邊緣"
L["CLAMPTOBLACK"]               = "用黑色填充溢出"
L["CLAMPTOBLACKADDITIVE"]       = "用透明黑色填充溢出"
L["CLAMPTOWHITE"]               = "用白色填充溢出"
L["REPEAT"]                     = "無限重複整個紋理"
L["MIRROR"]                     = "無限重複整個紋理，鏡像相鄰的迭代"

-- FilterMode
L["LINEAR"]                     = "雙線性濾波"
L["TRILINEAR"]                  = "三線過濾"
L["NEAREST"]                    = "最近鄰過濾"

-- AnimLoopType
L["NONE"]                       = "無"
L["REPEAT"]                     = "重複"
L["BOUNCE"]                     = "跳躍"

-- AnimSmoothType
L["IN"]                         = "進"
L["OUT"]                        = "出"
L["IN_OUT"]                     = "進_出"
L["OUT_IN"]                     = "出_進"

-- AnimCurveType
L["SMOOTH"]                     = "平滑"

-- AnchorType
L["ANCHOR_TOPRIGHT"]            = "右上角錨點"
L["ANCHOR_RIGHT"]               = "右側錨點"
L["ANCHOR_BOTTOMRIGHT"]         = "右下角錨點"
L["ANCHOR_TOPLEFT"]             = "左上角錨點"
L["ANCHOR_LEFT"]                = "左側錨點"
L["ANCHOR_BOTTOMLEFT"]          = "左下角錨點"
L["ANCHOR_CURSOR"]              = "鼠標錨點"
L["ANCHOR_PRESERVE"]            = "保留錨點"
L["ANCHOR_NONE"]                = "無錨點"

-- ButtonStateType
L["PUSHED"]                     = "按下"

-- VertexIndexType
L["UpperLeft"]                  = "左上"
L["LowerLeft"]                  = "左下"
L["UpperRight"]                 = "右上"
L["LowerRight"]                 = "右下"

-- FillStyle
L["STANDARD"]                   = "標準"
L["STANDARD_NO_RANGE_FILL"]  	= "標準無範圍填充"
L["REVERSE"]                    = "翻轉"


-----------------------------------------------------------
--                  Struct Member Name                   --
-----------------------------------------------------------
-- AtlasType
L["atlas"]                      = "材質集"
L["useAtlasSize"]               = "使用材質原始大小"

-- Dimension & Position
L["x"]                          = "橫軸坐標"
L["y"]                          = "縱軸坐標"
L["z"]                          = "樞軸坐標"

-- Size
L["width"]                      = "寬度"
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
L["mincolor"]                   = "顏色最小值"
L["maxcolor"]                   = "顏色最大值"

-- AlphaGradientType
L["start"]                      = "起始"
L["length"]                     = "長度"

-- FontType
L["font"]                       = "字體"
L["height"]                     = "高度"
L["outline"]                    = "輪廓"
L["monochrome"]                 = "單色"

-- BackdropType
L["bgFile"]                     = "背景材質"
L["edgeFile"]                   = "邊緣材質"
L["tile"]                       = "平鋪"
L["tileEdge"]                   = "平鋪邊緣"
L["tileSize"]                   = "平鋪尺寸"
L["edgeSize"]                   = "邊緣尺寸"
L["alphaMode"]                  = "透明度模式"
L["insets"]                     = "偏移"

-- Anchor
L["point"]                      = "錨點"
L["relativeTo"]                 = "關聯元素"
L["relativePoint"]              = "關聯錨點"

-- RectType
L["ULx"]                        = "左上角橫軸坐標"
L["ULy"]                        = "左上角縱軸坐標"
L["LLx"]                        = "左下角橫軸坐標"
L["LLy"]                        = "左下角縱軸坐標"
L["URx"]                        = "右上角橫軸坐標"
L["URy"]                        = "右上角縱軸坐標"
L["LRx"] 						= "右下角橫軸坐標"
L["LRy"]                        = "右下角縱軸坐標"

-- LightType
L["enabled"]                    = "啟用"
L["omni"]                       = "全向"
L["dir"]                        = "方向"
L["ambIntensity"]               = "環繞強度"
L["ambColor"]                   = "環繞顏色"
L["dirIntensity"]               = "方向強度"
L["dirColor"]                   = "方向顏色"

-- TextureType
L["file"]                       = "文件"
L["color"]                      = "顏色"

-- FadeoutOption
L["duration"]                   = "為期"
L["delay"]                      = "延遲"
L["stop"]                       = "結束"
L["autohide"]                   = "自動隱藏"

-- AnimateTexCoords
L["textureWidth"]               = "材質寬度"
L["textureHeight"]              = "材質高度"
L["frameWidth"]                 = "界面寬度"
L["frameHeight"]                = "界面高度"
L["numFrames"]                  = "幀數"
L["throttle"]                   = "閥值"