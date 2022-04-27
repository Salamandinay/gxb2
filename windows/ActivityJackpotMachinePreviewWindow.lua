local BaseWindow = import(".BaseWindow")
local ActivityJackpotMachinePreviewWindow = class("ActivityJackpotMachinePreviewWindow", BaseWindow)
local JackpotPreviewSpecialItem = class("JackpotPreviewSpecialItem", import("app.components.CopyComponent"))
local MACHINE_TYPE = {
	NORMAL = 1,
	SENIOR = 2
}
local DROPBOX_ID = {
	32006,
	32007
}

function ActivityJackpotMachinePreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.type = params.type
end

function ActivityJackpotMachinePreviewWindow:initWindow()
	self:getUIComponent()
	ActivityJackpotMachinePreviewWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityJackpotMachinePreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.specialGroup = self.groupMain:NodeByName("specialGroup").gameObject
	self.labelSpecial = self.specialGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.specialScoller = self.specialGroup:ComponentByName("scoller", typeof(UIScrollView))
	self.specialAwards = self.specialScoller:NodeByName("awardGroup").gameObject
	self.normalGroup = self.groupMain:NodeByName("normalGroup").gameObject
	self.labelNormal = self.normalGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.normalScoller = self.normalGroup:ComponentByName("scoller", typeof(UIScrollView))
	self.normalAwards = self.normalScoller:NodeByName("awardGroup").gameObject
	self.special_item = self.groupMain:NodeByName("special_item").gameObject
end

function ActivityJackpotMachinePreviewWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_JACKPOT_SHOW_TITLE")
	self.labelSpecial.text = __("ACTIVITY_JACKPOT_SHOW_TEXT01")
	self.labelNormal.text = __("ACTIVITY_JACKPOT_SHOW_TEXT02")
	local numOfImg = 3
	local indexs = {}

	for i = 1, numOfImg do
		indexs[i] = {
			0,
			0,
			0
		}
	end

	local ids = xyd.tables.activityJackpotMachineTable:getIDs()

	for i = 1, #ids do
		local positions = xyd.tables.activityJackpotMachineTable:getPositions(ids[i])

		table.sort(positions)

		if positions[1] == positions[3] then
			indexs[positions[1]][3] = i
		elseif positions[1] == positions[2] or positions[2] == positions[3] then
			indexs[positions[2]][2] = i
		end
	end

	for i = 1, numOfImg do
		for j = 2, 3 do
			local index = indexs[i][j]
			local award = self.type == MACHINE_TYPE.NORMAL and xyd.tables.activityJackpotMachineTable:getAwards(index) or xyd.tables.activityJackpotMachineTable:getAwardsUpdated(index)
			local go = NGUITools.AddChild(self.specialAwards.gameObject, self.special_item)
			local item = JackpotPreviewSpecialItem.new(go, self.specialScoller, {
				num = j,
				award = award,
				img = self.type == MACHINE_TYPE.NORMAL and xyd.tables.activityJackpotListTable:getUsePic(i) or xyd.tables.activityJackpotListTable:getUpdatedUsePic(i)
			})

			xyd.setDragScrollView(go, self.specialScoller)
		end
	end

	local dropbox_awards = xyd.tables.dropboxShowTable:getIdsByBoxId(DROPBOX_ID[self.type]).list

	for i = 1, #dropbox_awards do
		local award = xyd.tables.dropboxShowTable:getItem(dropbox_awards[i])

		xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			scale = 0.7037037037037037,
			uiRoot = self.normalAwards,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.normalScoller
		})
	end

	self.specialAwards:GetComponent(typeof(UIGrid)):Reposition()
	self.normalAwards:GetComponent(typeof(UIGrid)):Reposition()
	self.specialScoller:ResetPosition()
	self.normalScoller:ResetPosition()
end

function ActivityJackpotMachinePreviewWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

function JackpotPreviewSpecialItem:ctor(go, scrollView, params)
	JackpotPreviewSpecialItem.super.ctor(self, go)

	self.scrollView = scrollView
	self.params = params

	self:getUIComponent()
	self:initUIComponent()
end

function JackpotPreviewSpecialItem:getUIComponent()
	self.img = self.go:ComponentByName("img", typeof(UISprite))
	self.num = self.go:ComponentByName("num", typeof(UISprite))
	self.icon = self.go:NodeByName("icon").gameObject
end

function JackpotPreviewSpecialItem:initUIComponent()
	xyd.setUISpriteAsync(self.img, nil, self.params.img)
	xyd.setUISpriteAsync(self.num, nil, "jackpot_text_x" .. self.params.num)
	xyd.getItemIcon({
		show_has_num = true,
		notShowGetWayBtn = true,
		scale = 0.7037037037037037,
		uiRoot = self.icon,
		itemID = self.params.award[1],
		num = self.params.award[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.scrollView
	})
end

return ActivityJackpotMachinePreviewWindow
