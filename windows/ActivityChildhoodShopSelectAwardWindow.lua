local BaseWindow = import(".BaseWindow")
local ActivityChildhoodShopSelectAwardWindow = class("ActivityChildhoodShopSelectAwardWindow", BaseWindow)

function ActivityChildhoodShopSelectAwardWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP)
	self.index = 1

	self.activityData:clearChoose()
	BaseWindow.ctor(self, name, params)
end

function ActivityChildhoodShopSelectAwardWindow:initWindow()
	self:getUIComponent()
	ActivityChildhoodShopSelectAwardWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityChildhoodShopSelectAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTop = self.groupAction:NodeByName("groupTop").gameObject
	self.labelTitle = self.groupTop:ComponentByName("labelTitle", typeof(UILabel))
	self.groupMid = self.groupAction:NodeByName("groupMid").gameObject
	self.award = self.groupMid:NodeByName("award").gameObject
	self.effectNode = self.groupAction:NodeByName("effect").gameObject
	self.groupBottom = self.groupAction:NodeByName("groupBottom").gameObject
	self.labelDesc = self.groupBottom:ComponentByName("labelDesc", typeof(UILabel))
	self.groupAward = self.groupBottom:NodeByName("groupAward").gameObject
	self.btnSure = self.groupBottom:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("label", typeof(UILabel))
end

function ActivityChildhoodShopSelectAwardWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_CHILDREN_GAMBLE_TEXT01")
	self.labelDesc.text = __("ACTIVITY_CHILDREN_GAMBLE_TEXT03")
	self.btnSureLabel.text = __("SURE")

	self:update()
end

function ActivityChildhoodShopSelectAwardWindow:update()
	self.choose = nil
	self.icons = {}

	self.groupTop:SetActive(false)
	self.groupMid:SetActive(false)
	NGUITools.DestroyChildren(self.groupAward.transform)
	NGUITools.DestroyChildren(self.award.transform)

	local awards = self.activityData:splitAward(self.activityData.detail.items[self.index])

	for i, award in ipairs(awards) do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			isShowSelected = false,
			uiRoot = self.groupAward,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			callback = function ()
				self:onClickIcon(i)
			end
		})
		self.icons[i] = icon

		UIEventListener.Get(icon.go).onLongPress = function ()
			local params = {
				notShowGetWayBtn = true,
				show_has_num = true,
				itemID = award[1],
				itemNum = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end
	end

	self.groupAward:GetComponent(typeof(UILayout)):Reposition()

	if self.activityData.extraAward and #self.activityData.extraAward > 0 then
		for _, award in ipairs(self.activityData.extraAward) do
			if award.times == self.index then
				xyd.getItemIcon({
					show_has_num = true,
					notShowGetWayBtn = true,
					noClick = true,
					isShowSelected = false,
					uiRoot = self.award,
					itemID = award.item_id,
					num = award.item_num,
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})

				if not self.effect then
					self.effect = xyd.Spine.new(self.effectNode.gameObject)

					self.effect:setInfo("activity_children_balloon", function ()
						self.effect:play("extra", 1, nil, function ()
							self.groupTop:SetActive(true)
							self.groupMid:SetActive(true)
						end)
					end)
				else
					self.effect:play("extra", 1, nil, function ()
						self.groupTop:SetActive(true)
						self.groupMid:SetActive(true)
					end)
				end
			end
		end
	end
end

function ActivityChildhoodShopSelectAwardWindow:onClickIcon(index)
	self.choose = index

	for i, icon in ipairs(self.icons) do
		if i ~= index then
			icon:setChoose(false)
		else
			icon:setChoose(true)
		end
	end
end

function ActivityChildhoodShopSelectAwardWindow:register()
	ActivityChildhoodShopSelectAwardWindow.super.register(self)

	UIEventListener.Get(self.btnSure).onClick = function ()
		if not self.choose then
			xyd.alertTips(__("ACTIVITY_CHILDREN_GAMBLE_TEXT03"))

			return
		end

		self.activityData:setChoose(self.choose)

		self.index = self.index + 1

		if self.index <= #self.activityData.detail.items then
			self:update()
		else
			self:close()
		end
	end
end

return ActivityChildhoodShopSelectAwardWindow
