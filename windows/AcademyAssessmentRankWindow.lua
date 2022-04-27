local AcademyAssessmentRankItem = class("AcademyAssessmentRankItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function AcademyAssessmentRankItem:ctor(go, parent)
	AcademyAssessmentRankItem.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent.scroller)
	self:getUIComponent()

	self.playerIcon = nil
end

function AcademyAssessmentRankItem:getUIComponent()
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	local group1 = self.go:NodeByName("group1").gameObject
	self.imgRankIcon = group1:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = group1:ComponentByName("labelRank", typeof(UILabel))
	local groupLev = self.go:NodeByName("groupLev").gameObject
	self.labelLevel = groupLev:ComponentByName("labelLevel", typeof(UILabel))
	local groupScore = self.go:NodeByName("groupScore").gameObject
	self.labelDesc = groupScore:ComponentByName("labelDesc", typeof(UILabel))
	self.labelScore = groupScore:ComponentByName("labelScore", typeof(UILabel))
end

function AcademyAssessmentRankItem:update(index, info)
	local data = info

	if not data then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	local wnd = xyd.WindowManager:get():getWindow("acadey_assessment_rank_window")
	local fortId = 1

	if wnd then
		fortId = wnd:getFortId()
	end

	self.labelPlayerName.text = data.player_name
	self.labelDesc.text = __("RANK_TEXT02")
	self.labelLevel.text = data.lev
	self.labelScore.text = tostring(data.score - xyd.tables.academyAssessmentTable:getFirstId(fortId) + 1)
	local rank = index

	if rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. tostring(rank))
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = tostring(rank)

		self.labelRank:SetActive(true)
	end

	if not self.playerIcon then
		self.playerIcon = PlayerIcon.new(self.avatarGroup)

		self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)
	end

	self.playerIcon:setInfo({
		avatarID = data.avatar_id,
		avatar_frame_id = data.avatar_frame_id,
		callback = function ()
			local msg = messages_pb:get_school_used_partners_req()
			msg.fort_id = fortId
			msg.other_player_id = data.player_id

			xyd.Backend:get():request(xyd.mid.GET_SCHOOL_USED_PARTNERS, msg)

			local wnd = xyd.WindowManager:get():getWindow("academy_assessment_rank_window")

			if wnd then
				print(data.player_id)
				wnd:setOtherData({
					player_id = data.player_id,
					player_name = data.player_name,
					avatar_frame = data.avatar_frame_id,
					avatar_id = data.avatar_id,
					dress_style = data.dress_style
				})
			end
		end
	})
end

local BaseWindow = import(".BaseWindow")
local AcademyAssessmentRankWindow = class("AcademyAssessmentRankWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function AcademyAssessmentRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fortId = -1
	self.fortId = params.fort_id
end

function AcademyAssessmentRankWindow:initWindow()
	AcademyAssessmentRankWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()

	local msg = messages_pb:get_school_rank_list_req()
	msg.fort_id = self.fortId

	xyd.Backend:get():request(xyd.mid.GET_SCHOOL_RANK_LIST, msg)
end

function AcademyAssessmentRankWindow:addTitle()
	self.labelWinTitle.text = __("RANK")
end

function AcademyAssessmentRankWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle = groupMain:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite))
	self.rankNone = groupMain:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	local group1 = groupMain:NodeByName("group1").gameObject
	self.scroller = group1:ComponentByName("scroller", typeof(UIScrollView))
	self.groupMain = self.scroller:NodeByName("groupMain").gameObject
	local wrapContent = self.scroller:ComponentByName("groupMain", typeof(UIWrapContent))
	local item = self.scroller:NodeByName("new_trial_rank_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, item, AcademyAssessmentRankItem, self)
end

function AcademyAssessmentRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_SCHOOL_RANK_LIST, function (event)
		self.data = event.data

		self:layout()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_SCHOOL_USED_PARTNERS, function (event)
		local data = event.data

		dump(data.partners)

		if #data.partners <= 0 then
			xyd.showToast(__("SCHOOL_PRACTISE_RANK_TIP"))

			return
		end

		xyd.WindowManager:get():openWindow("academy_assessment_formation_window", {
			player_id = self.otherData.player_id,
			player_name = self.otherData.player_name,
			avatar_frame = self.otherData.avatar_frame_id,
			avatar_id = self.otherData.avatar_id,
			fort_id = self.fortId,
			info = data.partners,
			dress_style = self.otherData.dress_style
		})
	end)
end

function AcademyAssessmentRankWindow:layout()
	if not self.data then
		return
	end

	if #self.data.list <= 0 then
		self.rankNone:SetActive(true)

		self.labelNoneTips.text = __("NO_RANK")
	else
		self.rankNone:SetActive(false)
	end

	local list = self.data.list

	self.wrapContent:setInfos(list)
end

function AcademyAssessmentRankWindow:getFortId()
	return self.fortId
end

function AcademyAssessmentRankWindow:setOtherData(params)
	dump(params)

	self.otherData = params
end

return AcademyAssessmentRankWindow
