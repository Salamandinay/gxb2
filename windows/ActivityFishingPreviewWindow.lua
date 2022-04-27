local BaseWindow = import(".BaseWindow")
local ActivityFishingPreviewWindow = class("ActivityFishingPreviewWindow", BaseWindow)

function ActivityFishingPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityFishingPreviewWindow:initWindow()
	self:getUIComponent()
	ActivityFishingPreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityFishingPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.fixedGroup = self.groupMain:NodeByName("fixedGroup").gameObject
	self.labelFixed = self.fixedGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.fixedAwardGroup = self.fixedGroup:NodeByName("awardGroup").gameObject

	for i = 1, 6 do
		self["fixedItem" .. i] = self.fixedAwardGroup:NodeByName("fixedItem" .. i).gameObject
		self["imgFish" .. i] = self["fixedItem" .. i]:ComponentByName("imgFish", typeof(UISprite))
		self["imgArrow" .. i] = self["fixedItem" .. i]:ComponentByName("imgArrow", typeof(UISprite))
		self["icon" .. i] = self["fixedItem" .. i]:NodeByName("icon").gameObject
	end

	self.extraGroup = self.groupMain:NodeByName("extraGroup").gameObject
	self.labelExtra = self.extraGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.extraAwardGroup = self.extraGroup:NodeByName("awardGroup").gameObject
end

function ActivityFishingPreviewWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_FISH_AWARD_TITLE")
	self.labelFixed.text = __("ACTIVITY_FISH_AWARD_TEXT01")
	self.labelExtra.text = __("ACTIVITY_FISH_AWARD_TEXT02")

	for i = 1, 6 do
		local picURL = xyd.tables.activityFishingMainTable:getPic(i)
		local award = xyd.tables.activityFishingMainTable:getAwards(i)

		xyd.setUISpriteAsync(self["imgFish" .. i], nil, picURL, function ()
			self["imgFish" .. i].transform.localScale = Vector3(0.55, 0.55, 1)
		end, nil, true)
		xyd.setUISpriteAsync(self["imgArrow" .. i], nil, "summon_special_hero_gift_icon01")
		xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.7037037037037037,
			uiRoot = self["icon" .. i],
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	local dropboxID = xyd.tables.miscTable:getNumber("activity_fish_extraawards", "value")
	local datas = xyd.tables.dropboxShowTable:getIdsByBoxId(dropboxID)

	table.sort(datas.list)

	for i in pairs(datas.list) do
		local award = xyd.tables.dropboxShowTable:getItem(datas.list[i])

		xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.7962962962962963,
			uiRoot = self.extraAwardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.extraAwardGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityFishingPreviewWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

return ActivityFishingPreviewWindow
