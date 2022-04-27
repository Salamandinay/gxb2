local BaseWindow = import(".BaseWindow")
local ActivityVoteAwardWindow = class("ActivityVoteAwardWindow", BaseWindow)
local ActivityVoteAwardItem = class("ActivityVoteAwardItem")

function ActivityVoteAwardItem:ctor(go, params)
	self.go_ = go
	self.awards_ = params.awards
	self.desc_ = params.desc
	self.id = params.id
	self.awarded = params.awarded
	self.compNum_ = params.compNum
	local itemTrans = self.go_.transform
	self.textLabel = itemTrans:ComponentByName("labelText", typeof(UILabel))
	self.itemGroup = itemTrans:NodeByName("itemGroup").gameObject
	self.headFrame = self.itemGroup:ComponentByName("frameImg", typeof(UISprite))

	self.headFrame:SetActive(false)
	self:createChildren()
end

function ActivityVoteAwardItem:createChildren()
	local awards = self.awards_
	local itemGroup = self.itemGroup
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_VOTE2)
	local voteAwarded = activityData.detail.vote_awarded[self.id]
	local frameIndex = activityData.detail.frame_index
	local voteNum = activityData.detail.vote_num
	local awarded = self.awarded == 1 or self.compNum_ <= voteNum

	for i = 1, #awards do
		local data = awards[i]

		if data[1] == 8006 or data[1] == 8039 or data[1] == 8021 then
			local selectID = 8006
			local backpack = xyd.models.backpack
			local num = nil

			if not activityData then
				return
			end

			if not voteAwarded or tonumber(voteAwarded) == 0 then
				if backpack:getItemNumByID(8006) <= 0 then
					selectID = 8006
				elseif backpack:getItemNumByID(8006) > 0 and backpack:getItemNumByID(8021) <= 0 then
					selectID = 8021
				elseif backpack:getItemNumByID(8039) > 0 and backpack:getItemNumByID(8021) <= 0 then
					selectID = 8021
				elseif backpack:getItemNumByID(8021) > 0 and backpack:getItemNumByID(8039) <= 0 then
					selectID = 8039
				elseif backpack:getItemNumByID(8021) > 0 and backpack:getItemNumByID(8039) > 0 then
					selectID = 2
					num = awards[#awards][2]
				end
			else
				selectID = awards[frameIndex][1]

				if selectID == xyd.ItemID.CRYSTAL then
					num = awards[frameIndex][2]
				end
			end

			local callback = nil

			if selectID ~= xyd.ItemID.CRYSTAL then
				function callback()
					local params = {
						itemNum = 1,
						itemID = selectID
					}

					xyd.WindowManager:get():openWindow("item_tips_window", params)
				end
			end

			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.6481481481481481,
				uiRoot = itemGroup,
				itemID = selectID,
				num = num,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				clickCloseWnd = {
					"activity_vote_award_window"
				},
				callback = callback
			})

			if awarded then
				item:setChoose(true)
			end

			self.headFrame:SetActive(false)

			break
		else
			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.6481481481481481,
				uiRoot = itemGroup,
				itemID = data[1],
				num = data[2],
				clickCloseWnd = {
					"activity_vote_award_window"
				}
			})

			if awarded then
				item:setChoose(true)
			end
		end
	end

	self.textLabel.text = self.desc_
end

function ActivityVoteAwardWindow:ctor(name, params)
	ActivityVoteAwardWindow.super.ctor(self, name, params)

	self.item_id_ = params.item_id or xyd.ItemID.ACTIVITY_VOTE_ITEM
	self.table_ = params.table or xyd.tables.activityWeddingVoteAwardTable
	self.vote_awarded_ = params.vote_awarded
end

function ActivityVoteAwardWindow:getUIComponents()
	local win = self.window_
	self.titleLabel = win:ComponentByName("titleLabel", typeof(UILabel))
	self.descLabel = win:ComponentByName("descLabel", typeof(UILabel))
	self.itemGroup = win:NodeByName("scroller/itemGroup").gameObject
	self.closeBtn = win:NodeByName("closeBtn").gameObject
	self.itemPrefab = win:NodeByName("activity_vote_award_item").gameObject

	self.itemPrefab:SetActive(false)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityVoteAwardWindow:initWindow()
	ActivityVoteAwardWindow.super.initWindow(self)
	self:getUIComponents()
	self:layout()
end

function ActivityVoteAwardWindow:layout()
	self.titleLabel.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.descLabel.text = __("WEDDING_VOTE_TEXT_16")
	local ids = self.table_:getIDs()
	local itemGroup = self.itemGroup

	for i = 1, #ids do
		local id = ids[i]
		local itemRoot = NGUITools.AddChild(itemGroup, self.itemPrefab)
		local item = ActivityVoteAwardItem.new(itemRoot, {
			awards = self.table_:getAwards(id),
			desc = __("WEDDING_VOTE_TEXT_7", self.table_:getComplete(id), xyd.tables.itemTextTable:getName(self.item_id_)),
			id = id,
			awarded = self.vote_awarded_[i],
			compNum = self.table_:getComplete(id)
		})
	end
end

return ActivityVoteAwardWindow
