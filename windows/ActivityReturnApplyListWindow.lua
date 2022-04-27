local ActivityReturnApplyListWindow = class("ActivityReturnApplyListWindow", import(".BaseWindow"))
local ApplyItem = class("ApplyItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ActivityReturnApplyListWindow:ctor(name, params)
	ActivityReturnApplyListWindow.super.ctor(self, name, params)

	self.applyItemList_ = {}
	self.applyListInfo_ = params.applyListInfo or {}
	self.applyList_ = params.apply_list or {}
end

function ActivityReturnApplyListWindow:initWindow()
	ActivityReturnApplyListWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:layoutUI()
end

function ActivityReturnApplyListWindow:getComponent()
	local winTrans = self.window_:NodeByName("actionGroup").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.clearBtn_ = winTrans:NodeByName("clearBtn").gameObject
	self.clearBtn_label = winTrans:ComponentByName("clearBtn/label", typeof(UILabel))
	self.noneGroup_ = winTrans:NodeByName("groupNone").gameObject
	self.noneLabel_ = winTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollList", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollList/grid", typeof(UIGrid))
	self.applyItem_ = winTrans:NodeByName("applyItem").gameObject

	self.applyItem_:SetActive(false)
end

function ActivityReturnApplyListWindow:layoutUI()
	self.winTitle_.text = __("GUILD_APPLY_LIST_WINDOW")
	self.labelTips_.text = __("ACTIVITY_RETURN_APPLY_LIST_TIPS_2") .. #self.applyList_ .. "/15"
	self.clearBtn_label.text = __("ARENA_TEAM_DEL_ALL")
	self.noneLabel_.text = __("ACTIVITY_RETURN_APPLY_LIST_TIPS_3")

	if not self.applyList_ or #self.applyList_ <= 0 then
		self.noneGroup_:SetActive(true)
	else
		self.noneGroup_:SetActive(false)

		for i = 1, #self.applyList_ do
			if not self.applyItemList_[i] then
				local itemNew = NGUITools.AddChild(self.grid_.gameObject, self.applyItem_)

				itemNew:SetActive(true)

				local apply_item = ApplyItem.new(itemNew, self.applyListInfo_[i], self)
				self.applyItemList_[i] = apply_item
			else
				self.applyItemList_[i]:setInfo(self.applyListInfo_[i])
			end
		end

		for idx, item in ipairs(self.applyItemList_) do
			local player_id = item:getPlayerId()

			if xyd.arrayIndexOf(self.applyList_, player_id) < 0 then
				item:disapper(function ()
					table.remove(self.applyItemList_, idx)
					self.grid_:Reposition()
					self:waitForFrame(1, function ()
						self.scrollView_:ResetPosition()
					end)
				end)
			end
		end

		self.grid_:Reposition()
		self:waitForFrame(1, function ()
			self.scrollView_:ResetPosition()
		end)
	end
end

function ActivityReturnApplyListWindow:register()
	ActivityReturnApplyListWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.clearBtn_).onClick = function ()
		local msg = messages_pb.return_activity_clear_apply_req()
		msg.activity_id = xyd.ActivityID.RETURN

		for i = 1, #self.applyList_ do
			table.insert(msg.player_ids, self.applyList_[i])
		end

		xyd.Backend.get():request(xyd.mid.RETURN_ACTIVITY_CLEAR_APPLY, msg)
	end

	self.eventProxy_:addEventListener(xyd.event.RETURN_ACTIVITY_CLEAR_APPLY, handler(self, self.onClearApply))
	self.eventProxy_:addEventListener(xyd.event.RETURN_ACTIVITY_ACCEPT_APPLY, handler(self, self.onAccept))
end

function ActivityReturnApplyListWindow:onClearApply(event)
	self.applyList_ = event.data.apply_list or {}
	xyd.models.activity:getActivity(xyd.ActivityID.RETURN).detail.apply_list = self.applyList_
	local applyInfo = xyd.models.activity:getActivity(xyd.ActivityID.RETURN).detail.apply_show_info or {}

	for idx, info in ipairs(applyInfo) do
		if xyd.arrayIndexOf(self.applyList_, info.player_id) < 0 then
			table.remove(applyInfo, idx)
		end
	end

	self.applyListInfo_ = applyInfo

	self:layoutUI()
end

function ActivityReturnApplyListWindow:onAccept(event)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ApplyItem:ctor(go, params, parent)
	self.data_ = params
	self.parent_ = parent

	ApplyItem.super.ctor(self, go)
	self:register()
end

function ApplyItem:initUI()
	ApplyItem.super.initUI(self)
	self:getComponent()
	self:updatePlayerInfo()
end

function ApplyItem:getComponent()
	local goTrans = self.go.transform
	self.playerIconRoot_ = goTrans:NodeByName("playerIconRoot").gameObject
	self.playerName_ = goTrans:ComponentByName("playerName", typeof(UILabel))
	self.playerStatus_ = goTrans:ComponentByName("playerStatus", typeof(UILabel))
	self.btnNo_ = goTrans:NodeByName("btnNo").gameObject
	self.btnYes_ = goTrans:NodeByName("btnYes").gameObject
end

function ApplyItem:setInfo(data)
	self.data_ = data

	self:updatePlayerInfo()
end

function ApplyItem:updatePlayerInfo()
	self.playerName_.text = self.data_.player_name
	self.playerStatus_.text = xyd.checkCondition(self.data_.is_online ~= 0, __("GUILD_TEXT07"), " ")
	local playerInfo = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id,
		lev = self.data_.lev,
		callback = function ()
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.data_.player_id
			})
		end
	}

	if not self.teamerIcon_ then
		self.teamerIcon_ = PlayerIcon.new(self.playerIconRoot_)

		self.teamerIcon_:setInfo(playerInfo)
	else
		self.teamerIcon_:setInfo(playerInfo)
	end
end

function ApplyItem:register()
	UIEventListener.Get(self.btnNo_).onClick = function ()
		local msg = messages_pb.return_activity_clear_apply_req()
		msg.activity_id = xyd.ActivityID.RETURN

		table.insert(msg.player_ids, self.data_.player_id)
		xyd.Backend.get():request(xyd.mid.RETURN_ACTIVITY_CLEAR_APPLY, msg)
	end

	UIEventListener.Get(self.btnYes_).onClick = function ()
		local msg = messages_pb.return_activity_accept_apply_req()
		msg.activity_id = xyd.ActivityID.RETURN
		msg.other_player_id = self.data_.player_id

		xyd.Backend.get():request(xyd.mid.RETURN_ACTIVITY_ACCEPT_APPLY, msg)
	end
end

function ApplyItem:getPlayerId()
	return self.data_.player_id
end

function ApplyItem:disapper(callback)
	local sequene = self:getSequence()

	sequene:Append(self.go.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.1))
	sequene:Append(self.go.transform:DOScale(Vector3(0, 0, 0), 0.16))
	sequene:OnComplete(function ()
		NGUITools.Destroy(self.go.gameObject)

		if callback then
			callback()
		end
	end)
	sequene:SetAutoKill(true)
end

return ActivityReturnApplyListWindow
