local BaseWindow = import(".BaseWindow")
local FriendBossAssistAwardWindow = class("FriendBossAssistAwardWindow", BaseWindow)
local FriendBossAssistAwardItem = class("FriendBossAssistAwardItem", import("app.components.CopyComponent"))

function FriendBossAssistAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.awardTable = xyd.tables.friendBossHelpAwardTable
end

function FriendBossAssistAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	BaseWindow.register(self)
	self:layout()
end

function FriendBossAssistAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.descLabel = groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.Scroller = groupAction:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.Scroller_panel = groupAction:ComponentByName("e:Scroller", typeof(UIPanel))
	self.Scroller_panel.depth = winTrans:GetComponent(typeof(UIPanel)).depth + 1
	self.itemGroup = groupAction:NodeByName("e:Scroller/itemGroup").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.friendBossAssistAwardItem = groupAction:NodeByName("friendBossAssistAwardItem").gameObject
end

function FriendBossAssistAwardWindow:layout()
	self.titleLabel.text = __("ASSIST_AWARD")
	self.descLabel.text = __("WEDDING_VOTE_TEXT_16")
	local ids = self.awardTable:getIDs()
	local itemGroup = self.itemGroup

	for i in ipairs(ids) do
		local id = ids[i]
		local params = {
			awards = self.awardTable:getAwards(id),
			desc = tostring(__("ASSIST_NUM")) .. "  " .. tostring(self.awardTable:getAssistNum(id))
		}
		local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.friendBossAssistAwardItem.gameObject)
		local item = FriendBossAssistAwardItem.new(tmp, params)

		self.friendBossAssistAwardItem:SetActive(false)
	end
end

function FriendBossAssistAwardItem:ctor(goItem, params)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.awards_ = params.awards
	self.desc_ = params.desc
	self.currentState = xyd.Global.lang
	self.itemGroup = transGo:NodeByName("itemGroup").gameObject
	self.itemGroup_uiGrid = transGo:ComponentByName("itemGroup", typeof(UIGrid))
	self.textLabel = transGo:ComponentByName("textLabel", typeof(UILabel))

	self:createChildren()
end

function FriendBossAssistAwardItem:createChildren()
	local awards = self.awards_
	local itemGroup = self.itemGroup

	for i in ipairs(awards) do
		local data = awards[i]
		local item = xyd.getItemIcon({
			show_has_num = true,
			itemID = data[1],
			num = data[2],
			scale = Vector3(0.6481481481481481, 0.6481481481481481, 0.6481481481481481),
			uiRoot = itemGroup
		})
	end

	self.itemGroup_uiGrid:Reposition()

	self.textLabel.text = self.desc_
end

return FriendBossAssistAwardWindow
