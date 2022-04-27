local ActivityContent = import(".ActivityContent")
local ActivityAllStarsPray = class("ActivityAllStarsPray", ActivityContent)
local ActivityAllStarsPrayGroupItem = class("ActivityAllStarsPrayGroupItem", import("app.components.CopyComponent"))
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local CountDown = import("app.components.CountDown")

function ActivityAllStarsPray:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityAllStarsPray:getPrefabPath()
	return "Prefabs/Windows/activity/activity_all_start_pray"
end

function ActivityAllStarsPray:initUI()
	self:getUIComponent()
	ActivityAllStarsPray.super.initUI(self)

	self.box_label_prefix_ = "boxLabel"
	self.box_image_prefix_ = "boxImg"
	self.skinName = "ActivityAllStarsPraySkin"
	self.nowSelectGroup = 0
	self.groupItem = {}
	self.WishCoinID = self.activityData.WishCoinID
	self.GemID = self.activityData.gemIDs[1]
	self.groupFragmentID = self.activityData.groupFragmentIDs[1]
	self.omniFragmentID = self.activityData.omniFragmentID

	self:initUIComponent()
	self:euiComplete()
end

function ActivityAllStarsPray:getUIComponent()
	local go = self.go
	self.itemFloatCon = go:NodeByName("itemFloatCon").gameObject
	self.all_starts_pray_group_item = go:NodeByName("all_starts_pray_group_item").gameObject
	self.bg = go:NodeByName("bg").gameObject
	self.groupSelectNode = go:NodeByName("groupSelectNode").gameObject
	self.logoImg = self.groupSelectNode:ComponentByName("logoImg", typeof(UISprite))
	self.groupSelectNode_bg = self.groupSelectNode:NodeByName("bg_").gameObject
	self.fiveGroupNode = go:NodeByName("groupSelectNode/fiveGroupNode").gameObject

	for i = 1, 6 do
		self["group" .. tostring(i)] = go:NodeByName("groupSelectNode/fiveGroupNode/group" .. tostring(i)).gameObject
	end

	self.e_Group = go:NodeByName("groupSelectNode/e:Group").gameObject
	self.groupAward0 = go:NodeByName("groupSelectNode/e:Group/groupAward0").gameObject
	self.progress0 = go:ComponentByName("groupSelectNode/e:Group/groupAward0/progress0", typeof(UIProgressBar))
	self.progress0Label = self.progress0:ComponentByName("progressLabel", typeof(UILabel))
	self.labelHasUnlocked0 = go:ComponentByName("groupSelectNode/e:Group/groupAward0/e:Group/labelHasUnlocked0", typeof(UILabel))
	self.e_GroupGiftBox = go:NodeByName("groupSelectNode/e:Group/groupAward0/e:GroupGiftBox").gameObject

	for i = 0, 5 do
		self["boxImg" .. tostring(i)] = self.e_GroupGiftBox:ComponentByName("e:Group" .. i .. "/" .. "boxImg" .. i, typeof(UISprite))
		self["boxLabel" .. tostring(i)] = self.e_GroupGiftBox:ComponentByName("e:Group" .. i .. "/" .. "boxLabel" .. i, typeof(UILabel))
	end

	self.timeLabel_ = go:ComponentByName("groupSelectNode/timeLabel", typeof(UILabel))
	self.fragmentNode = go:NodeByName("groupSelectNode/e:Group/groupAward0/finalAwawd").gameObject
	self.fragmentMask = self.fragmentNode:NodeByName("finalAwardMask").gameObject
	self.fragmentIcon = self.fragmentNode:ComponentByName("icon", typeof(UISprite))
	self.omniFragmentFullEffectNode1 = self.fragmentNode:NodeByName("finalAwawdEffect1").gameObject
	self.omniFragmentFullEffectNode2 = self.fragmentNode:NodeByName("finalAwawdEffect2").gameObject
	self.giveMaterialNode = go:NodeByName("giveMaterialNode").gameObject
	self.selectedGroup = go:ComponentByName("giveMaterialNode/selectedGroup", typeof(UITexture))
	self.effectRepeat = go:NodeByName("giveMaterialNode/effectRepeat").gameObject
	self.effectRepeat2 = go:NodeByName("giveMaterialNode/effectRepeat2").gameObject
	self.barNode = go:NodeByName("giveMaterialNode/barNode").gameObject
	self.fragmentFullEffectNode1 = go:NodeByName("giveMaterialNode/barNode/fragmentFullEffect1").gameObject
	self.fragmentFullEffectNode2 = go:NodeByName("giveMaterialNode/barNode/fragmentFullEffect2").gameObject
	self.fragmentGetEffectNode = go:NodeByName("giveMaterialNode/barNode/fragmentGetEffect").gameObject
	self.progressBar = go:ComponentByName("giveMaterialNode/barNode/progressBar", typeof(UIProgressBar))
	self.persent = go:ComponentByName("giveMaterialNode/barNode/persent", typeof(UILabel))
	self.selectedHerosNode = go:NodeByName("giveMaterialNode/selectedHerosNode").gameObject
	self.tipText = go:ComponentByName("giveMaterialNode/selectedHerosNode/tipText", typeof(UILabel))

	for i = 0, 4 do
		self["hero" .. tostring(i)] = go:NodeByName("giveMaterialNode/selectedHerosNode/hero" .. tostring(i)).gameObject
	end

	self.selectedHerosClickNode = go:NodeByName("giveMaterialNode/selectedHerosClickNode").gameObject
	self.leftBtn = go:ComponentByName("giveMaterialNode/leftBtn", typeof(UISprite))
	self.rightBtn = go:ComponentByName("giveMaterialNode/rightBtn", typeof(UISprite))
	self.backBtn = go:ComponentByName("giveMaterialNode/backBtn", typeof(UITexture))
	self.useWishCoinBtn = go:ComponentByName("giveMaterialNode/useWishCoinBtn", typeof(UISprite))
	self.useWishCoinBtn_button_label = go:ComponentByName("giveMaterialNode/useWishCoinBtn/button_label", typeof(UILabel))
	self.useWishCoinIcon = go:ComponentByName("giveMaterialNode/useWishCoinBtn/button_icon", typeof(UISprite))
	self.useGemBtn = go:ComponentByName("giveMaterialNode/useGemBtn", typeof(UISprite))
	self.useGemBtn_button_label = go:ComponentByName("giveMaterialNode/useGemBtn/button_label", typeof(UILabel))
	self.useGemIcon = go:ComponentByName("giveMaterialNode/useGemBtn/button_icon", typeof(UISprite))
	self.prayAwardNode = self.barNode:NodeByName("prayAward").gameObject
	self.prayAwardMask = self.prayAwardNode:NodeByName("prayAwardMask").gameObject
	self.prayAwardIcon = self.prayAwardNode:ComponentByName("icon", typeof(UISprite))
	self.groupImg = go:ComponentByName("giveMaterialNode/group_bg", typeof(UITexture))
	self.useWishCoinBtnRedMark = self.giveMaterialNode:NodeByName("useWishCoinBtnRedMark").gameObject
	self.useGemBtnRedMark = self.giveMaterialNode:NodeByName("useGemBtnRedMark").gameObject
	self.materialNode1 = go:NodeByName("materialNode1").gameObject
	self.wishCoinNum = go:ComponentByName("materialNode1/materialNum", typeof(UILabel))
	self.wishCoinAddBtn = go:ComponentByName("materialNode1/materialAddBtn", typeof(UISprite))
	self.wishCoinIconOfAddBtn = go:ComponentByName("materialNode1/materialUnit", typeof(UISprite))
	self.materialNode2 = go:NodeByName("materialNode2").gameObject
	self.gemNum = go:ComponentByName("materialNode2/materialNum", typeof(UILabel))
	self.gemAddBtn = go:ComponentByName("materialNode2/materialAddBtn", typeof(UISprite))
	self.gemIconOfAddBtn = go:ComponentByName("materialNode2/materialUnit", typeof(UISprite))
	self.helpBtn = go:ComponentByName("helpBtn", typeof(UISprite))
	self.taskAwardBtn = go:NodeByName("taskAwardBtn").gameObject
	self.taskBtnRedMark = self.taskAwardBtn:NodeByName("taskBtnRedMark").gameObject
	self.awardGotBtn = go:ComponentByName("awardGotBtn", typeof(UISprite))
end

function ActivityAllStarsPray:resizeToParent()
	ActivityAllStarsPray.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
	local img = self.groupSelectNode_bg:ComponentByName("", typeof(UITexture))

	img:SetBottomAnchor(self.bg, 0, heightDis / 178 * 23 + 6)
	img:SetTopAnchor(self.bg, 1, -heightDis / 178 * 41 - 187)
	self:resizePosY(self.group1, 141, 167)

	self.group1:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.group2, 141, 167)

	self.group2:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.group3, -62, -72)

	self.group3:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.group4, -62, -72)

	self.group4:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.group5, -269, -312)

	self.group5:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.group6, -269, -312)

	self.group6:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.e_Group, 250, 317)

	self.e_Group:ComponentByName("", typeof(UIWidget)).height = heightDis / 178 * 26 + 196

	self:resizePosY(self.selectedGroup.gameObject, -260, -289)
	self.selectedGroup.gameObject:SetLocalScale(heightDis / 178 * 0.15 + 0.9, heightDis / 178 * 0.15 + 0.9, 1)
	self:resizePosY(self.effectRepeat.gameObject, 40, 20)
	self:resizePosY(self.barNode, -300, -343)
	self:resizePosY(self.useWishCoinBtn.gameObject, -376, -447)
	self:resizePosY(self.useGemBtn.gameObject, -404, -475)
	self:resizePosY(self.selectedHerosNode, 263, 326)
	self:resizePosY(self.selectedHerosClickNode, 263, 326)
	self:resizePosY(self.leftBtn.gameObject, -36, -36)
	self:resizePosY(self.rightBtn.gameObject, -36, -36)

	if xyd.Global.lang == "fr_fr" then
		self.logoImg.gameObject:SetLocalScale(0.8, 0.8, 1)
	end

	if xyd.Global.lang == "en_en" then
		self.logoImg.gameObject:SetLocalScale(0.85, 0.85, 1)
	end
end

function ActivityAllStarsPray:initUIComponent()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_all_star_pray_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.useWishCoinIcon, nil, "icon_" .. self.WishCoinID)
	xyd.setUISpriteAsync(self.useGemIcon, nil, "icon_" .. self.GemID)
	xyd.setUISpriteAsync(self.wishCoinIconOfAddBtn, nil, "icon_" .. self.WishCoinID)
	xyd.setUISpriteAsync(self.gemIconOfAddBtn, nil, "icon_" .. self.GemID)
	xyd.setUISpriteAsync(self.fragmentIcon, nil, "icon_" .. self.omniFragmentID)
	xyd.setUISpriteAsync(self.prayAwardIcon, nil, "icon_" .. self.groupFragmentID)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})
end

function ActivityAllStarsPray:euiComplete()
	self:initBtns()
	self:initGroupShow()
	self:updateNowPage(0)
	self:initMidListeners()
	self:updateProgress()

	self.fragmentFullEffect1 = xyd.Spine.new(self.fragmentFullEffectNode1)

	self.fragmentFullEffect1:setInfo("fx_pray_sp_full", function ()
		self.fragmentFullEffect1:setRenderTarget(self.prayAwardIcon, 1)
		self.fragmentFullEffect1:play("texiao01", 0)
	end)

	self.fragmentFullEffect2 = xyd.Spine.new(self.fragmentFullEffectNode2)

	self.fragmentFullEffect2:setInfo("fx_pray_omni_full", function ()
		self.fragmentFullEffect2:setRenderTarget(self.prayAwardIcon, 1)
		self.fragmentFullEffect2:play("texiao01", 0)
	end)

	self.fragmentGetEffect = xyd.Spine.new(self.fragmentGetEffectNode)

	self.fragmentGetEffect:setInfo("fx_pray_sp_get", function ()
		self.fragmentGetEffect:setRenderTarget(self.prayAwardIcon, 1)
		self.fragmentGetEffect:play("texiao01", 1)
	end)

	self.omniFragmentFullEffect1 = xyd.Spine.new(self.omniFragmentFullEffectNode1)

	self.omniFragmentFullEffect1:setInfo("fx_pray_sp_full", function ()
		self.omniFragmentFullEffect1:setRenderTarget(self.fragmentIcon, 1)
		self.omniFragmentFullEffect1:play("texiao01", 0)
	end)

	self.omniFragmentFullEffect2 = xyd.Spine.new(self.omniFragmentFullEffectNode2)

	self.omniFragmentFullEffect2:setInfo("fx_pray_omni_full", function ()
		self.omniFragmentFullEffect2:setRenderTarget(self.fragmentIcon, 1)
		self.omniFragmentFullEffect2:play("texiao01", 0)
	end)

	self.fountainEffect = xyd.Spine.new(self.selectedGroup.gameObject)

	self.fountainEffect:setInfo("garden_fountain", function ()
		self.fountainEffect:setRenderTarget(self.fragmentIcon, 1)
		self.fountainEffect:play("animation", 0)
	end)
end

function ActivityAllStarsPray:updateGroupProgress()
	if self.nowSelectGroup == 0 then
		return
	end

	self.progressBar.value = math.min(xyd.models.backpack:getItemNumByID(self.groupFragmentID), self.activityData.needNumsOfGroupFragment[self.nowSelectGroup]) / self.activityData.needNumsOfGroupFragment[self.nowSelectGroup]
	self.persent.text = tostring(math.min(xyd.models.backpack:getItemNumByID(self.groupFragmentID), self.activityData.needNumsOfGroupFragment[self.nowSelectGroup])) .. "/" .. tostring(self.activityData.needNumsOfGroupFragment[self.nowSelectGroup])
	local canGetAward = false
	canGetAward = self.activityData.needNumsOfGroupFragment[self.nowSelectGroup] <= xyd.models.backpack:getItemNumByID(self.groupFragmentID)

	if canGetAward then
		self.prayAwardMask:SetActive(true)
		self.fragmentFullEffectNode1:SetActive(true)
		self.fragmentFullEffectNode2:SetActive(true)
	else
		self.fragmentFullEffectNode1:SetActive(false)
		self.fragmentFullEffectNode2:SetActive(false)
		self.prayAwardMask:SetActive(false)
	end
end

function ActivityAllStarsPray:updateProgress()
	local maxNum = self.activityData.needOmniFragmentNum
	local cur_cnt = xyd.models.backpack:getItemNumByID(self.omniFragmentID)
	self.progress0Label.text = tostring(cur_cnt) .. "/" .. tostring(maxNum)
	self.progress0.value = math.min(cur_cnt, maxNum) / maxNum

	if maxNum <= cur_cnt then
		self.fragmentMask:SetActive(true)
		self.omniFragmentFullEffectNode1:SetActive(true)
		self.omniFragmentFullEffectNode2:SetActive(true)
	else
		self.fragmentMask:SetActive(false)
		self.omniFragmentFullEffectNode1:SetActive(false)
		self.omniFragmentFullEffectNode2:SetActive(false)
	end
end

function ActivityAllStarsPray:onUsePrayItem(event)
	self:updateProgress()
	self:updateGroupProgress()
	self:updateGroupShow()
	self:updateNowPage(self.nowSelectGroup)
	self:updateRedMask()

	local otherItems = {}
	local omniFragment = nil
	local playEffect = false

	for i = 1, #event.data.items do
		if event.data.items[i].item_id == self.omniFragmentID then
			omniFragment = event.data.items[i]
		else
			if event.data.items[i].item_id == self.groupFragmentID then
				playEffect = true
			elseif not self.activityData.detail.items[tostring(event.data.items[i].item_id)] then
				self.activityData.detail.items[tostring(event.data.items[i].item_id)] = event.data.items[i].item_num
			else
				self.activityData.detail.items[tostring(event.data.items[i].item_id)] = self.activityData.detail.items[tostring(event.data.items[i].item_id)] + event.data.items[i].item_num
			end

			local item = {
				item_id = event.data.items[i].item_id,
				item_num = event.data.items[i].item_num
			}

			table.insert(otherItems, item)
		end
	end

	if playEffect == true then
		self.fragmentGetEffectNode:SetActive(true)
		self.fragmentGetEffect:play("texiao01", 1, 1, function ()
			self.fragmentGetEffectNode:SetActive(false)
		end)
	end

	dump(otherItems, "a")
	xyd.itemFloat(otherItems, nil, , 6003)

	if omniFragment ~= nil then
		if self.activityData.needOmniFragmentNum <= xyd.models.backpack:getItemNumByID(self.omniFragmentID) and self.activityData.noShowTipWindow == nil then
			local params = {
				jumpToMode = true,
				showDesc = true,
				items = {
					{
						item_id = omniFragment.item_id,
						item_num = omniFragment.item_num
					}
				},
				jumpToBtnCallback = handler(self, function ()
					self.nowSelectGroup = 0

					self:updateNowPage(self.nowSelectGroup)
					xyd.WindowManager.get():closeWindow("alert_award_window")
				end),
				NoBtnCallback = handler(self, function ()
					self.activityData.noShowTipWindow = true

					xyd.WindowManager.get():closeWindow("alert_award_window")
				end),
				NoBtnLabel = __("ACTIVITY_PRAY_OMNI_BUTTON01"),
				jumpToBtnLabel = __("ACTIVITY_PRAY_OMNI_BUTTON02"),
				descText = __("ACTIVITY_PRAY_GET_OMNI")
			}

			xyd.WindowManager.get():openWindow("alert_award_window", params)
		else
			xyd.alertItems({
				{
					item_id = omniFragment.item_id,
					item_num = omniFragment.item_num
				}
			})
		end
	end

	if #event.data.partner_piece_item == 2 then
		xyd.alertItems({
			{
				item_id = event.data.partner_piece_item[1],
				item_num = event.data.partner_piece_item[2]
			}
		})

		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = self.id

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
	end

	self.usePrayItemEvent = nil
end

function ActivityAllStarsPray:initMidListeners()
	self.eventProxyInner_:addEventListener(xyd.event.USE_PRAY_ITEM, function (event)
		self.usePrayItemEvent = event

		if #event.data.partner_piece_item == 2 then
			self:onUsePrayItem(event)

			return
		end

		if not self.coinPrayEffect then
			self.coinPrayEffect = xyd.Spine.new(self.effectRepeat)

			self.coinPrayEffect:setInfo("coin_pray", function ()
				self.coinPrayEffect:setRenderTarget(self.effectRepeat:GetComponent(typeof(UITexture)), 1)
				self.coinPrayEffect:play("animation", 1, nil, function ()
					self:onUsePrayItem(event)
				end)
			end)
		else
			self.coinPrayEffect:play("animation", 1, nil, function ()
				self:onUsePrayItem(event)
			end)
		end
	end)
	self.eventProxyInner_:addEventListener(xyd.event.ALL_STAR_PRAY_BUY, function (event)
		if self.id == event.data.activity_id then
			self.activityData.detail.buy_times = event.data.buy_times

			self:updateRedMask()
		end
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ALL_STARS_PRAY then
			return
		end

		self:updateNowPage(self.nowSelectGroup)
	end))
	self.eventProxyInner_:addEventListener(xyd.event.CHANGE_PRAY_AWARD_2, function (event)
		for i = #self.activityData.detail.benches[self.nowSelectGroup].awards, 1, -1 do
			table.remove(self.activityData.detail.benches[self.nowSelectGroup].awards, i)
		end

		for i in ipairs(event.params.sendIds) do
			table.insert(self.activityData.detail.benches[self.nowSelectGroup].awards, event.params.sendIds[i])
		end

		for i = #self.activityData.detail.benches[self.nowSelectGroup].got_awards, 1, -1 do
			table.remove(self.activityData.detail.benches[self.nowSelectGroup].got_awards, i)
		end

		self:updateNowPage(-1)
	end)
	self.eventProxyInner_:addEventListener(xyd.event.CHANGE_PRAY_BACK, function (event)
		self:updateNowPage(0)
	end)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = self.id

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
		self:onGetTaskAward(event)
	end)
end

function ActivityAllStarsPray:initBtns()
	self.labelHasUnlocked0.text = __("ACTIVITY_PRAY_COMPLETE")
	self.tipText.text = __("ACTIVITY_PRAY_TIPS01")

	xyd.setUISpriteAsync(self.useWishCoinBtn, nil, "blue_btn70_70", nil, )

	self.useWishCoinBtn_button_label.text = __("ACTIVITY_PRAY_TEXT2")
	UIEventListener.Get(self.useWishCoinBtn.gameObject).onClick = handler(self, function ()
		self:getAddCallbackOfGem()
	end)

	xyd.setUISpriteAsync(self.useGemBtn, nil, "blue_btn70_70", nil, )

	self.useGemBtn_button_label.text = __("ACTIVITY_PRAY_TEXT5")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.useGemBtn_button_label_de_de = self.useGemBtn:ComponentByName("button_label_de_de", typeof(UILabel))
		self.useGemBtn_button_label_de_de.text = __("ACTIVITY_PRAY_TEXT5")

		self.useGemBtn_button_label_de_de.gameObject:SetActive(true)
		self.useGemBtn_button_label.gameObject:SetActive(false)
		self.useGemBtn:ComponentByName("", typeof(UILayout)):Reposition()
	else
		self.useGemBtn:ComponentByName("button_label_de_de", typeof(UILabel)).gameObject:SetActive(false)
		self.useGemBtn_button_label.gameObject:SetActive(true)
		self.useGemBtn:ComponentByName("", typeof(UILayout)):Reposition()
	end

	UIEventListener.Get(self.useGemBtn.gameObject).onClick = handler(self, function ()
		self.GemID = self.activityData.gemIDs[self.nowSelectGroup]
		local singleCost = self.activityData.singleCosts_gem[self.nowSelectGroup]
		local resource_num = xyd.models.backpack:getItemNumByID(self.GemID)
		local select_max_num = math.floor(resource_num / singleCost)
		local nowNum = xyd.models.backpack:getItemNumByID(self.activityData.groupFragmentIDs[self.nowSelectGroup])
		local needNum = self.activityData.needNumsOfGroupFragment[self.nowSelectGroup]
		local left_times = Mathf.Ceil((needNum - nowNum) / self.activityData.singleGetNum_GroupFragment[self.nowSelectGroup])

		if left_times > 0 then
			select_max_num = math.min(select_max_num, left_times * 2)
		end

		if self.activityData.needNumsOfGroupFragment[self.nowSelectGroup] <= xyd.models.backpack:getItemNumByID(self.activityData.groupFragmentIDs[self.nowSelectGroup]) then
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_PRAY_FULL_TIPS"))

			return
		end

		if resource_num < self.activityData.singleCosts_gem[self.nowSelectGroup] then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.GemID)))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = select_max_num,
			show_max_num = resource_num,
			select_multiple = singleCost,
			icon_info = {
				height = 34,
				width = 34,
				name = "icon_" .. self.GemID
			},
			title_text = __("ACTIVITY_PRAY_TITLE02"),
			explain_text = __("ACTIVITY_PRAY_TEXT6"),
			addCallback = handler(self, function ()
				xyd.WindowManager.get():closeWindow("common_use_cost_window", handler(self, self.getAddCallbackOfGem))
			end),
			sure_callback = function (num)
				self:useGem(num)

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end)
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:updateNowPage(0)

		if self.coinPrayEffect then
			self.coinPrayEffect:stop()

			if self.usePrayItemEvent then
				self:onUsePrayItem(self.usePrayItemEvent)
			end
		end
	end)
	UIEventListener.Get(self.rightBtn.gameObject).onClick = handler(self, function ()
		self.nowSelectGroup = self.nowSelectGroup + 1

		if self.nowSelectGroup > 6 then
			self.nowSelectGroup = 1
		end

		self:updateNowPage(self.nowSelectGroup)
	end)
	UIEventListener.Get(self.leftBtn.gameObject).onClick = handler(self, function ()
		self.nowSelectGroup = self.nowSelectGroup - 1

		if self.nowSelectGroup <= 0 then
			self.nowSelectGroup = 6
		end

		self:updateNowPage(self.nowSelectGroup)
	end)
	UIEventListener.Get(self.selectedHerosClickNode.gameObject).onClick = handler(self, function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		xyd.WindowManager.get():openWindow("activity_all_stars_pray_heros_window", {
			canClose = true,
			selectGroup = self.nowSelectGroup,
			alreadyHeros = self.activityData.detail.benches[self.nowSelectGroup].awards
		})
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_PRAY_HELP"
		})
	end)
	UIEventListener.Get(self.taskAwardBtn).onClick = handler(self, function ()
		local activityData = xyd.models.activity:getActivity(self.id)
		local all_info = {}
		local ids = xyd.tables.activityPrayAwardTable:getIDs()

		for j in pairs(ids) do
			local data = {
				id = j,
				max_value = xyd.tables.activityPrayAwardTable:getComplete(j)
			}
			data.name = __("ACTIVITY_PRAY_AWARDS", math.floor(data.max_value))
			data.cur_value = tonumber(activityData.detail.finish_times)

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			data.items = xyd.tables.activityPrayAwardTable:getAwards(j)

			if activityData.detail.award_records[j] == 0 then
				if data.cur_value == data.max_value then
					data.state = 1
				else
					data.state = 2
				end
			else
				data.state = 3
			end

			table.insert(all_info, data)
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("MAIL_AWAED_TEXT"),
			click_callBack = function (info)
				if self.activityData:getEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				self:GetTaskAward(info.id)
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_STAR_PRAY
		})
	end)
	UIEventListener.Get(self.awardGotBtn.gameObject).onClick = handler(self, function ()
		local data = {}

		for item_id, num in pairs(self.activityData.detail.items) do
			table.insert(data, {
				item_id = tonumber(item_id),
				num = num
			})
		end

		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = self.activityData.detail.items,
			winTitle = __("ACTIVITY_PARY_ALL_AWARDS")
		})
	end)
	local itemsInfos = {}
	local ids = xyd.tables.activityPrayPartnerTable:getIDs()

	for i = 1, #ids do
		local partner_ids = xyd.tables.activityPrayPartnerTable:getPartnerIds(i)

		for j = 1, #partner_ids do
			local info = {
				itemNum = 1,
				itemID = partner_ids[j]
			}

			table.insert(itemsInfos, info)
		end
	end

	UIEventListener.Get(self.fragmentMask.gameObject).onClick = handler(self, function ()
		local onClick = nil

		function onClick()
			xyd.openWindow("award_select_window", {
				itemsInfo = itemsInfos,
				sureCallback = function (item_id)
					local row_index = 0
					local col_index = 0
					local ids = xyd.tables.activityPrayPartnerTable:getIDs()

					for i = 1, #ids do
						local partner_ids = xyd.tables.activityPrayPartnerTable:getPartnerIds(i)

						for j = 1, #partner_ids do
							if tonumber(partner_ids[j]) == tonumber(item_id) then
								row_index = i
								col_index = j
							end
						end
					end

					local msg = messages_pb.use_pray_item_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
					msg.bench_id = row_index
					msg.num = 1
					msg.tp = 4
					msg.table_id = col_index

					xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
					xyd.WindowManager.get():closeWindow("award_select_window")
				end,
				longPressItemCallback = function (itemID)
					local params = {
						partners = {
							{
								table_id = itemID
							}
						},
						table_id = itemID,
						closeCallBack = function ()
							onClick()
						end
					}

					xyd.WindowManager.get():openWindow("guide_detail_window", params, function ()
						xyd.WindowManager.get():closeWindowsOnLayer(6)
					end)
				end
			})
		end

		onClick()
	end)
	UIEventListener.Get(self.fragmentIcon.gameObject).onClick = handler(self, function ()
		local params = {
			show_has_num = false,
			showGetWays = false,
			itemID = self.omniFragmentID,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.prayAwardMask.gameObject).onClick = handler(self, function ()
		local msg = messages_pb.use_pray_item_req()
		msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
		msg.bench_id = self.nowSelectGroup
		msg.num = 1
		msg.tp = 3

		xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
	end)
	UIEventListener.Get(self.prayAwardIcon.gameObject).onClick = handler(self, function ()
		local params = {
			show_has_num = false,
			showGetWays = false,
			itemID = self.groupFragmentID,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)

	for i = 0, 5 do
		local img = self["boxImg" .. tostring(i)]
		UIEventListener.Get(img.gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("activity_award_preview_window", {
				awards = xyd.tables.activityPrayAwardTable:getAwards(i + 1)
			})
		end)
	end

	self:initMaterialBtn()
end

function ActivityAllStarsPray:getAddCallbackOfWishCoin()
	if self:getBuyTime() <= 0 then
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

		return
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_pray_buy_price", "value", "#")
	local single = 1

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

		return
	end

	xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
		imgExchangeHeight = 38,
		imgExchangeWidth = 38,
		needTips = true,
		limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
		hasMaxMin = true,
		titleKey = "ACTIVITY_PRAY_TEXT4",
		notEnoughKey = "PERSON_NO_CRYSTAL",
		buyType = self.WishCoinID,
		buyNum = single,
		costType = tonumber(cost[1]),
		costNum = tonumber(cost[2]),
		descLabel = __("ACTIVITY_PRAY_LIMIT_BUY", self:getBuyTime(), tonumber(xyd.tables.miscTable:split2Cost("activity_pray_buy_limit", "value", "|")[1])),
		purchaseCallback = function (evt, num)
			local msg = messages_pb.all_star_pray_buy_req()
			msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
			msg.num = num
			msg.type = 1

			xyd.Backend.get():request(xyd.mid.ALL_STAR_PRAY_BUY, msg)

			if xyd.models.backpack:getItemNumByID(tonumber(cost[1])) < tonumber(cost[2]) then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

				return
			end

			xyd.itemFloat({
				{
					item_id = tonumber(self.WishCoinID),
					item_num = single * num
				}
			}, nil, self.itemFloatCon)
		end,
		limitNum = math.min(self:getBuyTime(), 1500),
		eventType = xyd.event.BOSS_BUY
	})
end

function ActivityAllStarsPray:getAddCallbackOfGem()
	if self.activityData.needNumsOfGroupFragment[self.nowSelectGroup] <= xyd.models.backpack:getItemNumByID(self.activityData.groupFragmentIDs[self.nowSelectGroup]) then
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_PRAY_FULL_TIPS"))

		return
	end

	self.WishCoinID = self.activityData.gemIDs[self.nowSelectGroup]
	local singleCost = self.activityData.singleCosts_gem[self.nowSelectGroup]
	local resource_num = xyd.models.backpack:getItemNumByID(self.WishCoinID)
	local select_max_num = math.floor(resource_num / singleCost)
	select_max_num = math.min(select_max_num, self.activityData.needNumsOfGroupFragment[self.nowSelectGroup] - xyd.models.backpack:getItemNumByID(self.groupFragmentID))

	if resource_num < singleCost then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(self.WishCoinID)))

		return
	end

	xyd.WindowManager.get():openWindow("common_use_cost_window", {
		select_max_num = select_max_num,
		show_max_num = resource_num,
		select_multiple = singleCost,
		icon_info = {
			height = 34,
			width = 34,
			name = "icon_" .. self.WishCoinID
		},
		title_text = __("ACTIVITY_PRAY_TEXT2"),
		explain_text = __("ACTIVITY_PRAY_TEXT3"),
		addCallback = handler(self, function ()
			xyd.WindowManager.get():closeWindow("common_use_cost_window", function ()
				xyd.WindowManager:get():openWindow("activity_item_getway_window", {
					itemID = self.WishCoinID,
					activityData = self.activityData,
					openItemBuyWnd = handler(self, self.getAddCallbackOfWishCoin)
				})
			end)
		end),
		sure_callback = function (num)
			self:useWishCoin(num)

			local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

			if common_use_cost_window_wd then
				xyd.WindowManager.get():closeWindow("common_use_cost_window")
			end
		end
	})
end

function ActivityAllStarsPray:arrowMove()
	if self.positionLeft == nil then
		self.positionLeft = self.leftBtn.gameObject.transform.localPosition.x
		self.positionRight = self.rightBtn.gameObject.transform.localPosition.x
	end

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	self.leftBtn.gameObject.transform.localPosition.x = self.positionLeft
	self.rightBtn.gameObject.transform.localPosition.x = self.positionRight

	function self.playAni2_()
		self.sequence2_ = DG.Tweening.DOTween.Sequence()

		self.sequence2_:Insert(0, self.leftBtn.gameObject.transform:DOLocalMove(Vector3(self.positionLeft - 5, self.leftBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence2_:Insert(1, self.leftBtn.gameObject.transform:DOLocalMove(Vector3(self.positionLeft + 5, self.leftBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence2_:Insert(0, self.rightBtn.gameObject.transform:DOLocalMove(Vector3(self.positionRight + 5, self.rightBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence2_:Insert(1, self.rightBtn.gameObject.transform:DOLocalMove(Vector3(self.positionRight - 5, self.rightBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = DG.Tweening.DOTween.Sequence()

		self.sequence1_:Insert(0, self.leftBtn.gameObject.transform:DOLocalMove(Vector3(self.positionLeft - 5, self.leftBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence1_:Insert(1, self.leftBtn.gameObject.transform:DOLocalMove(Vector3(self.positionLeft + 5, self.leftBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence1_:Insert(0, self.rightBtn.gameObject.transform:DOLocalMove(Vector3(self.positionRight + 5, self.rightBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence1_:Insert(1, self.rightBtn.gameObject.transform:DOLocalMove(Vector3(self.positionRight - 5, self.rightBtn.gameObject.transform.localPosition.y, 0), 1, false))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function ActivityAllStarsPray:initMaterialBtn()
	self:updateItemNumber()
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNumber))
	self.eventProxyInner_:addEventListener(xyd.event.ALL_STAR_PRAY_BUY, handler(self, function ()
		self:updateItemNumber()
		xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
	end))

	UIEventListener.Get(self.wishCoinAddBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = self.WishCoinID,
			activityData = self.activityData,
			openItemBuyWnd = handler(self, self.getAddCallbackOfWishCoin)
		})
	end)
	UIEventListener.Get(self.gemAddBtn.gameObject).onClick = handler(self, function ()
		xyd.alertTips(__("ACTIVITY_PRAY_GEM_TIPS", xyd.tables.itemTextTable:getName(self.GemID)))
	end)
end

function ActivityAllStarsPray:getBuyTime()
	return tonumber(xyd.tables.miscTable:split2Cost("activity_pray_buy_limit", "value", "|")[1]) - self.activityData.detail.buy_times
end

function ActivityAllStarsPray:updateItemNumber()
	self.wishCoinNum.text = tostring(xyd.models.backpack:getItemNumByID(self.WishCoinID))
	self.gemNum.text = tostring(xyd.models.backpack:getItemNumByID(self.GemID))
end

function ActivityAllStarsPray:updateNowPage(page)
	if page >= 0 then
		self.nowSelectGroup = page
	end

	if self.nowSelectGroup == 0 then
		self.groupSelectNode:SetActive(true)
		self.giveMaterialNode:SetActive(false)
		self.taskAwardBtn:SetActive(true)
		self.helpBtn:SetActive(true)
		self.materialNode2:SetActive(false)
		self:updateProgress()
		self:updateGroupShow()
		self:updateRedMask()
	else
		self.groupSelectNode:SetActive(false)
		self.giveMaterialNode:SetActive(true)
		self.taskAwardBtn:SetActive(false)
		self.helpBtn:SetActive(false)
		self.materialNode2:SetActive(false)
		self.useGemBtn:SetActive(false)
		self.useWishCoinBtn:X(0)
		self:updateRedMask()
		self:arrowMove()

		local canGetAward = false
		canGetAward = self.activityData.needNumsOfGroupFragment[self.nowSelectGroup] <= self.activityData.detail.benches[self.nowSelectGroup].point

		if canGetAward then
			self.prayAwardMask:SetActive(true)
			self.fragmentFullEffectNode1:SetActive(true)
			self.fragmentFullEffectNode2:SetActive(true)
		else
			self.fragmentFullEffectNode1:SetActive(false)
			self.fragmentFullEffectNode2:SetActive(false)
			self.prayAwardMask:SetActive(false)
		end

		self.GemID = self.activityData.gemIDs[self.nowSelectGroup]

		xyd.setUISpriteAsync(self.useGemIcon, nil, "icon_" .. self.GemID)
		xyd.setUISpriteAsync(self.gemIconOfAddBtn, nil, "icon_" .. self.GemID)

		self.groupFragmentID = self.activityData.groupFragmentIDs[self.nowSelectGroup]

		xyd.setUISpriteAsync(self.prayAwardIcon, nil, "icon_" .. self.groupFragmentID)
		self:updateItemNumber()

		self.giveMaterialNode:ComponentByName("groupLabel", typeof(UILabel)).text = __("ACTIVITY_PRAY_GROUP" .. tostring(self.nowSelectGroup))

		xyd.setUITextureAsync(self.groupImg, "Textures/scenes_web/college_scene" .. tostring(self.nowSelectGroup), function ()
		end, false)

		for i = 0, 4 do
			NGUITools.DestroyChildren(self["hero" .. tostring(i)].transform)
		end

		local tableList = xyd.tables.activityPrayPartnerTable:getPartnerIds(self.nowSelectGroup)
		local list = self.activityData.detail.benches[self.nowSelectGroup].awards
		local got_awards = self.activityData.detail.benches[self.nowSelectGroup].got_awards
		local indexNum = 0

		for i in ipairs(list) do
			indexNum = indexNum + 1
			local theGroup = self["hero" .. tostring(i - 1)]
			local copyIcon = HeroIcon.new(theGroup)
			local np = Partner.new()

			np:populate({
				tableID = tableList[list[i]]
			})

			local playerInfo = np:getInfo()
			playerInfo.noClick = true
			playerInfo.lev = 1
			playerInfo.scale = Vector3(0.8, 0.8, 1)

			copyIcon:setInfo(playerInfo)
			copyIcon:setChoose(false)

			if got_awards ~= nil and xyd.arrayIndexOf(got_awards, list[i]) ~= -1 then
				copyIcon:setChoose(true)
			end
		end

		if indexNum ~= 5 then
			xyd.WindowManager.get():openWindow("activity_all_stars_pray_heros_window", {
				canClose = false,
				selectGroup = self.nowSelectGroup,
				alreadyHeros = self.activityData.detail.benches[self.nowSelectGroup].awards
			})
		end

		self:updateGroupProgress()
	end
end

function ActivityAllStarsPray:initGroupShow()
	for i = 1, 6 do
		local tmp = NGUITools.AddChild(self["group" .. tostring(i)].gameObject, self.all_starts_pray_group_item.gameObject)
		local item = ActivityAllStarsPrayGroupItem.new(tmp, i, self)
		UIEventListener.Get(item:getObj()).onClick = handler(self, function ()
			self:updateNowPage(i)
		end)

		table.insert(self.groupItem, item)

		item:getObj():ComponentByName("", typeof(UIWidget)).height = self["group" .. tostring(i)].gameObject:ComponentByName("", typeof(UIWidget)).height
	end

	self.all_starts_pray_group_item:SetActive(false)
	self:updateGroupShow()
end

function ActivityAllStarsPray:updateGroupShow()
	for i = 1, 6 do
		self.groupItem[i]:setBarProgress(xyd.models.backpack:getItemNumByID(self.activityData.groupFragmentIDs[i]), self.activityData.needNumsOfGroupFragment[i])
		self.groupItem[i]:setBarProgress(xyd.models.backpack:getItemNumByID(self.activityData.groupFragmentIDs[i]), self.activityData.needNumsOfGroupFragment[i])
	end
end

function ActivityAllStarsPray:updateRedMask()
	for i = 1, 6 do
		self.groupItem[i]:updateRedMask()
	end

	local flag = self.activityData:checkRedPoint_wishCoin()

	self.useWishCoinBtnRedMark:SetActive(flag)
	self.taskBtnRedMark:SetActive(self.activityData:checkRedPoint_task())
end

function ActivityAllStarsPray:useWishCoin(num)
	local msg = messages_pb.use_pray_item_req()
	msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
	msg.bench_id = self.nowSelectGroup
	msg.num = num
	msg.tp = 1

	xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
end

function ActivityAllStarsPray:useGem(num)
	local msg = messages_pb.use_pray_item_req()
	msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
	msg.bench_id = self.nowSelectGroup
	msg.num = num
	msg.tp = 2

	xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
end

function ActivityAllStarsPray:GetTaskAward(id)
	self.AwardedTaskID = id
	local data = require("cjson").encode({
		id = id
	})
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityAllStarsPray:onGetTaskAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ALL_STARS_PRAY then
		return
	end

	local details = require("cjson").decode(event.data.detail)
	local items = details.items
	local infos = {}

	for key, value in pairs(items) do
		local item = {
			item_id = value.item_id,
			item_num = value.item_num
		}

		table.insert(infos, item)
	end

	xyd.models.itemFloatModel:pushNewItems(infos)

	local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

	if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_STAR_PRAY then
		common_progress_award_window_wn:updateItemState(tonumber(self.AwardedTaskID), 3)
	end

	self:updateRedMask()
end

function ActivityAllStarsPray:dispose()
	ActivityAllStarsPray.super.dispose(self)

	if self.sequence1_ then
		self.sequence1_:Pause()
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Pause()
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	xyd.Spine:cleanUp()
end

function ActivityAllStarsPrayGroupItem:ctor(goItem, groupId_, parent)
	self.groupId_ = groupId_
	self.skinName = "ActivityAllStarsPrayGroupItemSkin"
	self.goItem_ = goItem
	self.transGo = goItem.transform
	self.parent = parent

	self:getUIComponent(self.transGo)
	self:setImage()
	self:setAwardIcon()
	self:register()
end

function ActivityAllStarsPrayGroupItem:getUIComponent(transGo)
	self.groupIcon = transGo:ComponentByName("groupIcon", typeof(UISprite))
	self.progressBar = transGo:ComponentByName("progressBar", typeof(UIProgressBar))
	self.groupName = transGo:ComponentByName("groupName", typeof(UILabel))
	self.persent = transGo:ComponentByName("persent", typeof(UILabel))
	self.awardIconNode = transGo:NodeByName("awardIcon").gameObject
	self.awardMask = self.awardIconNode:NodeByName("awardMask").gameObject
	self.redMask = transGo:NodeByName("redMark").gameObject
end

function ActivityAllStarsPrayGroupItem:register()
	UIEventListener.Get(self.awardMask).onClick = handler(self, function ()
		local list = self.parent.activityData.detail.benches[self.groupId_].awards
		local indexNum = 0

		for i in ipairs(list) do
			indexNum = indexNum + 1
		end

		if indexNum ~= 5 then
			xyd.WindowManager.get():openWindow("activity_all_stars_pray_heros_window", {
				canClose = true,
				selectGroup = self.groupId_,
				alreadyHeros = self.parent.activityData.detail.benches[self.groupId_].awards
			})

			self.parent.nowSelectGroup = self.groupId_

			return
		end

		local msg = messages_pb.use_pray_item_req()
		msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
		msg.bench_id = self.groupId_
		msg.num = 1
		msg.tp = 3

		xyd.Backend.get():request(xyd.mid.USE_PRAY_ITEM, msg)
	end)
end

function ActivityAllStarsPrayGroupItem:setImage()
	if self.groupId_ == nil then
		return
	end

	xyd.setUISpriteAsync(self.groupIcon, nil, "img_group" .. tostring(self.groupId_))

	self.groupName.text = __("ACTIVITY_PRAY_GROUP" .. tostring(self.groupId_))
end

function ActivityAllStarsPrayGroupItem:setBarProgress(nowNum_, totalNum_)
	if totalNum_ then
		self.totalNum = totalNum_
	end

	self.nowNum = nowNum_
	self.progressBar.value = math.min(self.nowNum, self.totalNum) / self.totalNum
	self.persent.text = tostring(math.min(self.nowNum, self.totalNum)) .. "/" .. tostring(self.totalNum)

	self:updateMask()
end

function ActivityAllStarsPrayGroupItem:setAwardIcon()
	if self.groupId_ == nil then
		return
	end

	if not self.awardIcon then
		local itemID = self.parent.activityData.groupFragmentIDs[self.groupId_]
		self.awardIcon = xyd.getItemIcon({
			scale = 0.5462962962962963,
			itemID = itemID,
			uiRoot = self.awardIconNode
		})
	end

	self:updateMask()
end

function ActivityAllStarsPrayGroupItem:updateMask()
	local canGetAward = false
	canGetAward = self.parent.activityData.needNumsOfGroupFragment[self.groupId_] <= xyd.models.backpack:getItemNumByID(self.parent.activityData.groupFragmentIDs[self.groupId_])

	if canGetAward then
		self.awardMask:SetActive(true)
	else
		self.awardMask:SetActive(false)
	end
end

function ActivityAllStarsPrayGroupItem:updateRedMask()
	local flag = self.parent.activityData:checkRedPoint_gem(self.groupId_)

	self.redMask:SetActive(flag)
end

function ActivityAllStarsPrayGroupItem:getObj()
	return self.transGo.gameObject
end

return ActivityAllStarsPray
