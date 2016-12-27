--========================================================--
--                Scorpio UI FrameWork                    --
--                                                        --
-- Author      :  kurapica125@outlook.com                 --
-- Create Date :  2016/12/27                              --
--========================================================--

--========================================================--
Scorpio           "Scorpio.UI"                       "1.0.0"
--========================================================--

namespace "Scorpio.UI"

------------------------------------------------------------
--                     Enums(UI.xsd)                      --
------------------------------------------------------------
enum "FramePoint" {
	"TOPLEFT",
	"TOPRIGHT",
	"BOTTOMLEFT",
	"BOTTOMRIGHT",
	"TOP",
	"BOTTOM",
	"LEFT",
	"RIGHT",
	"CENTER",
}

enum "FrameStrata" {
	"PARENT",
	"BACKGROUND",
	"LOW",
	"MEDIUM",
	"HIGH",
	"DIALOG",
	"FULLSCREEN",
	"FULLSCREEN_DIALOG",
	"TOOLTIP",
}

enum "DrawLayer" {
	"BACKGROUND",
	"BORDER",
	"ARTWORK",
	"OVERLAY",
	"HIGHLIGHT",
}

__Default__"ADD"
enum "AlphaMode" {
	"DISABLE",
	"BLEND",
	"ALPHAKEY",
	"ADD",
	"MOD",
}

__Default__"NONE"
enum "OutlineType" {
	"NONE",
	"NORMAL",
	"THICK",
}

__Default__ "TOP"
enum "JustifyVType" {
	"TOP",
	"MIDDLE",
	"BOTTOM",
}

__Default__ "LEFT"
enum "JustifyHType" {
	"LEFT",
	"CENTER",
	"RIGHT",
}

enum "InsertMode" {
	"TOP",
	"BOTTOM",
}

enum "Orientation" {
	"HORIZONTAL",
	"VERTICAL",
}

enum "AttributeType" {
	"nil",
	"boolean",
	"number",
	"string",
}

enum "keyValueType" {
	"nil",
	"boolean",
	"number",
	"string",
	"global",
}

enum "ScriptInheritType" {
	"prepend",
	"append",
	"none",
}

enum "ScriptIntrinsicOrderType" {
	"precall",
	"postcall",
	"none",
}

enum "FontAlphabet" {
	"roman",
	"korean",
	"simplifiedchinese",
	"traditionalchinese",
	"russian",
}

enum "AnimLoopType" {
	"NONE",
	"REPEAT",
	"BOUNCE",
}

enum "AnimSmoothType" {
	"NONE",
	"IN",
	"OUT",
	"IN_OUT",
	"OUT_IN",
}

enum "AnimCurveType" {
	"NONE",
	"SMOOTH",
}
------------------------------------------------------------
--                     Struct(UI.xsd)                     --
------------------------------------------------------------
