-- See discussion in https://github.com/xournalpp/xournalpp/issues/7007
-- TODO: custom shortcut

local PREFIX_NAME = "*:"
local PREFIX_REF_STUDENTS = "*students:"
local SEP_NAME = "|"
local GRADE_SEP = "~>"
local CSV_SEP = "\t"
local FOLDER_EXPORT = "pdf_exports"

-- Settings car be configured via a text like:
-- *settings:
-- optionA = foo
-- optionB = bar
--
-- The list of options is:
-- - removeNoGradeCells = false/true (default true)
local PREFIX_SETTING = "*settings:"

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. ''..k..' = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function filter(l, f)
   local r = {}
   for i, x in ipairs(l) do
      if f(x) then
         table.insert(r, x)
      end
   end
   return r
end
function get_file_name(file)
      return file:match("[^/\\]*$")
end

function index_in_array(a, x)
   for i,y in ipairs(a) do
      if y == x then
         return i
      end
   end
   return nil
end

function size_of_object(o)
   local i = 0
   for k,v in pairs(o) do
      i = i + 1
   end
   return i
end

function max_value(o)
   local x = nil
   for k,v in pairs(o) do
      if x == nil then
         x = v
      else
         if v > x then
            x = v
         end
      end
   end
   return x
end

function fill_array_until_size(a, size, x)
   local r = {}
   for i=1, size do
      if i <= #a then
         r[i] = a[i]
      else
         r[i] = x
      end
   end
   return r
end

function isUnix()
   return package.config:sub(1,1) == '/'
end

function getOS()
   if package.config:sub(1,1) ~= '/' then
      return "windows"
   else
      -- Unix, Linux variants
      local fh, err = assert(io.popen("uname 2>/dev/null", "r"))
      if fh then
         local osname = trim(fh:read():lower())
         if osname == "linux" then
            return "linux"
         elseif osname == "darwin" then
            return "darwin"
         else
            print("WARNING: unknown OS " .. osname .. ", defaulting to linux.")
            return "linux"
         end
      end
   end
end


function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


function trim(x)
   return x:match("^%s*(.-)%s*$")
end

function trimNewLines(x)
   return x:match("^\n*(.-)\n*$")
end

function split(s, delimiter)
    result = {};
    delimiter_regexp = delimiter:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    for match in (s..delimiter):gmatch("(.-)"..delimiter_regexp) do
        table.insert(result, match);
    end
    return result;
end


-- We allow SEP_NAME and TAB to separate names
-- We don't have "OR" in pattern matching
-- https://stackoverflow.com/questions/3462370/logical-or-in-lua-patterns
-- https://www.lua.org/manual/5.5/manual.html#6.5.1
-- so to do "SEP_NAME or TAB", we first cut on SEP_NAME, then TAB, and we also strip
-- white space
function split_student_name_in_columns(student)
   local res = {}
   for _,x in ipairs(split(student, SEP_NAME)) do
      for _,y in ipairs(split(x, "\t")) do
         table.insert(res, trim(y))
      end
   end
   return res
end


-- Turn an integer (starting from 1) into a letter to represent the corresponding column in a spreadsheet
local function int_to_spreadsheet_col(n)
    local s = ""
    while n > 0 do
        n = n - 1
        s = string.char(65 + (n % 26)) .. s
        n = math.floor(n / 26)
    end
    return s
end

-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
function iterate_on_lines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
end

-- https://stackoverflow.com/questions/50459102/replace-accented-characters-in-string-to-standard-with-lua
function normalizeLatin(str)
  local tableAccents = {}
    tableAccents["À"] = "A"
    tableAccents["Á"] = "A"
    tableAccents["Â"] = "A"
    tableAccents["Ã"] = "A"
    tableAccents["Ä"] = "A"
    tableAccents["Å"] = "A"
    tableAccents["Æ"] = "AE"
    tableAccents["Ç"] = "C"
    tableAccents["È"] = "E"
    tableAccents["É"] = "E"
    tableAccents["Ê"] = "E"
    tableAccents["Ë"] = "E"
    tableAccents["Ì"] = "I"
    tableAccents["Í"] = "I"
    tableAccents["Î"] = "I"
    tableAccents["Ï"] = "I"
    tableAccents["Ð"] = "D"
    tableAccents["Ñ"] = "N"
    tableAccents["Ò"] = "O"
    tableAccents["Ó"] = "O"
    tableAccents["Ô"] = "O"
    tableAccents["Õ"] = "O"
    tableAccents["Ö"] = "O"
    tableAccents["Ø"] = "O"
    tableAccents["Ù"] = "U"
    tableAccents["Ú"] = "U"
    tableAccents["Û"] = "U"
    tableAccents["Ü"] = "U"
    tableAccents["Ý"] = "Y"
    tableAccents["Þ"] = "P"
    tableAccents["ß"] = "s"
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["å"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ð"] = "eth"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ø"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["þ"] = "p"
    tableAccents["ÿ"] = "y"

  local normalisedString = ''

  local normalisedString = str: gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)

  return normalisedString

end

-- ========== YAML ==========
local function is_array(t)
  local i = 1
  for k, _ in pairs(t) do
    if k ~= i then return false end
    i = i + 1
  end
  return true
end

local function indent(level)
  return string.rep("  ", level)
end

local function dump_string(str, level)
  local ind = indent(level)
  local lines = { "|-" }

  for line in str:gmatch("([^\n]*)\n?") do
    if line ~= "" then
      table.insert(lines, ind .. "  " .. line)
    end
  end

  return table.concat(lines, "\n")
end

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do table.insert(keys, k) end
  table.sort(keys)
  return keys
end

local function to_yaml(value, level)
  level = level or 0
  local ind = indent(level)

  if type(value) == "table" then
    local lines = {}

    if is_array(value) then
      -- LIST
      for _, v in ipairs(value) do
        if type(v) == "table" and not is_array(v) then
          -- dictionary inside list → inline first key
          local keys = sorted_keys(v)
          local first_key = keys[1]
          local first_val = v[first_key]

          -- first key inline
          if type(first_val) == "table" then
            table.insert(lines, ind .. "- " .. first_key .. ":")
            table.insert(lines, to_yaml(first_val, level + 2))
          elseif type(first_val) == "string" then
            table.insert(lines, ind .. "- " .. first_key .. ": " .. dump_string(first_val, level + 2))
          else
            table.insert(lines, ind .. "- " .. first_key .. ": " .. tostring(first_val))
          end

          -- remaining keys
          for i = 2, #keys do
            local k = keys[i]
            local val = v[k]

            if type(val) == "table" then
              table.insert(lines, indent(level + 1) .. k .. ":")
              table.insert(lines, to_yaml(val, level + 2))
            elseif type(val) == "string" then
              table.insert(lines, indent(level + 1) .. k .. ": " .. dump_string(val, level + 2))
            else
              table.insert(lines, indent(level + 1) .. k .. ": " .. tostring(val))
            end
          end

        elseif type(v) == "table" then
          -- nested list
          table.insert(lines, ind .. "-")
          table.insert(lines, to_yaml(v, level + 1))

        elseif type(v) == "string" then
          table.insert(lines, ind .. "- " .. dump_string(v, level + 1))
        else
          table.insert(lines, ind .. "- " .. tostring(v))
        end
      end

    else
      -- DICTIONARY
      for _, k in ipairs(sorted_keys(value)) do
        local v = value[k]

        if type(v) == "table" then
          table.insert(lines, ind .. k .. ":")
          table.insert(lines, to_yaml(v, level + 1))
        elseif type(v) == "string" then
          table.insert(lines, ind .. k .. ": " .. dump_string(v, level + 1))
        else
          table.insert(lines, ind .. k .. ": " .. tostring(v))
        end
      end
    end

    return table.concat(lines, "\n")
  end

  -- scalars
  if type(value) == "string" then
    return ind .. dump_string(value, level)
  else
    return ind .. tostring(value)
  end
end
-- ========== END YAML ==========
-- Absolute scroll is not doing what the documentation claims it's doing,
-- https://github.com/xournalpp/xournalpp/issues/7120
-- So let's implement my version
function scrollTo(page, x, y)
  local zoom = app.getZoom()
  app.setCurrentPage(page)
  app.scrollToPage(page)
  app.scrollToPos(x*zoom, y*zoom)
end

-- Register all Toolbar actions and intialize all UI stuff
function initUi()
  app.registerUi({["menu"] = "Unbook A3 to A4 (landscape)", ["callback"] = "unbookPDF", mode = 1});
  app.registerUi({["menu"] = "Unbook A3 to A4 (portrait)", ["callback"] = "unbookPDF", mode = 2});
  app.registerUi({["menu"] = "Merge all PDF/images in current folder (images in portrait)", ["callback"] = "mergePDF", mode = 1});
  app.registerUi({["menu"] = "Merge all PDF/images in current folder (images in landscape)", ["callback"] = "mergePDF", mode = 2});
  app.registerUi({["menu"] = "Merge all PDF/images in current folder (exif rotated images)", ["callback"] = "mergePDF", mode = 3});
  app.registerUi({["menu"] = "Add student", ["callback"] = "createStudent", ["accelerator"] = "F2"});
  app.registerUi({["menu"] = "1st uncorrected grade all doc & save", ["callback"] = "gotoSmallestUncorrectedGradeAndSave", ["accelerator"] = "<Alt>Return"});
  app.registerUi({["menu"] = " --- ", ["callback"] = "gotoSmallestUncorrectedGradeAndSave", ["accelerator"] = "<Alt>s"});
  app.registerUi({["menu"] = "Go to previously visited student", ["callback"] = "goBackHistory", ["accelerator"] = "F1"});
  app.registerUi({["menu"] = "Copy comment to clipboard", ["callback"] = "addComment", ["accelerator"] = "F7"});
  app.registerUi({["menu"] = "Paste zero grade for current question", ["callback"] = "pasteZeroGrade", ["accelerator"] = "<Alt>z"});
  app.registerUi({["menu"] = "Paste max grade for current question", ["callback"] = "pasteMaxGrade", ["accelerator"] = "<Alt>m"});
  app.registerUi({["menu"] = " --- ", ["callback"] = "pasteMaxGrade", ["accelerator"] = "<Alt>d"});
  app.registerUi({["menu"] = "Paste empty grade for current question", ["callback"] = "pasteEmptyGrade", ["accelerator"] = "<Alt>q"});
  app.registerUi({["menu"] = "Paste zero grade for all remaining grades", ["callback"] = "allRemainingGradesToZeroInClipboard", ["accelerator"] = "<Alt><Shift>z"});
  app.registerUi({["menu"] = "Export CSV and YAML", ["callback"] = "generateCSV", mode = 1});
  app.registerUi({["menu"] = "Export CSV (percent formula) and YAML", ["callback"] = "generateCSV", mode = 2});
  app.registerUi({["menu"] = "Export pdf", ["callback"] = "exportPdf"});
  app.registerUi({["menu"] = "Copy all settings", ["callback"] = "copyAllSettings"});

  app.registerUi({["menu"] = "Advanced: next student", ["callback"] = "gotoNextStudent"});
  app.registerUi({["menu"] = "Advanced: 1st uncorrected grade current student", ["callback"] = "gotoLastGrade"});
  app.registerUi({["menu"] = "Advanced: 1st uncorrected grade next student", ["callback"] = "gotoLastGradeNextStudent"});
  app.registerUi({["menu"] = "Advanced: 1st uncorrected grade next student & save", ["callback"] = "gotoLastGradeNextStudentAndSave"});
  app.registerUi({["menu"] = "Advanced: 1st uncorrected grade all doc", ["callback"] = "gotoSmallestUncorrectedGrade"});
  app.registerUi({["menu"] = "Advanced: debug", ["callback"] = "debug"});
  app.registerUi({["menu"] = "Advanced: toggle put grade in clipboard", ["callback"] = "togglePutGradeInClipboard"});
  -- F1 will be used to go backward, F3 will be used to add grades
end

-- Enable to automatically put the current grade in the clipboard
putCurrentGradeInClipboard = true

function togglePutGradeInClipboard()
   putCurrentGradeInClipboard = not putCurrentGradeInClipboard
   app.openDialog(putCurrentGradeInClipboard and "Grades will be copied in clipboard when going to the next exam" or "Grades will NOT be copied in clipboard when going to the next exam", {"Ok"}, nil)
end

function copyToClipboard(text)
   local currentOs = getOS()
   if currentOs == "windows" then
      -- https://github.com/JerwuQu/wlines
      cmd = "clip"
   elseif currentOs == "darwin" then
      -- https://github.com/chipsenkbeil/choose
      cmd = "pbcopy"
   else
      cmd = "xclip -selection clipboard"
   end
   local h = io.popen(cmd, "w")
   h:write(text)
   h:close()
end



gradeExamHistory = nil
gradeExamHistoryPosition = 0 -- We consider an array modulo to efficiently keep only a few elements.
gradeExamHistoryLength = 200

function recordPositionHistory()
   if gradeExamHistory == nil then
      gradeExamHistory = {}
      for i=1,gradeExamHistoryLength do
         gradeExamHistory[i] = nil
      end
   end
   gradeExamHistoryPosition = (gradeExamHistoryPosition + 1) % gradeExamHistoryLength
   gradeExamHistory[gradeExamHistoryPosition] = {
      page = app.getDocumentStructure().currentPage,
   }
end

function goBackHistory()
   lastPos = gradeExamHistory[gradeExamHistoryPosition]
   gradeExamHistory[gradeExamHistoryPosition] = nil
   gradeExamHistoryPosition = (gradeExamHistoryPosition - 1) % gradeExamHistoryLength
   if lastPos == nil then
      app.openDialog("No history available. Make sure to navigate via controls specific to this plugin.", {"Ok"}, nil)
   else
      app.setCurrentPage(lastPos.page)
      app.scrollToPage(lastPos.page)
   end
end

repeatLastActionEnabled = nil
repeatLastActionName = nil

-- In this mode, F4 does not 
function repeatLastAction()
   
end

function isStudentName(text)
   if string.sub(text,1,#PREFIX_NAME) == PREFIX_NAME then
      return string.sub(text,#PREFIX_NAME+1,-1)
   else
      return nil
   end
end


function sortTexts(a,b)
   if a.page == b.page then
      -- We write students first, simpler to deal with later
      local a_is_student = isStudentName(a.text)
      local b_is_student = isStudentName(b.text)
      if a_is_student and b_is_student then
         return a.y < b.y
      elseif a_is_student then
         return true
      elseif b_is_student then
         return false
      else
         return a.y < b.y
      end
   else
      return a.page < b.page
   end
end

function compareComments(x, y)
    return (x[1] > y[1]) or (x[1] == y[1] and #x[2] < #y[2])
end

warningAboutOldVersionNotShown = true

-- Try to fetch all texts only using the new lua API call. If this API is not available, return nil
function getAllTextsIfEfficient()
   local status, err_or_res = pcall(function () return app.getTexts("all") end)
   if status then
      -- If multiple grades are on the same page, make sure to read them from top to bottom
      table.sort(err_or_res, sortTexts)
      return err_or_res
   else
      if warningAboutOldVersionNotShown then
         app.openDialog("Warning: you are using an old xournal++ version that we barely support (does not support mis-ordered questions, can't skip already graded users, really slow, poorly tested, etc) hence we strongly recommend you to move to a more recent version. We would need v1.3.4, but as of april 2026 this is not yet released, so please install the nightly build v1.3.3+dev in the meantime. ", {"Continue"}, nil) -- This is not blocking, use callbacks otherwise
         warningAboutOldVersionNotShown = false
      end
      return nil
   end
end

function getAllTexts()
   -- This function only exists in a pull request of mine for now, if it does not exist
   -- we fallback to a dirty loop and print a warning
   local status, err_or_res = pcall(function () return app.getTexts("all") end)
   if status then
      -- If multiple grades are on the same page, make sure to read them from top to bottom
      table.sort(err_or_res, sortTexts)
      return err_or_res
   else
      local msg = "WARNING: we are falling back to a really inefficient solution because your installed xournalpp is too old. You should upgrade or be ready to wait maybe 30s on large documents."
      print(msg)
      app.openDialog(msg, {"Continue"}, nil) -- This is not blocking, use callbacks otherwise
      local texts = {}
      local docStructure = app.getDocumentStructure()
      local numPages = #docStructure.pages
      for i=1, numPages do
         app.setCurrentPage(i)
         local numLayers = #docStructure.pages[i].layers
         for j=1, numLayers do
            app.setCurrentLayer(j)
            local textsOnLayer = app.getTexts("layer")
            for k=1, #textsOnLayer do
               textsOnLayer[k].page = i
               textsOnLayer[k].layer = j
               table.insert(texts, textsOnLayer[k])
            end
         end
      end
      -- If multiple grades are on the same page, make sure to read them from top to bottom
      table.sort(texts, sortTexts)
      return texts
   end
end

-- provide allTexts if you have it, otherwise set it to nil and we will scrape the document to find it out
function extractTextsInPreamble(allTexts)
   local allTexts = allTexts or getAllTextsIfEfficient()
   if allTexts == nil then
      local currentPage = app.getDocumentStructure().currentPage
      local texts = {}
      local docStructure = app.getDocumentStructure()
      local numPages = #docStructure.pages
      for i=1, numPages do
         app.setCurrentPage(i)
         local numLayers = #docStructure.pages[i].layers
         local textsCurrentPage = {}
         for j=1, numLayers do
            app.setCurrentLayer(j)
            local textsOnLayer = app.getTexts("layer")
            for k=1, #textsOnLayer do
               if isStudentName(textsOnLayer[k].text) then
                  return texts
               end
               textsOnLayer[k].page = i
               textsOnLayer[k].layer = j
               table.insert(textsCurrentPage, textsOnLayer[k])
            end
         end
         for _,t in ipairs(textsCurrentPage) do
            table.insert(texts, t)
         end
      end
      app.setCurrentPage(currentPage)
      return texts
   else
      local res = {}
      for _,currText in ipairs(allTexts) do
         -- Try to check if new student (=starts with PREFIX_NAME)
         if string.sub(currText.text,1,#PREFIX_NAME) == PREFIX_NAME then
            break
         else
            table.insert(res, currText)
         end
      end
      return res
   end
end

-- provide allTexts only in efficient versions, otherwise set it to nil and we will scrape the document to find it out
function extractTextsCurrentStudent(currentPage, allTexts)
   local currentPage = currentPage or app.getDocumentStructure().currentPage
   if allTexts ~= nil then
      local res = {}
      for _,currText in ipairs(allTexts) do
         -- Try to check if new student (=starts with PREFIX_NAME)
         if string.sub(currText.text,1,#PREFIX_NAME) == PREFIX_NAME and currText.page <= currentPage then
            res = {}
         end
         if string.sub(currText.text,1,#PREFIX_NAME) == PREFIX_NAME and currText.page > currentPage then
            return res
         end
         table.insert(res, currText)
      end
      return res
   else
      -- First we go back until we find the current student
      local i = currentPage
      local isStudentPage = false
      local texts = {}
      local docStructure = app.getDocumentStructure()
      local numPages = #docStructure.pages
      repeat
         app.setCurrentPage(i)
         local numLayers = #docStructure.pages[i].layers
         for j=1, numLayers do
            app.setCurrentLayer(j)
            local textsOnLayer = app.getTexts("layer")
            for k=1, #textsOnLayer do
               textsOnLayer[k].page = i
               textsOnLayer[k].layer = j
               table.insert(texts, textsOnLayer[k])
               if isStudentName(textsOnLayer[k].text) then
                  isStudentPage = true
               end
            end
         end
         i = i - 1
      until (i == 0 or isStudentPage)
      -- Then we fetch pages after current page
      i = currentPage + 1
      isStudentPage = false
      if i <= numPages then
         repeat
            local textCurrentPage = {}
            app.setCurrentPage(i)
            local numLayers = #docStructure.pages[i].layers
            for j=1, numLayers do
               app.setCurrentLayer(j)
               local textsOnLayer = app.getTexts("layer")
               for k=1, #textsOnLayer do
                  textsOnLayer[k].page = i
                  textsOnLayer[k].layer = j
                  table.insert(textCurrentPage, textsOnLayer[k])
                  if isStudentName(textsOnLayer[k].text) then
                     isStudentPage = true
                  end
               end
            end
            if not isStudentPage then
               for _,t in ipairs(textCurrentPage) do
                  table.insert(texts, t)
               end
            end
            i = i + 1
         until (i > numPages or isStudentPage)
      end
      table.sort(texts, sortTexts)
      return texts
   end
end

-- Extracts a hash and a table of all reference students. Warning, this changes the current page, save it before if needed
function getReferenceStudents(allTextsInPreamble)
   local referenceStudentsHash = {}
   local referenceStudentsArray = {}
   for _, currText in ipairs(allTextsInPreamble) do
      -- Try to check if it is the list of all students (=starts with PREFIX_REF_STUDENTS)
      if string.sub(currText.text,1,#PREFIX_REF_STUDENTS) == PREFIX_REF_STUDENTS then
         local firstLine = 0
         for currLine in iterate_on_lines(currText.text) do
            if firstLine > 0 then
               if referenceStudentsHash[currLine] == nil then
                  table.insert(referenceStudentsArray, currLine)
                  referenceStudentsHash[currLine] = true
               end
            end
            firstLine = firstLine + 1
         end
      end
   end
   return referenceStudentsHash, referenceStudentsArray
end

-- Given a text, return an array-hash table grade[i] = questionName, and grade[questionName] = points
-- If grades is specified, modify the table directly
function extractGradesFromText(text, grades, extra, skipDuplicates)
   if grades == nil then
      grades = {}
   end
   local res = string.find(text, GRADE_SEP)
   if res ~= nil then
      -- We allow multiple grades separated by newlines
      for line in iterate_on_lines(text) do
         local res = string.find(line, GRADE_SEP)
         if res ~= nil then
            -- We trim white spaces
            local question = trim(string.sub(line, 1, res-1))
            local points = trim(string.sub(line, res + #GRADE_SEP, -1))
            if not skipDuplicates or grades[question] == nil then
               table.insert(grades, question)
               if extra == nil then
                  grades[question] = points
               else
                  grades[question] = { points = points }
                  for k,v in pairs(extra) do
                     grades[question][k] = v
                  end
               end
            end
         end
      end
   end
   return grades
end

-- extractCommentsFromText(text, questionToExtract) will extract the comments from text matching the
-- question "questionToExtract"
function extractCommentsFromText(text, questionToExtract, keepNewLines)
   local res = string.find(text, GRADE_SEP)
   local currentlyReadingComments = false
   local comments = nil
   if res ~= nil then
      -- We allow multiple grades separated by newlines
      for line in iterate_on_lines(text) do
         local res = string.find(line, GRADE_SEP)
         if res ~= nil then
            -- We trim white spaces
            local question = trim(string.sub(line, 1, res-1))
            if question == questionToExtract then
               currentlyReadingComments = true
            else
               currentlyReadingComments = false
            end
         else
            if currentlyReadingComments then
               if comments == nil then
                  comments = {""}
               end
               if line == "" then
                  table.insert(comments, "")
               else
                  local i = #(comments)
                  local c = comments[i]
                  comments[i] = c .. (c == "" and "" or (keepNewLines and "\n" or " ")) .. line
               end
            end
         end
      end
   end
   return comments   
end

-- Returns an array of grade names that is also an hashtable mapping grade names to their grades
-- Use ipairs to iterate since pairs will return each entry twice.
-- https://stackoverflow.com/questions/41417453/lua-print-table-keys-in-order-of-insertion
-- If allTextsInPreamble is nil we will get the texts
function getReferenceGrades(allTextsInPreamble)
   local allTextsInPreamble = extractTextsInPreamble(allTextsInPreamble) -- Make sure that only stuff in preamble is used
   local refGrades = {}
   for _,currText in ipairs(allTextsInPreamble) do
      -- extractGradesFromText modifies refGrades (side effects) hence this works:
      refGrades = extractGradesFromText(currText.text, refGrades)
   end
   return refGrades
end

-- refGrades is given by getReferenceGrades
function sortGrades(refGrades, gradeA, gradeB)
   -- Quadratic instead of linear, I can live with that given the size of the table and how often it is called
   -- (cleaner solution would involve building a reverse index...)
   -- Special case if gradeA == gradeB, otherwise we get an error about incorrect function
   if gradeA == gradeB then
      return false
   end
   -- Practical to specify a nil grade in gotoSmallestUncorrectedGrade that is smaller than any other grade
   if gradeA == nil then
      return true
   end
   if gradeB == nil then
      return false
   end
   for _,g in ipairs(refGrades) do
      if g == gradeA then
         return true
      elseif g == gradeB then
         return false
      end
   end
   -- The grades were not found in the references, so we sort them lexicographically for each dot-separated
   -- "column"
   gradeATable = split(gradeA, ".")
   gradeBTable = split(gradeB, ".")
   for i=1, math.min(#gradeATable, #gradeBTable) do
      if gradeATable[i] ~= gradeBTable[i] then
         -- If they are numbers we compare the numbers
         local a = tonumber(gradeATable[i]) 
         local b = tonumber(gradeBTable[i])
         if a and b then
            return a < b
         else
            return gradeATable[i] < gradeBTable[i] -- Sort lexicographically
         end
      end
   end
   if #gradeBTable > #gradeATable then
      return true
   else
      return false
   end
end


-- findReferenceForStudent("quick typed name") returns the possibly corrected new name, a number n of matches (1 means the name has been updated) and a warning error
function findReferenceForStudent(tmpCurrentStudent, referenceStudentsHash)
   local currentStudent = nil
   if referenceStudentsHash[tmpCurrentStudent] then
      return tmpCurrentStudent, 1, nil
   else
      -- We split the name and see if it the first or second etc column have
      -- exactly one match
      student_cols = split_student_name_in_columns(tmpCurrentStudent)
      local msg = nil
      local nb_matches = 0
      for _,c in ipairs(student_cols) do
         local matches = {}
         local best_match_for_col = nil
         for student,_ in pairs(referenceStudentsHash) do
            if string.find(normalizeLatin(student):lower(), normalizeLatin(c):lower()) then
               table.insert(matches, student)
               best_match_for_col = student
            end
         end
         if #matches == 1 then
            currentStudent = best_match_for_col
            nb_matches = 1
            break
         elseif #matches > 1 then
            msg = "WARNING: found multiple matches for student " .. tmpCurrentStudent .. " (" .. c .. "):"
            nb_matches = #matches
            for _,name in ipairs(matches) do
               msg = msg .. "\n- " .. name
            end
         end
      end
      -- We found no good match
      if currentStudent == nil then
         currentStudent = tmpCurrentStudent
         if msg then
            return currentStudent, nb_matches, msg
         else
            return currentStudent, 0, "WARNING: no matches found for the student " .. tmpCurrentStudent .. " in the reference list of students."
         end
      end
      return currentStudent, 1, nil
   end
end
function getCsvSymbolSum()
   local LANG = os.getenv("LANG")
   local lang = nil
   if LANG ~= nil then
      lang = string.sub(LANG .. "  ", 1, 2) -- Add spaces to ensure size is at least 2
   end
   if lang == "fr" then
      return "SOMME"
   elseif lang == "de" then
      return "SUMME"
   elseif lang == "es" then
      return "SUMA"
   else
      return "SUM"
   end
end

-- This function extracts a structured element (basically the exported YAML) that can be used to navigate etc
-- Mode may be nil (no raw grade conversion), 1 (grade as points) or 2 (grade as percentage.)
function extractYamlLikeStructure(allTexts, mode)
   local point_mode = 1 -- alias for the mode 1, easier to read
   local percent_formula_mode = 2 -- alias for the mode 2, easier to read
   local allTexts = allTexts or getAllTexts()
   local docStructure = app.getDocumentStructure()
   local numPages = #docStructure.pages

   -- Main structure that we will enrich. Type written like in typescript (yeah, doing typescript these days).
   local YAMLlike = {
      -- Questions found in the whole exam. Ordered via the bareme list if available and otherwise we try to order
      -- them appropriately (e.g. based on dots like 21.5 > 1.2, alphabetically if not numbers)
      -- {
      --   question: string, -- The name of the question
      --   max_grade?: string, -- If a bareme is present for this quesiton, this item contains the grade given in the bareme
      -- }[]
      questions = {},
      -- Map a column name (e.g. email...) to the **0-index** (most scripts exploiting this will be python I presume, let's make their life easy) of the element in name_columns.
      -- Record<string, integer>
      all_column_names = {},
      -- integer, final number of columns in student names.
      nb_columns = 0,
      -- integer: number of pages in the whole document
      document_nb_pages = numPages,
      -- Reference grades are present (i.e. grades are written before the first student)
      -- reference_grades_are_present: boolean
      reference_grades_are_present = false,
      -- Grade of students, ordered via the *students: list if available and in the order of appearance
      -- in the document otherwise.
      -- {
      --   name: string, -- Name of the student (after correction by *students:)
      --   name_columns: string[], -- Name decomposed into columns, we also include empty strings so that all students have the same number of columns
      --   exam_found: boolean, -- If an exam was found for this student
      --   pdf_file_name_export: string, -- Name of the PDF file that would be exported for this student (without folder name)
      --   pages: number[], -- List of all pages of the document that belong to this student.
      --   -- List of all grades/… for each question. They are listed in the exact same order (no skip)
      --   -- as the YAMLlike.questions field:
      --   questions: { 
      --     question: string, -- Name of the question
      --     found_grade: boolean, -- If a grade was found (possibly empty)
      --     empty_grade?: boolean, -- Only present when found_grade=true, says if the grade was empty
      --     grade_raw?: string, -- Raw string containing what the user typed (not available when found_grade is false)
      --     grade?: number, -- Grade, when convertible to a number and when exporting in either point or percentage mode (result will differ based on the mode)
      --     position: {page: number, x: number, y: number}, -- Position of the grade in the document
      --     comments?: string[], -- List of comments written below questions, when available
      --   }[]
      -- }[]
      students = {},
      -- Messages to display when finding unusual things
      warning_messages = {}, -- string[]
      -- Stores the settings configured via PREFIX_SETTING
      settings = { -- Record<string, string>
         removeNoGradeCells = "false",
         keepStudentsNoExam = "true",
         CsvAddStats = "true",
         CsvSymbolSum = getCsvSymbolSum(),
      },
   }
   -- allGrades[student][grade] = value;
   local allGrades = {}
   -- allGradePositions[student][grade] = {page: number, x: number, y: number};
   local allGradePositions = {}
   -- allComments[student][grade] = ["array of", "comments"];
   local allComments = {}
   -- studentInfo[student] = {
   --   pages: number[], -- Keep track of the pages in the document that belong to this user (list of pages allow multiple pages of a user to be spread across the document).
   -- }
   local studentInfo = {}
   -- If no student, it is the bareme, other grades may be expressible as a percentage of this value
   local bareme = "Max points"
   local currentStudents = { bareme }
   local currentStudentStartingPage = -1
   local tmpCurrentStudents = { bareme } -- Name before renaming them
   local stillParsingBareme = true -- To know if we are already reading student stuff
   -- We gather all questions by order of appearance
   local questionNamesHash = {} -- check efficiently if question already added
   -- Order questions properly 
   local questionNamesArray = {}
   -- Same for students
   local studentHash = {}
   local studentArray = {}
   -- Optionally, if we add at the beginning of the document a list (or multiple lists)
   -- of students called like *students: followed by a new line and
   -- students, one per line, then we will try to write the grades in
   -- this order (if a student appears in the reference but has no
   -- grade, an empty line will be added with the reference
   -- name). When a match is found, the reference name is kept. To
   -- find matches, since it is easy to make a mistake in a name, we
   -- read the name of the student currently graded, if an entry
   -- exactly match its name we pick it otherwise we separate it based
   -- on SEP_NAME, try to match the first column, if there is not
   -- exactly one match we try with the second etc.
   local referenceStudentsHash = {} -- This is simply a map "reference student name" -> true
   local studentWithExam = {} -- To know if a student got no grade because they have no exam at all or because we forgot to grade it
   local lastVisitedPage = 0
   local emptyPages = {} -- To print a warning if too many pages are empty (eg. forgot to correct one student because we forgot to write his name)
   -- We explore all pages of the document
   for _, currText in ipairs(allTexts) do
      -- Check if we forgot to annotate some pages
      if lastVisitedPage ~= currText.page then
         for i=lastVisitedPage+1,currText.page-1 do
            table.insert(emptyPages, i)
         end
         lastVisitedPage = currText.page
      end
      -- Try to check if it is the list of all students (=starts with PREFIX_REF_STUDENTS)
      if string.sub(currText.text,1,#PREFIX_REF_STUDENTS) == PREFIX_REF_STUDENTS then
         local firstLine = 0
         for currLine in iterate_on_lines(currText.text) do
            if firstLine == 0 then
               -- That's the first line, check if there are some column names (emails…)
               local restOfLine = trim(currLine:sub(#PREFIX_REF_STUDENTS+1))
               if restOfLine ~= "" then
                  local all_columns = split_student_name_in_columns(restOfLine)
                  for i, c in ipairs(all_columns) do
                     local col = trim(c)
                     if col ~= "" then
                        YAMLlike.all_column_names[col] = i - 1 -- We index from 0 to make python plugins life easier.
                     end
                  end
               end
            else
               -- This is a student
               referenceStudentsHash[currLine] = true
               allGrades[currLine] = allGrades[currLine] or {}
               allGradePositions[currLine] = allGradePositions[currLine] or {}
               if studentHash[currLine] == nil then
                  studentHash[currLine] = 1 -- Use it like a set based on a hash table
                  table.insert(studentArray,currLine)
               end
            end
            firstLine = firstLine + 1
         end
      end 
      -- Check if this is a setting (=starts with PREFIX_SETTING)
      if string.sub(currText.text,1,#PREFIX_SETTING) == PREFIX_SETTING then
         -- Allow multiple settings in the same box
         for line in iterate_on_lines(currText.text) do
            local res = string.find(line, "=")
            if res ~= nil then
               -- We trim white spaces
               local param = trim(string.sub(line, 1, res-1))
               local value = trim(string.sub(line, res + 1, -1))
               YAMLlike.settings[param] = value
            end
         end
      end
      -- Try to check if new student (=starts with PREFIX_NAME)
      if string.sub(currText.text,1,#PREFIX_NAME) == PREFIX_NAME then
         if stillParsingBareme and next(questionNamesArray) ~= nil then
            YAMLlike.reference_grades_are_present = true
         end
         stillParsingBareme = false
         -- We try to see if we find him in the list of reference students
         -- so we give him a temporary name until we know if it is in the list
         local tmpCurrentStudent = string.sub(currText.text,#PREFIX_NAME+1,-1)
         local currentStudent, _, errors = findReferenceForStudent(tmpCurrentStudent, referenceStudentsHash)
         if currText.page ~= currentStudentStartingPage then
            -- This is a new exam, we don't have two students with the same homework
            -- We update the studentInfo[currentStudent].pages position of the previous students
            -- WARNING: if you change this code, make sure to update the duplicate that deals with the last student
            -- at the end of the for loop (not super clean, but simple to reason)
            for i, previousStudent in ipairs(currentStudents) do
               if previousStudent ~= bareme then
                  studentInfo[previousStudent] = studentInfo[previousStudent] or {}
                  studentInfo[previousStudent].pages = studentInfo[previousStudent].pages or {}
                  for p = currentStudentStartingPage, currText.page-1 do
                     table.insert(studentInfo[previousStudent].pages, p)
                  end
               end
            end
            -- Then we reset the list of current students
            currentStudents = {}
            currentStudentStartingPage = currText.page
            tmpCurrentStudent = {}
         end
         table.insert(currentStudents, currentStudent)
         table.insert(tmpCurrentStudents, tmpCurrentStudent)
         if errors ~= nil then
            -- We print an error only if there is a reference list, otherwise meaningless
            if next(referenceStudentsHash) ~= nil then -- next(foo) == nil iff foo is empty
               table.insert(YAMLlike.warning_messages, errors)
            end
         end
         studentWithExam[currentStudent] = true
         allGrades[currentStudent] = allGrades[currentStudent] or {}
         allGradePositions[currentStudent] = allGradePositions[currentStudent] or {}
         if studentHash[currentStudent] == nil then
            studentHash[currentStudent] = 1 -- Use it like a set based on a hash table
            table.insert(studentArray,currentStudent)
         end
      end
      -- Then we check for new grades (they look like "1.2 ~> 100" depending on separator)
      local res = string.find(currText.text, GRADE_SEP)
      if res ~= nil then
         -- We allow multiple grades separated by newlines. Any line that comes after a grade is exported as a comment, newlines are replaced with white space
         -- but add an empty line to create a new comment (add them via rofi)
         local currentQuestionComment = nil
         for line in iterate_on_lines(currText.text) do
            local res = string.find(line, GRADE_SEP)
            if res ~= nil then
               -- We trim white spaces
               local question = trim(string.sub(line, 1, res-1))
               currentQuestionComment = question
               local points = trim(string.sub(line, res + #GRADE_SEP, -1))
               for i,currentStudent in ipairs(currentStudents) do
                  -- Create "Max points" if needed
                  if allGrades[currentStudent] == nil then
                     allGrades[currentStudent] = {}
                  end
                  if allGradePositions[currentStudent] == nil then
                     allGradePositions[currentStudent] = {}
                  end
                  if allGrades[currentStudent][question] then
                     local msg = "WARNING: the student " .. currentStudent
                     if tmpCurrentStudents[i] ~= currentStudent then
                        msg = msg .. " (aka " .. tmpCurrentStudents[i] .. ")"
                     end
                     msg = msg .. " has question '" .. question .. "' specified twice.\n"
                     table.insert(YAMLlike.warning_messages, msg)
                  end
                  allGrades[currentStudent][question] = points
                  allGradePositions[currentStudent][question] = {
                     page=currText.page,
                     x=currText.x,
                     y=currText.y
                  }
                  -- Maintain proper ordering
                  if questionNamesHash[question] == nil then
                     questionNamesHash[question] = 1 -- Use it like a set based on a hash table
                     table.insert(questionNamesArray,question)
                     -- Print warning if this question was not already added in the bareme
                     if not stillParsingBareme and YAMLlike.reference_grades_are_present then
                        table.insert(YAMLlike.warning_messages, "WARNING: the question '" .. question .. "' is not in the list of reference questions")
                     end
                  end
                  if studentHash[currentStudent] == nil then
                     studentHash[currentStudent] = 1 -- Use it like a set based on a hash table
                     table.insert(studentArray,currentStudent)
                  end
               end
            else
               if currentQuestionComment ~= nil then
                  local comment = trim(line)
                  for i,currentStudent in ipairs(currentStudents) do
                     if allComments[currentStudent] == nil then
                        allComments[currentStudent] = {}
                     end 
                     if allComments[currentStudent][currentQuestionComment] == nil then
                        allComments[currentStudent][currentQuestionComment] = {""}
                     end
                     if comment == "" then
                        table.insert(allComments[currentStudent][currentQuestionComment], "")
                     else
                        local i = #(allComments[currentStudent][currentQuestionComment])
                        local c = allComments[currentStudent][currentQuestionComment][i]
                        allComments[currentStudent][currentQuestionComment][i] = c .. (c == "" and "" or " ") .. comment
                     end                     
                  end
               end
            end
         end
      end
   end
   -- We update the studentInfo[currentStudent].pages position of the last students
   -- WARNING: if you change this code, make sure to update the duplicate that deals with the other students
   -- at the end of the for loop (not super clean, but simple to reason about)
   for i, previousStudent in ipairs(currentStudents) do
      if previousStudent ~= bareme then
         studentInfo[previousStudent] = studentInfo[previousStudent] or {}
         studentInfo[previousStudent].pages = studentInfo[previousStudent].pages or {}
         for p = currentStudentStartingPage, numPages do
            table.insert(studentInfo[previousStudent].pages, p)
         end
      end
   end   
   -- We re-order grades based on the reference grades etc
   local refGrades = getReferenceGrades(allTexts)
   table.sort(questionNamesArray, function (gradeA, gradeB) return sortGrades(refGrades, gradeA, gradeB) end)
   -- First, we check how many columns are configured in names, so that *:42__Alice__Foo
   -- creates 3 columns, one with the number 42, one with Alice, and one with Foo
   YAMLlike.nb_columns = (max_value(YAMLlike.all_column_names) or 0) + 1
   local SEP_NAME_REGEXP = SEP_NAME:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
   for i=1,#studentArray do
      YAMLlike.nb_columns = math.max(YAMLlike.nb_columns, #(split_student_name_in_columns(studentArray[i])))
   end
   -- We print the grade names
   for i=1,#questionNamesArray do
      table.insert(YAMLlike.questions, {
                      question  = questionNamesArray[i],
                      max_grade = (YAMLlike.reference_grades_are_present and allGrades[bareme][questionNamesArray[i]] ~= nil)
                         and allGrades[bareme][questionNamesArray[i]]
                         or nil
      })
   end
   -- We show the grades for each student
   local missing_grades_message = ""
   local missing_all_grades_message = ""
   local warning_cant_convert_to_grade = ""
   for i=1,#studentArray do
      local student = studentArray[i]
      if student ~= bareme then
         -- We cut student into multiple columns (ID, name…) if necessary
         local c = 0
         local student_cols = split_student_name_in_columns(student)
         local YAMLstudentToAdd = {
            name = student,
            name_columns = fill_array_until_size(student_cols, YAMLlike.nb_columns, ""),
            exam_found = studentWithExam[student] ~= nil,
            pdf_file_name_export = sanitizeFilename(student) .. ".pdf",
            pages = exam_found and studentInfo[student].pages or nil,
            questions = {},
         }
         local missing_grades_current_student = ""
         for j=1,#questionNamesArray do
            local YAMLQuestionToAdd = {}
            local gr = "NO GRADE"
            local question = questionNamesArray[j]
            local found_grade = false
            if allGrades[student][question] ~= nil then
               gr = allGrades[student][question]
               found_grade = true
            end
            if not found_grade then
               missing_grades_current_student = missing_grades_current_student .. (missing_grades_current_student == "" and "" or ", ") .. question
            end
            YAMLQuestionToAdd.question = question
            YAMLQuestionToAdd.found_grade = found_grade
            if found_grade then
               if gr == "" then
                  YAMLQuestionToAdd.empty_grade = true
               else
                  YAMLQuestionToAdd.empty_grade = false
               end
            end
            if found_grade then
               YAMLQuestionToAdd.grade_raw = gr
               YAMLQuestionToAdd.position = allGradePositions[student][question]
            end
            if mode == point_mode then -- For the bareme no need to write it this way
               if found_grade then
                  local gr_nb = tonumber(gr)
                  if gr_nb ~= nil then
                     YAMLQuestionToAdd.grade = gr
                  else
                     warning_cant_convert_to_grade = warning_cant_convert_to_grade .. "; student " .. question .. ", grade " .. gr
                  end
               end
            elseif mode == percent_formula_mode then
               if found_grade then
                  YAMLQuestionToAdd.grade_percent = gr
                  local gr_nb = tonumber(gr)
                  local bareme_nb = allGrades[bareme] ~= nil and allGrades[bareme][question] ~= nil and tonumber(allGrades[bareme][question]) or nil
                  if gr_nb ~= nil and bareme_nb ~= nil then
                     YAMLQuestionToAdd.grade = gr * bareme_nb / 100
                  else
                     local bareme_str = allGrades[bareme] ~= nil and allGrades[bareme][question] ~= nil and allGrades[bareme][question] or "missing reference grade"
                     warning_cant_convert_to_grade = warning_cant_convert_to_grade .. "; student " .. question .. ", grade " .. gr .. " = " .. bareme_str
                  end
               end
            end
            if allComments[student] ~= nil and allComments[student][question] ~= nil then
               for _, comment in ipairs(allComments[student][question]) do
                  if YAMLQuestionToAdd.comments == nil then
                     YAMLQuestionToAdd.comments = {}
                  end
                  table.insert(YAMLQuestionToAdd.comments, comment)
               end
            end
            table.insert(YAMLstudentToAdd.questions, YAMLQuestionToAdd)
         end
         if missing_grades_current_student ~= "" then
            if studentWithExam[student] then
               missing_grades_message = missing_grades_message .. (missing_grades_message == "" and "" or ", ") .. student .. " (" .. missing_grades_current_student .. ")"
            else
               missing_all_grades_message = missing_all_grades_message .. (missing_all_grades_message == "" and "" or ", ") .. student
            end
         end
         table.insert(YAMLlike.students, YAMLstudentToAdd)
      end
   end
   if warning_cant_convert_to_grade ~= "" then
      table.insert(YAMLlike.warning_messages, "WARNING: some grades in percentage could not be turned into grades in points: " .. warning_cant_convert_to_grade)
   end
   if missing_grades_message ~= "" then
      table.insert(YAMLlike.warning_messages, "WARNING: the following students are missing grades for the following questions: " .. missing_grades_message)
   end
   if missing_all_grades_message ~= "" then
      table.insert(YAMLlike.warning_messages, "WARNING: we found no exam for the following students: " .. missing_all_grades_message)
   end
   if #emptyPages > 0 then
      local msg = 'WARNING: ' .. #emptyPages .. ' pages were not annotated. Make sure you have not forgotten to grade some students (you can remove blank pages or add dummy text on blank pages to say you saw them). The list of pages with no annotation is as follows: '
      for x,p in ipairs(emptyPages) do
         msg = msg .. (x > 1 and ', ' or '') .. p
      end
      table.insert(YAMLlike.warning_messages, msg)
   end
   return YAMLlike
end


function extractYamlLikeStructureIfEfficient(allTexts)
   if allTexts == nil then
      allTexts = getAllTextsIfEfficient()
      if allTexts == nil then
         return nil
      end
   end
   return extractYamlLikeStructure(allTexts)
end

-- Goto the next student, and return -1 if no student is found and the page otherwise.
-- The "allTexts" string is optional, only use it to save time if  required 
function gotoNextStudent(allTexts, dontRecordHistory)
   if dontRecordHistory == nil then
      recordPositionHistory()
   end
   local allTexts = allTexts or getAllTextsIfEfficient()
   if allTexts == nil then
      print("Found no text")
      -- We go to the last question
      -- First we find the next student
      -- Not really efficient but only solution so far
      -- https://github.com/xournalpp/xournalpp/issues/7007
      local docStructure = app.getDocumentStructure()
      local numPages = #docStructure.pages
      for i=docStructure.currentPage + 1, numPages do
         -- We change page and search for texts on current page
         app.setCurrentPage(i)
         local numLayers = #docStructure.pages[i].layers
         for j=1, numLayers do
            app.setCurrentLayer(j)
            local textsOnLayer = app.getTexts("layer")
            for k=1, #textsOnLayer do
               -- Check if text starts with PREFIX_NAME
               if string.sub(textsOnLayer[k].text,1,#PREFIX_NAME) == PREFIX_NAME then
                  app.scrollToPage(i)
                  return i
               end
            end
         end
      end
      return -1
   else
      local docStructure = app.getDocumentStructure()
      local numPages = #docStructure.pages
      local currentPage = docStructure.currentPage
      for _,t in ipairs(allTexts) do
         if t.page > currentPage and isStudentName(t.text) then
            app.scrollToPage(t.page)
            return t.page
         end
      end
      app.openDialog("There is no more students!", {"Ok"}, nil)
      return -1
   end
end

-- Old version.
function gotoLastGradeOld() 
   -- We go to the last grade
   local docStructure = app.getDocumentStructure()
   local numPages = #docStructure.pages
   local pageLastGrade = docStructure.currentPage
   local posLastGradeX = 0
   local posLastGradeY = 0
   for i=docStructure.currentPage, numPages do
      -- We change page and search for texts on current page
      app.setCurrentPage(i)
      local numLayers = #docStructure.pages[i].layers
      -- Check first if we are not on a new student
      if i ~= docStructure.currentPage then
         for j=1, numLayers do
            app.setCurrentLayer(j)
            local textsOnLayer = app.getTexts("layer")
            for k=1, #textsOnLayer do
               -- Check if text starts with PREFIX_NAME
               for k=1, #textsOnLayer do
                  -- Check if text starts with PREFIX_NAME
                  if string.sub(textsOnLayer[k].text,1,#PREFIX_NAME) == PREFIX_NAME then
                     -- We finished to loop over the current student
                     scrollTo(pageLastGrade, posLastGradeX, posLastGradeY)
                     return pageLastGrade
                  end
               end
            end
         end
      end
      -- Otherwise we check for new grades
      for j=1, numLayers do
         app.setCurrentLayer(j)
         local textsOnLayer = app.getTexts("layer")
         for k=1, #textsOnLayer do
            -- Grades look like "1.2 := 100"
            local res = string.find(textsOnLayer[k].text, "=>")
            if res ~= nil then
               pageLastGrade = i
               posLastGradeX = textsOnLayer[k].x
               posLastGradeY = textsOnLayer[k].y
            end
         end
      end
   end
   scrollTo(pageLastGrade, posLastGradeX, posLastGradeY)
   return pageLastGrade
end

-- Helper to go to the "correct" grade for the current student (first empty grade if it directly follows the
-- last non-empty grade in ref (or if no ref is available) or last non-empty grade if none is found)
-- grades is a array+hash table, where the hash maps question name to an objects points/page/x/y
-- This returns two things: the grade to go to in format {points, page, x, y}, and the name of the highest already graded grade, maybe nil if none is graded
-- or nil, nil if grades is empty
-- TODO: this function is now outdated, extractYamlLikeStructureIfEfficient should be used instead.
function selectHighestGradeToGo(refGrades, grades)
   print(".. selectHighestGradeToGo", dump(grades))
   if refGrades == nil then
      refGrades = {}
   end
   if next(grades) == nil then
      return nil, nil
   end
   table.sort(grades, function (gradeA, gradeB) return sortGrades(refGrades, gradeA, gradeB) end)
   local lastGrade = nil
   local highestAlreadyGradedGrade = nil
   for _,g in ipairs(grades) do
      -- Go to the first empty grade
      if grades[g].points == "" then
         -- If the very first grade is empty, highestAlreadyGradedGrade hence needs a special case
         if highestAlreadyGradedGrade == nil then
            return grades[g], nil
         else
            -- Check if this grade is right after the highestAlreadyGradedGrade in the refGrades, as we don't want to jump to exercice 2
            -- if exercice 1 is not finished to be corrected. If ref grades are not available, we do jump to it
            if #refGrades == 0 then -- No ref grade available
               lastGrade = grades[g]
            else
               local i = index_in_array(refGrades, highestAlreadyGradedGrade)
               print(dump(refGrades), dump(highestAlreadyGradedGrade))
               if i == nil then
                  -- This grade is not in the reference grade, weird. Jump to it and print a warning.
                  local msg = "WARNING: we found a question name " .. highestAlreadyGradedGrade .. " page " .. lastGrade.page .. " that is not in the reference grade list at the beginning of the document. You should add it since otherwise we don't know if we should navigate to " .. highestAlreadyGradedGrade .. " or to " .. g .. " (current behavior)."
                  print(msg)
                  app.openDialog(msg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
                  lastGrade = grades[g]
               else
                  if #refGrades <= i then
                     -- This next grade is not in the reference grade, weird. Jump to it and print a warning.
                     local msg = "WARNING: we found a question name " .. g .. " page " .. grades[g].page .. " that is not in the reference grade list at the beginning of the document. You should add it since otherwise we don't know if we should navigate to " .. highestAlreadyGradedGrade .. " or to " .. g .. " (current behavior)."
                     print(msg)
                     app.openDialog(msg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
                     lastGrade = grades[g]
                  else
                     if refGrades[i+1] == g then
                        -- The next grade to grade is precisely the one we want to grade!
                        lastGrade = grades[g]
                     else
                        -- The next grade to grade is not yet g, so stay on the older grade
                     end
                  end
               end
            end
         end
         break
      else
         lastGrade = grades[g]
         highestAlreadyGradedGrade = g
      end
   end
   return lastGrade, highestAlreadyGradedGrade
end

-- Goto the first empty grade if it directly follows the last non-empty grade in ref (or if no ref is available)
-- or last non-empty grade if none is found, allTexts is optional
function gotoLastGrade(allTexts, dontRecordHistory)
   if dontRecordHistory == nil then
      recordPositionHistory()
   end
   local currentPage = app.getDocumentStructure().currentPage
   local allTexts = allTexts or getAllTextsIfEfficient()
   local gradesCurrentStudent = {}
   local refGrades = getReferenceGrades(allTexts) -- This changes the current page
   local grades = {}
   local gradePos = {}
   for _,currText in ipairs(extractTextsCurrentStudent(currentPage, allTexts)) do
      local res = string.find(currText.text, GRADE_SEP)
      if res ~= nil then
         -- We allow multiple grades separated by newlines
         for line in iterate_on_lines(currText.text) do
            local res = string.find(line, GRADE_SEP)
            if res ~= nil then
               -- We trim white spaces
               local question = trim(string.sub(line, 1, res-1))
               local points = trim(string.sub(line, res + #GRADE_SEP, -1))
               table.insert(grades, question)
               grades[question] = {points = points, page = currText.page, x = currText.x, y = currText.y}
            end
         end
      end
   end
   if #grades > 0 then
      local lastGrade, _ = selectHighestGradeToGo(refGrades, grades)
      scrollTo(lastGrade.page, lastGrade.x, lastGrade.y)
      return p
   end
end

function gotoLastGradeNextStudent(dontRecordHistory)
   gotoNextStudent(nil, dontRecordHistory)
   gotoLastGrade(nil, true)
end

-- Callback if the menu item is executed
function gotoLastGradeNextStudentAndSave()
   -- Not sure why, but print does not work with latest version (appimage), so let's
   -- debug by writting in a file
   -- file = io.open("debug.txt", "w")
   -- file:write("Hello world")
   app.activateAction("save")
   gotoLastGradeNextStudent()
   -- file:close()
end

gradeExamQuestionCurrentlyCorrected = nil

-- This goes to the smallest uncorrected grade in the whole exam. This way we skip students that we have already corrected
function gotoSmallestUncorrectedGrade()
   recordPositionHistory()
   
   local YAMLlike = extractYamlLikeStructureIfEfficient()
   if YAMLlike == nil then
      -- We don't implement it on the old API because it is just too inefficient
      gotoLastGradeNextStudent(true)
   else
      -- Check where to go
      local currentPageToGo, questionCurrentlyCorrected = (function () -- Fake nested break via anonymous function
            for i, q in ipairs(YAMLlike.questions) do
               -- Check if question q is graded for all students:
               for j, s in ipairs(YAMLlike.students) do
                  -- Only deal with students that have a written exam
                  if s.exam_found then
                     local sq = s.questions[i]
                     if not sq.found_grade or sq.empty_grade then
                        if YAMLlike.reference_grades_are_present and q.max_grade == nil then
                           app.openDialog("Weird, the question " .. q.question .. " is not part of the reference list of questions. Have you misspelled it? If not, add it to the reference list of questions.", {"Ok"}, nil)
                        end
                        if sq.position ~= nil then
                           return sq.position, q.question
                        else
                           -- First question is empty, go to first page of student
                           if i == 1 then
                              return {page = (s.pages or {0})[0] or 0, x = 0, y = 0}, q.question
                           else
                              -- We go to the previous question in the list.
                              -- Should never be nil, since the previous question should be found_grade and
                              -- not empty_grade
                              return s.questions[i-1].position, q.question
                           end 
                        end
                     end
                  end
               end
            end
            -- All questions are corrected… or reference grades are incomplete
            return {page = 0, x = 0, y = 0}, "?.?"
      end)()
      -- We go there
      scrollTo(currentPageToGo.page, currentPageToGo.x, currentPageToGo.y)
      -- Copy the grade in the clipboard
      if putCurrentGradeInClipboard then
         copyToClipboard(questionCurrentlyCorrected .. " " .. GRADE_SEP .. " ")
      end
      -- Print a message if we started correcting a new question
      if gradeExamQuestionCurrentlyCorrected ~= questionCurrentlyCorrected then
         local msg = ""
         if gradeExamQuestionCurrentlyCorrected == nil then
            msg = "This is the first question that you seem to be correcting in this session. "
            if putCurrentGradeInClipboard then
               msg = msg .. "We just copied in your clipboard a text '" .. questionCurrentlyCorrected .. " " .. GRADE_SEP .. "' that you can paste in a new text area next to the first question. Change '" .. questionCurrentlyCorrected .. "' so that it represents the number of the question that you are correcting now, and add after the arrow '~>' the point/percentage that you are giving to the student for this question (e.g. 1.1 ~> 2.5 to put 2.5 points to the question 1.1, or 1.1.1 ~> 100 to put 100% of the points when exporting in percentage mode)."
            else
               msg = msg .. "Now, add a new text area next to the question containing something like '1.1 ~> 4' (remove quotes) to attribute 4 points to the question 1.1. Depending on the export mode, the number will be interpreted as points or percentage of the maximum number of points so that '1.1 ~> 100' gives all points to this question."
            end
            msg = msg .. "\n\nIf the student mis-ordered the question and added a different question/exercise X before, add an empty grade for the question X, and we will get back to it when it will be the time to correct this question/exercise (no need to add an empty grade for all the questions of the exercise X, only the first misplaced question matters). Then, press F4 to move to the next student."
            if not YAMLlike.reference_grades_are_present then
               msg = msg .. "\n\nFor a better experience (especially when students write their questions in a bad ordering, or to be able to easily say that all remaining grades are 0 via 'Plugin > GradeExam > Put to clipboard all remaining grades to zero'), you certainly want to **add a list of reference grades** (same syntax) before the first exam on a new empty page to list all available questions and their maximum number of points."
            end
         else
            if questionCurrentlyCorrected == "?.?" then
               if YAMLlike.reference_grades_are_present then
                  msg = "You finished to correct all exams, congrats! Now time to export to CSV ;-) (make sure to read warnings to ensure you forgot nothing, and press ENTER to close the message if too many warnings are shown)"
               else
                  msg = "You finished to correct the question " .. gradeExamQuestionCurrentlyCorrected .. ", but we are not yet sure what is the name of the next question to correct (please, provide a reference list of questions on a blank page before the first exam (same syntax where points represent the maximum number of points) to help us to navigate properly. You can also just paste the current clipboard and change the ?.? with the name of the new question to correct, but be warned that reference questions are still helpful, especially when student has re-ordered questions or to put 0 to all remaining questions."
               end
            else
               if gradeExamQuestionCurrentlyCorrected ~= "?.?" then
                  msg = "You finished to correct the question " .. gradeExamQuestionCurrentlyCorrected .. " and you will now correct the question " .. questionCurrentlyCorrected .. "."
               end
            end
         end
         gradeExamQuestionCurrentlyCorrected = questionCurrentlyCorrected
         if msg ~= "" then
            app.openDialog(msg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
         end
      end
   end
end
function pasteZeroGrade()
    if gradeExamQuestionCurrentlyCorrected == nil then
         app.openDialog("No question currently getting corrected.", {"Ok"}, nil)
     else
         copyToClipboard(gradeExamQuestionCurrentlyCorrected .. " " .. GRADE_SEP .. " 0")
         app.activateAction("paste")
     end
end
function pasteEmptyGrade()
    if gradeExamQuestionCurrentlyCorrected == nil then
         app.openDialog("No question currently getting corrected.", {"Ok"}, nil)
     else
         copyToClipboard(gradeExamQuestionCurrentlyCorrected .. " " .. GRADE_SEP .. " ")
         app.activateAction("paste")
     end
end
-- Only works right after gotoNextUncorrectedGrade since it uses the value currently in the clipboard
function pasteMaxGrade()
    if gradeExamQuestionCurrentlyCorrected == nil then
         app.openDialog("No question currently getting corrected.", {"Ok"}, nil)
     else
         app.activateAction("paste")
     end
end

function gotoSmallestUncorrectedGradeAndSave()
   app.activateAction("save")
   gotoSmallestUncorrectedGrade()
end

-- mode = 1 is just copy/paste grades as it
-- mode = 2 is write a percent formula based on the max grade
function generateCSV(mode)
   local point_mode = 1 -- alias for the mode 1, easier to read
   local percent_formula_mode = 2 -- alias for the mode 2, easier to read

   local YAMLlike = extractYamlLikeStructure(nil, mode)
   
   -- First we save the YAML file
   local yml = string.gsub(app.getDocumentStructure().xoppFilename, "%.xopp$", "") .. "_grades_with_comments.yml"
   ymlFile = io.open(yml, "w")
   ymlFile:write(to_yaml(YAMLlike))
   ymlFile:close()
   -- We determine the name of the file to write grades
   local csv = string.gsub(app.getDocumentStructure().xoppFilename, "%.xopp$", "") .. "_grades.csv"
   file = io.open(csv, "w")
   
   -- Then, we write the logs
   local logs = string.gsub(app.getDocumentStructure().xoppFilename, "%.xopp$", "") .. "_grades_log.txt"
   logfile = io.open(logs, "w")
   local logMsg = "The CSV file (based on " .. #filter(YAMLlike.students, function (s) return s.exam_found end) .. " corrected exams) has been saved in " .. csv .. ". Make sure to import it with the English locale in Libre Office Calc or numbers with decimals won't be imported properly." .. (mode == percent_formula_mode and " Also make sure to import the CSV with 'Evaluate formulas' or the formulas will not be evaluated." or "")
   if #YAMLlike.warning_messages > 0 then
      logMsg = logMsg .. "\n\nDuring the production of the CSV file, we found the following warnings  (**press ENTER to dismiss this message** in case it is so long that you can\'t see the OK button, see " .. get_file_name(logs) .. " for the full logs):"
      for _,w in ipairs(YAMLlike.warning_messages) do
         logMsg = logMsg .. "\n\n" .. w
      end
   end
   print(logMsg .. '\n')
   logfile:write(logMsg)
   logfile:close()
   
   -- We write the question names in the CSV
   file:write("Questions")
   for i=2,YAMLlike.nb_columns do
      -- Space for student names
      file:write(CSV_SEP)
   end
   for i, q in ipairs(YAMLlike.questions) do
      file:write(CSV_SEP)
      file:write(q.question)
   end
   if YAMLlike.settings.CsvAddStats ~= "false" then
      file:write(CSV_SEP)
      file:write("Total")
   end   
   file:write("\n")
   -- We write the bareme if present in the CSV
   if YAMLlike.reference_grades_are_present or mode == percent_formula_mode then
      file:write("Points")
      -- Space for student names
      for i=2,YAMLlike.nb_columns do
         file:write(CSV_SEP)
      end
      for i, q in ipairs(YAMLlike.questions) do
         file:write(CSV_SEP)
         file:write(q.max_grade or "???")
      end
      if YAMLlike.settings.CsvAddStats ~= "false" then
         file:write(CSV_SEP)
         file:write("=" .. YAMLlike.settings.CsvSymbolSum .. "(" .. int_to_spreadsheet_col(1 + YAMLlike.nb_columns) .. "2:" .. int_to_spreadsheet_col(#YAMLlike.questions + YAMLlike.nb_columns) .. "2)")
      end
      
      
      file:write("\n")
   end

   -- We show the grades for each student
   for i, s in ipairs(YAMLlike.students) do
      if YAMLlike.settings.keepStudentsNoExam ~= "false" or s.exam_found then
         -- Write the student name (columns)
         for c, col in ipairs(s.name_columns) do
            if c > 1 then
               file:write(CSV_SEP)
            end
            file:write(col)
         end
         -- Write the grades
         for j, q in ipairs(s.questions) do
            file:write(CSV_SEP)
            local grade_to_write = ""
            if q.found_grade and not q.empty_grade then
               grade_to_write = q.grade_raw
            else
               if YAMLlike.settings.removeNoGradeCells ~= "true" then
                  grade_to_write = "NO GRADE"
               end
            end
            if mode ~= percent_formula_mode then
               if YAMLlike.settings.removeNoGradeCells == "true" and q.found_grade == false then
                  -- We write nothing if no grade is given
               else
                  file:write(grade_to_write)
               end
            else
               if YAMLlike.settings.removeNoGradeCells == "true" and q.found_grade == false then
                  -- We write nothing if no grade is given
               else
                  file:write("=" .. (grade_to_write) .. "*" .. int_to_spreadsheet_col(j + YAMLlike.nb_columns) .. "2/100")
               end            
            end
         end
         if YAMLlike.settings.CsvAddStats ~= "false" then
            file:write(CSV_SEP)
            local line = 1 + i
            if YAMLlike.reference_grades_are_present or mode == percent_formula_mode then
               line = line + 1
            end
            file:write("=" .. YAMLlike.settings.CsvSymbolSum .. "(" .. int_to_spreadsheet_col(1 + YAMLlike.nb_columns) .. line .. ":" .. int_to_spreadsheet_col(#YAMLlike.questions + YAMLlike.nb_columns) .. line .. ")")
         end
         file:write('\n')
      end
   end
   file:close()
   -- We show the logs to the user
   app.openDialog(logMsg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
end


-- mode = 1 is just copy/paste grades as it
-- mode = 2 is write a percent formula based on the max grade
function debug()
   print("STarting debug")
   -- Not sure why, but print does not work with latest version (appimage), so let's
   -- debug by writting in a file
   -- logfile = io.open("debug.txt", "w")
   -- logfile:write("COucou")
   -- local textsOnLayer = app.getTexts("all")
   -- print(dump(textsOnLayer))
   -- textsOnLayer = app.getTexts("page")
   -- print(dump(textsOnLayer))
   -- logfile:write(dump(textsOnLayer))
   -- logfile:close()
   -- print(dump(app.getTexts("selection")))
   -- app.setCurrentPage(30)
   -- app.scrollToPage(30)
   -- I want to center the view on this new text:
   -- app.addTexts({texts={{
   --                     text="Hello World",font={name="Noto Sans Mono Medium", size=8.0},color=0x1259b9,x = 30.38,y = 735.35
   -- }}})
   -- app.refreshPage() -- Hope it helps, but no. At least text is written.
   -- local zoom = app.getZoom()
   -- app.setZoom(1)
   -- app.scrollToPos(30.38, 735.35) -- Absolute mode.
   -- app.setZoom(zoom)
   local x = extractYamlLikeStructure()
   print(to_yaml(x))
end

-- Automatically export

function sanitizeFilename(filename)
   filename = filename:gsub(' | ', '__')
   filename = filename:gsub('[|\t]', '__')
   filename = filename:gsub(' ', '_')
   filename = filename:gsub('[/\\#%&{}<>*?$!\'":@+`|=]', '')
   return filename
end

-- Check if a file or directory exists in this path
-- https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
function exists(file)
   local ok, err, code = os.rename(file, file)
   if not ok then
      if code == 13 then
         -- Permission denied, but it exists
         return true
      end
   end
   return ok, err
end

function exportPdf()
   if exists(FOLDER_EXPORT) then
      if isUnix() then
         os.execute("rm --recursive \"" .. FOLDER_EXPORT .. "\"")
      else
         os.execute("rmdir /S /Q " .. FOLDER_EXPORT) -- quotes can disturb windows I think... Don't put spaces in this folder
      end
   end
   os.execute("mkdir " .. FOLDER_EXPORT)
   local allTexts = getAllTexts()
   -- We add a dummy user at the end or the last user will not be exported properly
   table.insert(allTexts, {
      text = PREFIX_NAME .. " DUMMY USER";
      page = #(app.getDocumentStructure().pages) + 1
   })
   local allTextsInPreamble = extractTextsInPreamble(allTexts)
   local referenceStudentsHash, referenceStudentsArray = getReferenceStudents(allTextsInPreamble)
   local start = -1
   local currStudents = {} -- We can export to multiple students sharing the same exam (eg homework)
   for _,currText in ipairs(allTexts) do
      -- Try to check if new student (=starts with PREFIX_NAME)
      local maybeName = isStudentName(currText.text)
      if maybeName ~= nil then
         -- Extract the potential reference name (we show no warnings if none is found,
         -- export to CSV first if you care about warnings)
         local name, nb_matches, _ = findReferenceForStudent(maybeName, referenceStudentsHash)
         --
         if start < currText.page then -- We finished to parse the previous user, let's render
            if start >= 1 then -- Previous user is not preamble
               for _,prevStudent in ipairs(currStudents) do
                  local filename = FOLDER_EXPORT .. package.config:sub(1,1) .. sanitizeFilename(prevStudent) .. ".pdf"
                  print("Exporting " .. filename .. "(" .. start .. "-" .. currText.page-1 .. ")")
                  app.export({outputFile = filename, range = start .. "-" .. currText.page-1})
               end
            end
            currStudents = { }
            start = currText.page
         end
         table.insert(currStudents, name)
      end
   end
   local msg = "Exported all files in folder " .. FOLDER_EXPORT
   print(msg)
   app.openDialog(msg, {"OK"}, nil) -- This is not blocking, use callbacks otherwise
end

function rofiLikeSelect(listOfTexts)
   -- TODO: I heard that this might not work on windows?
   local file = os.tmpname()
   local f = io.open(file, "w")
   for _,student in ipairs(listOfTexts) do
      f:write(student .. "\n")
   end
   local execFile = nil
   local currentOs = getOS()
   local cmd = ""
   if os.getenv("GRADEEXAM_LIST_CMD") ~= nil then
      cmd = os.getenv("GRADEEXAM_LIST_CMD")
   else
      if currentOs == "windows" then
         -- https://github.com/JerwuQu/wlines
         cmd = "wlines.exe"
      elseif currentOs == "darwin" then
         -- https://github.com/chipsenkbeil/choose
         cmd = "choose"
      else
         cmd = "rofi -dmenu -i"
      end
   end
   if currentOs == "windows" then
      -- I think that windows does not like quotes, as it may interpret them as part of the name...
      execFile = io.popen("type " .. file .. " | " .. cmd .. " 2> gradeExam.log", 'r')
   else
      execFile = io.popen("cat \"" .. file .. "\" | " .. cmd .. " 2> gradeExam.log", 'r')
   end
   local resultRofi = trimNewLines(execFile:read('*a') or "")
   local ret = execFile:close()
   f:close()
   os.remove(file)
   local errorHandle = io.open("gradeExam.log", "r")
   local errorStr = trimNewLines(assert(errorHandle:read('*a')))
   errorHandle:close()
   os.remove("gradeExam.log")
   return resultRofi, ret, errorStr
end

-- Set the student of the current page based on the reference file
function createStudent()
   recordPositionHistory()
   local allTexts = getAllTextsIfEfficient()
   local allTextsInPreamble = extractTextsInPreamble(allTexts)
   local referenceStudentsHash, referenceStudentsArray = getReferenceStudents(allTextsInPreamble)
   if next(referenceStudentsArray) == nil then
      local msg = "Error: This function helps to add students when an already existing 'reference' list of students is provided (e.g. via a spreadsheet that you need to fill, it helps to quickly type student names, avoid typo, and to sort students correctly when exporting). So far **we found no such reference list**. So two options:\n\n 1. If you have no such list (or if you will get it only later), simply create on the first page of each student a new text area containing *:student|name where | (you can also use TAB instead of |) separates the various columns to export, like student number ID|first name|last name. These columns will also help to match the student with a reference template if you add one later, by trying to check for each column of the name you typed if there exists a unique student with this text in the reference list.\n\n2. Or you already have a reference list of students, so you can create the reference list yourself: create a new text area in an empty page at the beginning of the document (just create a new empty page if none is present), write *students: on the first line, and on the next lines just copy/paste the list of names from your template spreadsheet (i.e. one name per line, columns separated by TABS or |) into a text area. Then try again to call this function!"
      print(msg)
      app.openDialog(msg, {"OK"}, nil) -- This is not blocking, use callbacks otherwise
      return
   end
   -- remove already assigned students from rofi
   if allText ~= nil then
    for _,currText in ipairs(allTexts) do
       local maybeName = isStudentName(currText.text)
       if maybeName ~= nil then
           local i = index_in_array(referenceStudentsArray, maybeName)
           if i ~= nil then
               table.remove(referenceStudentsArray, i)
           end
       end
    end
   end
   --
   local selectedStudent, ret, errorStr = rofiLikeSelect(referenceStudentsArray)
   if referenceStudentsHash[selectedStudent] == nil then
      local msg = "An error occurred '" .. errorStr .. "' while trying to get the student. Make sure that you have rofi installed (linux), choose (MacOS https://github.com/chipsenkbeil/choose) or to add wlines.exe (windows, https://github.com/JerwuQu/wlines) in your PATH. Alternatively, you can specify a different program by setting the GRADEEXAM_LIST_CMD environment variable, or you can also simply add a text field *:student|name (adding multiple columns, e.g. for ID, first name, last name… via TAB or |) at the beginning of each student exam. These columns are needed to match with the reference list when exporting: we will automatically try to guess the proper name of the student by trying to search if a unique student matches this text in the reference list."
      print(msg)
      app.openDialog(msg, {"OK"}, nil) -- This is not blocking, use callbacks otherwise
      return
   else
      app.addTexts({texts={{text="*:" .. selectedStudent, font={name="Noto Sans Mono Medium", size=8.0}, color=0xFF0000, x=10, y=10}}})
      app.refreshPage()
   end
end

function allRemainingGradesToZeroInClipboard()
   local allTexts = getAllTextsIfEfficient()
   local textsCurrentStudent = extractTextsCurrentStudent(nil, allTexts)
   local refGrades = getReferenceGrades(allTexts)
   local refGradesAvailable = true
   if #refGrades == 0 then
      -- If refGrades are not available, we still try to generate some based on already written grades
      refGradesAvailable = false
      refGrades = {}
      for _,currentText in ipairs(allTexts) do
         extractGradesFromText(currentText.text, refGrades, nil, true)
      end
      table.sort(refGrades, function (gradeA, gradeB) return sortGrades({}, gradeA, gradeB) end)
   end
   local gradesCurrentStudent = {}
   for _,currentText in ipairs(textsCurrentStudent) do
      extractGradesFromText(currentText.text, gradesCurrentStudent)
   end
   local strToPaste = ""
   for _,question in ipairs(refGrades) do
      if gradesCurrentStudent[question] == nil then
         strToPaste = strToPaste .. (strToPaste ~= "" and "\n" or "") .. question .. " " .. GRADE_SEP .. " 0"
      end
   end
   copyToClipboard(strToPaste)
   app.activateAction("paste")
end

-- #### PDF manipulation


-- Execute python script (in string). Set optional dont_escape to true if you don't want to escape
-- Returns the return code and stderr+stdout
function runPythonScript(script, args, dont_escape)
   local script_path = os.tmpname()
   local script_h = io.open(script_path, "w")
   script_h:write(script)
   script_h:close()
   local escaped_arg_str = ""
   -- Fairly naive escaping I think, check if it works on windows as I think to remember that it deals weirdly with quotes
   for _,arg in ipairs(args) do
      if not dont_escape then
         arg = " \"" .. string.gsub(arg, "\"", "\\\"") .. "\""
      end
      escaped_arg_str = escaped_arg_str .. arg
   end
   execFile = io.popen("python3 " .. script_path .. " " .. escaped_arg_str .. " 2>&1", 'r')
   local stderr_and_out = execFile:read('*a')
   local ret = execFile:close()
   os.remove(script_path)
   return ret, stderr_and_out
end 

-- Split a a3 book into a4 pages (paysage)
function unbookPDF(mode)
   local portrait = mode == 2
   local script = [[
#!/usr/bin/env python3
import argparse
from pypdf import PdfReader, PdfWriter, Transformation
import sys
import os

def split_page(page):
    x0, y0 = page.mediabox.lower_left
    x1, y1 = page.mediabox.upper_right
    w = x1 - x0
    h = y1 - y0

    halves = []

    # LEFT HALF
    left_page = page.__class__.create_blank_page(width=w/2, height=h)
    left_transformation = Transformation().translate(tx=-x0, ty=-y0)
    left_page.merge_transformed_page(page, left_transformation)
    halves.append(left_page)

    # RIGHT HALF
    right_page = page.__class__.create_blank_page(width=w/2, height=h)
    right_transformation = Transformation().translate(tx=-(x0 + w/2), ty=-y0)
    right_page.merge_transformed_page(page, right_transformation)
    halves.append(right_page)

    return halves


def unbook(input_pdf, output_pdf, portrait=False):
    reader = PdfReader(input_pdf)
    writer = PdfWriter()

    pages = []

    even = False
    for page in reader.pages:
        if portrait:
            page.rotation = (page.rotation + (-90 if even else 90)) % 360
            even = not even
        if page.rotation != 0:
            page.transfer_rotation_to_content()
        halves = split_page(page)
        pages.extend(halves)

    # Reorder [D, A, B, C] → [A, B, C, D]
    for i in range(0, len(pages), 4):
        block = pages[i:i+4]
        if len(block) != 4:
            raise Exception("Number of pages is not a multiple of 4")

        for j in [1, 2, 3, 0]:
            writer.add_page(block[j])

    with open(output_pdf, "wb") as f:
        writer.write(f)


def main():
    parser = argparse.ArgumentParser(
                    prog='Unbook',
                    description='Unbook an A3 booklet into A4')
    parser.add_argument('--portrait', action='store_true')
    parser.add_argument('INPUT_PDF')
    parser.add_argument('OUTPUT_PDF', nargs='?', default=None)
    args = parser.parse_args()
    if args.OUTPUT_PDF == None:
        args.OUTPUT_PDF = os.path.splitext(args.INPUT_PDF)[0] + "_unbook.pdf"
    unbook(args.INPUT_PDF, args.OUTPUT_PDF, portrait=args.portrait)
    print("Generated pdf:", args.OUTPUT_PDF)

if __name__ == "__main__":
    main()
   ]]
   local pdfBackgroundFilename = app.getDocumentStructure().pdfBackgroundFilename
   local args = {pdfBackgroundFilename}
   if portrait then
      table.insert(args, "--portrait")
   end 
   local ret, msg = runPythonScript(script, args)
   if not ret then
      msg = "It seems like an error occurred, this command requires python hence make sure to install python and the pypdf python library by typing 'python3 -m pip install pypdf' in a terminal (cmd on Windows). Error details:\n\n" .. msg
   end
   print(msg .. '\n')
   app.openDialog(msg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
end

-- Merge all PDFs in the current folder into a single file
function mergePDF(mode)
   local script = [[
#!/usr/bin/env python3
from pypdf import PdfWriter
from PIL import Image, ImageOps
import sys
import os
from pathlib import Path
import io

IMAGE_EXTS = (".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff")

# A4 size in points (1 pt = 1/72 inch)
A4_WIDTH_PT = 595
A4_HEIGHT_PT = 842

def image_to_pdf_bytes(img_path, mode="exif"):
    img = Image.open(img_path)

    # Fix EXIF rotation
    img = ImageOps.exif_transpose(img)

    # Convert to RGB
    if img.mode != "RGB":
        img = img.convert("RGB")

    w_px, h_px = img.size

    print("mode", mode, w_px, h_px)
    # Force portrait
    if mode == "portrait" and w_px > h_px:
        img = img.rotate(90, expand=True)
        w_px, h_px = img.size
    if mode == "landscape" and w_px < h_px:
        img = img.rotate(90, expand=True)
        w_px, h_px = img.size

    # Compute scale so image "fits like A4"
    scale = min(A4_WIDTH_PT / w_px, A4_HEIGHT_PT / h_px)

    # Save image as PDF with controlled DPI
    pdf_bytes = io.BytesIO()

    # DPI controls physical size → match our scale
    dpi = 72 / scale

    img.save(pdf_bytes, format="PDF", resolution=dpi)
    pdf_bytes.seek(0)

    return pdf_bytes

def merge(input_files=None, output_pdf=None, mode="portrait"):
    writer = PdfWriter()

    if not input_files:
        input_files = sorted(os.listdir("."))  # deterministic order

    if not output_pdf:
        output_pdf = "all_exams/all_exams.pdf"

    output_pdf = os.path.abspath(output_pdf)
    Path(os.path.dirname(output_pdf)).mkdir(parents=True, exist_ok=True)

    for f in input_files:
        if f.lower().endswith(".pdf"):
            writer.append(f)

        elif f.lower().endswith(IMAGE_EXTS):
            pdf_bytes = image_to_pdf_bytes(f, mode)
            writer.append(pdf_bytes)

        else:
            continue  # ignore other files

    with open(output_pdf, "wb") as out:
        writer.write(out)

    return output_pdf

def main():
    if len(sys.argv) == 1:
        output_pdf = merge()
        print(f"The merged PDF has been generated in {output_pdf}")
    elif len(sys.argv) == 2:
        if sys.argv[1] not in ["portrait", "landscape", "exif"]:
            print(f"The mode {sys.argv[1]} is not supported (must be portrait, landscape, or exif)")
            exit(1)
        output_pdf = merge(mode=sys.argv[1])
        print(f"The merged PDF has been generated in {output_pdf} in mode {sys.argv[1]}")
    else:
        print("Usage: python3 merge.py")


if __name__ == '__main__':
    main()
]]
   local modeP = "portrait"
   if mode == 1 then
      modeP = "portrait"
   end
   if mode == 2 then
      modeP = "landscape"
   end
   if mode == 3 then
      modeP = "exif"
   end   
   local ret, msg = runPythonScript(script, {modeP})
   if not ret then
      msg = "It seems like an error occurred, this command requires python hence make sure to install python and the pypdf python library by typing 'python3 -m pip install pypdf' in a terminal (cmd on Windows). Error details:\n\n" .. msg
   end
   print(msg .. '\n')
   app.openDialog(msg, {"Ok"}, nil) -- This is not blocking, use callbacks otherwise
end

function addComment()
   local allTexts = getAllTextsIfEfficient()
   if allTexts == nil then
      app.openDialog("Please upgrade your xournal++ to nightly or v1.3.4 if it is already published. We do not support adding comments automatically in prior versions, but you can still write them manually by adding texts on new lines right after your grade.", {"Ok"}, nil)
   else
      if gradeExamQuestionCurrentlyCorrected == nil then
         app.openDialog("Please call '1st uncorrected grade all doc & save' at least once to let us know which grade we are correcting now, or manually add comments after a new line right after your grades.", {"Ok"}, nil)
      else
         local allCommentsForThisQuestion = {}
         for _,currentText in ipairs(allTexts) do
            print(dump(currentText))
            local comments = extractCommentsFromText(currentText.text, gradeExamQuestionCurrentlyCorrected, true)
            if comments ~= nil then
               for _, x in ipairs(comments) do
                  table.insert(allCommentsForThisQuestion, x)
               end
            end
         end
         if #allCommentsForThisQuestion > 0 then
            -- Remove newlines in rofi select or it thinks it is two different entries
            table.sort(allCommentsForThisQuestion)
            local allCommentsForThisQuestionNoNewLines = {}
            local previousComment = nil
            for _, x in ipairs(allCommentsForThisQuestion) do
               local nnl = trim(x:gsub("\n", " "))
               if previousComment == nil or nnl ~= previousComment then
                   table.insert(allCommentsForThisQuestionNoNewLines, {1, nnl, x})
                   previousComment = nnl
               else
                   local n = #allCommentsForThisQuestionNoNewLines
                   local nocc, nnl, wnl = table.unpack(allCommentsForThisQuestionNoNewLines[n])
                   allCommentsForThisQuestionNoNewLines[n] = table.pack(nocc+1, nnl, wnl)
               end
            end
            table.sort(allCommentsForThisQuestionNoNewLines, compareComments)
            local allCommentsSorted = {}
            for _,x in ipairs(allCommentsForThisQuestionNoNewLines) do
                table.insert(allCommentsSorted,x[2])
            end
            local resultRofi, ret, errorStr = rofiLikeSelect(allCommentsSorted)
            if not ret then
               app.openDialog("An error occured when adding comments (" .. errorStr .. ").  Make sure that you have rofi installed (linux), choose (MacOS https://github.com/chipsenkbeil/choose) or to add wlines.exe (windows, https://github.com/JerwuQu/wlines) in your PATH. Otherwise, just add comments manually by adding an empty line and your comment after any grade.", {"Ok"}, nil)
            else
               -- TODO: detect that a text is already present and change directly the text accordingly
               -- local i = index_in_array(allCommentsSorted, trim(resultRofi))
               for i, x in ipairs(allCommentsForThisQuestionNoNewLines) do
                   if x[2] == trim(resultRofi) then
                      print(i, resultRofi, x[3])
                      copyToClipboard('\n' .. x[3])
                      break
                  end
               end
            end
         end
      end
   end
   app.activateAction("paste")
end


function copyAllSettings()
   local YAMLlike = extractYamlLikeStructure()
   local s = PREFIX_SETTING .. "\n"
   for k, v in pairs(YAMLlike.settings) do
      s = s .. k .. "=" .. v .. "\n"
   end
   copyToClipboard(s)
end
