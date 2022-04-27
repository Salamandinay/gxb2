local ActivityCrystalBallStoryWindow = class("ActivityCrystalBallStoryWindow", import(".BaseWindow"))

function ActivityCrystalBallStoryWindow:ctor(name, params)
	ActivityCrystalBallStoryWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CRYSTAL_BALL)
end

function ActivityCrystalBallStoryWindow:initWindow()
	ActivityCrystalBallStoryWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateItem()
	self:regisetr()
end

function ActivityCrystalBallStoryWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction").gameObject
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))

	for i = 1, 5 do
		self["storyItem" .. i] = goTrans:NodeByName("itemGroup/story" .. i).gameObject
		self["storyItem" .. i .. "box"] = self["storyItem" .. i]:GetComponent(typeof(UnityEngine.BoxCollider))
		self["storyMask" .. i] = self["storyItem" .. i]:NodeByName("mask").gameObject
		self["storyRedPoint" .. i] = self["storyItem" .. i]:NodeByName("redPoint").gameObject
		self["storyLock" .. i] = self["storyItem" .. i]:NodeByName("lock").gameObject
		self["storyItemRoot" .. i] = self["storyItem" .. i]:NodeByName("itemRoot").gameObject
		self["storyLabel" .. i] = self["storyItem" .. i]:ComponentByName("labelTitle", typeof(UILabel))
		self["storyLabelDesc" .. i] = self["storyItem" .. i]:ComponentByName("labelTitle2", typeof(UILabel))
	end
end

function ActivityCrystalBallStoryWindow:regisetr()
	self.eventProxy_:addEventListener(xyd.event.CRYSTAL_BALL_READ_PLOT, handler(self, self.updateItem))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityCrystalBallStoryWindow:onGetAward()
	if not self.reqAwardIndex then
		return
	end

	local awards = xyd.tables.activityCrystalBallTable:getAwards(self.reqAwardIndex)
	local itemType = xyd.tables.itemTable:getType(awards[1])
	local floatItems = {
		{
			item_id = awards[1],
			item_num = awards[2]
		}
	}

	if itemType == xyd.ItemType.SKIN then
		local skins = {
			awards[1]
		}

		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = skins,
			callback = function ()
				xyd.models.itemFloatModel:pushNewItems(floatItems)
			end
		})
	else
		xyd.models.itemFloatModel:pushNewItems(floatItems)
	end

	self.reqAwardIndex = nil

	self:updateItem()
end

function ActivityCrystalBallStoryWindow:layout()
	for i = 1, 5 do
		local starPlotId = xyd.tables.activityCrystalBallTable:getUnlockPlot(i)
		self["storyLabel" .. i].text = __("CHAPTER_COUNT", i)
		local award = xyd.tables.activityCrystalBallTable:getAwards(i)
		self["storyLabelDesc" .. i].text = xyd.tables.activityCrystalBallPlotTextTable:getTitle(starPlotId)
		self["storyAwardItem" .. i] = xyd.getItemIcon({
			showTipsAfterCallback = true,
			noClickSelected = true,
			notShowGetWayBtn = true,
			scale = 0.6481481481481481,
			uiRoot = self["storyItemRoot" .. i],
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = function ()
				self:onClickItem(i)
			end
		})

		UIEventListener.Get(self["storyItem" .. i]).onClick = function ()
			local overBefore = self:hasReadOver(i - 1)
			local storyData = self.activityData:getStoryData()
			local story = storyData[i]
			local is_read = self:hasReadOver(i)

			if i == 5 then
				local needReadPlots = xyd.tables.activityCrystalBallTable:getFinishPlot(4)

				for _, plot in ipairs(needReadPlots) do
					if xyd.arrayIndexOf(self.activityData.detail.plot_ids, plot) > 0 then
						overBefore = true

						break
					end
				end
			end

			if story.is_unlock and overBefore and not is_read then
				self:startStory(starPlotId)
			elseif story.is_unlock and overBefore and is_read then
				xyd.alertYesNo(__("ACTIVITY_SPROUTS_STORY_TIP"), function (yes_no)
					if yes_no then
						self:startStory(starPlotId)
					end
				end)
			else
				local nowDay = math.ceil((xyd.getServerTime() - self.activityData.start_time) / 86400)

				if i <= nowDay and overBefore then
					xyd.alertTips(__("ACTIVITY_CRYSTAL_BALL_TEXT03"))
				elseif i <= nowDay and not overBefore then
					xyd.alertTips(__("ACTIVITY_CRYSTAL_BALL_TEXT08"))
				else
					xyd.alertTips(__("ACTIVITY_CRYSTAL_BALL_TEXT04"))
				end
			end
		end
	end

	self.tipsLabel_.text = __("LOGIN_HANGUP_TEXT04")
end

function ActivityCrystalBallStoryWindow:updateItem()
	local storyData = self.activityData:getStoryData()

	for _, story in ipairs(storyData) do
		local id = story.id
		local starPlotId = xyd.tables.activityCrystalBallTable:getUnlockPlot(id)

		if id == 4 then
			self["storyLabelDesc" .. id].color = Color.New2(4294967295.0)
			self["storyLabelDesc" .. id].text = "[394046ff]" .. xyd.tables.activityCrystalBallPlotTextTable:getTitle(starPlotId) .. "[-] [369900ff](" .. self:getReadNum(id) .. "/3)[-]"
		end

		local overBefore = self:hasReadOver(id - 1)

		if id == 5 then
			local needReadPlots = xyd.tables.activityCrystalBallTable:getFinishPlot(4)

			for _, plot in ipairs(needReadPlots) do
				if xyd.arrayIndexOf(self.activityData.detail.plot_ids, plot) > 0 then
					overBefore = true

					break
				end
			end
		end

		self["storyMask" .. id]:SetActive(not story.is_unlock or not overBefore)
		self["storyLock" .. id]:SetActive(not story.is_unlock or not overBefore)
		self["storyAwardItem" .. id]:setChoose(story.is_awarded)
		self["storyRedPoint" .. id]:SetActive(story.is_unlock and overBefore and not self:hasReadOver(id))

		if self:checkCanAward(id) and overBefore then
			local effect = "bp_available"

			self["storyAwardItem" .. id]:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				target = self.target_
			})
		else
			self["storyAwardItem" .. id]:setEffect(false)
		end
	end
end

function ActivityCrystalBallStoryWindow:hasReadOver(id)
	if id <= 0 then
		return true
	end

	local hasReadOver = true
	local needReadPlots = xyd.tables.activityCrystalBallTable:getFinishPlot(id)

	for _, plot in ipairs(needReadPlots) do
		if xyd.arrayIndexOf(self.activityData.detail.plot_ids, plot) <= 0 then
			hasReadOver = false
		end
	end

	return hasReadOver
end

function ActivityCrystalBallStoryWindow:getReadNum(id)
	if id <= 0 then
		return true
	end

	local readNum = 0
	local needReadPlots = xyd.tables.activityCrystalBallTable:getFinishPlot(id)

	for _, plot in ipairs(needReadPlots) do
		if xyd.arrayIndexOf(self.activityData.detail.plot_ids, plot) > 0 then
			readNum = readNum + 1
		end
	end

	return readNum
end

function ActivityCrystalBallStoryWindow:checkCanAward(id)
	local unlock_plot = xyd.tables.activityCrystalBallTable:getUnlockPlot(id)
	local is_unlock = xyd.arrayIndexOf(self.activityData.detail.plot_ids, unlock_plot)
	local hasReadOver = self:hasReadOver(id)

	if is_unlock > 0 and (not self.activityData.detail.awards[id] or self.activityData.detail.awards[id] == 0) and hasReadOver then
		return true
	end

	return false
end

function ActivityCrystalBallStoryWindow:onClickItem(id)
	if self:checkCanAward(id) then
		local params = require("cjson").encode({
			table_id = id
		})
		self.reqAwardIndex = id

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.CRYSTAL_BALL, params)
	elseif id ~= 5 then
		local params = {
			notShowGetWayBtn = true,
			itemID = self["storyAwardItem" .. id].itemID_,
			itemNum = self["storyAwardItem" .. id].itemNum_,
			wndType = self["storyAwardItem" .. id].itemWndType_,
			callback = function ()
				self["storyAwardItem" .. id]:setSelected(false)
			end,
			smallTips = self["storyAwardItem" .. id].smallTips_,
			hideText = self["storyAwardItem" .. id].hideText,
			show_has_num = self["storyAwardItem" .. id].showHasNum,
			showGetWays = self["storyAwardItem" .. id].showGetWays
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	else
		local partnerInfo = self["storyAwardItem" .. id].partnerInfo
		local heroID = partnerInfo.itemID or partnerInfo.tableID
		local params = {
			notShowGetWayBtn = true,
			itemID = heroID,
			itemNum = partnerInfo.itemNum or 0,
			wndType = partnerInfo.wndType,
			callback = function ()
				if tolua.isnull(self.go) then
					return
				end

				self.selected = false
			end
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityCrystalBallStoryWindow:startStory(starPlotId)
	xyd.WindowManager.get():openWindow("story_window", {
		jumpToSelect = true,
		story_type = xyd.StoryType.CRYSTAL_BALL,
		story_list = {
			starPlotId
		}
	})
end

return ActivityCrystalBallStoryWindow
