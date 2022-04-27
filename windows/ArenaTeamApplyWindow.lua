local BaseWindow = import(".BaseWindow")
local ArenaTeamApplyWindow = class("ArenaTeamApplyWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ArenaTeamApplyItem = class("ArenaTeamApplyItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamApplyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfos_ = {}
end

function ArenaTeamApplyWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamApplyWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.groupTop = mainGroup:NodeByName("groupTop").gameObject
	self.labelNum_ = self.groupTop:ComponentByName("labelNum_", typeof(UILabel))
	self.btnDelAll_ = self.groupTop:NodeByName("btnDelAll_").gameObject
	self.btnDelAll_LabelDisplay = self.btnDelAll_:ComponentByName("button_label", typeof(UILabel))
	self.groupNone_ = mainGroup:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.scroller_ = mainGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupMain_ = mainGroup:NodeByName("scroller_/groupMain_").gameObject
	self.item = winTrans:NodeByName("item").gameObject
end

function ArenaTeamApplyWindow:layout()
	self.btnDelAll_LabelDisplay.text = __("ARENA_TEAM_DEL_ALL")
	self.labelTitle.text = __("APPLY")
	self.labelNoneTips_.text = __("ARENA_TEAM_NO_APPLY")
end

function ArenaTeamApplyWindow:registerEvent()
	ArenaTeamApplyWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnDelAll_, self, self.onDelAllTouch)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_APPLY_LIST, handler(self, self.initList))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_REFUSE_APPLY, handler(self, self.initList))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_ACCEPT, handler(self, self.onAccept))
end

function ArenaTeamApplyWindow:onAccept()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ArenaTeamApplyWindow:onDelAllTouch()
	local memberIDs = {}
	local list = xyd.models.arenaTeam:getApplyList()

	for i = 1, #list do
		table.insert(memberIDs, list[i].player_id)
	end

	xyd.models.arenaTeam:refuseApply(memberIDs)
end

function ArenaTeamApplyWindow:playOpenAnimation(callback)
	local call = nil

	function call()
		if callback then
			callback()
		end

		self:initList()
	end

	BaseWindow.playOpenAnimation(self, call)
end

function ArenaTeamApplyWindow:initList()
	print("==================> init list")

	local list = xyd.models.arenaTeam:getApplyList()

	for k, v in ipairs(list) do
		print(v.player_name, v.lev, v.power)
	end

	self.labelNum_.text = __("ARENA_TEAM_INVITATION_1", #list)

	if #list <= 0 then
		self.groupNone_:SetActive(true)
		self.groupMain_:SetActive(false)
	else
		if not self.wrapContent then
			self:initWrapContent()
		end

		self.groupNone_:SetActive(false)
		self.wrapContent:setInfos(list, {})
	end
end

function ArenaTeamApplyWindow:initWrapContent()
	self.groupMain_:SetActive(true)

	local wrapContent = self.groupMain_:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scroller_, wrapContent, self.item, ArenaTeamApplyItem, self)
end

function ArenaTeamApplyWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)
end

function ArenaTeamApplyWindow:getScrollView()
	return self.scroller_
end

function ArenaTeamApplyItem:ctor(go, parent)
	ArenaTeamApplyItem.super.ctor(self, go)

	self.parent = parent

	self:getUIComponent()
	self:registerEvent()
	xyd.setDragScrollView(self.groupTouch_, parent:getScrollView())
end

function ArenaTeamApplyItem:getUIComponent()
	local go = self.go
	local mainGroup = go:NodeByName("mainGroup").gameObject
	self.groupIcon_ = mainGroup:NodeByName("groupIcon_").gameObject
	local levGroup = mainGroup:NodeByName("levGroup").gameObject
	self.labeLev_ = levGroup:ComponentByName("labeLev_", typeof(UILabel))
	self.labelName_ = mainGroup:ComponentByName("labelName_", typeof(UILabel))
	self.labelForce_ = mainGroup:ComponentByName("labelForce_", typeof(UILabel))
	self.groupTouch_ = mainGroup:NodeByName("groupTouch_").gameObject
	self.groupApply_ = mainGroup:NodeByName("groupApply_").gameObject
	self.btnRefuse_ = self.groupApply_:NodeByName("btnRefuse_").gameObject
	self.btnSure_ = self.groupApply_:NodeByName("btnSure_").gameObject
end

function ArenaTeamApplyItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	print("get info")
	self.go:SetActive(true)

	self.data_ = info

	self:layout()
end

function ArenaTeamApplyItem:layout()
	self.labelName_.text = self.data_.player_name
	self.labeLev_.text = self.data_.lev
	self.labelForce_.text = self.data_.power

	NGUITools.DestroyChildren(self.groupIcon_.transform)

	local playerIcon = PlayerIcon.new(self.groupIcon_)
	local info = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id
	}

	playerIcon:setInfo(info)
	self.groupApply_:SetActive(true)
end

function ArenaTeamApplyItem:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnRefuse_, self, self.onRefuseTouch)
	xyd.setDarkenBtnBehavior(self.btnSure_, self, self.onSureTouch)

	UIEventListener.Get(self.groupTouch_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("arena_team_formation_window", {
			hideBtn = true,
			player_id = self.data_.player_id
		})
	end)
end

function ArenaTeamApplyItem:onRefuseTouch()
	xyd.models.arenaTeam:refuseApply({
		self.data_.player_id
	})
end

function ArenaTeamApplyItem:onSureTouch()
	xyd.models.arenaTeam:accept(self.data_.player_id)

	local wnd2 = xyd.WindowManager.get():getWindow("arena_team_my_team_window")

	if wnd2 then
		wnd2:updateRedPoint()
	end
end

return ArenaTeamApplyWindow
