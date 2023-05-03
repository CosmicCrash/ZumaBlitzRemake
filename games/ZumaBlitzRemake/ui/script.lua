-- This is a default UI script file for OpenSMCE games.
-- Keep in mind that more methods may be added, or existing changed in the future.
-- These script files will be automatically updated if needed by the engine.

-- All callbacks will be stored here.
local c = {}





-- The first parameter of each callback is a variable "f".
-- It is used just as a simple way to provide the function library to be used here.

-- SPLASH STUFF
function c.init(f)
  f.getWidgetN("splash"):show()
end



function c.disclaimerClickShown(f)
  f.getWidgetN("splash/Disclaimer/Frame/Container/ClickAnywhere"):hide()
end



function c.disclaimerClickHidden(f)
  f.getWidgetN("splash/Disclaimer/Frame/Container/ClickAnywhere"):show()
end



function c.click(f)
  if f.getWidgetN("splash/Disclaimer") and f.getWidgetN("splash/Disclaimer"):isVisible() then
    f.getWidgetN("splash/Disclaimer"):hide()
  end
end



function c.disclaimerEnd(f)
  f.getWidgetN("splash/Disclaimer"):clean()
  f.getWidgetN("splash/Main"):show()
  f.getWidgetN("splash/Main"):setActive()
end



function c.splashStart(f)
  f.loadMain()
end



function c.splashClick(f)
  f.getWidgetN("splash/Main"):hide()
end



function c.splashEnd(f)
  f.initSession()
  f.getWidgetN("root/Main"):show()
  f.musicVolume("menu", 1)

  -- initSession() initializes all the UI, so from this point we can initialize all the modules.
  c.root = f.getWidgetN("root")
  c.Main = f.getWidgetN("root/Main")
  c.Main_Background = f.getWidgetN("root/Main/Background")

  c.Profile_Manage = f.getWidgetN("root/Main/Profile_Manage")
  c.Profile_Manage_Frame = f.getWidgetN("root/Main/Profile_Manage/Frame")
  c.Profile_Manage_Button_Up = f.getWidgetN("root/Main/Profile_Manage/Frame/Listbox/Button_Up")
  c.Profile_Manage_Button_Down = f.getWidgetN("root/Main/Profile_Manage/Frame/Listbox/Button_Down")
  c.Profile_Manage_Button_Delete = f.getWidgetN("root/Main/Profile_Manage/Frame/Button_Delete")
  c.Profile_Manage_Button_Select = f.getWidgetN("root/Main/Profile_Manage/Frame/Button_Select")
  
  c.FoodTemp_Manage = f.getWidgetN("root/Main/FoodTemp_Manage")
  c.FoodTemp_Manage_Frame = f.getWidgetN("root/Main/FoodTemp_Manage/Frame")
  c.FoodTemp_Manage_Button_Up = f.getWidgetN("root/Main/FoodTemp_Manage/Frame/Listbox/Button_Up")
  c.FoodTemp_Manage_Button_Down = f.getWidgetN("root/Main/FoodTemp_Manage/Frame/Listbox/Button_Down")
  c.FoodTemp_Manage_Button_Delete = f.getWidgetN("root/Main/FoodTemp_Manage/Frame/Button_Delete")
  c.FoodTemp_Manage_Button_Select = f.getWidgetN("root/Main/FoodTemp_Manage/Frame/Button_Select")

  c.Profile_Create = f.getWidgetN("root/Main/Profile_Create")
  c.Profile_Create_Button_Cancel = f.getWidgetN("root/Main/Profile_Create/Frame/Button_Cancel")
  c.Profile_Create_Button_Ok = f.getWidgetN("root/Main/Profile_Create/Frame/Button_Ok")
  c.Profile_Duplicate = f.getWidgetN("root/Main/Profile_Duplicate")
  c.Profile_Delete = f.getWidgetN("root/Main/Profile_Delete")

  c.Menu_Game = f.getWidgetN("root/Menu_Game")
  c.Menu_Game_Frame = f.getWidgetN("root/Menu_Game/Frame")
  c.Menu_Highscores = f.getWidgetN("root/Menu_Highscores")
  c.Menu_Highscores_Frame = f.getWidgetN("root/Menu_Highscores/Frame")
  c.Menu_Highscores_Highlight = f.getWidgetN("root/Menu_Highscores/Frame/Psys_Highlight")
  c.Menu_ClearScores = f.getWidgetN("root/Menu_ClearScores")
  c.Menu_ClearScores_Frame = f.getWidgetN("root/Menu_ClearScores/Frame")
  c.Menu_Options = f.getWidgetN("root/Menu_Options")
  c.Menu_Options_Frame = f.getWidgetN("root/Menu_Options/Frame")
  c.Menu_QuitGame = f.getWidgetN("root/Menu_QuitGame")
  c.Menu_QuitGame_Frame = f.getWidgetN("root/Menu_QuitGame/Frame")
  c.Menu_Credits = f.getWidgetN("root/Menu_Credits")
  c.Menu_Instructions = f.getWidgetN("root/Menu_Instructions")
  c.Menu_Instructions_Background = f.getWidgetN("root/Menu_Instructions/Background")
  c.Menu_Instructions_Frame = f.getWidgetN("root/Menu_Instructions/Frame")
  c.Menu_Instructions_Toggle_DontShow = f.getWidgetN("root/Menu_Instructions/Frame/Toggle_DontShow")
  c.Menu_Instructions_Mask = f.getWidgetN("root/Menu_Instructions_Mask")
  c.Menu_Instructions_Mask_Background = f.getWidgetN("root/Menu_Instructions_Mask/Background")
  c.Menu_Continue = f.getWidgetN("root/Menu_Continue")
  c.Menu_Continue_Background = f.getWidgetN("root/Menu_Continue/Background")
  c.Menu_StageSelect = f.getWidgetN("root/Menu_StageSelect")
  c.Menu_StageSelect_Frame = f.getWidgetN("root/Menu_StageSelect/Frame")

  c.Hud = f.getWidgetN("root/Game/Hud")
  c.Hud_NewLife = f.getWidgetN("root/Game/Hud/Frame/Psys_NewLife")
  c.Button_Menu = f.getWidgetN("root/Game/Hud/Frame/Button_Menu")
  c.Button_Pause = f.getWidgetN("root/Game/Hud/Frame/Button_Pause")
  c.Banner_Paused = f.getWidgetN("root/Game/Hud/Banner_Paused")
  c.Banner_Paused_Panel = f.getWidgetN("root/Game/Hud/Banner_Paused/Panel")
  c.Banner_LevelComplete = f.getWidgetN("root/Game/Hud/Banner_LevelComplete")
  c.Banner_LevelComplete_Frame = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame")
  c.Banner_LevelComplete_Record = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/VW_LevelScoreRecord")
  c.Banner_StageMapTrans = f.getWidgetN("root/Game/Hud/Banner_StageMapTrans")
  c.Banner_StageMapTrans_Background = f.getWidgetN("root/Game/Hud/Banner_StageMapTrans/Background")
  c.Banner_StageMap = f.getWidgetN("root/Game/Hud/Banner_StageMap")
  c.Banner_StageMap_Frame = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame")
  c.Banner_HighScore = f.getWidgetN("root/Game/Hud/Banner_HighScore")
  c.Banner_HighScore_Panel = f.getWidgetN("root/Game/Hud/Banner_HighScore/Panel")
  c.Banner_QuitBackground = f.getWidgetN("root/Game/Hud/Banner_QuitBackground")
  c.Banner_QuitBackground_Background = f.getWidgetN("root/Game/Hud/Banner_QuitBackground/Background")
  c.Banner_LevelLose = f.getWidgetN("root/Game/Hud/Banner_LevelLose")
  c.Banner_LevelLose_Panel = f.getWidgetN("root/Game/Hud/Banner_LevelLose/Panel")
  c.Banner_Intro = f.getWidgetN("root/Game/Hud/Banner_Intro")
  c.Banner_Intro_Panel = f.getWidgetN("root/Game/Hud/Banner_Intro/Panel")
  c.Banner_GameOver = f.getWidgetN("root/Game/Hud/Banner_GameOver")
  c.Banner_GameOver_Panel = f.getWidgetN("root/Game/Hud/Banner_GameOver/Panel")



  c.LevelButtons = {}
  local i = 1
  while f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/LevelButtons/" .. tostring(i)) do
    c.LevelButtons[i] = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/LevelButtons/" .. tostring(i))
    i = i + 1
  end
  c.StageButtons = {}
  local i = 1
  while f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/StageButtons/" .. tostring(i)) do
    c.StageButtons[i] = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/StageButtons/" .. tostring(i))
    i = i + 1
  end
  c.Banner_StageMap_StageCompletePsys = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/StageCompletePsys")
  c.Banner_StageMap_StageUnlockPsys = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/StageUnlockPsys")
  c.Banner_StageMap_LevelPsys = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/LevelPsys")
  c.Banner_StageMap_StageButtons = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/StageButtons")
  c.Banner_StageMap_LevelButtons = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/LevelButtons")
  c.Banner_StageMap_Set = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Stage_Select/Set")

  c.NewGameLevelButtons = {}
  local i = 1
  while f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/LevelButtons/" .. tostring(i)) do
    c.NewGameLevelButtons[i] = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/LevelButtons/" .. tostring(i))
    i = i + 1
  end
  c.NewGameStageButtons = {}
  local i = 1
  while f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/StageButtons/" .. tostring(i)) do
    c.NewGameStageButtons[i] = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/StageButtons/" .. tostring(i))
    i = i + 1
  end
  c.Menu_StageSelect_LevelPsys = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/LevelPsys")
  c.Menu_StageSelect_StageButtons = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/StageButtons")
  c.Menu_StageSelect_LevelButtons = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/LevelButtons")
  c.Menu_StageSelect_Set = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Stage_Select/Set")



  --[[
  c.HighscoreRows = {}
  local i = 1
  while f.getWidgetN("root/Menu_Highscores/Frame/HS_Table/Row" .. tostring(i - 1)) do
    local path = "root/Menu_Highscores/Frame/HS_Table/Row" .. tostring(i - 1) .. "/HS_Row"
    local row = {}
    row.rank = f.getWidgetN(path .. "/Rank")
    row.name = f.getWidgetN(path .. "/Name")
    row.name2 = f.getWidgetN(path .. "/Name2")
    row.level = f.getWidgetN(path .. "/Level")
    row.score = f.getWidgetN(path .. "/Score")
    c.HighscoreRows[i] = row
    i = i + 1
  end
  ]]

  c.LeaderboardRows = {}
  local i = 1
  while f.getWidgetN("root/Main/Menu/Leaderboards/Row" .. tostring(i)) do
    local path = "root/Main/Menu/Leaderboards/Row" .. tostring(i) .. "/LB_Row"
    local row = {}
    --row.rank = f.getWidgetN(path .. "/Rank")
    row.name = f.getWidgetN(path .. "/Name")
    --row.name2 = f.getWidgetN(path .. "/Name2")
    --row.level = f.getWidgetN(path .. "/Level")
    row.score = f.getWidgetN(path .. "/Score")
    c.LeaderboardRows[i] = row
    i = i + 1
  end

  c.ProfileRows = {}
  local i = 1
  while f.getWidgetN("root/Main/Profile_Manage/Frame/Listbox/Button_" .. tostring(i)) do
    local path = "root/Main/Profile_Manage/Frame/Listbox/Button_" .. tostring(i)
    local row = {}
    row.button = f.getWidgetN(path)
    row.name = f.getWidgetN(path .. "/Text_E")
    row.name2 = f.getWidgetN(path .. "/Text_H")
    c.ProfileRows[i] = row
    i = i + 1
  end

  c.FoodTempRows = {}
  local i = 1
  while f.getWidgetN("root/Main/FoodTemp_Manage/Frame/Listbox/Button_" .. tostring(i)) do
    local path = "root/Main/FoodTemp_Manage/Frame/Listbox/Button_" .. tostring(i)
    local row = {}
    row.button = f.getWidgetN(path)
    row.name = f.getWidgetN(path .. "/Text_E")
    row.name2 = f.getWidgetN(path .. "/Text_H")
    c.FoodTempRows[i] = row
    i = i + 1
  end

  c.stageNames = {
    "THE QUEST BEGINS",
    "CHASING THE CARAVAN",
    "TO THE PYRAMIDS",
    "CLUE IN THE RUINS",
    "THE OASIS OF ISIS",
    "JOURNEY TO THE SPHINX",
    "PILLARS OF KARNAK",
    "AFTER THE HIGH PRIEST",
    "CITY OF THE DEAD",
    "UP THE CATARACTS",
    "THE HERMIT'S ADVICE",
    "TEMPLE OF THE GODDESS",
    "THE WRATH OF SET"
  }
  c.newGameStage = 1
  c.newGameStarting = false
  c.scoreDisplay = 0
  c.highscorePlace = 1
  c.profileSelectID = 0
  if f.profileGetExists() then
    for i, name in ipairs(f.profileMGetNameOrder()) do
      if f.profileGetName() == name then
        c.profileSelectID = i
        break
      end
    end
  end
  c.profileOffset = 0
  c.foodtempOffset = 0
  c.foodtempSelectID = 0
  if f.profileGetExists() and f.profileGetEquippedFood() then
    for food, v in pairs(f.getFoodItems()) do
      if f.profileGetEquippedFood() == food then
        c.foodSelectID = i
        break
      end
    end
  end



  c.Main_Text_PlayerE = f.getWidgetN("root/Main/Menu/Text_PlayerE")
  c.Main_Text_PlayerH = f.getWidgetN("root/Main/Menu/Text_PlayerH")
  c.Main_Text_Version = f.getWidgetN("root/Main/Menu/Text_Version")
  c.Main_Text_PlayerItems = f.getWidgetN("root/Main/Menu/Text_PlayerItems")
  c.Main_Text_Level = f.getWidgetN("root/Main/Menu/Text_Level")
  c.Main_Text_Currency = f.getWidgetN("root/Main/Menu/Text_Currency")
  c.Main_Progress_XP = f.getWidgetN("root/Main/Menu/Progress_XP")
  c.Menu_Continue_Text_Stage = f.getWidgetN("root/Menu_Continue/Frame/Text_Stage")
  c.Menu_Continue_Text_Score = f.getWidgetN("root/Menu_Continue/Frame/Text_Score")
  c.Menu_StageSelect_Text_StageName = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Text_StageName")
  c.Menu_StageSelect_Text_StageNumber = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Text_StageNumber")
  c.Menu_StageSelect_Text_MapName = f.getWidgetN("root/Menu_StageSelect/Frame/StageMap/Text_MapName")
  c.Profile_Create_Entry_Name = f.getWidgetN("root/Main/Profile_Create/Frame/Entry_Name")
  c.Profile_Delete_Text_Name = f.getWidgetN("root/Main/Profile_Delete/Frame/Text_Name")
  c.Hud_Text_Stage = f.getWidgetN("root/Game/Hud/Frame/Text_Stage")
  c.Hud_Text_Lives = f.getWidgetN("root/Game/Hud/Frame/Text_Lives")
  c.Hud_Text_Coins = f.getWidgetN("root/Game/Hud/Frame/Text_Coins")
  c.Hud_Text_Score = f.getWidgetN("root/Game/Hud/Frame/Text_Score")
  c.Hud_Blitz_Meter = f.getWidgetN("root/Game/Hud/Frame/Blitz_Meter")
  c.Hud_Progress = f.getWidgetN("root/Game/Hud/Frame/Progress")
  c.Hud_Progress_Marker = f.getWidgetN("root/Game/Hud/Frame/Blitz_Meter")
  c.Banner_LevelComplete_Text_Stage = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Text_Stage")
  c.Banner_LevelComplete_Text_MapName = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Text_MapName")
  c.Banner_LevelComplete_Text_LevelScore = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_LevelScore")
  c.Banner_LevelComplete_Text_ShotsFired = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_ShotsFired")
  c.Banner_LevelComplete_Text_MaxCombo = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_MaxCombo")
  c.Banner_LevelComplete_Text_Coins = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_Coins")
  c.Banner_LevelComplete_Text_MaxChain = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_MaxChain")
  c.Banner_LevelComplete_Text_Gems = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_Gems")
  c.Banner_LevelComplete_Text_Segments = f.getWidgetN("root/Game/Hud/Banner_LevelComplete/Frame/Container/Text_Segments")
  c.Banner_StageMap_Text_StageName = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Text_StageName")
  c.Banner_StageMap_Text_StageNumber = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Text_StageNumber")
  c.Banner_StageMap_Text_MapName = f.getWidgetN("root/Game/Hud/Banner_StageMap/Frame/StageMap/Text_MapName")
  c.Banner_HighScore_Text_Congrats = f.getWidgetN("root/Game/Hud/Banner_HighScore/Panel/Text_Congrats")
  c.Banner_HighScore_Text_Score = f.getWidgetN("root/Game/Hud/Banner_HighScore/Panel/Text_Score")
  c.Banner_Intro_Text_Stage = f.getWidgetN("root/Game/Hud/Banner_Intro/Panel/Text_Stage")
  c.Banner_Intro_Text_Map = f.getWidgetN("root/Game/Hud/Banner_Intro/Panel/Text_Map")



  -- Prompt a user to write their name if no profiles available.
  if not f.profileGetExists() then
    c.Main_Background:scheduleFunction("showEnd",
    function()
      c.Profile_Create:show()
      c.Profile_Create:setActive()
    end
    )
  end

  c.Main_Button_FoodTemp = f.getWidgetN("root/Main/Menu/Button_Food")

  --Comment out these lines if you want (not so helpful) debug functionality
  c.Main_Text_PlayerItems:hide()
  c.Main_Button_FoodTemp:hide()
  c.Main_Text_PlayerItems.alpha = 0
  c.Main_Button_FoodTemp.alpha = 0
end





-- WHEN CLICKED PAUSE ON HUD
function c.hudPause(f)
  if c.Banner_Paused:isVisible() then
    c.Banner_Paused:hide()
    c.Banner_Paused_Panel:scheduleFunction("hideEnd",
    function()
      f.levelUnpause()
    end
    )
  else
    c.Banner_Paused:show()
    f.levelPause()
  end
end



-- WHEN CLICKED MENU ON HUD
function c.hudMenu(f)
  if c.Banner_Paused:isVisible() then
    c.Banner_Paused:hide()
    c.Banner_Paused_Panel:scheduleFunction("hideEnd", c.hudMenu)
  else
    c.Menu_Game:show()
    c.Menu_Game:setActive()
    f.levelPause()
  end
end



-- WHEN CLICKED DONE ON LEVEL COMPLETE SCREEN
function c.levelCompleteOk(f)
  f.resetActive()
  c.Banner_LevelComplete:hide()
  c.Banner_LevelComplete_Frame:scheduleFunction("hideEnd",
  function()
    f.levelWin()
    c.Banner_LevelComplete:clean()
    c.Hud:hide()
    c.Main:show()
    c.Main:setActive()
    f.profileDeleteGame()
    f.musicVolume("menu", 1)
  end
  )
end



-- WHEN CLICKED "DONE" ON NEW HIGHSCORE SCREEN
function c.highscoreOk(f)
  c.Banner_HighScore:hide()
  c.Banner_HighScore_Panel:scheduleFunction("hideEnd",
  function()
    c.Banner_HighScore:clean()
    c.Hud:hide()
    c.Hud:scheduleFunction("hideEnd",
    function()
      f.profileDeleteGame()
      c.Menu_Highscores:show()
      c.Menu_Highscores:setActive()
      c.Menu_Highscores_Highlight.pos.y = c.highscorePlace * 45 + 62
      c.Menu_Highscores_Highlight:show()
      f.musicVolume("menu", 1)
    end
    )
  end
  )
end



-- WHEN CLICKED "CONTINUE PLAYING" ON GAME MENU
function c.gameMenuContinue(f)
  c.Menu_Game:hide()
  c.Menu_Game_Frame:scheduleFunction("hideEnd",
  function()
    c.Hud:setActive()
    f.levelUnpause()
  end
  )
end



-- WHEN CLICKED "OPTIONS" ON GAME MENU
function c.gameMenuOptions(f)
  c.Menu_Options:show()
  c.Menu_Options:setActive()
end



-- WHEN CLICKED "INSTRUCTIONS" ON GAME MENU
function c.gameMenuHelp(f)
  c.Menu_Instructions_Mask:show()
  c.Menu_Instructions_Mask_Background:scheduleFunction("showEnd",
  function()
    c.Menu_Instructions:show()
    c.Menu_Instructions:setActive()
    c.Menu_Instructions_Toggle_DontShow.widget:setState(f.profileGetVariable("dontShowInstructions"))
  end
  )
end



-- WHEN CLICKED "QUIT GAME" ON GAME MENU
function c.gameMenuQuit(f)
  c.Menu_Game:hide()
  c.Menu_Game_Frame:scheduleFunction("hideEnd",
  function()
    c.Menu_QuitGame:show()
    c.Menu_QuitGame:setActive()
  end
  )
end



-- WHEN CLICKED "CONTINUE PLAYING" ON GAME QUIT MENU
function c.quitMenuContinue(f)
  c.Menu_QuitGame:hide()
  c.Menu_QuitGame_Frame:scheduleFunction("hideEnd",
  function()
    c.Menu_Game:show()
    c.Menu_Game:setActive()
  end
  )
end



-- WHEN CLICKED "EXIT GAME" ON GAME QUIT MENU
function c.quitMenuExit(f)
  f.quit()
end



-- WHEN CLICKED "QUIT TO MAIN MENU" ON GAME QUIT MENU
function c.quitMenuQuit(f)
  c.Menu_QuitGame:hide()
  c.Menu_QuitGame_Frame:scheduleFunction("hideEnd",
  function()
    c.Banner_QuitBackground:show()
    c.Banner_QuitBackground_Background:scheduleFunction("showEnd",
    function()
      c.Banner_LevelComplete:hide()
      c.Banner_LevelComplete:clean()
      c.Banner_HighScore:hide()
      c.Banner_HighScore:clean()
      c.Hud:hide()
      c.Hud:scheduleFunction("hideEnd",
      function()
        f.levelSave()
        c.Banner_QuitBackground:hide()
        c.Banner_QuitBackground:clean()
        c.Main:show()
        c.Main:setActive()
        f.musicVolume("menu", 1)
      end
      )
    end
    )
  end
  )
end



-- WHEN CLICKED "DONE" ON OPTIONS MENU
function c.optionsDone(f)
  c.Menu_Options:hide()
  if c.Menu_Game:isVisible() then
    c.Menu_Game:setActive()
  else
    c.Main:setActive()
  end
end



-- WHEN CLICKED "CREDITS" ON OPTIONS MENU
function c.optionsCredits(f)
  c.Menu_Credits:show()
  c.Menu_Credits:setActive()
end



-- WHEN CLICKED "DONE" ON CREDITS MENU
function c.creditsDone(f)
  c.Menu_Credits:hide()
  c.Menu_Options:setActive()
end



-- WHEN CLICKED "OK" ON INSTRUCTIONS MENU
function c.helpDone(f)
  c.Menu_Instructions:hide()
  c.Menu_Instructions_Background:scheduleFunction("hideEnd",
  function()
    c.Menu_Instructions_Frame:hide()
    c.Menu_Instructions_Frame:clean()
    c.Menu_Instructions_Background:clean()
    -- Three possibilities:
    -- 1. from menu during level
    -- 2. popup when starting a new game
    -- 3. from menu
    if c.Menu_Game:isVisible() then
      c.Menu_Instructions_Mask:hide()
      c.Menu_Game:setActive()
    elseif c.newGameStarting then
      c.startGame(f)
    else
      c.Main:show()
      c.Main:setActive()
    end
  end
  )
end



-- WHEN CLICKED "DONE" ON HIGHSCORES MENU
function c.highscoresDone(f)
  c.Menu_Highscores:hide()
  c.Menu_Highscores_Frame:scheduleFunction("hideEnd",
  function()
    c.Main:show()
    c.Main:setActive()
  end
  )
end



-- WHEN CLICKED "CLEAR" ON HIGHSCORES MENU
function c.highscoresClear(f)
  c.Menu_ClearScores:show()
  c.Menu_ClearScores:setActive()
end



-- WHEN CLICKED "YES" ON HIGHSCORE CLEAR MENU
function c.highscoresClearYes(f)
  f.highscoreReset()
  c.Menu_ClearScores:hide()
  c.Menu_Highscores:setActive()
end



-- WHEN CLICKED "YES" ON HIGHSCORE CLEAR MENU
function c.highscoresClearNo(f)
  c.Menu_ClearScores:hide()
  c.Menu_Highscores:setActive()
end



-- WHEN CLICKED "START GAME" ON MAIN MENU
function c.mainStart(f)
  if f.profileGetSession() then
    c.Menu_Continue:show()
    c.Menu_Continue:setActive()
  else
    --c.stageSelectShow(f)
    f.profileNewGame(c.newGameStage)
    c.Main:hide()
    c.Main_Background:scheduleFunction("hideEnd",
    function()
      c.Main:clean()
      f.musicVolume("menu", 0)
      c.newGameStarting = true
      c.startGame(f)
    end
    )
  end
end



-- WHEN CLICKED "OPTIONS" ON MAIN MENU
function c.mainOptions(f)
  c.Menu_Options:show()
  c.Menu_Options:setActive()
end



-- WHEN CLICKED "INSTRUCTIONS" ON MAIN MENU
function c.mainHelp(f)
  c.Main:hide()
  c.Main_Background:scheduleFunction("hideEnd",
  function()
    c.Main_Background:clean()
    c.Menu_Instructions:show()
    c.Menu_Instructions:setActive()
    c.Menu_Instructions_Toggle_DontShow.widget:setState(f.profileGetVariable("dontShowInstructions"))
  end
  )
end



-- WHEN CLICKED "HALL OF FAME" ON MAIN MENU
function c.mainHighscores(f)
  c.Main:hide()
  c.Main_Background:scheduleFunction("hideEnd",
  function()
    c.Main:clean()
    c.Menu_Highscores:show()
    c.Menu_Highscores:setActive()
  end
  )
end



-- WHEN CLICKED "IF IT'S NOT YOU, CLICK HERE" ON MAIN MENU
function c.mainProfiles(f)
  c.profileManagerUpdateButtons(f)
  c.Profile_Manage:show()
  c.Profile_Manage:setActive()
end



-- URL OPEN
function c.openURL(f, params)
  local url = params[1]
  f.openURL(url)
end



-- WHEN CLICKED "FOOD" ON MAIN MENU
function c.mainFoodTemp(f)
  c.foodUpdateButtons(f)
  c.FoodTemp_Manage:show()
  c.FoodTemp_Manage:setActive()
end



-- WHEN CLICKED AN ENTRY ON TEMP FOOD MENU
function c.foodChange(f, params)
  local id = params[1]
  c.foodtempSelectID = id + c.foodtempOffset
  c.foodUpdateButtons(f)
end



-- WHEN CLICKED "SELECT" ON TEMP FOOD MENU
function c.foodTempSelect(f)
  local food
  for i, row in ipairs(c.FoodTempRows) do
    local n = c.foodtempOffset + i
    if n == c.foodtempSelectID then
      food = row.name.widget.text
    end
  end
  
  f.profileSetEquippedFood(food)
  c.FoodTemp_Manage:hide()
  c.Main:setActive()
end



-- WHEN CLICKED "CANCEL" ON TEMP FOOD MENU
function c.foodTempCancel(f)
  c.FoodTemp_Manage:hide()
  c.Main:setActive()
end



-- WHEN CLICKED "DELETE" ON TEMP FOOD MENU
function c.foodTempDelete(f)
  f.profileSetEquippedFood()
  c.FoodTemp_Manage:hide()
  c.Main:setActive()
end



-- WHEN SCROLLED UP ON TEMP FOOD MENU
function c.foodtempScrollUp(f)
  c.foodtempOffset = c.foodtempOffset - 1
  c.foodUpdateButtons(f)
end



-- WHEN SCROLLED DOWN ON TEMP FOOD MENU
function c.foodtempScrollDown(f)
  c.foodtempOffset = c.foodtempOffset + 1
  c.foodUpdateButtons(f)
end



-- WHEN CLICKED "CREATE" ON PROFILE MENU
function c.profilesCreate(f)
  c.Profile_Create:show()
  c.Profile_Create:setActive()
end



-- WHEN CLICKED "CREATE" ON PROFILE CREATE MENU
function c.profilesCreateYes(f)
  if f.profileMCreate(c.Profile_Create_Entry_Name.widget.text) then
    c.Profile_Create_Entry_Name.widget.text = ""
    c.profileManagerUpdateButtons(f)
    c.Profile_Create:hide()
    -- Profile Manage may be invisible if the creation prompt is from the main menu (no profiles exist)
    if c.Profile_Manage:isVisible() then
      c.Profile_Manage:setActive()
    else
      c.Main:setActive()
    end
  else
    c.Profile_Duplicate:show()
    c.Profile_Duplicate:setActive()
  end
end



-- WHEN CLICKED "OK" ON PROFILE DUPLICATE MENU
function c.profilesDuplicateOk(f)
  c.Profile_Duplicate:hide()
  c.Profile_Create:setActive()
end



-- WHEN CLICKED "CANCEL" ON PROFILE CREATE MENU
function c.profilesCreateNo(f)
  c.Profile_Create:hide()
  c.Profile_Manage:setActive()
end



-- WHEN CLICKED "DELETE" ON PROFILE MENU
function c.profilesDelete(f)
  c.Profile_Delete_Text_Name.widget.text = f.profileMGetNameOrder()[c.profileSelectID]
  c.Profile_Delete:show()
  c.Profile_Delete:setActive()
end



-- WHEN CLICKED "DELETE" ON PROFILE DELETE MENU
function c.profilesDeleteYes(f)
  f.profileMDelete(f.profileMGetNameOrder()[c.profileSelectID])
  c.profileManagerUpdateButtons(f)
  c.Profile_Delete:hide()
  c.Profile_Manage:setActive()
end



-- WHEN CLICKED "CANCEL" ON PROFILE DELETE MENU
function c.profilesDeleteNo(f)
  c.Profile_Delete:hide()
  c.Profile_Manage:setActive()
end



-- WHEN CLICKED "SELECT" ON PROFILE MENU
function c.profilesSelect(f)
  f.profileMSet(f.profileMGetNameOrder()[c.profileSelectID])
  c.Profile_Manage:hide()
  c.Main:setActive()
end



-- WHEN CLICKED "CANCEL" ON PROFILE MENU
function c.profilesCancel(f)
  c.Profile_Manage:hide()
  c.Main:setActive()
  -- If no profiles, prompt for addition of one
  if not f.profileGetExists() then
    c.Profile_Manage_Frame:scheduleFunction("hideEnd",
    function()
      c.Profile_Create:show()
      c.Profile_Create:setActive()
    end
    )
  end
end



-- WHEN CLICKED AN ENTRY ON PROFILE MENU
function c.profilesChange(f, params)
  local id = params[1]
  c.profileSelectID = id + c.profileOffset
  c.profileManagerUpdateButtons(f)
end



-- WHEN SCROLLED UP ON PROFILE MENU
function c.profilesScrollUp(f)
  c.profileOffset = c.profileOffset - 1
  c.profileManagerUpdateButtons(f)
end



-- WHEN SCROLLED DOWN ON PROFILE MENU
function c.profilesScrollDown(f)
  c.profileOffset = c.profileOffset + 1
  c.profileManagerUpdateButtons(f)
end



-- WHEN CLICKED QUIT ON MAIN MENUhide()
function c.mainQuit(f)
  f.quit()
end



-- WHEN CLICKED NEW GAME ON CONTINUE MENU
function c.mainContinueNew(f)
  c.Menu_Continue:hide()
  c.Menu_Continue_Background:scheduleFunction("hideEnd",
  function()
    f.profileNewGame(c.newGameStage)
    c.Main:hide()
    c.Main_Background:scheduleFunction("hideEnd",
    function()
      c.Main:clean()
      f.musicVolume("menu", 0)
      c.newGameStarting = true
      c.startGame(f)
    end
    )
  end
  )
end



-- WHEN CLICKED CONTINUE GAME ON CONTINUE MENU
function c.mainContinueContinue(f)
  c.Menu_Continue:hide()
  c.Menu_Continue_Background:scheduleFunction("hideEnd",
  function()
    c.Main:hide()
    f.musicVolume("menu", 0)
    c.Hud:show()
    c.Main_Background:scheduleFunction("hideEnd",
    function()
      if f.profileGetSavedLevel() then
        c.Main:clean()
        c.Hud:setActive()
        f.levelStart()
      else
        c.stageMapShow(f, false)
      end
    end
    )
  end
  )
end



-- WHEN CLICKED CANCEL ON CONTINUE MENU
function c.mainContinueCancel(f)
  c.Menu_Continue:hide()
  c.Main:setActive()
end



-- WHEN CLICKED START ON LEVEL MAP
function c.mainMapStart(f)
  f.profileNewGame(c.newGameStage)
  c.Menu_StageSelect:hide()
  c.Menu_StageSelect_Frame:scheduleFunction("hideEnd",
  function()
    f.musicVolume("menu", 0)
    c.startGame(f)
  end
  )
end



-- WHEN CLICKED CANCEL ON LEVEL MAP
function c.mainMapCancel(f)
  c.Menu_StageSelect:hide()
  c.Menu_StageSelect_Frame:scheduleFunction("hideEnd",
  function()
    c.Main:show()
    c.Main:setActive()
  end
  )
end



-- WHEN CLICKED A STAGE BUTTON ON LEVEL MAP
function c.mainMapSelect(f, params)
  local stage = params[1]
  c.newGameStage = stage
  c.stageSelectUpdateButtons(f)
end



-- WHEN CLICKED START ON LEVEL MAP 2
function c.gameMapStart(f)
  c.Banner_StageMap:hide()
  c.Banner_StageMap_Frame:scheduleFunction("hideEnd",
  function()
    c.Banner_StageMapTrans:hide()
    c.Banner_StageMapTrans_Background:scheduleFunction("hideEnd",
    function()
      c.Hud:setActive()
      f.levelStart()
    end
    )
  end
  )
end



-- WHEN CLICKED CANCEL ON LEVEL MAP 2
function c.gameMapCancel(f)
  c.Hud:hide()
  c.Banner_StageMap:hide()
  c.Banner_StageMap_Frame:scheduleFunction("hideEnd",
  function()
    c.Banner_StageMapTrans:hide()
    c.Banner_StageMapTrans:clean()
    c.Main:show()
    c.Main:setActive()
    f.musicVolume("menu", 1)
  end
  )
end





----------------------
-- GLOBAL CALLBACKS --
----------------------

function c.tick(f)
  -- update splash screen
  local splash = f.getWidgetN("splash/Main")
  if splash then
    local progress = f.loadingGetProgress()
    f.getWidgetN("splash/Main/Frame/Progress").widget.valueData = progress
    if progress == 1 then
      c.splashClick(f)
    end
  end



  -- when the options menu is open, update options to the widget positions

  -- The "if Menu_Options" check refers to the existence of the widget itself.
  -- Note that this script is loaded when the splash screen starts, and most of
  -- the widgets do not exist at this point yet.
  if c.Menu_Options and c.Menu_Options:isVisible() then
    f.optionsSave()
  end

  if c.Profile_Create and c.Profile_Create:isVisible() then
    c.Profile_Create_Button_Cancel:buttonSetEnabled(f.profileGetExists())
    c.Profile_Create_Button_Ok:buttonSetEnabled(c.Profile_Create_Entry_Name.widget.text:len() > 0)
  end

  if c.Menu_Instructions and c.Menu_Instructions:isVisible() then
    f.profileSetVariable("dontShowInstructions", c.Menu_Instructions_Toggle_DontShow.widget.state)
  end



  -- Update texts
  if c.Banner_StageMap then
    local player = ""
    local playerlevel = 0
    local playercurrency = 0 
    local player_progress_bar = 0

    if f.profileGetExists() then
      player = f.profileGetName()
      playerlevel = f.profileGetPlayerLevel()
      playercurrency = f.profileGetPlayerCurrency()
      

      if f.profileGetSession() then
        local coins = tostring(f.profileGetCoins())
        local score = f.profileGetScore()
        local scoreStr = _NumStr(score)
        if c.scoreDisplay < score then
          c.scoreDisplay = c.scoreDisplay + math.ceil((score - c.scoreDisplay) / 10)
        elseif c.scoreDisplay > score then
          c.scoreDisplay = c.scoreDisplay + math.floor((score - c.scoreDisplay) / 10)
        end
        local scoreAnim = _NumStr(c.scoreDisplay)
        local levelName = f.profileGetLevelName()
        local levelMapName = f.profileGetMap().name
        local stageName = c.stageNames[f.profileGetLatestCheckpoint()]

        c.Menu_Continue_Text_Stage.widget.text = "STAGE " .. levelName
        c.Menu_Continue_Text_Score.widget.text = scoreStr

        c.Hud_Text_Stage.widget.text = levelName
        c.Hud_Text_Coins.widget.text = coins
        c.Hud_Text_Score.widget.text = scoreAnim

        c.Banner_StageMap_Text_StageName.widget.text = stageName
        c.Banner_StageMap_Text_StageNumber.widget.text = "STAGE " .. levelName
        c.Banner_StageMap_Text_MapName.widget.text = levelMapName

        c.Banner_HighScore_Text_Congrats.widget.text = "CONGRATULATIONS, " .. player .. "!"
        c.Banner_HighScore_Text_Score.widget.text = scoreStr

        c.Banner_Intro_Text_Stage.widget.text = "STAGE " .. levelName
        c.Banner_Intro_Text_Map.widget.text = levelMapName

        -- Level
        if f.levelExists() then
          local levelProgress = f.levelGetBlitzMeter()
          local levelObjectives = f.levelGetObjectives()
          local levelScore = _NumStr(f.levelGetScore())
          local levelShots = tostring(f.levelGetShots())
          local levelCoins = tostring(f.levelGetCoins())
          local levelGems = tostring(f.levelGetGems())
          local levelChains = tostring(f.levelGetChains())
          local levelMaxCombo = tostring(f.levelGetMaxCombo())
          local levelMaxChain = tostring(f.levelGetMaxChain())
          local time = math.floor(math.max(levelObjectives[1].target - levelObjectives[1].progress, 0))
          local levelTime = string.format("%.1d %.2d", math.floor(time / 60), time % 60)
          local levelCombo = tostring(f.levelGetCombo())
          local levelMultiplier = tostring(f.levelGetMultiplier())

          c.Hud_Text_Lives.widget.text = levelTime
          c.Hud_Text_Stage.widget.text = levelCombo
          c.Hud_Text_Coins.widget.text = levelMultiplier

          c.Hud_Progress.widget.valueData = levelProgress
          c.Hud_Progress_Marker.angle = -math.pi / 2 + c.Hud_Progress.widget.value * math.pi

          c.Banner_LevelComplete_Text_Stage.widget.text = "STAGE " .. levelName
          c.Banner_LevelComplete_Text_MapName.widget.text = levelMapName
          c.Banner_LevelComplete_Text_LevelScore.widget.text = levelScore
          c.Banner_LevelComplete_Text_ShotsFired.widget.text = levelShots
          c.Banner_LevelComplete_Text_MaxCombo.widget.text = levelMaxCombo
          c.Banner_LevelComplete_Text_Coins.widget.text = levelCoins
          c.Banner_LevelComplete_Text_MaxChain.widget.text = levelMaxChain
          c.Banner_LevelComplete_Text_Gems.widget.text = levelGems
          c.Banner_LevelComplete_Text_Segments.widget.text = levelChains
        end
      end
    end

    -- New game
    local newCheckpointID = f.configGetCheckpointID(c.newGameStage)
    local newLevelID = f.configGetLevelID(newCheckpointID)
    local newLevelData = f.configGetLevelData(newLevelID)
    local newLevelName = f.configGetLevelName(newCheckpointID)
    local newLevelMapName = f.configGetMapData(newLevelData.map).name
    local newStageName = c.stageNames[c.newGameStage]


    -- update widget to get current coins / values
    c.Main_Text_Level.widget.text = math.floor(playerlevel)
    c.Main_Text_Currency.widget.text = _NumStr(playercurrency)
    c.Main_Progress_XP.widget.valueData = playerlevel % 1

    c.Main_Text_PlayerE.widget.text = player
    c.Main_Text_Version.widget.text = "Running on OpenSMCE " .. _VERSION

    if not f.profileGetExists() then
      c.Main_Text_PlayerItems.widget.text = ""
    else
      c.Main_Text_PlayerItems.widget.text = string.format(
        "Equipped Food: %s\nEquipped Powers: %s\nFrogatar: %s\nSpirit Animal: %s",
        f.profileGetEquippedFood() or "none",
        table.concat(f.profileGetEquippedPowers(), ", "),
        f.profileGetFrogatar(),
        f.profileGetMonument() or "none"
      )
    end

    --[[
    for i, row in ipairs(c.HighscoreRows) do
      local entry = f.highscoreGetEntry(i)
      row.rank.widget.text = tostring(i)
      row.name.widget.text = entry.name
      row.name2.widget.text = entry.name
      row.level.widget.text = entry.level
      row.score.widget.text = _NumStr(entry.score)
    end
    ]]
    for i, row in ipairs(c.LeaderboardRows) do
      local entry = f.highscoreGetEntry(i)
      --row.rank.widget.text = tostring(i)
      row.name.widget.text = entry.name
      row.score.widget.text = _NumStr(entry.score)
    end

    c.Menu_StageSelect_Text_StageName.widget.text = newStageName
    c.Menu_StageSelect_Text_StageNumber.widget.text = "STAGE " .. newLevelName
    c.Menu_StageSelect_Text_MapName.widget.text = newLevelMapName
  end
end



function c.sessionInit(f)
  f.getWidgetN("root"):show()
  f.getWidgetN("root/Main"):setActive()
  f.optionsLoad()
end



function c.lostFocus(f)
  if c.Button_Pause and c.Button_Pause:isActive() and not c.Banner_Paused:isVisible() then
    c.Banner_Paused:show()
    f.levelPause()
  end
end



function c.levelStart(f)
  c.Banner_LevelLose:clean()
  f.levelBegin()
  c.Button_Pause:buttonSetEnabled(true)
end



function c.levelLoaded(f)
  f.levelBeginLoad()
  c.Banner_Paused:show()
  c.Button_Pause:buttonSetEnabled(true)
end



function c.levelComplete(f)
  c.Button_Pause:buttonSetEnabled(false)
  c.Banner_LevelComplete:show()
  if not f.levelGetNewRecord() then
    c.Banner_LevelComplete_Record:hide()
  end
end



function c.levelLost(f)
  c.levelComplete(f)
end



function c.gameOver(f)
  c.Banner_LevelLose:clean()
  c.Banner_GameOver:show()
  c.Button_Menu:buttonSetEnabled(false)
  c.Banner_GameOver_Panel:scheduleFunction("hideEnd",
  function()
    c.Banner_GameOver:clean()
    local place = f.profileHighscoreWrite()
    if place then
      c.highscorePlace = place
      c.Banner_HighScore:show()
      c.Banner_HighScore:setActive()
    else
      c.Hud:hide()
      c.Hud:scheduleFunction("hideEnd",
      function()
        f.profileDeleteGame()
        c.Main:show()
        c.Main:setActive()
        f.musicVolume("menu", 1)
      end
      )
    end
  end
  )
end



function c.newLife(f)
  c.Hud_NewLife:show()
end





----------------------
-- HELPER FUNCTIONS --
----------------------



function c.startGame(f)
  c.newGameStarting = false
  c.Hud:show()
  c.Hud:scheduleFunction("showEnd",
  function()
    c.Hud:setActive()
    c.Button_Menu:buttonSetEnabled(true)
    f.levelStart()
  end
  )
end



function c.stageMapShow(f, advance)
  c.Banner_StageMapTrans:show()
  c.Banner_StageMapTrans_Background:scheduleFunction("showEnd",
  function()
    c.Main:clean()
    c.stageMapUpdateButtons(f)
    c.Banner_StageMap:show()
    if advance then
      c.Banner_StageMap_Frame:scheduleFunction("showEnd",
      function()
        if f.profileGetLevelN() == 88 or f.profileIsCheckpointUpcoming() then
          c.Banner_StageMap_StageCompletePsys:show()
          c.Banner_StageMap_StageCompletePsys:scheduleFunction("particleDespawn",
          function()
            if f.profileIsCheckpointUpcoming() then
              f.profileLevelAdvance()
              c.stageMapSetActive(f)
              c.Banner_StageMap_StageUnlockPsys:show()
            else
              c.Banner_StageMap:hide()
              c.Banner_StageMap_Frame:scheduleFunction("hideEnd",
              function()
                -- If you've dug this deep, you should know that I'm leaving the "game win" feature to the very end of Beta state :)
                c.Banner_StageMapTrans:hide()
                c.Banner_StageMapTrans:clean()
                c.Hud:hide()
                c.Main:show()
                c.Main:setActive()
              end
              )
            end
          end
          )
        else
          f.profileLevelAdvance()
          c.stageMapSetActive(f)
        end
      end
      )
    else
      c.stageMapSetActive(f)
    end
  end
  )
end



function c.stageMapSetActive(f)
  c.Banner_StageMap:setActive()
  c.Banner_StageMap_StageButtons:resetActive()
  c.Banner_StageMap_LevelButtons:resetActive()
  c.stageMapUpdateButtons(f)
end



function c.stageMapUpdateButtons(f)
  local s = f.profileGetLatestCheckpoint()
  for i, StageButton in ipairs(c.StageButtons) do
    StageButton:buttonSetEnabled(i <= s)
    StageButton.widget.clickedV = i == s
    if i == s then
      c.Banner_StageMap_StageUnlockPsys.pos = StageButton.pos + 32
    end
  end
  if s == 13 then
    c.Banner_StageMap_Set:show()
  else
    c.Banner_StageMap_Set:hide()
    c.Banner_StageMap_Set:clean()
  end

  local n = f.profileGetLevelN()
  for i, LevelButton in ipairs(c.LevelButtons) do
    if i < n then
      LevelButton:show()
    else
      LevelButton:hide()
      LevelButton:clean()
    end
    if i == n then
      c.Banner_StageMap_LevelPsys.pos = LevelButton.pos
    end
  end
end



function c.stageSelectShow(f)
  c.Main:hide()
  c.Main_Background:scheduleFunction("hideEnd",
  function()
    c.Main:clean()
    -- latest checkpoint will be selected by default
    local checkpoints = f.profileGetUnlockedCheckpoints()
    c.newGameStage = checkpoints[#checkpoints]
    --
    c.stageSelectUpdateButtons(f)
    c.Menu_StageSelect:show()
    c.Menu_StageSelect:setActive()
  end
  )
end



function c.stageSelectUpdateButtons(f)
  c.Menu_StageSelect_StageButtons:show()

  local n = f.configGetCheckpointLevel(c.newGameStage)
  for i, LevelButton in ipairs(c.NewGameLevelButtons) do
    if i < n then
      LevelButton:show()
    else
      LevelButton:hide()
      LevelButton:clean()
    end
    if i == n then
      c.Menu_StageSelect_LevelPsys.pos = LevelButton.pos
    end
  end

  local s = c.newGameStage
  for i, StageButton in ipairs(c.NewGameStageButtons) do
    StageButton:buttonSetEnabled(f.profileIsCheckpointUnlocked(i))
    StageButton.widget.clickedV = i == s
  end
  if s == 13 then
    c.Menu_StageSelect_Set:show()
  else
    c.Menu_StageSelect_Set:hide()
    c.Menu_StageSelect_Set:clean()
  end
end



function c.profileManagerUpdateButtons(f)
  local names = f.profileMGetNameOrder()

  if c.profileSelectID > #names then
    c.profileSelectID = #names
  end
  if c.profileOffset > 0 and c.profileOffset > #names - #c.ProfileRows then
    c.profileOffset = #names - #c.ProfileRows
  end

  local s = c.profileSelectID
  for i, row in ipairs(c.ProfileRows) do
    local n = c.profileOffset + i
    local name = names[n] or ""
    row.name.widget.text = name
    row.name2.widget.text = name
    row.button:buttonSetEnabled(names[n])
    row.button.widget.clickedV = n == s
  end

  c.Profile_Manage_Button_Up:buttonSetEnabled(c.profileOffset > 0)
  c.Profile_Manage_Button_Down:buttonSetEnabled(c.profileOffset < #names - #c.ProfileRows)
  c.Profile_Manage_Button_Delete:buttonSetEnabled(c.profileSelectID > 0)
  c.Profile_Manage_Button_Select:buttonSetEnabled(c.profileSelectID > 0)
end



function c.foodUpdateButtons(f)
  local names = {}
  for k, v in pairs(f.getFoodItems()) do
    table.insert(names, k)
  end

  if c.foodtempSelectID > #names then
    c.foodtempSelectID = #names
  end
  if c.foodtempOffset > 0 and c.profileOffset > #names - #c.FoodTempRows then
    c.foodtempOffset = #names - #c.FoodTempRows
  end

  local s = c.foodtempSelectID
  for i, row in ipairs(c.FoodTempRows) do
    local n = c.foodtempOffset + i
    local name = names[n] or ""
    row.name.widget.text = name
    row.button:buttonSetEnabled(names[n])
    row.button.widget.clickedV = n == s
  end

  c.FoodTemp_Manage_Button_Up:buttonSetEnabled(c.foodtempOffset > 0)
  c.FoodTemp_Manage_Button_Down:buttonSetEnabled(c.foodtempOffset < #names - #c.ProfileRows)
  c.FoodTemp_Manage_Button_Delete:buttonSetEnabled(c.foodtempSelectID > 0)
  c.FoodTemp_Manage_Button_Select:buttonSetEnabled(c.foodtempSelectID > 0)
end





-- Now we need to carry all functions that we've inserted over to the engine.
return c
