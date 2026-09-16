-- Hammerspoon config managed by chezmoi

require("hs.ipc")

local spotifyVolumeStep = 1
local spotifyVolumeDebounceSeconds = 0.08
local spotifyTransportDoublePressSeconds = 0.5
local pendingSpotifyVolumeDelta = 0
local spotifyVolumeTimer = nil
local spotifyTransportTapCount = 0
local spotifyTransportTimer = nil

local reloadTimer = nil
local function reloadConfig(files)
  for _, file in ipairs(files) do
    if file:match("%.lua$") then
      if reloadTimer then
        reloadTimer:stop()
      end
      reloadTimer = hs.timer.doAfter(0.5, hs.reload)
      return
    end
  end
end

configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon", reloadConfig):start()

local function spotifyVolumeScript(direction, steps)
  if direction > 0 then
    return string.format([[
      if application "Spotify" is running then
        tell application "Spotify"
          set currentVolume to sound volume
          repeat with stepIndex from 1 to %d
            if currentVolume >= 100 then exit repeat
            set changed to false
            repeat with candidate from (currentVolume + 1) to 100
              set sound volume to candidate
              set actualVolume to sound volume
              if actualVolume > currentVolume then
                set currentVolume to actualVolume
                set changed to true
                exit repeat
              end if
            end repeat
            if changed is false then exit repeat
          end repeat
          return currentVolume
        end tell
      else
        return "not running"
      end if
    ]], steps)
  end

  return string.format([[
    if application "Spotify" is running then
      tell application "Spotify"
        set currentVolume to sound volume
        repeat with stepIndex from 1 to %d
          if currentVolume <= 0 then exit repeat
          set changed to false
          repeat with candidate from (currentVolume - 1) to 0 by -1
            set sound volume to candidate
            set actualVolume to sound volume
            if actualVolume < currentVolume then
              set currentVolume to actualVolume
              set changed to true
              exit repeat
            end if
          end repeat
          if changed is false then exit repeat
        end repeat
        return currentVolume
      end tell
    else
      return "not running"
    end if
  ]], steps)
end

local function setSpotifyVolume(delta)
  local direction = delta > 0 and 1 or -1
  local steps = math.max(1, math.floor(math.abs(delta)))
  local script = spotifyVolumeScript(direction, steps)

  local ok, result, descriptor = hs.osascript.applescript(script)
  if ok then
    if result == "not running" then
      hs.alert.show("Spotify not running")
    end
  else
    local message = "Spotify volume failed"
    if type(descriptor) == "table" then
      local errorNumber = descriptor.NSAppleScriptErrorNumber
      local errorMessage = descriptor.NSAppleScriptErrorMessage or descriptor.NSAppleScriptErrorBriefMessage

      if errorNumber == -1743 then
        message = "Allow Hammerspoon to control Spotify"
      elseif errorMessage then
        message = "Spotify: " .. errorMessage
      end

      hs.printf("Spotify volume AppleScript failed: %s", hs.inspect(descriptor))
    else
      hs.printf("Spotify volume AppleScript failed: %s", tostring(descriptor))
    end

    hs.alert.show(message, 4)
  end
end

local function flushSpotifyVolumeChange()
  local delta = pendingSpotifyVolumeDelta
  pendingSpotifyVolumeDelta = 0
  spotifyVolumeTimer = nil

  if delta ~= 0 then
    setSpotifyVolume(delta)
  end
end

local function queueSpotifyVolumeChange(delta)
  pendingSpotifyVolumeDelta = pendingSpotifyVolumeDelta + delta

  if spotifyVolumeTimer then
    spotifyVolumeTimer:stop()
  end

  spotifyVolumeTimer = hs.timer.doAfter(spotifyVolumeDebounceSeconds, flushSpotifyVolumeChange)
end

local function spotifyVolumeDown()
  queueSpotifyVolumeChange(-spotifyVolumeStep)
end

local function spotifyVolumeUp()
  queueSpotifyVolumeChange(spotifyVolumeStep)
end

local function runSpotifyCommand(command)
  local script = string.format([[
    if application "Spotify" is running then
      tell application "Spotify" to %s
      return "ok"
    else
      return "not running"
    end if
  ]], command)

  local ok, result, descriptor = hs.osascript.applescript(script)
  if ok then
    if result == "not running" then
      hs.alert.show("Spotify not running")
    end
  else
    hs.printf("Spotify command failed: %s", hs.inspect(descriptor))
    hs.alert.show("Spotify command failed", 4)
  end
end

local function spotifyPlayPause()
  runSpotifyCommand("playpause")
end

local function spotifyNextTrack()
  runSpotifyCommand("next track")
end

local function spotifyTransportButton()
  spotifyTransportTapCount = spotifyTransportTapCount + 1

  if spotifyTransportTapCount == 1 then
    spotifyTransportTimer = hs.timer.doAfter(spotifyTransportDoublePressSeconds, function()
      spotifyTransportTapCount = 0
      spotifyTransportTimer = nil
      spotifyPlayPause()
    end)
    return
  end

  if spotifyTransportTimer then
    spotifyTransportTimer:stop()
    spotifyTransportTimer = nil
  end

  spotifyTransportTapCount = 0
  spotifyNextTrack()
end

-- VIA/QMK-friendly bindings.
-- Recommended encoder mapping in VIA: CCW = KC_F16, CW = KC_F17.
-- Recommended transport key in VIA: KC_F15.
--   single press = play/pause, double press = next track.
-- F18/F19 are kept too, but F19 can be awkward on some macOS setups.
hs.hotkey.bind({}, "f15", spotifyTransportButton)
hs.hotkey.bind({}, "f16", spotifyVolumeDown)
hs.hotkey.bind({}, "f17", spotifyVolumeUp)
hs.hotkey.bind({}, "f18", spotifyVolumeDown)
hs.hotkey.bind({}, "f19", spotifyVolumeUp)
hs.hotkey.bind({}, "f20", spotifyVolumeUp)

-- Alternate bindings if you prefer sending a Hyper combo from VIA/QMK.
local hyper = { "cmd", "alt", "ctrl", "shift" }
hs.hotkey.bind(hyper, "p", spotifyTransportButton)
hs.hotkey.bind(hyper, "[", spotifyVolumeDown)
hs.hotkey.bind(hyper, "]", spotifyVolumeUp)

hs.alert.show("Hammerspoon config loaded")
