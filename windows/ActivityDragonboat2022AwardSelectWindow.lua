local BaseWindow = import(".BaseWindow")
local ActivityDragonboat2022AwardSelectWindow = class("ActivityDragonboat2022AwardSelectWindow", BaseWindow)
local cjson = require("cjson")

function ActivityDragonboat2022AwardSelectWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022)

	BaseWindow.ctor(self, name, params)
end

function ActivityDragonboat2022AwardSelectWindow:initWindow()
	self.icons = {}

	self:getUIComponent()
	ActivityDragonboat2022AwardSelectWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityDragonboat2022AwardSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.model = self.groupAction:ComponentByName("model", typeof(UITexture))
	self.labelTalk = self.groupAction:ComponentByName("talk/label", typeof(UILabel))

	for i = 1, 4 do
		self["item" .. i] = self.groupAction:NodeByName("award" .. i).gameObject
		self["iconPos" .. i] = self["item" .. i]:NodeByName("iconPos").gameObject
		self["changeBtn" .. i] = self["item" .. i]:NodeByName("changeBtn").gameObject
		self["num" .. i] = self["item" .. i]:ComponentByName("num", typeof(UILabel))
	end

	self.labelTotalPoint = self.groupAction:ComponentByName("tipsGroup/labelTotalPoint", typeof(UILabel))
end

function ActivityDragonboat2022AwardSelectWindow:initUIComponent()
	self.partnerEffect = xyd.Spine.new(self.model.gameObject)

	self.partnerEffect:setInfo("qianhezi_pifu02", function ()
		self.partnerEffect:play("idle", 0)
	end)

	self.labelTalk.text = __("ACTIVITY_DRAGONBOAT2022_TEXT04")
	self.labelTotalPoint.text = __("ACTIVITY_DRAGONBOAT2022_TEXT10", self.activityData.detail.point2)

	for i = 1, 4 do
		local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)
		self["num" .. i].text = point
	end

	self:update()
end

function ActivityDragonboat2022AwardSelectWindow:update()
	for i = 1, 4 do
		NGUITools.DestroyChildren(self["iconPos" .. i].transform)

		if self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[i] and self.activityData.detail.chosen_ids[i] ~= 0 then
			self["iconPos" .. i]:SetActive(true)
			self["changeBtn" .. i]:SetActive(true)

			local awards = xyd.tables.activityDragonboat2022ChoseTable:getAwards(i)
			local awardChosen = awards[self.activityData.detail.chosen_ids[i]]
			local icon = xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.6018518518518519,
				noClick = true,
				uiRoot = self["iconPos" .. i],
				itemID = awardChosen[1],
				num = awardChosen[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
			self.icons[i] = icon
			local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)

			if point <= self.activityData.detail.point2 and (not self.activityData.detail.awarded_chosen or not self.activityData.detail.awarded_chosen[i] or self.activityData.detail.awarded_chosen[i] == 0) then
				icon:setEffect(true, "fx_ui_bp_available", {
					effectPos = Vector3(3, 6, 0),
					effectScale = Vector3(1.1, 1.1, 1.1)
				})
			end
		else
			self["iconPos" .. i]:SetActive(false)
			self["changeBtn" .. i]:SetActive(false)
		end

		if self.activityData.detail.awarded_chosen and self.activityData.detail.awarded_chosen[i] and self.activityData.detail.awarded_chosen[i] ~= 0 then
			self.icons[i]:setChoose(true)
			self["changeBtn" .. i]:SetActive(false)
		end
	end
end

function ActivityDragonboat2022AwardSelectWindow:register()
	ActivityDragonboat2022AwardSelectWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:update()
	end)

	for i = 1, 4 do
		UIEventListener.Get(self["item" .. i]).onClick = function ()
			if self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[i] and self.activityData.detail.chosen_ids[i] ~= 0 then
				local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)

				if point <= self.activityData.detail.point2 then
					if not self.activityData.detail.awarded_chosen or not self.activityData.detail.awarded_chosen[i] or self.activityData.detail.awarded_chosen[i] == 0 then
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022, cjson.encode({
							award_type = 3,
							award_id = i
						}))

						self.activityData.award_id = i
					end
				else
					xyd.alertTips(__("ACTIVITY_DRAGONBOAT2022_TEXT06", point))
				end
			else
				local awards = xyd.tables.activityDragonboat2022ChoseTable:getAwards(i)

				xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
					mustChoose = true,
					items = awards,
					sureCallback = function (index)
						local indexs = {
							0,
							0,
							0,
							0
						}

						for j = 1, 4 do
							if self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[j] and self.activityData.detail.chosen_ids[j] ~= 0 then
								indexs[j] = self.activityData.detail.chosen_ids[j]
							end
						end

						indexs[i] = index

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022, cjson.encode({
							award_type = 2,
							indexs = indexs
						}))
					end,
					buttomTitleText = __("ACTIVITY_DRAGONBOAT2022_TEXT05"),
					titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
					sureBtnText = __("SURE"),
					cancelBtnText = __("CANCEL"),
					tipsText = __("ACTIVITY_ICE_SECRET_ITEM_TIPS"),
					selectedIndex = self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[i] or 0
				})
			end
		end

		UIEventListener.Get(self["changeBtn" .. i]).onClick = function ()
			local awards = xyd.tables.activityDragonboat2022ChoseTable:getAwards(i)

			xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
				mustChoose = true,
				items = awards,
				sureCallback = function (index)
					local indexs = {
						0,
						0,
						0
					}

					for j = 1, 4 do
						if self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[j] and self.activityData.detail.chosen_ids[j] ~= 0 then
							indexs[j] = self.activityData.detail.chosen_ids[j]
						end
					end

					indexs[i] = index

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022, cjson.encode({
						award_type = 2,
						indexs = indexs
					}))
				end,
				buttomTitleText = __("ACTIVITY_DRAGONBOAT2022_TEXT05"),
				titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT01"),
				sureBtnText = __("SURE"),
				cancelBtnText = __("CANCEL"),
				tipsText = __("ACTIVITY_ICE_SECRET_ITEM_TIPS"),
				selectedIndex = self.activityData.detail.chosen_ids and self.activityData.detail.chosen_ids[i] or 0
			})
		end
	end
end

return ActivityDragonboat2022AwardSelectWindow
