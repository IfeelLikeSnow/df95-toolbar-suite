-- @description Recording QA & Metadata Inspector
-- @version 1.0
-- @author DF95
-- @about
--   Prüft ausgewählte Items / Takes auf:
--     - Sample-Rate (kHz)
--     - Bit-Tiefe (soweit aus WAV-Header lesbar)
--     - Kanäle
--     - Länge
--     - Peak ca. (via PCM_Source_GetPeaks)
--   Zeigt eine kleine Übersicht in der Console an.
--
--   Hinweis:
--     - Bit-Tiefe wird nur zuverlässig aus unkomprimierten WAV-Dateien
--       ausgelesen. Für andere Formate wird "unknown" angezeigt.

local r = reaper

local function msg(s)
  r.ShowConsoleMsg(tostring(s) .. "\n")
end

local function get_wav_bitdepth(path)
  -- Sehr einfacher WAV-Parser:
  -- prüft "RIFF....WAVEfmt " und liest bitsPerSample (2 Bytes bei Offset 34)
  local f = io.open(path, "rb")
  if not f then return nil end

  local header = f:read(64)
  f:close()
  if not header or #header < 36 then return nil end

  if header:sub(1,4) ~= "RIFF" or header:sub(9,12) ~= "WAVE" then
    return nil
  end

  -- Suche "fmt " Chunk
  local fmt_pos = header:find("fmt ")
  if not fmt_pos then return nil end

  -- bitsPerSample liegt normalerweise bei Offset 34 (0-basiert) vom Datei-Anfang,
  -- aber wir gehen defensiv relativ zur fmt-Position vor:
  local bps_offset = fmt_pos + 15  -- fmt_pos zeigt auf 'f', +4 (ChunkID), +4 (ChunkSize), +2(AudioFormat), +2(Channels), +4(SampleRate), +4(ByteRate), +2(BlockAlign) = +22 -> Index (Lua) = +23; plus 1-based Korrektur => +23-1=+22, hier grob geschätzt
  -- In vielen Standard-WAVs ist Offset 35/36 (1-based) -> wir lesen 2 Bytes ab 35 (1-based)
  local b1 = header:byte(35)
  local b2 = header:byte(36)
  if not b1 or not b2 then return nil end
  local bits = b1 + b2 * 256
  if bits == 0 then return nil end
  return bits
end

local function inspect_take(take)
  if not take then return nil end

  local src = r.GetMediaItemTake_Source(take)
  if not src then return nil end

  local buf = string.rep(" ", 4096)
  local _, src_path = r.GetMediaSourceFileName(src, buf, 4096)
  src_path = src_path:match("([^\0]+)") or ""

  local sr = r.GetMediaSourceSampleRate(src) or 0
  local ch = r.GetMediaSourceNumChannels(src) or 0

  local sr_khz = sr > 0 and (sr / 1000.0) or 0

  local bits = nil
  local ext = src_path:lower():match("%.([%a%d]+)$") or ""
  if ext == "wav" then
    bits = get_wav_bitdepth(src_path)
  end

  -- Peak grob via PCM_Source_GetPeaks
  local peak = 0.0
  local length = r.GetMediaSourceLength(src)
  if length and length > 0 then
    local numch = ch > 0 and ch or 1
    local num_samples = 4096
    local buf_sz = num_samples * numch
    local peak_buf = r.new_array(buf_sz)
    local _, __ = r.PCM_Source_GetPeaks(src, num_samples, 0, 1, numch, 0, peak_buf)
    for i = 1, buf_sz do
      local v = math.abs(peak_buf[i])
      if v > peak then peak = v end
    end
  end

  return {
    path = src_path,
    sr = sr,
    sr_khz = sr_khz,
    ch = ch,
    bits = bits,
    peak = peak,
  }
end

local function main()
  r.ClearConsole()
  msg("DF95 Recording QA / Metadata Inspector")
  msg("--------------------------------------")

  local cnt = r.CountSelectedMediaItems(0)
  if cnt == 0 then
    msg("Keine Items ausgewählt.")
    return
  end

  for i = 0, cnt-1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local info = inspect_take(take)
      if info then
        msg(string.rep("-", 60))
        msg(string.format("Item #%d", i+1))
        msg("Quelle: " .. (info.path ~= "" and info.path or "<unsaved / recorded buffer>"))
        msg(string.format("Sample-Rate: %.1f kHz", info.sr_khz))
        msg(string.format("Kanäle: %d", info.ch or 0))
        if info.bits then
          msg(string.format("Bit-Tiefe (WAV-Header): %d-bit", info.bits))
        else
          msg("Bit-Tiefe: <unbekannt oder nicht-WAV>")
        end
        msg(string.format("Peak (ca.): %.2f dBFS", (info.peak > 0) and (20*math.log(info.peak,10)) or -120))
      end
    end
  end

  msg(string.rep("=", 60))
  msg("Fertig. Tipp: Diese Infos kannst du für DF95-Tags / Routing nutzen.")
end

main()
