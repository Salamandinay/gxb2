local BaseWindow = import(".BaseWindow")
local GuildPolicySelectWindow = class("GuildPolicySelectWindow", BaseWindow)

function GuildPolicySelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.policy_ = params.policy or 1
	self.callback = params.callback
	self.closeCallBack = params.closeCallBack
	self.components = {}
end

function GuildPolicySelectWindow:initWindow()
	GuildPolicySelectWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function GuildPolicySelectWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = goTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = goTrans:ComponentByName("titleLabel", typeof(UILabel))
	local itemGroup = goTrans:NodeByName("itemGroup")

	for i = 1, 6 do
		self["chooseItem" .. i] = itemGroup:NodeByName("item" .. i).gameObject
		self["chooseItemLabel" .. i] = self["chooseItem" .. i]:ComponentByName("labelName_", typeof(UILabel))
		self["chooseItemImg1" .. i] = self["chooseItem" .. i]:NodeByName("btnLan_").gameObject
		self["chooseItemImg2" .. i] = self["chooseItem" .. i]:NodeByName("select").gameObject

		UIEventListener.Get(self["chooseItem" .. i]).onClick = function ()
			self:onclickItem(i)
		end
	end
end

function GuildPolicySelectWindow:layout()
	self.titleLabel_.text = __("GUILD_POLICY_BTN_LABEL")
	UIEventListener.Get(self.closeBtn_).onClick = handler(self, self.close)

	for i = 1, 6 do
		self["chooseItemLabel" .. i].text = __("GUILD_POLICY_TEXT" .. i)

		if xyd.Global.lang == "zh_tw" or xyd.Global.lang == "ko_kr" then
			self["chooseItemLabel" .. i].fontSize = 24
		end
	end

	self:updateBtnState()
end

function GuildPolicySelectWindow:onclickItem(i)
	self.policy_ = i

	self:updateBtnState()

	if self.callback then
		self.callback(self.policy_)
	end
end

function GuildPolicySelectWindow:updateBtnState()
	for i = 1, 6 do
		if self.policy_ == i then
			self["chooseItemImg1" .. i]:SetActive(false)
			self["chooseItemImg2" .. i]:SetActive(true)
		else
			self["chooseItemImg1" .. i]:SetActive(true)
			self["chooseItemImg2" .. i]:SetActive(false)
		end
	end
end

return GuildPolicySelectWindow
