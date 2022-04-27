local FriendRankAwardItem = class("FriendRankAwardItem")

function FriendRankAwardItem:ctor(go, parent)
	self.go_ = go
	self.parent_ = parent
	self.awardsList_ = {}
	self.imgRankIcon_ = self.go_:ComponentByName("groupRank/imgRankIcon", typeof(UISprite))
	self.rankLable_ = self.go_:ComponentByName("groupRank/rankLable", typeof(UILabel))
	self.grid_ = self.go_:ComponentByName("groupIcon/grid", typeof(UIGrid))
	self.itemPos_ = self.go_:ComponentByName("groupIcon/iconPos", typeof(UIWidget))

	self.itemPos_.gameObject:SetActive(false)
end

function FriendRankAwardItem:update(index, realIndex, info)
	local id = info

	if id then
		self.go_.gameObject:SetActive(true)

		local rank = xyd.tables.friendRankTable:getrank(id)
		local awards = xyd.tables.friendRankTable:getAwards(id)
		local lastRank = xyd.tables.friendRankTable:getrank(id - 1) or 0

		if rank <= 3 then
			xyd.setUISpriteAsync(self.imgRankIcon_, nil, "rank_icon0" .. rank, nil, )
			self.imgRankIcon_.gameObject:SetActive(true)
			self.rankLable_.gameObject:SetActive(false)
		else
			self.imgRankIcon_.gameObject:SetActive(false)

			self.rankLable_.text = lastRank + 1 .. "~" .. rank

			self.rankLable_.gameObject:SetActive(true)
		end

		for idx, awardStr in ipairs(awards) do
			if self.awardsList_[idx] then
				NGUITools.Destroy(self.awardsList_[idx])
			end

			local award = xyd.split(awardStr, "#", true)
			local itemRoot = NGUITools.AddChild(self.grid_.gameObject, self.itemPos_.gameObject)

			itemRoot:SetActive(true)

			itemRoot.transform.localScale = Vector3(0.7, 0.7, 0.7)

			xyd.getItemIcon({
				hideText = true,
				uiRoot = itemRoot,
				itemID = award[1],
				num = award[2],
				dragScrollView = self.parent_.scrollView_
			})

			self.awardsList_[idx] = itemRoot
		end

		self.grid_:Reposition()
	else
		self.go_.gameObject:SetActive(false)
	end
end

function FriendRankAwardItem:getGameObject()
	return self.go_.gameObject
end

local BaseWindow = import(".BaseWindow")
local FriendRankAwardsWindow = class("FriendRankAwardsWindow", BaseWindow)

function FriendRankAwardsWindow:ctor(name, params)
	FriendRankAwardsWindow.super.ctor(self, name, params)

	self.awardItems_ = {}
end

function FriendRankAwardsWindow:initWindow()
	FriendRankAwardsWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.grid_ = contentTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.scrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.labelRefreshTime_ = contentTrans:ComponentByName("groupTime/labelRefreshTime", typeof(UILabel))
	local scrollPanel = self.scrollView_:GetComponent(typeof(UIPanel))
	scrollPanel.depth = self.window_:GetComponent(typeof(UIPanel)).depth + 1
	local closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject

	UIEventListener.Get(closeBtn).onClick = function ()
		xyd.closeWindow("friend_rank_award_window")
	end
end

function FriendRankAwardsWindow:playOpenAnimation(callback)
	local function afterAction()
		self:initData()
		self:initTime()
		callback()
	end

	FriendRankAwardsWindow.super.playOpenAnimation(self, afterAction)
end

function FriendRankAwardsWindow:initData()
	local data = xyd.tables.friendRankTable:getIDs()

	table.sort(data, function (a, b)
		return tonumber(a) < tonumber(b)
	end)

	local contentTrans = self.content_.transform
	local FriendAwardItemRoot = contentTrans:Find("FriendRankAwardItem").gameObject

	FriendAwardItemRoot:SetActive(false)

	for idx, info in ipairs(data) do
		XYDCo.WaitForFrame(idx, function ()
			if self.window_ ~= nil then
				local item = self.awardItems_[idx]

				if not item then
					local itemRoot = NGUITools.AddChild(self.grid_.gameObject, FriendAwardItemRoot)

					itemRoot:SetActive(true)

					item = FriendRankAwardItem.new(itemRoot, self)

					item:update(nil, , tonumber(info))

					self.awardItems_[idx] = item
				else
					item:getGameObject():SetActive(true)
				end

				self.grid_:Reposition()

				if idx == #data or idx == 1 then
					self.scrollView_:ResetPosition()
				end
			end
		end, nil)
	end
end

function FriendRankAwardsWindow:initTime()
	local endTime = xyd.models.friend:getBossAwardEndTime()
	local duration = endTime - xyd.getServerTime()

	if duration > 0 then
		local params = {
			duration = duration,
			callback = function ()
				if self.labelRefreshTime_ then
					self.labelRefreshTime_.text = "00:00:00"
				end
			end
		}

		if not self.countDown_ then
			self.countDown_ = import("app.components.CountDown").new(self.labelRefreshTime_, params)
		else
			self.countDown_:setInfo(params)
		end
	else
		self.labelRefreshTime_.text = "00:00:00"
	end

	if not self.timer_ then
		self:initAlarmAni()
	end
end

function FriendRankAwardsWindow:initAlarmAni()
	local alarmLineTrans = self.window_.transform:ComponentByName("content/groupTime/alarmIcon/linePos", typeof(UIWidget)).transform
	self.alarmAni1_ = DG.Tweening.DOTween.Sequence()
	local angles = 360

	local function playAlarmAni1()
		angles = math.fmod(angles - 90, 360)

		if self.window_ then
			self.alarmAni1_:Insert(0, alarmLineTrans:DORotate(Vector3(0, 0, angles), 0.2))
			self.alarmAni1_:Insert(0, alarmLineTrans:DORotate(Vector3(0, 0, angles - 5), 0.1))
			self.alarmAni1_:Insert(0, alarmLineTrans:DORotate(Vector3(0, 0, angles), 0.1))
		end
	end

	playAlarmAni1()

	self.timer_ = Timer.New(handler(self, playAlarmAni1), 2, -1, false)

	self.timer_:Start()
end

function FriendRankAwardsWindow:willClose()
	FriendRankAwardsWindow.super.willClose(self)

	if self.timer_ then
		self.timer_:Stop()
	end
end

return FriendRankAwardsWindow
