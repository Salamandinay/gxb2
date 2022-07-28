local TimeCloisterProbeWindow = class("TimeCloisterProbeWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local HeroIcon = import("app.components.HeroIcon")
local timeCloister = xyd.models.timeCloisterModel
local tecTable = xyd.tables.timeCloisterTecTable
local cardPosInfo = {
	{
		delta = 135,
		x = -218,
		y = -152,
		scale = {
			0.47,
			0.44
		}
	},
	{
		delta = 125,
		x = -202,
		y = 15,
		scale = {
			0.4371,
			0.4092
		}
	},
	{
		delta = 115,
		x = -188,
		y = 172,
		scale = {
			0.40419999999999995,
			0.3784
		}
	}
}

function TimeCloisterProbeWindow:ctor(name, params)
	self.cloister = params.cloister
	self.cardTime = tonumber(xyd.tables.miscTable:getVal("time_cloister_card_time"))

	timeCloister:reqAchieveInfo(self.cloister)
	timeCloister:reqTechInfo(self.cloister)
	TimeCloisterProbeWindow.super.ctor(self, name, params)
end

function TimeCloisterProbeWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	dump(timeCloister:getTechInfoByCloister(self.cloister), "test tec tree")

	local isGuide = self:checkGuide()

	if timeCloister:getChosenCloister() ~= 0 then
		self.hangInfo = timeCloister:getHangInfo()

		self:initContent()
		self:updateShowEventIcon()

		if not isGuide then
			self:autoOpenExtraEventWindow()
		else
			xyd.WindowManager.get():closeWindow("time_cloister_encounter_window")
			xyd.WindowManager.get():closeWindow("time_cloister_show_dress_window")
		end
	end
end

function TimeCloisterProbeWindow:getUIComponent()
	local groupTop = self.window_:NodeByName("groupTop").gameObject
	self.helpBtn = groupTop:NodeByName("helpBtn").gameObject
	self.awradPreviewBtn = groupTop:NodeByName("awradPreviewBtn").gameObject
	self.titleLabel = groupTop:ComponentByName("titleLabel", typeof(UILabel))
	self.bigBg = self.window_:ComponentByName("bg", typeof(UITexture))
	local groupMid = self.window_:NodeByName("groupMid").gameObject
	self.countDownGroup = groupMid:NodeByName("countDownGroup").gameObject
	self.tipsLabel = self.countDownGroup:ComponentByName("tipsLabel", typeof(UILabel))
	self.timeLabel = self.countDownGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.speedUpGroup = groupMid:NodeByName("speedUpGroup").gameObject
	self.numLabel = self.speedUpGroup:ComponentByName("numLabel", typeof(UILabel))
	self.handNode3 = self.speedUpGroup:NodeByName("handNode").gameObject
	self.speedUpRedPoint = self.speedUpGroup:NodeByName("redPoint").gameObject
	self.btnSupply = groupMid:NodeByName("btnSupply").gameObject
	self.btnSupplyLabel = self.btnSupply:ComponentByName("label", typeof(UILabel))
	self.btnSupplyUISprite = self.btnSupply:GetComponent(typeof(UISprite))
	self.btnChallenge = groupMid:NodeByName("btnChallenge").gameObject
	self.btnChallengeLabel = self.btnChallenge:ComponentByName("label", typeof(UILabel))
	self.btnChallengeUISprite = self.btnChallenge:GetComponent(typeof(UISprite))
	self.btnEvent = groupMid:NodeByName("btnEvent").gameObject
	self.btnEventLabel = self.btnEvent:ComponentByName("label", typeof(UILabel))
	self.btnEventUISprite = self.btnEvent:GetComponent(typeof(UISprite))
	self.btnRecord = groupMid:NodeByName("btnRecord").gameObject
	self.btnRecordLabel = self.btnRecord:ComponentByName("label", typeof(UILabel))
	self.btnRecordUISprite = self.btnRecord:GetComponent(typeof(UISprite))
	self.progressBar = groupMid:ComponentByName("progressBar", typeof(UISlider))
	self.selectCard1 = groupMid:ComponentByName("selectCard1", typeof(UISprite))
	self.handNode1 = groupMid:NodeByName("handNode").gameObject
	self.extraEventCon = groupMid:NodeByName("extraEventCon").gameObject
	self.extraEventConUILayout = groupMid:ComponentByName("extraEventCon", typeof(UILayout))
	self.extraEventBtn1 = self.extraEventCon:NodeByName("extraEventBtn1").gameObject
	self.extraEventBtn1UISprite = self.extraEventCon:ComponentByName("extraEventBtn1", typeof(UISprite))
	self.extraEventBtn1NumBg = self.extraEventBtn1:NodeByName("extraEventBtn1NumBg").gameObject
	self.extraEventBtn1Num = self.extraEventBtn1:ComponentByName("extraEventBtn1Num", typeof(UILabel))
	self.extraEventBtn2 = self.extraEventCon:NodeByName("extraEventBtn2").gameObject
	self.extraEventBtn2UISprite = self.extraEventCon:ComponentByName("extraEventBtn2", typeof(UISprite))
	self.extraEventBtn2NumBg = self.extraEventBtn2:NodeByName("extraEventBtn2NumBg").gameObject
	self.extraEventBtn2Num = self.extraEventBtn2:ComponentByName("extraEventBtn2Num", typeof(UILabel))
	local groupBot = self.window_:NodeByName("groupBot").gameObject
	self.btnTech = groupBot:NodeByName("btnTech").gameObject
	self.btnTechLabel = self.btnTech:ComponentByName("label", typeof(UILabel))
	self.btnTechRedPoint = self.btnTech:NodeByName("redPoint").gameObject
	self.handNode2 = self.btnTech:NodeByName("handNode").gameObject
	local groupPartners = groupBot:NodeByName("groupPartners").gameObject
	self.partnerRoots = {}

	for i = 1, 6 do
		table.insert(self.partnerRoots, groupPartners:NodeByName("partner_" .. i .. "/partner_root").gameObject)
	end

	local groupAttr = groupBot:NodeByName("groupAttr").gameObject
	self.labelYQ = groupAttr:ComponentByName("labelYQ", typeof(UILabel))
	self.labelML = groupAttr:ComponentByName("labelML", typeof(UILabel))
	self.labelZS = groupAttr:ComponentByName("labelZS", typeof(UILabel))
	self.cardTable = self.window_:NodeByName("cardTable").gameObject

	for i = 1, 3 do
		self["cardRow_" .. i] = self.cardTable:NodeByName("row" .. i).gameObject
	end

	self.cardItem = self.cardTable:NodeByName("cardItem").gameObject
	self.dressRoot = self.cardTable:NodeByName("topPanel/dressRoot").gameObject
	self.selectCard2 = self.cardTable:ComponentByName("topPanel/selectCard2", typeof(UISprite))
	self.selectCard2Icon = self.selectCard2:ComponentByName("icon", typeof(UISprite))
	self.selectCard2NameBg = self.selectCard2:NodeByName("nameBg").gameObject
	self.selectCard2NameLabel = self.selectCard2:ComponentByName("nameLabel", typeof(UILabel))
	self.selectCard2DescLabel = self.selectCard2:ComponentByName("descLabel", typeof(UILabel))
	self.selectCard3 = self.cardTable:NodeByName("topPanel/selectCard3").gameObject
	self.selectCard3UISprite = self.cardTable:ComponentByName("topPanel/selectCard3", typeof(UISprite))
	self.showTweenCon = self.window_:NodeByName("showTweenCon").gameObject
	self.showTweenMask = self.showTweenCon:NodeByName("showTweenMask").gameObject
end

function TimeCloisterProbeWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			hidePlus = true,
			id = xyd.ItemID.TIME_CLOISTR_SPEED_UP
		}
	}

	self.windowTop:setItem(items)
end

function TimeCloisterProbeWindow:layout()
	self:initTopGroup()
	self.selectCard1:SetActive(false)
	self.selectCard2:SetActive(false)
	self.selectCard3:SetActive(false)

	local bgImgName = xyd.tables.timeCloisterTable:getBg(self.cloister)

	xyd.setUITextureByNameAsync(self.bigBg, bgImgName)
end

function TimeCloisterProbeWindow:showSpeedUpTips()
	if self.hangInfo.stop_time and self.hangInfo.stop_time > 0 then
		self.speedUpRedPoint:SetActive(false)

		return
	end

	if not xyd.db.misc:getValue("time_cloister_speed_up_hand") and xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_CLOISTR_SPEED_UP) > 0 then
		self.hand3 = xyd.Spine.new(self.handNode3)

		self.hand3:setInfo("fx_ui_dianji", function ()
			self.hand3:play("texiao01", 0)
		end)
		self.speedUpRedPoint:SetActive(false)
	else
		self.handNode1:SetActive(false)
		self.speedUpRedPoint:SetActive(xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_CLOISTR_SPEED_UP) > 0)
	end
end

function TimeCloisterProbeWindow:getCloisterImg(str)
	local img = str

	if self.cloister and self.cloister ~= 1 then
		img = img .. "_level_" .. self.cloister
	end

	return img
end

function TimeCloisterProbeWindow:initContent()
	local colorArr1 = xyd.tables.timeCloisterTable:getMainWindowCardColor1(self.cloister)
	local colorArr2 = xyd.tables.timeCloisterTable:getMainWindowCardColor2(self.cloister)
	self.btnSupplyLabel.text = __("TIME_CLOISTER_TEXT21")
	self.btnSupplyLabel.color = Color.New2("0x" .. colorArr1[1] .. "ff")
	self.btnSupplyLabel.effectColor = Color.New2("0x" .. colorArr1[2] .. "ff")

	xyd.setUISpriteAsync(self.btnSupplyUISprite, nil, self:getCloisterImg("time_cloister_btn_supply"))

	self.btnChallengeLabel.text = __("TIME_CLOISTER_TEXT22")
	self.btnChallengeLabel.color = Color.New2("0x" .. colorArr1[1] .. "ff")
	self.btnChallengeLabel.effectColor = Color.New2("0x" .. colorArr1[2] .. "ff")

	xyd.setUISpriteAsync(self.btnChallengeUISprite, nil, self:getCloisterImg("time_cloister_btn_challenge"))

	self.btnEventLabel.text = __("TIME_CLOISTER_TEXT23")
	self.btnEventLabel.color = Color.New2("0x" .. colorArr1[1] .. "ff")
	self.btnEventLabel.effectColor = Color.New2("0x" .. colorArr1[2] .. "ff")

	xyd.setUISpriteAsync(self.btnEventUISprite, nil, self:getCloisterImg("time_cloister_btn_event"))

	self.btnRecordLabel.text = __("TIME_CLOISTER_TEXT24")
	self.btnRecordLabel.color = Color.New2("0x" .. colorArr2[1] .. "ff")
	self.btnRecordLabel.effectColor = Color.New2("0x" .. colorArr2[2] .. "ff")

	xyd.setUISpriteAsync(self.btnRecordUISprite, nil, self:getCloisterImg("time_cloister_btn_record"))

	self.btnTechLabel.text = __("TIME_CLOISTER_TEXT32")
	self.titleLabel.text = xyd.tables.timeCloisterTable:getName(self.cloister)

	xyd.setUISpriteAsync(self.selectCard3UISprite, nil, self:getCloisterImg("time_cloister_card_1"))
	xyd.setUISpriteAsync(self.selectCard1, nil, self:getCloisterImg("time_cloister_card"))
	self:initHangPartner()
	self:updateCountDown()
	self:initCardTable()

	if timeCloister:getTechInfoByCloister(self.cloister) then
		self:updateTechRed()
	end

	self:showSpeedUpTips()
end

function TimeCloisterProbeWindow:showHandTips()
	if not self.hand1 then
		self.hand1 = xyd.Spine.new(self.handNode1)

		self.hand1:setInfo("fx_ui_dianji", function ()
			self.hand1:play("texiao01", 0)
		end)
	end

	self.handNode1:SetActive(true)
end

function TimeCloisterProbeWindow:initHangPartner()
	local partners = self.hangInfo.partners
	local partner_infos = self.hangInfo.partner_infos or {}

	for i = 1, 6 do
		local parnterInfo = nil

		if partner_infos[i] and partner_infos[i].table_id and partner_infos[i].table_id ~= 0 then
			parnterInfo = {
				tableID = partner_infos[i].table_id,
				lev = partner_infos[i].lv,
				isVowed = partner_infos[i].is_vowed,
				star = xyd.tables.partnerTable:getStar(partner_infos[i].table_id) + partner_infos[i].awake,
				skin_id = partner_infos[i].equips[7]
			}
		elseif partners[i] and partners[i] ~= 0 then
			local partner = xyd.models.slot:getPartner(partners[i])

			if partner then
				parnterInfo = partner:getInfo()
			end
		end

		if parnterInfo then
			local item = HeroIcon.new(self.partnerRoots[i])
			parnterInfo.scale = 0.7037037037037037
			parnterInfo.callback = nil

			item:setInfo(parnterInfo)
			item:setNoClick(true)
		end
	end

	local baseAttr = self.hangInfo.black_base
	local self_base = self.hangInfo.self_base
	self.labelYQ.text = baseAttr[1] .. "+[c][3aba58]" .. self_base[1] - baseAttr[1]
	self.labelML.text = baseAttr[2] .. "+[c][3aba58]" .. self_base[2] - baseAttr[2]
	self.labelZS.text = baseAttr[3] .. "+[c][3aba58]" .. self_base[3] - baseAttr[3]
end

function TimeCloisterProbeWindow:updateCountDown()
	local energy = self.hangInfo.energy
	self.numLabel.text = math.floor(energy) .. "/" .. self.hangInfo.maxEnergy

	if self.hangInfo.stop_time and self.hangInfo.stop_time > 0 then
		if self.countDown then
			self.countDown:stopTimeCount()
		end

		self.tipsLabel.text = __("TIME_CLOISTER_TEXT20")

		self.timeLabel:SetActive(false)

		self.progressBar.value = 1

		self:showHandTips()
		self.speedUpRedPoint:SetActive(false)
	else
		self.tipsLabel.text = __("TIME_CLOISTER_TEXT19")

		if not self.countDown then
			self.countDown = import("app.components.CountDown").new(self.timeLabel)
		end

		self.secCount = math.max(xyd.getServerTime() - self.hangInfo.start_time, 1) % self.cardTime
		self.progressBar.value = self.secCount / self.cardTime

		self.countDown:setInfo({
			duration = timeCloister.leftProbeTime,
			callback = function ()
				self.tipsLabel.text = __("TIME_CLOISTER_TEXT20")

				self.timeLabel:SetActive(false)

				self.progressBar.value = 1

				self.speedUpRedPoint:SetActive(false)
			end,
			doOnTime = function ()
				self.secCount = self.secCount % self.cardTime + 1

				if self.progressBar then
					self.progressBar.value = self.secCount / self.cardTime
				else
					return
				end

				if self.secCount % self.cardTime == self.cardTime - 3 then
					self.selectCard = self.hangInfo.after_events2[1]
				end

				if self.secCount % self.cardTime == 0 then
					self:waitForTime(1, function ()
						self.numLabel.text = math.floor(self.hangInfo.energy) .. "/" .. self.hangInfo.maxEnergy
					end)
					self:playCardTableAnimation()
				end
			end
		})
	end

	self.countDownGroup:GetComponent(typeof(UILayout)):Reposition()
end

function TimeCloisterProbeWindow:initCardTable()
	self.cardList = {}

	for i = 1, 3 do
		self.cardList[i] = {}
		local pos = cardPosInfo[i]

		for j = 1, 5 do
			local cardItem = NGUITools.AddChild(self["cardRow_" .. i], self.cardItem)

			cardItem:SetLocalPosition(pos.x + (j - 1) * pos.delta, 0, 0)
			cardItem:SetLocalScale(pos.scale[1], pos.scale[2], 1)

			local cardImgUISprite = cardItem:ComponentByName("cardImg", typeof(UISprite))
			local imgName = "time_cloister_card"

			if self.cloister and tonumber(self.cloister) ~= 1 then
				imgName = "time_cloister_card_level_" .. self.cloister
			end

			xyd.setUISpriteAsync(cardImgUISprite, nil, imgName, nil, , )

			self.cardList[i][j] = {
				cardItem = cardItem,
				cardImg = cardImgUISprite,
				select = cardItem:ComponentByName("select", typeof(UISprite))
			}
		end

		self.cardList[i][5].cardItem:SetActive(false)
	end

	self.senpaiModel = import("app.components.SenpaiModel").new(self.dressRoot)

	self.senpaiModel:setModelInfo({
		ids = xyd.models.dress:getEffectEquipedStyles()
	})
	self.senpaiModel:SetLocalScale(0.6, 0.6, 1)

	self.curRow = math.random(1, 3)

	if next(self.hangInfo.events) then
		self.curCol = 3

		self.cardList[self.curRow][self.curCol].cardImg:SetActive(false)
	else
		self.curCol = 2
	end

	self.nextRow = 0
	local pos = cardPosInfo[self.curRow]

	self.senpaiModel:SetLocalPosition(pos.x + (self.curCol - 1) * pos.delta, pos.y - 25, 0)
end

function TimeCloisterProbeWindow:playCardTableAnimation()
	if self.isPlayCardAnimation then
		return
	end

	self.isPlayCardAnimation = true

	if self.nextRow == 0 then
		self.nextRow = math.random(1, 3)
	end

	for i = 1, 3 do
		self.cardList[i][5].cardImg:SetActive(true)
		self.cardList[i][5].cardItem:SetActive(true)
	end

	local select = self.cardList[self.nextRow][self.curCol + 1].select

	select:SetActive(true)

	local sequence = self:getSequence()

	self.senpaiModel:walk()
	sequence:Append(self.cardTable.transform:DOLocalMoveX(18, 0.01))

	if self.curCol == 3 then
		for i = 1, 3 do
			local pos = cardPosInfo[i]

			for j = 1, 5 do
				local trans = self.cardList[i][j].cardItem.transform

				sequence:Join(trans:DOLocalMoveX(pos.x + (j - 2) * pos.delta, 1))
			end
		end
	end

	local nextPos = cardPosInfo[self.nextRow]

	sequence:Join(self.senpaiModel.go.transform:DOLocalMove(Vector3(nextPos.x + 2 * nextPos.delta, nextPos.y, 0), 1))
	self:drawCard(sequence)
end

function TimeCloisterProbeWindow:drawCard(sequence)
	if not self.selectCard then
		if self.senpaiModel then
			self.senpaiModel:idle()
		end

		self.isPlayCardAnimation = false

		return
	end

	local type = xyd.tables.timeCloisterCardTable:getType(self.selectCard)
	local deck = nil

	if type == xyd.TimeCloisterCardType.SUPPLY then
		deck = self.btnSupply:GetComponent(typeof(UISprite))
	elseif type == xyd.TimeCloisterCardType.EVENT then
		deck = self.btnEvent:GetComponent(typeof(UISprite))
	else
		deck = self.btnChallenge:GetComponent(typeof(UISprite))
	end

	sequence:AppendCallback(function ()
		self.senpaiModel:idle()

		if self.curCol == 3 then
			for i = 1, 3 do
				local item = table.remove(self.cardList[i], 1)

				item.cardItem:X(cardPosInfo[i].x + 4 * cardPosInfo[i].delta)
				item.cardItem:SetActive(false)
				table.insert(self.cardList[i], item)
			end
		end

		self.curCol = 3

		self.cardList[self.nextRow][self.curCol].select:SetActive(false)
		self.cardList[self.nextRow][self.curCol].cardImg:SetActive(false)

		self.nextRow = 0
		self.curRow = self.nextRow

		self.selectCard1:SetActive(true)

		self.selectCard1.alpha = 0.01
		self.selectCard1.width = deck.width
		self.selectCard1.height = deck.height
		local pos = deck.gameObject.transform.localPosition

		self.selectCard1:SetLocalPosition(pos.x, pos.y, pos.z)
	end)

	local getter, setter = xyd.getTweenAlphaGeterSeter(self.selectCard1)

	sequence:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.5):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(self.selectCard1.gameObject.transform:DOLocalMoveY(-550, 0.5))
	sequence:Join(deck.gameObject.transform:DOScale(Vector3(0.95, 0.95, 0.95), 0.05))
	sequence:Insert(1.55, deck.gameObject.transform:DOScale(Vector3(1, 1, 1), 0.1))
	sequence:AppendCallback(function ()
		self.selectCard1:SetActive(false)
		self.selectCard2:SetLocalPosition(0, -550, 0)
		self.selectCard2:SetLocalScale(0.6, 0.6, 1)

		local cardTable = xyd.tables.timeCloisterCardTable
		self.selectCard2NameLabel.text = cardTable:getName(self.selectCard)
		self.selectCard2DescLabel.text = cardTable:getDesc(self.selectCard)
		local img = xyd.tables.timeCloisterCardTable:getImg(self.selectCard)

		xyd.setUISpriteAsync(self.selectCard2Icon, nil, img)
		xyd.models.timeCloisterModel:changeCommonCardUI(self.selectCard2.gameObject)
		self.selectCard2NameBg:SetActive(true)
		self.selectCard2NameLabel:SetActive(true)
		self.selectCard2DescLabel:SetActive(true)
		self.selectCard2Icon:SetActive(true)
		self.selectCard2:SetActive(true)
	end)

	local recordPos = self.cardTable.transform:InverseTransformPoint(self.btnRecord.transform.position)
	local selectTrans = self.selectCard2.gameObject.transform

	sequence:Append(selectTrans:DOLocalMove(Vector3(5, -125, 0), 0.1))
	sequence:Join(selectTrans:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))
	sequence:Append(selectTrans:DOScale(Vector3(1.1, 1.1, 1.1), 3))
	sequence:Append(selectTrans:DOLocalMove(Vector3(recordPos.x, recordPos.y, recordPos.z), 1))
	sequence:Join(selectTrans:DOScale(Vector3(0.4, 0.4, 0.4), 1))
	sequence:AppendCallback(function ()
		self.selectCard2:SetActive(false)
		sequence:Kill(false)

		self.isPlayCardAnimation = false

		self:updateShowEventIcon()
	end)
end

function TimeCloisterProbeWindow:playSpeedUpCardAnimation(num)
	if self.isPlayCardAnimation then
		return
	end

	self.isPlayCardAnimation = true
	local sequence = self:getSequence()

	self.senpaiModel:walk()

	for i = 1, 3 do
		self.cardList[i][5].cardImg:SetActive(true)
		self.cardList[i][5].cardItem:SetActive(true)
	end

	local randList = {}

	for i = 1, num do
		randList[i] = math.random(1, 3)
	end

	randList[0] = math.random(1, 3)

	self.cardList[randList[0]][5].cardImg:SetActive(false)
	self.cardList[math.random(1, 3)][4].cardImg:SetActive(false)

	for i = 1, 3 do
		local pos = cardPosInfo[i]

		for j = 1, 5 do
			local trans = self.cardList[i][j].cardItem.transform
			local first = math.max(0, j - num)

			sequence:Insert(0, trans:DOLocalMoveX(pos.x + (first - 1) * pos.delta, (j - first) / num):SetEase(DG.Tweening.Ease.Linear))

			local loop = math.floor(math.max(num - j, 0) / 5)

			for k = 1, loop do
				sequence:InsertCallback((k - 1) * 5 / num + (j - first) / num, function ()
					trans:X(pos.x + 4 * pos.delta)
					self.cardList[i][j].cardImg:SetActive(i ~= randList[j + 5 * loop])
				end)
				sequence:Insert((k - 1) * 5 / num + (j - first) / num, trans:DOLocalMoveX(pos.x - pos.delta, 5 / num):SetEase(DG.Tweening.Ease.Linear))
			end

			local left = num - loop * 5 - (j - first)

			if left > 0 then
				sequence:InsertCallback(loop * 5 / num + (j - first) / num, function ()
					trans:X(pos.x + 4 * pos.delta)

					if left > 1 then
						self.cardList[i][j].cardImg:SetActive(i ~= randList[j + 5 * loop])
					else
						self.cardList[i][j].cardImg:SetActive(true)
					end
				end)
				sequence:Insert(loop * 5 / num + (j - first) / num, trans:DOLocalMoveX(pos.x + (4 - left) * pos.delta, left / num):SetEase(DG.Tweening.Ease.Linear))
			end
		end
	end

	self.nextRow = randList[num - 2]
	local nextPos = cardPosInfo[self.nextRow]

	sequence:Insert(0, self.senpaiModel.go.transform:DOLocalMove(Vector3(nextPos.x + 2 * nextPos.delta, nextPos.y, 0), 1))
	sequence:AppendCallback(function ()
		self.senpaiModel:idle()

		for i = 1, 3 do
			local newOrder = {}

			for j = 1, 5 do
				newOrder[(j - num) % 5 + 1] = self.cardList[i][j]
			end

			self.cardList[i] = newOrder
		end

		self.curCol = 3

		self.senpaiModel:idle()

		for i = 1, 3 do
			local item = table.remove(self.cardList[i], 1)

			item.cardItem:X(cardPosInfo[i].x + 4 * cardPosInfo[i].delta)
			item.cardItem:SetActive(false)
			table.insert(self.cardList[i], item)
		end

		self.cardList[self.nextRow][self.curCol].select:SetActive(false)
		self.cardList[self.nextRow][self.curCol].cardImg:SetActive(false)

		self.nextRow = 0
		self.curRow = self.nextRow

		self.selectCard2:SetActive(true)
		self.selectCard2:SetLocalPosition(0, -550, 0)
		self.selectCard2:SetLocalScale(0.6, 0.6, 1)
		self.selectCard3:SetActive(true)
		self.selectCard3:SetLocalPosition(0, -550, 0)
		self.selectCard3:SetLocalScale(0.6, 0.6, 1)
		xyd.setUISpriteAsync(self.selectCard2, nil, timeCloister:getCloisterImg("time_cloister_card_1"))
		self.selectCard2NameBg:SetActive(false)
		self.selectCard2NameLabel:SetActive(false)
		self.selectCard2DescLabel:SetActive(false)
		self.selectCard2Icon:SetActive(false)
	end)
	sequence:Append(self.selectCard3.transform:DOLocalMove(Vector3(5, -125, 0), 0.1))
	sequence:Join(self.selectCard3.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))

	local selectTrans = self.selectCard2.gameObject.transform

	for i = 1, num - 2 do
		sequence:Append(selectTrans:DOLocalMove(Vector3(5, -125, 0), 0.1)):Join(selectTrans:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))
		sequence:AppendCallback(function ()
			self.selectCard2:SetLocalPosition(0, -550, 0)
			self.selectCard2:SetLocalScale(0.6, 0.6, 1)
		end)
	end

	sequence:Append(selectTrans:DOLocalMove(Vector3(5, -125, 0), 0.1))
	sequence:Join(selectTrans:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))
	sequence:AppendInterval(1)
	sequence:AppendCallback(function ()
		self.selectCard3:SetActive(false)
		self.selectCard2:SetActive(false)
		sequence:Kill(false)

		self.isPlayCardAnimation = false

		if self.hangInfo and self.hangInfo.events and next(self.hangInfo.events) then
			local isHasCommonCard = false

			for key, value in pairs(self.hangInfo.events) do
				local cardType = xyd.tables.timeCloisterCardTable:getType(key)

				if cardType ~= xyd.TimeCloisterCardType.ENCOUNTER_BATTLE and cardType ~= xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
					isHasCommonCard = true

					break
				end
			end

			if isHasCommonCard then
				xyd.WindowManager.get():openWindow("time_cloister_card_record_window")
			end
		end

		self:updateShowEventIcon()
	end)
end

function TimeCloisterProbeWindow:updateTechRed()
	local techInfo = timeCloister:getTechInfoByCloister(self.cloister)
	local canUp = false

	for _, groupList in ipairs(techInfo) do
		for tec_id, info in pairs(groupList) do
			if type(info) == "table" and info.curLv < info.maxLv then
				local cost = tecTable:getUpgradeCost(tec_id)[info.curLv + 1]

				if tec_id == xyd.TimeCloisterSpecialTecId.PARTNER_3_TEC then
					cost = {
						0,
						1
					}
					local specialCost = xyd.tables.timeCloisterTecTable:getUpgradeCostSpecial(tec_id)
					local partnerTecLev = techInfo[3][tec_id].curLv

					for i in pairs(specialCost) do
						if partnerTecLev < specialCost[i][2][1] then
							cost = specialCost[i][1]

							break
						end
					end
				end

				local preId = tecTable:getPreId(tec_id)

				if info.curLv > 0 or not next(preId) then
					canUp = cost[2] <= xyd.models.backpack:getItemNumByID(cost[1])
				else
					local unlock = false

					if next(preId) then
						local preLv = tecTable:getPreLv(tec_id)

						for i, id in ipairs(preId) do
							unlock = unlock or preLv[i] <= groupList[id].curLv
						end
					end

					if unlock then
						local unLockType = tecTable:getUnlockType(tec_id)
						local unLockNum = tecTable:getUnlockNum(tec_id)

						if unLockType == xyd.TimeCloisterUnLockType.SELF_BASE then
							local baseAttr = self.hangInfo.black_base

							for i = 1, 3 do
								unlock = unlock and unLockNum[i] <= baseAttr[i]
							end
						elseif unLockType == xyd.TimeCloisterUnLockType.EVENT_NUM then
							local sum_events = timeCloister:getSumEvents()
							unlock = unlock and unLockNum[2] <= (sum_events[tostring(unLockNum[1])] or 0)
						elseif unLockType == xyd.TimeCloisterUnLockType.ACHIEVEMENT then
							local achInfo = timeCloister:getAchInfo(self.cloister) or {}

							for _, data in ipairs(achInfo) do
								if data.achieve_type == unLockNum[1] then
									unlock = unlock and (data.achieve_id == 0 or unLockNum[2] < data.achieve_id)

									break
								end
							end
						elseif unLockType == xyd.TimeCloisterUnLockType.PROGRESS then
							unlock = unlock and unLockNum[1] <= self.hangInfo.progress
						elseif unLockType == xyd.TimeCloisterUnLockType.ENCOUNTER_FIGHT then
							local sum_start_events = timeCloister:getSumStartEvents()
							local needNum = sum_start_events[tostring(unLockNum[1])]
							needNum = not needNum and 0 or tonumber(needNum)
							unlock = sum_start_events and tonumber(unLockNum[2]) <= needNum
						end

						if unlock then
							canUp = cost[2] <= xyd.models.backpack:getItemNumByID(cost[1])
						end
					end
				end

				if canUp then
					break
				end
			end
		end
	end

	self.btnTechRedPoint:SetActive(canUp)
	self:checkAnotherBtnTechRedPoint()

	if not xyd.db.misc:getValue("time_cloister_tech_hand") then
		local hasLv = false
		local ids = tecTable:getIdsByCloister(self.cloister)

		for group, groupList in ipairs(techInfo) do
			hasLv = hasLv or groupList[ids[group][1]].curLv > 0
		end

		if not hasLv and xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_CLOISTR_TEC) >= 10 then
			-- Nothing
		end
	else
		self.handNode2:SetActive(false)
	end
end

function TimeCloisterProbeWindow:onBackSetIds(event)
	if event.data and event.data.cloister_id == xyd.TimeCloisterMissionType.THREE then
		self:updateTechRed()
	end
end

function TimeCloisterProbeWindow:checkAnotherBtnTechRedPoint()
	if self.cloister == xyd.TimeCloisterMissionType.THREE then
		if not self.btnTechRedPoint.gameObject.activeSelf then
			local resArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")
			local showNumArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_buy_tips", "value", "|")
			local isShow = true

			for i, id in pairs(resArr) do
				if xyd.models.backpack:getItemNumByID(id) < showNumArr[i] then
					isShow = false

					break
				end
			end

			if isShow then
				self.btnTechRedPoint.gameObject:SetActive(true)
			end
		end

		if not self.btnTechRedPoint.gameObject.activeSelf then
			local threeBattleSetIds = timeCloister:getThreeChoiceCrystalBattleCardIds()

			if threeBattleSetIds ~= nil and #threeBattleSetIds == 0 then
				self.btnTechRedPoint.gameObject:SetActive(true)
			end
		end
	end
end

function TimeCloisterProbeWindow:onStartHang()
	self.hangInfo = timeCloister:getHangInfo()

	self:initContent()
end

function TimeCloisterProbeWindow:onSpeedUpHang(event)
	if event.data and event.data.client_speed then
		self:overUpdateTime()

		return
	end

	self.hangInfo = timeCloister:getHangInfo()

	if timeCloister:getSpeedMorePropTips() then
		xyd.showToast(__("TIME_CLOISTER_TEXT18") .. "\n" .. __("TIME_CLOISTER_TEXT110"))
		timeCloister:setSpeedMorePropTips(false)
	else
		xyd.showToast(__("TIME_CLOISTER_TEXT18"))
	end

	self:updateCountDown()

	local num = timeCloister:getSpeedUpNum()

	if num > 0 then
		self:playSpeedUpCardAnimation(math.min(num * 2, 10))
	end
end

function TimeCloisterProbeWindow:overUpdateTime()
	self.hangInfo = timeCloister:getHangInfo()

	xyd.showToast(__("TIME_CLOISTER_TEXT109"))
	self:updateCountDown()
end

function TimeCloisterProbeWindow:onItemChange(event)
	local data = event.data.items
	local threeResArr = nil

	if self.cloister == xyd.TimeCloisterMissionType.THREE then
		threeResArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")
	end

	for i = 1, #data do
		if data[i].item_id == xyd.ItemID.TIME_CLOISTR_SPEED_UP and self.hangInfo then
			self:showSpeedUpTips()
		end

		if threeResArr ~= nil and xyd.arrayIndexOf(threeResArr, tonumber(data[i].item_id)) > -1 then
			self:checkAnotherBtnTechRedPoint()

			break
		end
	end
end

function TimeCloisterProbeWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.START_HANG, handler(self, self.onStartHang))
	self.eventProxy_:addEventListener(xyd.event.SPEED_UP_HANG, handler(self, self.onSpeedUpHang))
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_SKILL, handler(self, self.updateTechRed))
	self.eventProxy_:addEventListener(xyd.event.GET_TEC_INFO, handler(self, self.updateTechRed))
	self.eventProxy_:addEventListener(xyd.event.TIME_CLOISTER_COMMON_SET_IDS, handler(self, self.onBackSetIds))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))

	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TIME_CLOISTER_HELP02"
		})
	end)
	UIEventListener.Get(self.awradPreviewBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("time_cloister_award_preview_window", {
			items = self.hangInfo.items
		})
	end)
	UIEventListener.Get(self.speedUpGroup).onClick = handler(self, function ()
		if self.countDown and self.countDown.duration > 0 then
			if self.hand3 then
				self.hand3:destroy()

				self.hand3 = nil

				xyd.db.misc:setValue({
					value = 1,
					key = "time_cloister_speed_up_hand"
				})
				self.speedUpRedPoint:SetActive(true)
			end

			xyd.WindowManager.get():openWindow("time_cloister_speed_up_window", {
				info = self.hangInfo
			})
		end
	end)
	UIEventListener.Get(self.btnTech).onClick = handler(self, function ()
		if self.hand2 then
			self.hand2:destroy()

			self.hand2 = nil

			xyd.db.misc:setValue({
				value = 1,
				key = "time_cloister_tech_hand"
			})
		end

		xyd.WindowManager.get():openWindow("time_cloister_tech_window", {
			cloister = self.cloister
		})
	end)
	UIEventListener.Get(self.countDownGroup).onClick = handler(self, function ()
		if self.isPlayCardAnimation then
			return
		end

		local function endFunction()
			if timeCloister:canGetAward() then
				if self.hand1 then
					self.hand1:destroy()

					self.hand1 = nil

					xyd.db.misc:setValue({
						value = 1,
						key = "time_cloister_award_hand"
					})
				end

				xyd.WindowManager.get():openWindow("time_cloister_award_window", {
					info = self.hangInfo,
					cloister = self.cloister,
					closeCallBack = function ()
						self:close()
					end
				})
			end
		end

		if timeCloister:canGetAward() and (self.extraEventBtn1.gameObject.activeSelf or self.extraEventBtn2.gameObject.activeSelf) then
			xyd.alert(xyd.AlertType.YES_NO, __("TIME_CLOISTER_TEXT71"), function (yes)
				if yes then
					endFunction()
				end
			end)
		else
			endFunction()
		end
	end)

	UIEventListener.Get(self.btnSupply).onClick = function ()
		if self.isPlayCardAnimation then
			return
		end

		timeCloister:reqCardInfo()
		xyd.WindowManager.get():openWindow("time_cloister_card_preview_window", {
			type = xyd.TimeCloisterCardType.SUPPLY,
			cloister = self.cloister
		})
	end

	UIEventListener.Get(self.btnChallenge).onClick = function ()
		if self.isPlayCardAnimation then
			return
		end

		timeCloister:reqCardInfo()
		xyd.WindowManager.get():openWindow("time_cloister_card_preview_window", {
			type = xyd.TimeCloisterCardType.BATTLE,
			cloister = self.cloister
		})
	end

	UIEventListener.Get(self.btnEvent).onClick = function ()
		if self.isPlayCardAnimation then
			return
		end

		timeCloister:reqCardInfo()
		xyd.WindowManager.get():openWindow("time_cloister_card_preview_window", {
			type = xyd.TimeCloisterCardType.EVENT,
			cloister = self.cloister
		})
	end

	UIEventListener.Get(self.btnRecord).onClick = function ()
		if self.isPlayCardAnimation then
			return
		end

		if next(self.hangInfo.events) then
			local isHasCommonCard = false

			for key, value in pairs(self.hangInfo.events) do
				local cardType = xyd.tables.timeCloisterCardTable:getType(key)

				if cardType ~= xyd.TimeCloisterCardType.ENCOUNTER_BATTLE and cardType ~= xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
					isHasCommonCard = true

					break
				end
			end

			if isHasCommonCard then
				xyd.WindowManager.get():openWindow("time_cloister_card_record_window")
			else
				xyd.showToast(__("TIME_CLOISTER_TEXT49"))
			end
		else
			xyd.showToast(__("TIME_CLOISTER_TEXT49"))
		end
	end

	UIEventListener.Get(self.extraEventBtn1.gameObject).onClick = function ()
		self:openExtraEventWindow(xyd.TimeCloisterExtraEvent.ENCOUNTER_BATTLE)
	end

	UIEventListener.Get(self.extraEventBtn2.gameObject).onClick = function ()
		self:openExtraEventWindow(xyd.TimeCloisterExtraEvent.DRESS_SHOW)
	end
end

function TimeCloisterProbeWindow:openExtraEventWindow(type)
	if type == xyd.TimeCloisterExtraEvent.ENCOUNTER_BATTLE and self.extraEventBtn1.gameObject.activeSelf then
		local searchWd = xyd.WindowManager.get():getWindow("time_cloister_encounter_window")

		if searchWd then
			return
		end

		local hangInfo = timeCloister:getHangInfo()

		if hangInfo.events then
			for key, value in pairs(hangInfo.events) do
				local type = xyd.tables.timeCloisterCardTable:getType(tonumber(key))

				if type == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE then
					xyd.WindowManager.get():openWindow("time_cloister_encounter_window", {
						cardId = tonumber(key),
						cloister = self.cloister
					})

					break
				end
			end
		end
	elseif type == xyd.TimeCloisterExtraEvent.DRESS_SHOW and self.extraEventBtn2.gameObject.activeSelf then
		local searchWd = xyd.WindowManager.get():getWindow("time_cloister_show_dress_window")

		if searchWd then
			return
		end

		xyd.WindowManager.get():openWindow("time_cloister_show_dress_window")
	end
end

function TimeCloisterProbeWindow:autoOpenExtraEventWindow()
	if self.extraEventBtn1.gameObject.activeSelf then
		self:openExtraEventWindow(xyd.TimeCloisterExtraEvent.ENCOUNTER_BATTLE)
	elseif self.extraEventBtn2.gameObject.activeSelf then
		self:openExtraEventWindow(xyd.TimeCloisterExtraEvent.DRESS_SHOW)
	end
end

function TimeCloisterProbeWindow:checkGuide(type)
	if self.cloister == xyd.TimeCloisterMissionType.ONE then
		if not xyd.db.misc:getValue("time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_3) then
			local skills = timeCloister:getTechInfoByCloister(self.cloister)
			local skills_total = 0

			for i in pairs(skills) do
				skills_total = skills_total + tonumber(skills[i].curNum)
			end

			if skills_total == 0 and xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_CLOISTR_TEC) > 0 then
				xyd.WindowManager:get():openWindow("exskill_guide_window", {
					wnd = self,
					table = xyd.tables.timeCloisterGuideTable,
					guide_type = xyd.GuideType.TIME_CLOISTER_3
				})
				xyd.db.misc:setValue({
					value = "1",
					key = "time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_3
				})

				return true
			end
		end

		if (not type or type == xyd.GuideType.TIME_CLOISTER_2) and not xyd.db.misc:getValue("time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_2) then
			local cloisterInfo = timeCloister:getCloisterInfo()
			local info = cloisterInfo[self.cloister]

			if info and info.progress < 0.1 and self.hangInfo and self.hangInfo.stop_time and self.hangInfo.stop_time > 0 then
				xyd.WindowManager:get():openWindow("exskill_guide_window", {
					wnd = self,
					table = xyd.tables.timeCloisterGuideTable,
					guide_type = xyd.GuideType.TIME_CLOISTER_2
				})
				xyd.db.misc:setValue({
					value = "1",
					key = "time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_2
				})

				return true
			end
		end
	end

	if (not type or type == xyd.GuideType.TIME_CLOISTER_1) and not xyd.db.misc:getValue("time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_1) then
		if self.hangInfo and self.hangInfo.stop_time and self.hangInfo.stop_time > 0 then
			-- Nothing
		elseif xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_CLOISTR_SPEED_UP) > 0 then
			xyd.WindowManager:get():openWindow("exskill_guide_window", {
				wnd = self,
				table = xyd.tables.timeCloisterGuideTable,
				guide_type = xyd.GuideType.TIME_CLOISTER_1
			})
			xyd.db.misc:setValue({
				value = "1",
				key = "time_cloister_guide_" .. xyd.GuideType.TIME_CLOISTER_1
			})

			return true
		end
	end

	return false
end

function TimeCloisterProbeWindow:getCloister()
	return self.cloister
end

function TimeCloisterProbeWindow:updateShowEventIcon()
	local hangInfo = timeCloister:getHangInfo()
	local encounterNum = 0
	local dressMissionNum = 0
	local firstFightCardImgName, firstDressMissionImgName = nil

	if hangInfo.events then
		for key, value in pairs(hangInfo.events) do
			local type = xyd.tables.timeCloisterCardTable:getType(tonumber(key))

			if type == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE then
				encounterNum = encounterNum + tonumber(value)

				if not firstFightCardImgName then
					firstFightCardImgName = xyd.tables.timeCloisterCardTable:getImg(key)
				end
			elseif type == xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
				dressMissionNum = dressMissionNum + tonumber(value)
				firstDressMissionImgName = firstDressMissionImgName or xyd.tables.timeCloisterCardTable:getImg(key)
			end
		end

		if encounterNum > 0 then
			self.extraEventBtn1.gameObject:SetActive(true)

			if firstFightCardImgName then
				xyd.setUISpriteAsync(self.extraEventBtn1UISprite, nil, firstFightCardImgName)
			end

			self.extraEventBtn1Num.text = tostring(encounterNum)
		else
			self.extraEventBtn1.gameObject:SetActive(false)
		end

		if dressMissionNum > 0 then
			self.extraEventBtn2.gameObject:SetActive(true)

			if firstDressMissionImgName then
				xyd.setUISpriteAsync(self.extraEventBtn2UISprite, nil, firstDressMissionImgName)
			end

			self.extraEventBtn2Num.text = tostring(dressMissionNum)
		else
			self.extraEventBtn2.gameObject:SetActive(false)
		end
	else
		self.extraEventBtn1.gameObject:SetActive(false)
		self.extraEventBtn2.gameObject:SetActive(false)
	end

	self.extraEventConUILayout:Reposition()
end

function TimeCloisterProbeWindow:showItemsTween(items, type)
	local selTween = self:getSequence()

	if not self.showItemsArr then
		self.showItemsArr = {}
	end

	local tweenPosArr = {}

	for i in pairs(items) do
		if not self.showItemsArr[i] then
			local params = {
				show_has_num = true,
				noClick = true,
				itemID = items[i].item_id,
				num = items[i].item_num,
				uiRoot = self.showTweenCon.gameObject
			}
			local item = xyd.getItemIcon(params)

			table.insert(self.showItemsArr, item)
		else
			self.showItemsArr[i]:getGameObject():SetActive(true)

			local params = {
				show_has_num = true,
				noClick = true,
				itemID = items[i].item_id,
				num = items[i].item_num
			}

			self.showItemsArr[i]:setInfo(params)
		end

		local x = math.random() * 200 - 100
		local y = math.random() * 200 - 100

		if #items == 1 then
			x = 0
			y = 0
		end

		self.showItemsArr[i]:getGameObject():SetLocalPosition(x, y, 0)
		table.insert(tweenPosArr, Vector2(x, y))

		local scale = 0.7

		self.showItemsArr[i]:getGameObject():SetLocalScale(scale, scale, scale)
		self.showItemsArr[i]:setItemIconDepth((i - 1) * 40)
	end

	for i = #items + 1, #self.showItemsArr do
		self.showItemsArr[i]:getGameObject():SetActive(false)
	end

	local p0 = Vector2(0, 0)
	local p1 = self.showTweenCon.gameObject.transform:InverseTransformPoint(self.awradPreviewBtn.transform.position)

	local function itemTweenSetter(t)
		for i = 1, #items do
			local x = tweenPosArr[i].x + (p1.x - tweenPosArr[i].x) * t
			local y = tweenPosArr[i].y + (p1.y - tweenPosArr[i].y) * t

			self.showItemsArr[i]:getGameObject():SetLocalPosition(x, y, 0)

			local scale = 0.7 * (1 - (t - 0.1))

			if t < 0.1 then
				scale = 0.7
			end

			if scale < 0.1 then
				scale = 0.3
			end

			self.showItemsArr[i]:getGameObject():SetLocalScale(scale, scale, scale)
		end
	end

	selTween:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(itemTweenSetter), 0, 1, 1.2):SetEase(DG.Tweening.Ease.Linear))
	selTween:AppendCallback(function ()
		selTween:Kill(true)

		selTween = nil

		for i = 1, #items do
			self.showItemsArr[i]:getGameObject():SetActive(false)
		end

		self.showTweenMask.gameObject:SetActive(false)
		self:openExtraEventWindow(type)
	end)
end

return TimeCloisterProbeWindow
