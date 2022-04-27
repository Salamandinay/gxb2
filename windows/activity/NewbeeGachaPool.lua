local NewbeeGachaPool = class("NewbeeGachaPool", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")

function NewbeeGachaPool:ctor(parentGO, params, parent)
	NewbeeGachaPool.super.ctor(self, parentGO, params, parent)
end

function NewbeeGachaPool:getPrefabPath()
	return "Prefabs/Windows/activity/newbee_gacha_pool"
end

function NewbeeGachaPool:initUI()
	self:getUIComponent()
	NewbeeGachaPool.super.initUI(self)
	self:initUIComponent()
	self:updateSkipBtn()
	self:updateItemNum()
	self:register()
	self:updateRedMarkState()
	self:updateRedMarkState2()
end

function NewbeeGachaPool:getUIComponent()
	local goTrans = nil
	local timeStamp = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox_new_time", "value")

	if timeStamp < xyd.getServerTime() then
		self.isNewVersion = true
	end

	if self.isNewVersion then
		goTrans = self.go.transform:NodeByName("group2").gameObject
	else
		goTrans = self.go.transform:NodeByName("group1").gameObject
	end

	goTrans:SetActive(true)

	self.textImg_ = goTrans:ComponentByName("textImg_", typeof(UITexture))
	self.timeLabel_ = goTrans:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn_").gameObject
	self.checkBtn_ = goTrans:NodeByName("checkBtn_").gameObject
	self.skipBtn_ = goTrans:ComponentByName("skipBtn_", typeof(UISprite))
	self.preViewBtnTrans = goTrans:NodeByName("previewGroup")
	self.bottomGroup = goTrans:NodeByName("bottomGroup")
	self.bg1_ = self.bottomGroup:ComponentByName("bg1_", typeof(UISprite))
	self.hitLabel_ = self.bottomGroup:ComponentByName("hitLabel_", typeof(UILabel))
	self.tipLabel_ = self.bottomGroup:ComponentByName("tipGroup/tipLabel_", typeof(UILabel))
	self.resLabel_ = self.bottomGroup:ComponentByName("resGroup/resLabel_", typeof(UILabel))
	self.plusBtn_ = self.bottomGroup:NodeByName("resGroup/plusBtn_").gameObject
	self.summonBtnOne_ = self.bottomGroup:NodeByName("summonBtnOne").gameObject
	self.summonBtnOneLabel_ = self.bottomGroup:ComponentByName("summonBtnOne/label_", typeof(UILabel))
	self.summonBtnTen_ = self.bottomGroup:NodeByName("summonBtnTen").gameObject
	self.summonBtnTenLabel_ = self.bottomGroup:ComponentByName("summonBtnTen/label_", typeof(UILabel))
	self.awardBtn_ = self.bottomGroup:NodeByName("awardBtn").gameObject
	self.awardLabel_ = self.awardBtn_:ComponentByName("label", typeof(UILabel))
	self.awardEffectGroup_ = self.awardBtn_:ComponentByName("effectGroup", typeof(UITexture))
	self.awardRedMark = self.awardBtn_:NodeByName("redPoint").gameObject
end

function NewbeeGachaPool:initUIComponent()
	xyd.setUITextureByNameAsync(self.textImg_, "newbee_gacha_pool_text01_" .. xyd.Global.lang, true)

	self.summonBtnOneLabel_.text = __("SUMMON_X_TIME2", 1)
	self.summonBtnTenLabel_.text = __("SUMMON_X_TIME2", 10)
	self.tipLabel_.text = __("ACTIVITY_NEWBEE_GACHA_TEXT03")
	self.awardLabel_.text = __("ACTIVITY_NEWBEE_GACHA_TEXT05")

	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd:getServerTime()
	})

	local partners = nil

	if self.isNewVersion then
		partners = xyd.tables.miscTable:split2num("activity_newbee_gacha_jump_new", "value", "|")
	else
		partners = xyd.tables.miscTable:split2num("activity_newbee_gacha_jump", "value", "|")
	end

	for i = 1, #partners do
		local id = partners[i]
		local label = self.preViewBtnTrans:ComponentByName("group" .. i .. "/label_", typeof(UILabel))
		local preViewBtn = self.preViewBtnTrans:NodeByName("group" .. i .. "/preViewBtn").gameObject
		label.text = xyd.tables.partnerTable:getName(id)

		UIEventListener.Get(preViewBtn).onClick = function ()
			xyd.WindowManager.get():openWindow("guide_detail_window", {
				partners = {
					{
						table_id = id
					}
				},
				table_id = id
			})
		end
	end

	local effect = xyd.Spine.new(self.awardEffectGroup_.gameObject)

	effect:setInfo("fx_ui_txsaoguang", function ()
		effect:SetLocalScale(0.5, 0.5, 0.5)
		effect:SetLocalPosition(0, -10, 0)
		effect:play("texiao01", 0, 1)
	end)

	self.skipAnimation = false
	local val = xyd.db.misc:getValue("set_newbee_summon_skip")

	if tonumber(val) == 1 then
		self.skipAnimation = true
	end

	self.secureTime = xyd.tables.miscTable:split2num("activity_newbee_gacha_security_time", "value", "|")
end

function NewbeeGachaPool:register()
	self:registerEvent(xyd.event.NEWBEE_SUMMON, handler(self, self.onSummonEvent))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateRedMarkState2))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_NEWBEE_GACHA_HELP"
		})
	end

	UIEventListener.Get(self.checkBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("newbee_gacha_pool_drob_prob_window", {
			isNewVersion = self.isNewVersion
		})
	end

	UIEventListener.Get(self.skipBtn_.gameObject).onClick = function ()
		self:updateSkipBtn(true)
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("newbee_gacha_pool_award_window", {
			isNewVersion = self.isNewVersion
		})
	end

	UIEventListener.Get(self.plusBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.WindowManager.get():openWindow("activity_window", {
				select = xyd.ActivityID.NEWBEE_GIFTBAG
			})
		end)
	end

	UIEventListener.Get(self.summonBtnOne_).onClick = function ()
		self:onClickSummon(1)
	end

	UIEventListener.Get(self.summonBtnTen_).onClick = function ()
		self:onClickSummon(10)
	end
end

function NewbeeGachaPool:onClickSummon(num)
	local canSummonNum = xyd.models.slot:getCanSummonNum()
	self.collectionBefore_ = xyd.models.slot:getCollectionCopy()

	if canSummonNum < num then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWBEE_SUMMON_SCROLL)

	if num <= hasNum then
		local msg = messages_pb.newbee_summon_req()
		msg.activity_id = self.id
		msg.num = num

		xyd.Backend.get():request(xyd.mid.NEWBEE_SUMMON, msg)
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.NEWBEE_SUMMON_SCROLL)))

		return false
	end
end

function NewbeeGachaPool:onSummonEvent(event)
	local function effectCallBack()
		local partners = event.data.partners or {}
		local items = {}

		for _, partner in ipairs(partners) do
			local item_id = partner.table_id

			table.insert(items, {
				item_num = 1,
				item_id = item_id
			})
		end

		local params = {
			progressValue = 0,
			type = 7,
			oldBaodiEnergy = 0,
			items = items,
			btnSummonRightCallBack = function (num)
				self:onClickSummon(num)
			end
		}

		xyd.WindowManager.get():closeWindow("summon_res_window")

		if xyd.WindowManager.get():isOpen("summon_result_window") then
			local win = xyd.WindowManager.get():getWindow("summon_result_window")

			win:updateWindow(params)
		else
			xyd.WindowManager.get():openWindow("summon_result_window", params)
		end

		self:updateActivityData(#event.data.partners)
		self:updateRedMarkState2()
		self:updateItemNum()
	end

	local new5stars = xyd.isHasNew5Stars(event, self.collectionBefore_)

	if self.skipAnimation then
		if xyd.WindowManager.get():isOpen("summon_result_window") then
			local win = xyd.WindowManager.get():getWindow("summon_result_window")

			win:playDisappear(function ()
				if #new5stars > 0 then
					xyd.WindowManager.get():openWindow("summon_res_window", {}, function (reswin)
						if reswin then
							reswin:playEffect(new5stars, event.data.summon_id, effectCallBack, true)
						else
							effectCallBack()
						end
					end)
				else
					effectCallBack()
				end
			end, 7)
		elseif #new5stars > 0 then
			xyd.WindowManager.get():openWindow("summon_res_window", {}, function (reswin)
				if reswin then
					reswin:playEffect(new5stars, event.data.summon_id, effectCallBack, true)
				else
					effectCallBack()
				end
			end)
		else
			effectCallBack()
		end
	else
		xyd.WindowManager.get():openWindow("summon_res_window", {}, function (win)
			if win then
				win:playEffect(event.data.partners, 6, effectCallBack)
			else
				effectCallBack()
			end
		end)
	end
end

function NewbeeGachaPool:updateActivityData(num)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBEE_GACHA_POOL, function ()
		self.activityData.detail.draw_times = self.activityData.detail.draw_times + num
		self.activityData.detail.secure_times = math.min(math.floor(self.activityData.detail.draw_times / self.secureTime[1]), self.secureTime[2])
	end)
end

function NewbeeGachaPool:updateItemNum()
	if self.secureTime[2] <= self.activityData.detail.secure_times then
		self.hitLabel_:SetActive(false)
	else
		self.hitLabel_:SetActive(true)

		local leftScore = (self.activityData.detail.secure_times + 1) * self.secureTime[1] - self.activityData.detail.draw_times
		self.hitLabel_.text = __("ACTIVITY_NEWBEE_GACHA_TEXT01", leftScore, self.secureTime[2] - self.activityData.detail.secure_times, self.secureTime[2])
	end

	self.resLabel_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.NEWBEE_SUMMON_SCROLL)
end

function NewbeeGachaPool:updateRedMarkState()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBEE_GACHA_POOL, function ()
		xyd.db.misc:setValue({
			key = "newbee_gacha_pool_time",
			value = xyd.getServerTime()
		})
	end)
end

function NewbeeGachaPool:updateRedMarkState2()
	self.awardRedMark:SetActive(self.activityData:getRedMarkState2())
	xyd.models.redMark:setMark(xyd.RedMarkType.NEWBEE_GACHA_POOL, self.activityData:getRedMarkState())

	local win = xyd.getWindow("main_window")

	if win then
		win:CheckExtraActBtn(xyd.MAIN_LEFT_TOP_BTN_TYPE.NEWBEE_GACHA_POOL)
	end
end

function NewbeeGachaPool:updateSkipBtn(flag)
	if flag then
		self.skipAnimation = not self.skipAnimation
	end

	if self.skipAnimation then
		xyd.setUISprite(self.skipBtn_, nil, "battle_img_skip")
	else
		xyd.setUISprite(self.skipBtn_, nil, "btn_max")
	end

	local val = 0

	if self.skipAnimation then
		val = 1
	end

	xyd.db.misc:setValue({
		key = "set_newbee_summon_skip",
		value = val
	})
end

function NewbeeGachaPool:resizeToParent()
	NewbeeGachaPool.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	self.bg1_.alpha = math.min(1, (255 - (1043 - p_height)) / 255)
	local timeGroup = nil

	if self.isNewVersion then
		timeGroup = self.go.transform:NodeByName("group2/timeGroup").gameObject

		self.bottomGroup:Y(-780 - (p_height - 873))
		self.preViewBtnTrans:NodeByName("group4").gameObject:Y(-656 - (p_height - 1043) / -170 * -104)
		self.preViewBtnTrans:NodeByName("group5").gameObject:Y(-692 - (p_height - 1043) / -170 * -92)
		self.preViewBtnTrans:NodeByName("group6").gameObject:Y(-711 - (p_height - 1043) / -170 * -92)
		self.bottomGroup:NodeByName("tipGroup").gameObject:Y(119 - (p_height - 1043) / -170 * 27)
		self.bottomGroup:NodeByName("resGroup").gameObject:Y(203 - (p_height - 1043) / -170 * 47)
		self.bottomGroup:NodeByName("awardBtn").gameObject:Y(5.5 - (p_height - 1043) / -170 * 18)
		self.bottomGroup:NodeByName("summonBtnOne").gameObject:Y(0 - (p_height - 1043) / -170 * 14.5)
		self.bottomGroup:NodeByName("summonBtnTen").gameObject:Y(0 - (p_height - 1043) / -170 * 14.5)
		self.bottomGroup:NodeByName("hitLabel_").gameObject:Y(-75 - (p_height - 1043) / -170 * 6)
	else
		timeGroup = self.go.transform:NodeByName("group1/timeGroup").gameObject

		self.bottomGroup:Y(-780 - (p_height - 873))
	end

	if xyd.Global.lang == "en_en" then
		timeGroup:Y(-125)
	elseif xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		timeGroup:Y(-125)
		self.awardBtn_:Y(-10)
		self.summonBtnOneLabel_:Y(13)
		self.summonBtnTenLabel_:Y(13)

		self.hitLabel_.fontSize = 18
		self.summonBtnOneLabel_.fontSize = 18
		self.summonBtnTenLabel_.fontSize = 18
		self.tipLabel_.fontSize = 22
	elseif xyd.Global.lang == "ja_jp" then
		timeGroup:Y(-115)

		self.awardLabel_.width = 80
	elseif xyd.Global.lang == "ko_kr" then
		timeGroup:Y(-120)
	end
end

return NewbeeGachaPool
