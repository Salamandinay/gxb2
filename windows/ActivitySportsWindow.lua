local BaseWindow = import(".BaseWindow")
local ActivitySportsWindow = class("ActivitySportsWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local WindowTop = require("app.components.WindowTop")
local ActivitySportsHelpItems = import("app.components.ActivitySportsHelpItems")

function ActivitySportsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)
	self.id = xyd.ActivityID.SPORTS
	self.ActivitySportsHelpItems = ActivitySportsHelpItems.new()
end

function ActivitySportsWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:createChildren()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.SPORTS)
end

function ActivitySportsWindow:getUIComponent()
	self.trans = self.window_.transform
	self.imgBg_uiTexture = self.trans:ComponentByName("imgBg", typeof(UITexture))
	self.upCon = self.trans:NodeByName("upCon").gameObject
	self.flag_uiSprite = self.upCon:ComponentByName("flag", typeof(UISprite))
	self.flag = self.flag_uiSprite.gameObject
	self.logoNode = self.upCon:NodeByName("logoNode").gameObject
	self.logo_uiTexture = self.logoNode:ComponentByName("logo", typeof(UITexture))
	self.stateText = self.logoNode:ComponentByName("stateText", typeof(UILabel))
	self.countDownText = self.logoNode:ComponentByName("countDownText", typeof(UILabel))
	self.e_Group = self.upCon:NodeByName("e:Group").gameObject
	self.helpBtn0 = self.e_Group:NodeByName("helpBtn0").gameObject
	self.helpBtn0_uiSprite = self.e_Group:ComponentByName("helpBtn0", typeof(UISprite))
	self.button_label_uiLabel = self.helpBtn0:ComponentByName("button_label", typeof(UILabel))
	self.lizhanNode = self.trans:NodeByName("lizhanNode").gameObject
	self.lizhanImg_uiTexture = self.lizhanNode:ComponentByName("lizhanImg", typeof(UITexture))
	self.lizhanText = self.lizhanNode:ComponentByName("lizhanText", typeof(UILabel))

	self.lizhanNode:SetActive(false)

	self.showsNode = self.trans:NodeByName("showsNode").gameObject
	self.showsImg_uiTexture = self.showsNode:ComponentByName("showsImg", typeof(UITexture))
	self.showsText = self.showsNode:ComponentByName("showsText", typeof(UILabel))
	self.exchangeNode = self.trans:NodeByName("exchangeNode").gameObject
	self.exchangeImg_uiTexture = self.exchangeNode:ComponentByName("exchangeImg", typeof(UITexture))
	self.exchangeRedPoint = self.exchangeNode:ComponentByName("exchangeRedPoint", typeof(UISprite))
	self.exchangeText = self.exchangeNode:ComponentByName("exchangeText", typeof(UILabel))
	self.fightNode = self.trans:NodeByName("fightNode").gameObject
	self.fightImg_uiTexture = self.fightNode:ComponentByName("fightImg", typeof(UITexture))
	self.fightText = self.fightNode:ComponentByName("fightText", typeof(UILabel))
	self.groupNode = self.trans:NodeByName("groupNode").gameObject
	self.groupImg_uiTexture = self.groupNode:ComponentByName("groupImg", typeof(UITexture))
	self.groupText = self.groupNode:ComponentByName("groupText", typeof(UILabel))
	self.leftLabel = self.trans:NodeByName("leftLabel").gameObject
	self.manaNode = self.leftLabel:NodeByName("manaNode").gameObject
	self.manaNodeImg = self.manaNode:NodeByName("manaNodeImg").gameObject
	self.manaNodeImg_layout = self.manaNode:ComponentByName("manaNodeImg", typeof(UILayout))
	self.manaNodeImg_imgWidth = self.manaNode:ComponentByName("manaNodeImg", typeof(UIWidget))
	self.labelIcon_uiSprite = self.manaNodeImg:ComponentByName("labelIcon", typeof(UISprite))
	self.manaText = self.manaNodeImg:ComponentByName("manaText", typeof(UILabel))
	self.scoreNode = self.leftLabel:NodeByName("scoreNode").gameObject
	self.scoreNode_imgWidth = self.scoreNode:ComponentByName("e:Image", typeof(UIWidget))
	self.groupScoreWords = self.scoreNode:ComponentByName("groupScoreWords", typeof(UILabel))
	self.fightScoreWords = self.scoreNode:ComponentByName("fightScoreWords", typeof(UILabel))
	self.groupScoreText = self.scoreNode:ComponentByName("groupScoreText", typeof(UILabel))
	self.fightScoretext = self.scoreNode:ComponentByName("fightScoretext", typeof(UILabel))

	self.leftLabel:Y(413 + 47 * self.scale_num_contrary)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.SPORTS, self.exchangeRedPoint.gameObject)
end

function ActivitySportsWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivitySportsWindow:createChildren()
	local play_tips = xyd.db.misc:getValue("activity_sports_tips" .. xyd.tables.miscTable:getVal("activity_sports_term"))

	if tostring(xyd.Global.lang) == "zh_tw" then
		self.scoreNode_imgWidth.width = 214
		self.manaNodeImg_imgWidth.width = 228

		self.manaNodeImg_layout:Reposition()
	elseif tostring(xyd.Global.lang) == "de_de" then
		self.scoreNode_imgWidth.width = 340
		self.manaNodeImg_imgWidth.width = 268

		self.manaNodeImg_layout:Reposition()
	elseif tostring(xyd.Global.lang) == "fr_fr" then
		self.scoreNode_imgWidth.width = 295
		self.manaNodeImg_imgWidth.width = 268

		self.manaNodeImg_layout:Reposition()
	else
		self.scoreNode_imgWidth.width = 254
		self.manaNodeImg_imgWidth.width = 268

		self.manaNodeImg_layout:Reposition()
	end

	local msg = messages_pb:record_activity_req()
	msg.activity_id = xyd.ActivityID.SPORTS

	xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
	self.scoreNode:SetActive(false)
	self:layout()

	if play_tips and play_tips ~= "" then
		self:registerEvent()
		self:playOpenEffect()
		self.flag:SetActive(true)
		self.scoreNode:SetActive(true)
	else
		xyd.WindowManager.get():openWindow("story_window", {
			jumpToSelect = true,
			story_type = xyd.StoryType.ACTIVITY,
			story_id = xyd.tables.activityTable:getPlotId(xyd.ActivityID.SPORTS),
			callback = function ()
				xyd.db.misc:setValue({
					value = "true",
					key = "activity_sports_tips" .. xyd.tables.miscTable:getVal("activity_sports_term")
				})
				self:registerEvent()
				self:playOpenEffect()
				self.flag:SetActive(true)
				self.scoreNode:SetActive(true)
				xyd.WindowManager.get():openWindow("img_guide_window", {
					totalPage = 3,
					items = {
						self.ActivitySportsHelpItems.ActivitySportsHelp1,
						self.ActivitySportsHelpItems.ActivitySportsHelp2,
						self.ActivitySportsHelpItems.ActivitySportsHelp3
					},
					callback = function ()
						xyd.WindowManager.get():openWindow("alert_window", {
							alertType = xyd.AlertType.CONFIRM,
							message = __("ACTIVITY_SPORTS_TEXT02", xyd.tables.groupTextTable:getName(self.activityData.detail.arena_info.group)),
							callback = function ()
								xyd.WindowManager.get():openWindow("activity_sports_fight_window")
							end
						})
					end
				})
			end
		})
	end

	local rankType = xyd.ActivitySportsRankType.FIGHT_POINT_2

	if self.activityData:getNowState() <= 3 then
		rankType = xyd.ActivitySportsRankType.FIGHT_POINT_1
	end

	local msg2 = messages_pb:sports_get_rank_list_req()
	msg2.activity_id = xyd.ActivityID.SPORTS
	msg2.rank_type = rankType

	xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST, msg2)

	if self.activityData:getNowState() == xyd.ActivitySportsTime.SHOW then
		xyd.applyChildrenGrey(self.showsNode.gameObject)
	end
end

function ActivitySportsWindow:playOpenEffect()
	local nodes = {
		self.exchangeNode,
		self.fightNode,
		self.showsNode,
		self.groupNode,
		self.e_Group
	}

	for i = 1, #nodes do
		local delayTime = 0

		if i < 2 then
			delayTime = 0.1
		end

		nodes[i].gameObject:GetComponent(typeof(UIWidget)).alpha = 0.5

		nodes[i]:SetLocalScale(0.5, 0.5, 0.5)

		local action = self:getSequence()

		action:Append(nodes[i].transform:DOScale(0.5, delayTime))

		local function resGroupSetter(value)
			nodes[i]:GetComponent(typeof(UIWidget)).alpha = value
			local nodesScale = 0.5 + 0.6000000000000001 * (value - 0.5) * 2

			nodes[i]:SetLocalScale(nodesScale, nodesScale, nodesScale)
		end

		action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(resGroupSetter), 0.5, 1, 0.13):SetEase(DG.Tweening.Ease.Linear))
		action:Append(nodes[i].transform:DOScale(0.97, 0.13))
		action:Append(nodes[i].transform:DOScale(1, 0.16))
		action:AppendCallback(function ()
			action:Kill(true)
		end)
	end

	self.flag:Y(668)

	local actionFlag = self:getSequence()

	actionFlag:Append(self.flag.transform:DOLocalMoveY(575, 0.2))
	actionFlag:AppendCallback(function ()
		actionFlag:Kill(true)
	end)
	self.logoNode:Y(730)

	local actionLogo = self:getSequence()

	actionLogo:Append(self.logoNode.transform:DOLocalMoveY(572, 0.13))
	actionLogo:Append(self.logoNode.transform:DOLocalMoveY(582, 0.17))
	actionLogo:AppendCallback(function ()
		actionLogo:Kill(true)
	end)
	self.manaNode:X(-115)

	local actionMana = self:getSequence()

	actionMana:Append(self.manaNode.transform:DOLocalMoveX(101, 0.2))
	actionMana:AppendCallback(function ()
		actionMana:Kill(true)
	end)
	self.scoreNode:X(101 - self.scoreNode_imgWidth.width)

	local actionScore = self:getSequence()

	actionScore:Append(self.scoreNode.transform:DOLocalMoveX(101 - self.scoreNode_imgWidth.width, 0.1))
	actionScore:Append(self.scoreNode.transform:DOLocalMoveX(101, 0.2))
	actionScore:AppendCallback(function ()
		actionScore:Kill(true)
	end)
end

function ActivitySportsWindow:registerEvent()
	UIEventListener.Get(self.showsNode.gameObject).onClick = handler(self, function ()
		if self.activityData:getNowState() == xyd.ActivitySportsTime.SHOW then
			xyd.showToast(__("ACTIVITY_SPORTS_SHOWS_OVER"))

			return
		end

		xyd.WindowManager.get():openWindow("activity_sports_shows_window")
	end)
	UIEventListener.Get(self.groupNode.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_sports_group_window", {
			activityData = self.activityData
		})
	end)
	UIEventListener.Get(self.exchangeNode.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_sports_exchange_window")
	end)
	UIEventListener.Get(self.lizhanNode.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_travelfrog_window")
	end)
	UIEventListener.Get(self.fightNode.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_sports_fight_window")
	end)
	UIEventListener.Get(self.helpBtn0.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SPORTS_HELP"
		})
	end)

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateScore))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_SET_PARTNERS, handler(self, self.updatePartnersDef))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST, handler(self, self.updateRank))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:updateScore()
	end)
end

function ActivitySportsWindow:layout()
	self:setTimeShow()
	xyd.setUITextureByNameAsync(self.logo_uiTexture, "activity_sports_logo_" .. xyd.Global.lang, true)
	xyd.setUISpriteAsync(self.flag_uiSprite, nil, "sports_group_" .. tostring(self.activityData.detail.arena_info.group), nil, )
	self:updateScore()

	self.fightText.text = __("ACTIVITY_SPORTS_LABEL_1")
	self.lizhanText.text = __("ACTIVITY_SPORTS_LABEL_2")
	self.exchangeText.text = __("ACTIVITY_SPORTS_LABEL_3")
	self.showsText.text = __("ACTIVITY_SPORTS_LABEL_4")
	self.groupText.text = __("ACTIVITY_SPORTS_LABEL_5")
	self.groupScoreWords.text = __("ACTIVITY_SPORTS_SCORE")
	self.fightScoreWords.text = __("ACTIVITY_SPORTS_FIGHT_SCORE")
end

function ActivitySportsWindow:setTimeShow()
	if self.activityData:getStateEndTime() < xyd.getServerTime() then
		self.countDownText:SetActive(false)

		self.stateText.text = ""
	else
		self.countDownText:SetActive(true)

		self.setCountDownTime = CountDown.new(self.countDownText, {
			duration = self.activityData:getStateEndTime() - xyd:getServerTime(),
			callback = handler(self, self.timeOver)
		})
		self.stateText.text = __("ACTIVITY_SPORTS_STATE_" .. tostring(self.activityData:getNowState()))
	end
end

function ActivitySportsWindow:timeOver()
	self.countDownText:SetActive(false)

	self.stateText.text = ""
end

function ActivitySportsWindow:updateScore()
	self.manaText.text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.SPORTS_SCORE))

	self.manaNodeImg_layout:Reposition()

	self.fightScoretext.text = self.activityData.detail.arena_info.point
	local group = self.activityData.detail.arena_info.group
	self.groupScoreText.text = xyd.getRoughDisplayNumber(self.activityData.detail.all_group_points[group])

	self:checkRedPoint()
end

function ActivitySportsWindow:checkRedPoint()
	local state = false

	if self.activityData:getRedMarkState() then
		state = true
	end

	self.exchangeRedPoint:SetActive(state)
	xyd.models.redMark:setMark(xyd.RedMarkType.SPORTS, state)
end

function ActivitySportsWindow:updatePartnersDef(event)
	self.activityData.detail.arena_info.partners = event.data.partners
	self.activityData.detail.arena_info.pet = event.data.pet or {}
	local win = xyd.WindowManager.get():getWindow("activity_sports_fight_window")

	if win then
		win:updatePower()

		if not self.activityData.selfRank or self.activityData.selfRank == 0 then
			win:getRankListInfo()
		end
	end
end

function ActivitySportsWindow:updateRank(event)
	if event.data.rank_type > 6 then
		self.activityData.selfRank = event.data.rank
		self.activityData.totalRankNum = event.data.total_num
	end
end

function ActivitySportsWindow:openMatchInfoWin(event)
	local win = xyd.WindowManager.get():getWindow("activity_sports_fight_window")

	if win then
		win:initWindow()
	else
		xyd.WindowManager:openWindow("activity_sports_fight_window", {
			activityData = self.activityData,
			matchData = event.data
		})

		local rankType = 8

		if self.activityData:getNowState() <= 3 then
			rankType = 7
		end

		local msg2 = messages_pb:sports_get_rank_list_req()
		msg2.activity_id = xyd.ActivityID.SPORTS
		msg2.rank_type = rankType

		xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST, msg2)
	end
end

return ActivitySportsWindow
