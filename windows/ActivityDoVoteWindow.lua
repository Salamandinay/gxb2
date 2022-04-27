local ActivityDoVoteWindow = class("ActivityDoVoteWindow", import(".BaseWindow"))
local SelectNum = import("app.components.SelectNum")
local Partner = import("app.models.Partner")
local PartnerCard = import("app.components.PartnerCard")

function ActivityDoVoteWindow:ctor(name, params)
	ActivityDoVoteWindow.super.ctor(self, name, params)

	self.id_ = params.id
	self.count_ = params.count
	self.activity_content = params.activity
	self.table_ = params.table or xyd.tables.activityWeddingVoteTable
	self.cardSortFun_ = params.cardSortFun
	self.cur_center_ = 1
	self.num_ = 0
	self.skin_cards_ = {}
	self.partners_ = {}
end

function ActivityDoVoteWindow:initWindow()
	ActivityDoVoteWindow.super.initWindow(self)
	self:getComponent()
	self:initUI()
	self:register()
end

function ActivityDoVoteWindow:register()
	ActivityDoVoteWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.WEDDING_DRESS_VOTE, function ()
		xyd.showToast(__("WEDDING_VOTE_TEXT_6"))
		xyd.WindowManager.get():closeWindow(self.name_)
	end, self)

	UIEventListener.Get(self.voteBtn_).onClick = function ()
		self:reqVote(self.num_)
	end
end

function ActivityDoVoteWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleImg_ = winTrans:ComponentByName("titleImg", typeof(UISprite))
	self.voteBtn_ = winTrans:NodeByName("voteBtn").gameObject
	self.voteBtnLabel_ = winTrans:ComponentByName("voteBtn/button_label", typeof(UILabel))
	self.itemGroup_ = winTrans:NodeByName("itemGroup").gameObject
	self.selectNumRoot_ = winTrans:NodeByName("selectNumRoot").gameObject
	self.countTextLabel_ = winTrans:ComponentByName("countGroup/countTextLabel", typeof(UILabel))
	self.countLabel_ = winTrans:ComponentByName("countGroup/countLabel", typeof(UILabel))
	self.playerNameText_ = winTrans:ComponentByName("partnerGroup/playerNameText", typeof(UILabel))
	self.cardGroup_ = winTrans:ComponentByName("cardGroup", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("cardGroup/grid", typeof(UIGrid))
	self.centerOn_ = winTrans:ComponentByName("cardGroup/grid", typeof(UICenterOnChild))
	self.centerOn_.onCenter = handler(self, self.onCenter)
end

function ActivityDoVoteWindow:initUI()
	self:setSelectNumInfo()

	if not self:checkVote() then
		xyd.setEnabled(self.voteBtn_, false)
	end

	local status = self.activity_content.status_
	self.voteBtnLabel_.text = __("FOR_SURE")
	self.item_ = xyd.getItemIcon({
		uiRoot = self.itemGroup_,
		itemID = self.activity_content:getItemType()
	})
	self.countLabel_.text = tostring(self.count_)
	self.countTextLabel_.text = __("WEDDING_VOTE_TEXT_4")

	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_vote_vote_title_" .. xyd.Global.lang, nil, , true)
	self:initPartnerCard()

	if status == 3 or status == 4 then
		self.countLabel_.gameObject:SetActive(false)
		self.countTextLabel_.gameObject:SetActive(false)
		xyd.setEnabled(self.voteBtn_, false)
	end
end

function ActivityDoVoteWindow:checkVote()
	return xyd.models.backpack:getLev() >= 30
end

function ActivityDoVoteWindow:setSelectNumInfo()
	self.selectNum_ = SelectNum.new(self.selectNumRoot_, "minmax")

	self.selectNum_:setInfo({
		curNum = 1,
		maxNum = xyd.models.backpack:getItemNumByID(self.activity_content:getItemType()),
		callback = function (num)
			self.num_ = num
		end
	})
	self.selectNum_:setSelectBG2(true)
	self.selectNum_:setSelectBG(false)
	self.selectNum_:setPrompt(1)
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -190)
end

function ActivityDoVoteWindow:initPartnerCard()
	local table_ids = self.table_:getShowIDs(self.id_)
	local cur_center_ = 1

	if self.cardSortFun_ then
		table_ids, cur_center_ = self.cardSortFun_(table_ids)
	end

	for i = 1, #table_ids do
		local np = Partner.new()

		np:populate({
			table_id = table_ids[i],
			star = xyd.tables.partnerTable:getStar(table_ids[i]),
			lev = xyd.tables.partnerTable:getMaxlev(table_ids[i])
		})

		if i == 1 then
			self.playerNameText_.text = np:getName()
		end

		table.insert(self.partners_, np)

		local card = PartnerCard.new(self.grid_.gameObject)
		card.go.name = i

		card:setInfo(np:getInfo())
		card.levNum:SetActive(false)
		card:setGroupScale(0.9)
		card:setDragScrollView(self.cardGroup_)
		card:setTouchListener(function ()
			self.centerOn_:CenterOn(card.go.transform)
		end)
		table.insert(self.skin_cards_, card)
	end

	self.grid_.gameObject:SetLocalPosition(-180 * (cur_center_ - 1), self.grid_.transform.localPosition.y, 0)
	self:onCenter(self.skin_cards_[cur_center_].go.transform)
end

function ActivityDoVoteWindow:reqVote(num)
	if not self:checkVote() then
		xyd.showToast(__("WEDDING_VOTE_TEXT_5"))

		return
	end

	if xyd.models.backpack:getItemNumByID(self.activity_content:getItemType()) < 1 then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.activity_content:getItemType())))

		return
	end

	if num < 1 then
		xyd.showToast(__("WEDDING_VOTE_TEXT_18"))

		return
	end

	local msg = messages_pb.wedding_dress_vote_req()
	msg.activity_id = self.activity_content:getActivityId()
	msg.table_id = tonumber(self.id_)
	msg.num = num

	xyd.Backend.get():request(xyd.mid.WEDDING_DRESS_VOTE, msg)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_VOTE2)

	activityData:addVoteNum(num)
end

function ActivityDoVoteWindow:onCenter(target)
	if not target then
		return
	end

	local name = target.gameObject.name
	self.cur_center_ = tonumber(name)

	self:setSkinState()
end

function ActivityDoVoteWindow:setSkinState()
	for i = 1, #self.skin_cards_ do
		local card = self.skin_cards_[i]

		if self.hasOverFistIn_ then
			if i == self.cur_center_ then
				card:setGroupScale(0.9, 0.6)
			else
				card:setGroupScale(0.817, 0.6)
			end
		elseif i == self.cur_center_ then
			card:setGroupScale(0.9)
		else
			card:setGroupScale(0.817)
		end
	end

	self.hasOverFistIn_ = true
end

return ActivityDoVoteWindow
