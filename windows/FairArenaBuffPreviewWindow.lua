local BaseWindow = import(".BaseWindow")
local FairArenaBuffPreviewWindow = class("FairArenaBuffPreviewWindow", BaseWindow)
local GroupBuffIcon = import("app.components.GroupBuffIcon")

function FairArenaBuffPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.actBuffID_ = params.actBuffID or 0
end

function FairArenaBuffPreviewWindow:initWindow()
	FairArenaBuffPreviewWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function FairArenaBuffPreviewWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.tipsLabel_ = winTrans:ComponentByName("tipsLabel_", typeof(UILabel))
	self.scrollView = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("itemGroup").gameObject
end

function FairArenaBuffPreviewWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_GROUP_BUFF_TITLE")
	self.tipsLabel_.text = __("FAIR_ARENA_DESC_GROUP_BUFF")
	local buffDataList = {}
	local buffIds = xyd.tables.groupBuffTable:getIds()

	for i, buffId in ipairs(buffIds) do
		table.insert(buffDataList, tonumber(buffId))
	end

	table.sort(buffDataList, function (a, b)
		local aVale = a
		local bVale = b

		if aVale == self.actBuffID_ then
			aVale = aVale - 10000
		end

		if bVale == self.actBuffID_ then
			bVale = bVale - 10000
		end

		return aVale < bVale
	end)

	for i = 1, #buffDataList do
		local buffID = buffDataList[i]
		local groupBuff = GroupBuffIcon.new(self.itemGroup)

		groupBuff:setInfo(buffID, true)
		groupBuff:setEffectScale(0.95)

		if buffID == self.actBuffID_ then
			groupBuff:setSelectImg("fair_arena_buff_select_bg", true)
		end

		UIEventListener.Get(groupBuff:getGameObject()).onClick = function ()
			local params = {
				contenty = 130,
				buffID = buffID
			}
			local win = xyd.getWindow("group_buff_detail_window")

			if win then
				win:update(params)
			else
				xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if xyd.Global.lang == "de_de" then
		self.tipsLabel_.fontSize = 25
	end
end

function FairArenaBuffPreviewWindow:register()
	FairArenaBuffPreviewWindow.super.register(self)
end

function FairArenaBuffPreviewWindow:willClose()
	FairArenaBuffPreviewWindow.super.willClose(self)
	xyd.closeWindow("group_buff_detail_window")
end

return FairArenaBuffPreviewWindow
