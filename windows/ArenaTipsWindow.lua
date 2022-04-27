local BaseWindow = import(".BaseWindow")
local ArenaTipsWindow = class("ArenaTipsWindow", BaseWindow)

function ArenaTipsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaTipsSkin"
end

function ArenaTipsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.desc = groupAction:ComponentByName("desc", typeof(UILabel))
	self.labelDef = groupAction:ComponentByName("bot/labelDef", typeof(UILabel))
	self.labelAtk = groupAction:ComponentByName("bot/labelAtk", typeof(UILabel))
	self.labelHead = groupAction:ComponentByName("mid/labelHead", typeof(UILabel))
	self.labelTail = groupAction:ComponentByName("mid/labelTail", typeof(UILabel))
	self.labelAtk = groupAction:ComponentByName("bot/labelAtk", typeof(UILabel))
end

function ArenaTipsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()

	self.labelTitle.text = __("BATTLE_TIPS")
	self.desc.text = __("ARENA_BATTLE_TIPS")
	self.labelHead.text = __("HEAD_POS")
	self.labelTail.text = __("BACK_POS")
	self.labelDef.text = __("DEF_PARTNER")
	self.labelAtk.text = __("ATK_PARTNER")

	if xyd.Global.lang == "fr_fr" then
		self.labelHead.fontSize = 19
		self.labelTail.fontSize = 19
		self.labelDef.fontSize = 17
		self.labelAtk.fontSize = 17
	end
end

return ArenaTipsWindow
