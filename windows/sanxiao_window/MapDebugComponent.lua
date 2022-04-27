local MapDebugComponent = class("MapDebugComponent")

function MapDebugComponent:ctor(parent)
	self.window = ResCache.AddGameObject(parent, "Prefabs/Components/map_debug_component")

	self:getUIComponent()
	self:initWindow()

	self.btnState = 0
	self.playerInfoModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYER_INFO)
	self.backpackModel = xyd.ModelManager.get():loadModel(xyd.ModelType.BACKPACK)
end

function MapDebugComponent:getUIComponent()
	local winTrans = self.window.transform
	self.gm_btn = winTrans:NodeByName("e:Skin/gm_btn").gameObject
	self.group_gm = winTrans:NodeByName("e:Skin/group_gm").gameObject
	self.btn_confirm = winTrans:NodeByName("e:Skin/group_gm/btn_confirm").gameObject
	self.text_input = winTrans:ComponentByName("e:Skin/group_gm/text_input", typeof(UIInput))
	self.text_return = winTrans:ComponentByName("e:Skin/group_gm/text_return", typeof(UIInput))
	winTrans.localPosition = Vector3(0, -xyd.getFixedHeight() / 2)
end

function MapDebugComponent:initWindow()
	xyd.setDarkenBtnBehavior(self.btn_confirm, self, self.confirmBtnClick)
	xyd.setNormalBtnBehavior(self.gm_btn, self, self.gmBtnClick)
end

function MapDebugComponent:gmBtnClick()
	if self.btnState == 0 then
		self:showSetting()

		self.btnState = 1
	else
		self:hideSetting()

		self.btnState = 0
	end
end

function MapDebugComponent:showSetting()
	self.btn_confirm:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

	self.group_gm:SetActive(true)
end

function MapDebugComponent:hideSetting()
	self.btn_confirm:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

	self.group_gm:SetActive(false)
end

function MapDebugComponent:confirmBtnClick()
	if self.text_input.value ~= "" then
		print("Input: " .. self.text_input.value)
		self:runDebugCommand(self.text_input.value)

		local input = string.split(self.text_input.value, " ")

		if #input == 2 and tonumber(input[1]) ~= nil then
			local pos = Vector2(tonumber(input[1]), tonumber(input[2]))
			local pos1 = nil

			if pos.x > 100 then
				pos1 = xyd.CameraManager.get():worldToGridPointFloat(pos)
			else
				pos1 = xyd.CameraManager.get():gridToWorldPoint(pos)
			end

			self.text_input.value = pos1.x .. " " .. pos1.y
		end
	end
end

function MapDebugComponent:runDebugCommand(text)
	local params = string.split(text, " ")
	local type = table.remove(params, 1)

	if type == "itili" then
		local id = tonumber(params[1])

		self.backpackModel:addInfStaminaByID(id)
	elseif type == "citili" then
		self.backpackModel:clearInfStamina()
	elseif type == "tili" then
		local count = tonumber(params[1])

		self.playerInfoModel:addStamina(count)
	elseif type == "gem" then
		local count = tonumber(params[1])

		self.playerInfoModel:addGem(count)
	elseif type == "tlog" then
		for i = 1, 10 do
			xyd.db.logEconomy:add(xyd.mid.LOG_CONSUME_GEM, "gem", 0, 0)
		end
	elseif type == "plog" then
		xyd.LogPoster.get():tryPost(xyd.db.logEconomy)
	elseif type == "star" then
		local count = tonumber(params[1])

		self.playerInfoModel:addStar(count)
	elseif type == "item" then
		local id = tonumber(params[1])
		local count = 1
		local expire_time_list = nil

		if params[2] and tonumber(params[2]) > 0 then
			count = tonumber(params[2])
		end

		if params[3] then
			expire_time_list = {}

			for i = 3, #params do
				if tonumber(params[i]) > 0 then
					table.insert(expire_time_list, os.time() + tonumber(params[i]))
				end
			end
		end

		xyd.DataPlatform.get():request("GAME_BUY_ITEM", {
			itemID = id,
			count = count,
			expire_time_list = expire_time_list
		})
	elseif type == "load" then
		local function callback(response, success)
			if success then
				dump(response)
			end
		end

		xyd.DataPlatform.get():loadActivity(callback)
	elseif type == "cs" then
		local function callback(response, success)
			if success then
				local data = response.payload

				dump(data)
				xyd.WindowManager:get():openWindow("saved_game_choose_window", data)
			end
		end

		xyd.DataPlatform.get():loadPlayerInfo(callback)
	elseif type == "g" then
		dump(xyd.Global)
	else
		if type == "promise" then
			local Promise = require("lua-promise")

			Promise.new(function (resolve, reject)
				resolve("aaaa")
			end):next(function (ret)
				print("1", ret)

				return Promise.resolve("bbbb"):next(function (ret0)
					print("1.1", ret0)

					return ret0 .. "cccc"
				end)
			end):next(function (ret)
				print("2", ret)

				return Promise.reject({
					code = -1
				})
			end):catch(function (err)
				print("err", err, err.code)

				return "000"
			end):next(function (ret)
				print("3", ret)

				return 0 / nil
			end):next(function (ret)
				print("4", ret)
			end):catch(function (err)
				print("err2", err)
			end)
			Promise.all({
				Promise.resolve(1),
				Promise.resolve(2)
			}):next(function (rets)
				for i = 1, #rets do
					print("rets", rets[i])
				end
			end)
			Promise.race({
				Promise.resolve("a"),
				Promise.reject("b"),
				Promise.resolve("c")
			}):next(function (ret)
				print(ret)
			end):catch(function (err)
				print("err", err)
			end)

			return
		end

		if type == "ac" then
			local ActivityTable = xyd.tables.activity

			dump(ActivityTable:getTableById(xyd.ActivityConstants.CLEAR_STREAK_REWARD))
		elseif type == "showad" then
			xyd.SdkManager.get():showGoogleRewardVideoAd()
		elseif type == "clear" then
			xyd.db.logLevel:add(xyd.mid.LOG_GAME_WIN, 1, 3, 1000)
			xyd.LogPoster.get():tryPost(xyd.db.logLevel)
		elseif type == "restart" then
			xyd.MainController.get():restartGame()
		end
	end
end

function MapDebugComponent:dispose()
	if not tolua.isnull(self.window) then
		UnityEngine.Object.Destroy(self.window)

		self.window = nil
	end
end

return MapDebugComponent
