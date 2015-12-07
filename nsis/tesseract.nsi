; (C) Copyright 2010, Sergey Bronnikov
; (C) Copyright 2010-2012, Zdenko Podobný
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

SetCompressor /FINAL /SOLID lzma
SetCompressorDictSize 32

; Settings which normally should be passed as command line arguments.
!ifndef SRCDIR
!define SRCDIR .
!endif
!ifndef VERSION
!define VERSION 3.05-dev
!endif

!define PRODUCT_NAME "Tesseract-OCR"
!define PRODUCT_VERSION "${VERSION}"
!define PRODUCT_PUBLISHER "Tesseract-OCR community"
!define PRODUCT_WEB_SITE "https://github.com/tesseract-ocr/tesseract"
; FIXME
!define FILE_URL "http://tesseract-ocr.googlecode.com/files/"
!define GITHUB_RAW_FILE_URL "https://raw.githubusercontent.com/tesseract-ocr/tessdata/master"

!ifdef CROSSBUILD
!addincludedir ${SRCDIR}\nsis\include
!addplugindir ${SRCDIR}\nsis\plugins
!ifdef SHARED
!define APIDIR "../api/.libs"
!else
!define APIDIR "../api"
!endif
!define TRAININGDIR "../training"
!else
!define APIDIR "LIB_Release"
!define TRAININGDIR "LIB_Release"
!endif

# General Definitions
Name "${PRODUCT_NAME} ${VERSION} for Windows"
Caption "Tesseract-OCR ${VERSION}"
!ifndef CROSSBUILD
BrandingText /TRIMCENTER "(c) 2010-2012 Tesseract-OCR "
!endif

!define REGKEY "SOFTWARE\${PRODUCT_NAME}"
; HKLM (all users) vs HKCU (current user) defines
!define env_hklm 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define env_hkcu 'HKCU "Environment"'

# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Admin
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME MultiUserInstallMode
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR ${PRODUCT_NAME}
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUE "Path"

# MUI Symbol Definitions
!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-blue-full.ico"
!define MUI_FINISHPAGE_LINK "Tesseract on GitHub"
!define MUI_FINISHPAGE_LINK_LOCATION "https://github.com/tesseract-ocr/tesseract"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_FINISHPAGE_SHOWREADME "notepad $INSTDIR\doc\README"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION ShowReadme
!define MUI_LICENSEPAGE_CHECKBOX
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGKEY}
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER ${PRODUCT_NAME}
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_WELCOMEPAGE_TITLE_3LINES

# Included files
!include MultiUser.nsh
!include Sections.nsh
!include MUI2.nsh
!include EnvVarUpdate.nsh
!include LogicLib.nsh
!include winmessages.nsh # include for some of the windows messages defines

# Variables
Var StartMenuGroup
Var PathKey
; Define user variables
Var OLD_KEY

# Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${SRCDIR}\COPYING"
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!ifdef VERSION
  Page custom PageReinstall PageLeaveReinstall
!endif
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuGroup
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Languages
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Slovak"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SpanishInternational"

# Installer attributes
ShowInstDetails show
InstProgressFlags smooth colored
XPStyle on
SpaceTexts
CRCCheck on
InstProgressFlags smooth colored
CRCCheck On  # Do a CRC check before installing
InstallDir "$PROGRAMFILES\Tesseract-OCR"
# Name of program and file
!ifdef VERSION
OutFile tesseract-ocr-setup-${VERSION}.exe
!else
OutFile tesseract-ocr-setup.exe
!endif

!macro AddToPath
  # TODO(zdenop): Check if $INSTDIR is in path. If yes, do not append it.
  # append bin path to user PATH environment variable
  StrCpy $PathKey "HKLM"
  StrCmp $MultiUser.InstallMode "AllUsers" +2
    StrCpy $PathKey "HKCU"
  DetailPrint "Setting PATH to $INSTDIR at $PathKey"
  ${EnvVarUpdate} $0 "PATH" "A" "$PathKey" "$INSTDIR"
  ; make sure windows knows about the change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend

!macro RemoveTessdataPrefix
  ReadRegStr $R2 ${env_hklm} 'TESSDATA_PREFIX'
  ReadRegStr $R3 ${env_hkcu} 'TESSDATA_PREFIX'
  StrCmp $R2 "" Next1 0
    DetailPrint "Removing $R2 from HKLM Environment..."
    DeleteRegValue ${env_hklm} TESSDATA_PREFIX  # This only empty variable, but do not remove it!
    ${EnvVarUpdate} $0 "TESSDATA_PREFIX"  "R" "HKLM" $R1
  Next1:
    StrCmp $R3 "" Next2 0
      DetailPrint "Removing $R3 from HKCU Environment..."
      DeleteRegValue ${env_hkcu} "TESSDATA_PREFIX"
  Next2:
    # make sure windows knows about the change
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend

!macro SetTESSDATA
  !insertmacro RemoveTessdataPrefix
  StrCpy $PathKey "HKLM"
  StrCmp $MultiUser.InstallMode "AllUsers" +2
    StrCpy $PathKey "HKCU"
  DetailPrint "Setting TESSDATA_PREFIX at $PathKey"
  ${EnvVarUpdate} $0 "TESSDATA_PREFIX" "A" "$PathKey" "$INSTDIR\"
  # make sure windows knows about the change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend

!macro Download_Lang_Data Lang
  ; Download traineddata file.
  DetailPrint "Download: ${Lang} language files"
  inetc::get /caption "Downloading ${Lang} language files" /popup "" \
      "${GITHUB_RAW_FILE_URL}/${Lang}.traineddata" $INSTDIR/tessdata/${Lang}.traineddata \
      /END
    Pop $0 # return value = exit code, "OK" if OK
    StrCmp $0 "OK" +2
    MessageBox MB_OK|MB_ICONEXCLAMATION "http download error. Download Status of ${Lang}: $0. Click OK to continue." /SD IDOK
!macroend

!macro Download_Lang_Data_with_Cube Lang
  ; Download traineddata file.
  DetailPrint "Download: ${Lang} language files"
  inetc::get /CAPTION "Downloading ${Lang} language files" /POPUP "" \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.fold" $INSTDIR/tessdata/${Lang}.cube.fold \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.lm" $INSTDIR/tessdata/${Lang}.cube.lm \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.nn" $INSTDIR/tessdata/${Lang}.cube.nn \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.params" $INSTDIR/tessdata/${Lang}.cube.params \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.size" $INSTDIR/tessdata/${Lang}.cube.size \
      "${GITHUB_RAW_FILE_URL}/${Lang}.cube.word-freq" $INSTDIR/tessdata/${Lang}.cube.word-freq \
      "${GITHUB_RAW_FILE_URL}/${Lang}.traineddata" $INSTDIR/tessdata/${Lang}.traineddata \
      /END
    Pop $0 # return value = exit code, "OK" if OK
    StrCmp $0 "OK" +2
    MessageBox MB_OK|MB_ICONEXCLAMATION "http download error. Download Status of ${Lang}: $0. Click OK to continue." /SD IDOK
!macroend

!macro Download_Leptonica DataUrl
  IfFileExists $TEMP/leptonica.zip dlok
  inetc::get /caption "Downloading $1" /popup "" ${DataUrl} $TEMP/leptonica.zip /END
    Pop $R0 # return value = exit code, "OK" if OK
    StrCmp $R0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "http download error. Download Status of $1: $R0. Click OK to continue." /SD IDOK
    Goto error
  dlok:
!ifndef CROSSBUILD
    nsisunz::UnzipToLog "$TEMP/leptonica.zip" "$INSTDIR"
!endif
    Pop $R0
    StrCmp $R0 "success" +2
        MessageBox MB_OK "Decompression of leptonica failed: $R0"
        Goto error
  error:
    Delete "$TEMP\leptonica.zip"
!macroend

!macro Download_Data2 Filename Komp
  IfFileExists $TEMP/${Filename} dlok
    inetc::get /caption "Downloading $1" /popup "" "${FILE_URL}/${Filename}" $TEMP/${Filename} /END
    Pop $R0 # return value = exit code, "OK" if OK
    StrCmp $R0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "http download error. Download Status of $1: $R0. Click OK to continue." /SD IDOK
    Goto error
  dlok:
    ${If} ${Komp} == "tgz"
        DetailPrint "Extracting ${Filename}"
!ifndef CROSSBUILD
        untgz::extract "-d" "$INSTDIR\.." "$TEMP\${Filename}"
!endif
        Goto install
    ${EndIf}
    ${If} ${Komp} == "zip"
        DetailPrint "Extracting ${Filename}"
!ifndef CROSSBUILD
        nsisunz::UnzipToLog "$TEMP\${Filename}" "$INSTDIR\"
!endif
        Goto install
    ${EndIf}
     MessageBox MB_OK|MB_ICONEXCLAMATION "Unsupported compression!"
  install:
        Pop $R0
        StrCmp $R0 "success" +3
            MessageBox MB_OK "Decompression of ${Filename} failed: $R0"
            Goto error
    Delete "$TEMP\${Filename}"
  error:
!macroend

!macro Download_Data Filename Komp
  IfFileExists $TEMP/${Filename} dlok
  inetc::get /caption "Downloading $1" /popup "" "${FILE_URL}/${Filename}" $TEMP/${Filename} /END
    Pop $R0 # return value = exit code, "OK" if OK
    StrCmp $R0 "OK" dlok
    MessageBox MB_OK|MB_ICONEXCLAMATION "http download error. Download Status of $1: $R0. Click OK to continue." /SD IDOK
    Goto end
  dlok:
    ${If} ${Komp} == "tgz"
!ifndef CROSSBUILD
        untgz::extract "-d" "$INSTDIR" "$TEMP\${Filename}"
!endif
        Goto install
    ${EndIf}
    ${If} ${Komp} == "zip"
!ifndef CROSSBUILD
        nsisunz::UnzipToLog "$TEMP\${Filename}" "$INSTDIR"
!endif
        Goto install
    ${EndIf}
     MessageBox MB_OK|MB_ICONEXCLAMATION "Unsupported compression!"
  install:
        Pop $R0
        StrCmp $R0 "success" +3
            MessageBox MB_OK "Decompression of ${Filename} failed: $R0"
            Goto end
    Delete "$TEMP\${Filename}"
    ${If} ${Komp} == "zip"
        Goto end
    ${EndIf}
    CopyFiles "$TEMP\Tesseract-OCR\*" "$INSTDIR"
    RMDir /r "$TEMP\Tesseract-OCR"
  end:
!macroend

Section -Main SEC0000
  ; mark as read only component
  SectionIn RO
  SetOutPath "$INSTDIR"
  # files included in distribution
  File ${APIDIR}\tesseract.exe
!ifdef SHARED
  File ${APIDIR}\libtesseract-3.dll
!endif
!ifdef CROSSBUILD
  File ${SRCDIR}\dll\i686-w64-mingw32\*.dll
!endif
  File ${SRCDIR}\nsis\tar.exe
  CreateDirectory "$INSTDIR\java"
  SetOutPath "$INSTDIR\java"
  File ..\java\ScrollView.jar
  CreateDirectory "$INSTDIR\tessdata"
  CreateDirectory "$INSTDIR\tessdata\configs"
  SetOutPath "$INSTDIR\tessdata\configs"
  File ${SRCDIR}\tessdata\configs\ambigs.train
  File ${SRCDIR}\tessdata\configs\api_config
  File ${SRCDIR}\tessdata\configs\bazaar
  File ${SRCDIR}\tessdata\configs\bigram
  File ${SRCDIR}\tessdata\configs\box.train
  File ${SRCDIR}\tessdata\configs\box.train.stderr
  File ${SRCDIR}\tessdata\configs\digits
  File ${SRCDIR}\tessdata\configs\get.image
  File ${SRCDIR}\tessdata\configs\hocr
  File ${SRCDIR}\tessdata\configs\inter
  File ${SRCDIR}\tessdata\configs\kannada
  File ${SRCDIR}\tessdata\configs\linebox
  File ${SRCDIR}\tessdata\configs\logfile
  File ${SRCDIR}\tessdata\configs\makebox
  File ${SRCDIR}\tessdata\configs\pdf
  File ${SRCDIR}\tessdata\configs\quiet
  File ${SRCDIR}\tessdata\configs\rebox
  File ${SRCDIR}\tessdata\configs\strokewidth
  File ${SRCDIR}\tessdata\configs\unlv
  CreateDirectory "$INSTDIR\tessdata\tessconfigs"
  SetOutPath "$INSTDIR\tessdata\tessconfigs"
  File ${SRCDIR}\tessdata\tessconfigs\batch
  File ${SRCDIR}\tessdata\tessconfigs\batch.nochop
  File ${SRCDIR}\tessdata\tessconfigs\matdemo
  File ${SRCDIR}\tessdata\tessconfigs\msdemo
  File ${SRCDIR}\tessdata\tessconfigs\nobatch
  File ${SRCDIR}\tessdata\tessconfigs\segdemo
  CreateDirectory "$INSTDIR\doc"
  SetOutPath "$INSTDIR\doc"
  File ${SRCDIR}\AUTHORS
  File ${SRCDIR}\COPYING
  File ${SRCDIR}\testing\eurotext.tif
  File ${SRCDIR}\testing\phototest.tif
  File ${SRCDIR}\testing\README
  File ${SRCDIR}\ReleaseNotes
SectionEnd

Section "Training Tools" SecTr
  SectionIn 1
  SetOutPath "$INSTDIR"
  File ${TRAININGDIR}\ambiguous_words.exe
  File ${TRAININGDIR}\classifier_tester.exe
  File ${TRAININGDIR}\cntraining.exe
  File ${TRAININGDIR}\combine_tessdata.exe
  File ${TRAININGDIR}\dawg2wordlist.exe
  File ${TRAININGDIR}\mftraining.exe
  File ${TRAININGDIR}\unicharset_extractor.exe
  File ${TRAININGDIR}\wordlist2dawg.exe
  File ${TRAININGDIR}\shapeclustering.exe
SectionEnd

Section -post SEC0001
  ;Store installation folder - we use allways HKLM!
  WriteRegStr HKLM "${REGKEY}" "Path" "$INSTDIR"
  WriteRegStr HKLM "${REGKEY}" "Mode" $MultiUser.InstallMode
  WriteRegStr HKLM "${REGKEY}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${REGKEY}" "CurrentVersion" "${VERSION}"
  WriteRegStr HKLM "${REGKEY}" "Uninstaller" "$INSTDIR\uninstall.exe"
  ;WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "Tesseract-OCR" "$INSTDIR\tesseract.exe"
  ; Register to Add/Remove program in control panel
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME} - open source OCR engine"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" DisplayVersion "${VERSION}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" Publisher "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" URLInfoAbout "${PRODUCT_WEB_SITE}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayIcon" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" NoModify 1
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" NoRepair 1
  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  ;ExecShell "open" "https://github.com/tesseract-ocr/tesseract"
  ;ExecShell "open" '"$INSTDIR"'
  ;BringToFront
SectionEnd

Section "Shortcuts creation" SecCS
  SetOutPath $INSTDIR
  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Console.lnk" $WINDIR\system32\CMD.EXE
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Homepage.lnk" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\ReadMe.lnk" "${PRODUCT_WEB_SITE}/wiki/ReadMe"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\FAQ.lnk" "${PRODUCT_WEB_SITE}/wiki/FAQ"
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  ;CreateShortCut "$DESKTOP\Tesseract-OCR.lnk" "$INSTDIR\tesseract.exe" "" "$INSTDIR\tesseract.exe" 0
  ;CreateShortCut "$QUICKLAUNCH\.lnk" "$INSTDIR\tesseract.exe" "" "$INSTDIR\tesseract.exe" 0
SectionEnd

SectionGroup "Registry settings" SecRS
    Section /o "Add to Path" SecRS_path
        !insertmacro AddToPath
    SectionEnd
    Section /o "Set TESSDATA_PREFIX variable" SecRS_tessdata
        !insertmacro SetTESSDATA
    SectionEnd
SectionGroupEnd

SectionGroup "Tesseract development files" SecGrp_dev
    Section /o "tesseract libraries including header files" SecLang_tlib
    !insertmacro Download_Data2 tesseract-ocr-${VERSION}-win32-lib-include-dirs.zip zip
    CopyFiles $INSTDIR\lib\libtesseract*.dll $INSTDIR\  ; $INSTDIR is in the path!
    Delete $INSTDIR\lib\libtesseract*.dll
    SectionEnd
    Section /o "Download and install leptonica 1.68 libraries including header files" SecLang_llib
    !insertmacro Download_Leptonica http://leptonica.org/source/leptonica-1.68-win32-lib-include-dirs.zip
    CopyFiles $INSTDIR\lib\liblept*.dll $INSTDIR\  ; move to path
    Delete $INSTDIR\lib\liblept*.dll
    SectionEnd
    Section /o "Download and install VC++ 2008 tesseract API example solution" SecLang_example
    !insertmacro Download_Data2 tesseract-ocr-API-Example-vs2008.zip zip
    SectionEnd
    Section /o "Download and install tesseract source code" SecLang_source
    !insertmacro Download_Data tesseract-ocr-${VERSION}.tar.gz tgz
    SectionEnd
    Section /o "Download and install VS C++ 2008 solution for tesseract" SecLang_vs2008
    !insertmacro Download_Data tesseract-ocr-3.02-vs2008.zip zip
    SectionEnd
    Section /o "Download and install doxygen documentation for tesseract" SecLang_doxygen
    !insertmacro Download_Data tesseract-ocr-${VERSION}-doc-html.tar.gz tgz
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\DoxygenDoc.lnk" "$INSTDIR\tesseract-ocr\doc\html\index.html"
    SectionEnd
SectionGroupEnd

; Language files
SectionGroup "Language data" SecGrp_LD
    Section "English" SecLang_eng
    SectionIn RO
      SetOutPath "$INSTDIR\tessdata"
      File ${SRCDIR}\tessdata\eng.*
    SectionEnd

    Section "Orientation and script detection" SecLang_osd
    SectionIn 1
      SetOutPath "$INSTDIR\tessdata"
      File ${SRCDIR}\tessdata\osd.*
    SectionEnd
SectionGroupEnd

; Download language files
SectionGroup "Additional language data (download)" SecGrp_ALD
  Section /o "Math / equation detection module" SecLang_equ
    !insertmacro Download_Lang_Data equ
  SectionEnd

  ; The language names are documented here:
  ; https://github.com/tesseract-ocr/tesseract/blob/master/doc/tesseract.1.asc#languages

  Section /o "Afrikaans" SecLang_afr
    !insertmacro Download_Lang_Data afr
  SectionEnd

  Section /o "Albanian" SecLang_sqi
    !insertmacro Download_Lang_Data sqi
  SectionEnd

  Section /o "Amharic" SecLang_amh
    !insertmacro Download_Lang_Data amh
  SectionEnd

  Section /o "Arabic" SecLang_ara
    !insertmacro Download_Lang_Data ara.cube.bigrams
    !insertmacro Download_Lang_Data_with_Cube ara
  SectionEnd

  Section /o "Assamese" SecLang_asm
    !insertmacro Download_Lang_Data asm
  SectionEnd

  Section /o "Azerbaijani" SecLang_aze
    !insertmacro Download_Lang_Data aze
  SectionEnd

  Section /o "Azerbaijani (Cyrilic)" SecLang_aze_cyrl
    !insertmacro Download_Lang_Data aze_cyrl
  SectionEnd

  Section /o "Basque" SecLang_eus
    !insertmacro Download_Lang_Data eus
  SectionEnd

  Section /o "Belarusian" SecLang_bel
    !insertmacro Download_Lang_Data bel
  SectionEnd

  Section /o "Bengali" SecLang_ben
    !insertmacro Download_Lang_Data ben
  SectionEnd

  Section /o "Tibetan" SecLang_bod
    !insertmacro Download_Lang_Data bod
  SectionEnd

  Section /o "Bosnian" SecLang_bos
    !insertmacro Download_Lang_Data bos
  SectionEnd

  Section /o "Bulgarian" SecLang_bul
    !insertmacro Download_Lang_Data bul
  SectionEnd

  Section /o "Catalan" SecLang_cat
    !insertmacro Download_Lang_Data cat
  SectionEnd

  Section /o "Cebuano" SecLang_ceb
    !insertmacro Download_Lang_Data ceb
  SectionEnd

  Section /o "Cherokee" SecLang_chr
    !insertmacro Download_Lang_Data chr
  SectionEnd

  Section /o "Chinese (Traditional)" SecLang_chi_tra
    !insertmacro Download_Lang_Data chi_tra
  SectionEnd

  Section /o "Chinese (Simplified)" SecLang_chi_sim
    !insertmacro Download_Lang_Data chi_sim
  SectionEnd

  Section /o "Croatian" SecLang_hrv
    !insertmacro Download_Lang_Data hrv
  SectionEnd

  Section /o "Czech" SecLang_ces
    !insertmacro Download_Lang_Data ces
  SectionEnd

  Section /o "Welsh" SecLang_cym
    !insertmacro Download_Lang_Data cym
  SectionEnd

  Section /o "Danish" SecLang_dan
    !insertmacro Download_Lang_Data dan
  SectionEnd

  Section /o "Danish (Fraktur)" SecLang_dan_frak
    !insertmacro Download_Lang_Data dan_frak
  SectionEnd

  Section /o "Dutch" SecLang_nld
    !insertmacro Download_Lang_Data nld
  SectionEnd

  Section /o "English - Middle (1100-1500)" SecLang_enm
    !insertmacro Download_Lang_Data enm
  SectionEnd

  Section /o "Esperanto" SecLang_epo
    !insertmacro Download_Lang_Data epo
  SectionEnd

  Section /o "Estonian" SecLang_est
    !insertmacro Download_Lang_Data est
  SectionEnd

  Section /o "German" SecLang_deu
    !insertmacro Download_Lang_Data deu
  SectionEnd

  Section /o "German (Fraktur)" SecLang_deu_frak
    !insertmacro Download_Lang_Data deu_frak
  SectionEnd

  Section /o "Dzongkha" SecLang_dzo
    !insertmacro Download_Lang_Data dzo
  SectionEnd

  Section /o "Greek" SecLang_ell
    !insertmacro Download_Lang_Data ell
  SectionEnd

  Section /o "Greek - Ancient" SecLang_grc
    !insertmacro Download_Lang_Data grc
  SectionEnd

  Section /o "Persian" SecLang_fas
    !insertmacro Download_Lang_Data fas
  SectionEnd

  Section /o "Finnish" SecLang_fin
    !insertmacro Download_Lang_Data fin
  SectionEnd

  Section /o "Frankish" SecLang_frk
    !insertmacro Download_Lang_Data frk
  SectionEnd

  Section /o "French" SecLang_fra
    !insertmacro Download_Lang_Data fra.cube.bigrams
    !insertmacro Download_Lang_Data fra.tesseract_cube.nn
    !insertmacro Download_Lang_Data_with_Cube fra
  SectionEnd

  Section /o "French - Middle (ca. 1400-1600)" SecLang_frm
    !insertmacro Download_Lang_Data frm
  SectionEnd

  Section /o "Irish" SecLang_gle
    !insertmacro Download_Lang_Data gle
  SectionEnd

  Section /o "Galician" SecLang_glg
    !insertmacro Download_Lang_Data glg
  SectionEnd

  Section /o "Gujarati" SecLang_guj
    !insertmacro Download_Lang_Data guj
  SectionEnd

  Section /o "Haitian" SecLang_hat
    !insertmacro Download_Lang_Data hat
  SectionEnd

  Section /o "Hebrew" SecLang_heb
    !insertmacro Download_Lang_Data heb
  SectionEnd

  Section /o "Hindi" SecLang_hin
    !insertmacro Download_Lang_Data hin.cube.bigrams
    !insertmacro Download_Lang_Data hin.cube.fold
    !insertmacro Download_Lang_Data hin.cube.lm
    !insertmacro Download_Lang_Data hin.cube.nn
    !insertmacro Download_Lang_Data hin.cube.params
    !insertmacro Download_Lang_Data hin.cube.word-freq
    !insertmacro Download_Lang_Data hin.tesseract_cube.nn
    !insertmacro Download_Lang_Data hin
  SectionEnd

  Section /o "Hungarian" SecLang_hun
    !insertmacro Download_Lang_Data hun
  SectionEnd

  Section /o "Inuktitut" SecLang_iku
    !insertmacro Download_Lang_Data iku
  SectionEnd

  Section /o "Icelandic" SecLang_isl
    !insertmacro Download_Lang_Data isl
  SectionEnd

  Section /o "Indonesian" SecLang_ind
    !insertmacro Download_Lang_Data ind
  SectionEnd

  Section /o "Italian" SecLang_ita
    !insertmacro Download_Lang_Data ita.cube.bigrams
    !insertmacro Download_Lang_Data ita.tesseract_cube.nn
    !insertmacro Download_Lang_Data_with_Cube ita
  SectionEnd

  Section /o "Italian (Old)" SecLang_ita_old
    !insertmacro Download_Lang_Data ita_old
  SectionEnd

  Section /o "Javanese" SecLang_jav
    !insertmacro Download_Lang_Data jav
  SectionEnd

  Section /o "Japanese" SecLang_jpn
    !insertmacro Download_Lang_Data jpn
  SectionEnd

  Section /o "Kannada" SecLang_kan
    !insertmacro Download_Lang_Data kan
  SectionEnd

  Section /o "Georgian" SecLang_kat
    !insertmacro Download_Lang_Data kat
  SectionEnd

  Section /o "Georgian (Old)" SecLang_kat_old
    !insertmacro Download_Lang_Data kat_old
  SectionEnd

  Section /o "Kazakh" SecLang_kaz
    !insertmacro Download_Lang_Data kaz
  SectionEnd

  Section /o "Central Khmer" SecLang_khm
    !insertmacro Download_Lang_Data khm
  SectionEnd

  Section /o "Kirghiz" SecLang_kir
    !insertmacro Download_Lang_Data kir
  SectionEnd

  Section /o "Korean" SecLang_kor
    !insertmacro Download_Lang_Data kor
  SectionEnd

  Section /o "Kurdish" SecLang_kur
    !insertmacro Download_Lang_Data kur
  SectionEnd

  Section /o "Lao" SecLang_lao
    !insertmacro Download_Lang_Data lao
  SectionEnd

  Section /o "Latin" SecLang_lat
    !insertmacro Download_Lang_Data lat
  SectionEnd

  Section /o "Latvian" SecLang_lav
    !insertmacro Download_Lang_Data lav
  SectionEnd

  Section /o "Lithuanian" SecLang_lit
    !insertmacro Download_Lang_Data lit
  SectionEnd

  Section /o "Marathi" SecLang_mar
    !insertmacro Download_Lang_Data mar
  SectionEnd

  Section /o "Macedonian" SecLang_mkd
    !insertmacro Download_Lang_Data mkd
  SectionEnd

  Section /o "Malay" SecLang_msa
    !insertmacro Download_Lang_Data msa
  SectionEnd

  Section /o "Malayalam" SecLang_mal
    !insertmacro Download_Lang_Data mal
  SectionEnd

  Section /o "Maltese" SecLang_mlt
    !insertmacro Download_Lang_Data mlt
  SectionEnd

  Section /o "Burmese" SecLang_mya
    !insertmacro Download_Lang_Data mya
  SectionEnd

  Section /o "Nepali" SecLang_nep
    !insertmacro Download_Lang_Data nep
  SectionEnd

  Section /o "Norwegian" SecLang_nor
    !insertmacro Download_Lang_Data nor
  SectionEnd

  Section /o "Oriya" SecLang_ori
    !insertmacro Download_Lang_Data ori
  SectionEnd

  Section /o "Panjabi / Punjabi" SecLang_pan
    !insertmacro Download_Lang_Data pan
  SectionEnd

  Section /o "Polish" SecLang_pol
    !insertmacro Download_Lang_Data pol
  SectionEnd

  Section /o "Portuguese" SecLang_por
    !insertmacro Download_Lang_Data por
  SectionEnd

  Section /o "Pushto / Pashto" SecLang_pus
    !insertmacro Download_Lang_Data pus
  SectionEnd

  Section /o "Romanian" SecLang_ron
    !insertmacro Download_Lang_Data ron
  SectionEnd

  Section /o "Russian" SecLang_rus
    !insertmacro Download_Lang_Data_with_Cube rus
  SectionEnd

  Section /o "Sanskrit" SecLang_san
    !insertmacro Download_Lang_Data san
  SectionEnd

  Section /o "Sinhala / Sinhalese" SecLang_sin
    !insertmacro Download_Lang_Data sin
  SectionEnd

  Section /o "Slovak" SecLang_slk
    !insertmacro Download_Lang_Data slk
  SectionEnd

  Section /o "Slovak (Fraktur)" SecLang_slk_frak
    !insertmacro Download_Lang_Data slk_frak
  SectionEnd

  Section /o "Slovenian" SecLang_slv
    !insertmacro Download_Lang_Data slv
  SectionEnd

  Section /o "Spanish" SecLang_spa
    !insertmacro Download_Lang_Data spa.cube.bigrams
    !insertmacro Download_Lang_Data_with_Cube spa
  SectionEnd

  Section /o "Spanish (Old)" SecLang_spa_old
    !insertmacro Download_Lang_Data spa_old
  SectionEnd

  Section /o "Serbian" SecLang_srp
    !insertmacro Download_Lang_Data srp
  SectionEnd

  Section /o "Serbian (Latin)" SecLang_srp_latn
    !insertmacro Download_Lang_Data srp_latn
  SectionEnd

  Section /o "Swahili" SecLang_swa
    !insertmacro Download_Lang_Data swa
  SectionEnd

  Section /o "Swedish" SecLang_swe
    !insertmacro Download_Lang_Data swe
  SectionEnd

  Section /o "Swedish (Fraktur)" SecLang_swe_frak
    !insertmacro Download_Lang_Data swe-frak
  SectionEnd

  Section /o "Syriac" SecLang_syr
    !insertmacro Download_Lang_Data syr
  SectionEnd

  Section /o "Tagalog" SecLang_tgl
    !insertmacro Download_Lang_Data tgl
  SectionEnd

  Section /o "Tajik" SecLang_tgk
    !insertmacro Download_Lang_Data tgk
  SectionEnd

  Section /o "Tamil" SecLang_tam
    !insertmacro Download_Lang_Data tam
  SectionEnd

  Section /o "Telugu" SecLang_tel
    !insertmacro Download_Lang_Data tel
  SectionEnd

  Section /o "Thai" SecLang_tha
    !insertmacro Download_Lang_Data tha
  SectionEnd

  Section /o "Tigrinya" SecLang_tir
    !insertmacro Download_Lang_Data tir
  SectionEnd

  Section /o "Turkish" SecLang_tur
    !insertmacro Download_Lang_Data tur
  SectionEnd

  Section /o "Uighur" SecLang_uig
    !insertmacro Download_Lang_Data uig
  SectionEnd

  Section /o "Ukrainian" SecLang_ukr
    !insertmacro Download_Lang_Data ukr
  SectionEnd

  Section /o "Urdu" SecLang_urd
    !insertmacro Download_Lang_Data urd
  SectionEnd

  Section /o "Uzbek" SecLang_uzb
    !insertmacro Download_Lang_Data uzb
  SectionEnd

  Section /o "Uzbek (Cyrilic)" SecLang_uzb_cyrl
    !insertmacro Download_Lang_Data uzb_cyrl
  SectionEnd

  Section /o "Vietnamese" SecLang_vie
    !insertmacro Download_Lang_Data vie
  SectionEnd

  Section /o "Yiddish" SecLang_yid
    !insertmacro Download_Lang_Data yid
  SectionEnd
SectionGroupEnd

;--------------------------------
;Descriptions
  ; At first we need to localize installer for languages which supports well in tesseract: Eng, Spa, Ger, Ita, Dutch + Russian (it is authors native language)
  ;Language strings
  LangString DESC_SEC0001 ${LANG_RUSSIAN} "Установочные файлы."
  ;LangString DESC_SecHelp ${LANG_RUSSIAN} "Справочная информация."
  LangString DESC_SecCS    ${LANG_RUSSIAN} "Добавить ярлыки в меню Пуск"

  LangString DESC_SEC0001 ${LANG_ENGLISH} "Installation files."
  ;LangString DESC_SecHelp ${LANG_ENGLISH} "Help information."
  LangString DESC_SecCS    ${LANG_ENGLISH} "Add shortcuts to Start menu."

  LangString DESC_SEC0001 ${LANG_ITALIAN} "File di installazione."
  ;LangString DESC_SecHelp ${LANG_ITALIAN} "Guida di informazioni."
  LangString DESC_SecCS    ${LANG_ITALIAN} "Aggiungere collegamenti al menu Start."

  LangString DESC_SEC0001 ${LANG_SLOVAK} "Súbory inštalácie."
  ;LangString DESC_SecHelp ${LANG_ENGLISH} "Pomocné informácie."
  LangString DESC_SecCS    ${LANG_SLOVAK} "Pridať odkaz do Start menu."

  LangString DESC_SEC0001 ${LANG_SPANISH} "Los archivos de instalación."
  ;LangString DESC_SecHelp ${LANG_SPANISH} "Información de ayuda."
  LangString DESC_SecCS    ${LANG_SPANISH} "Ańadir accesos directos al menú Inicio."

  LangString DESC_SEC0001 ${LANG_SPANISHINTERNATIONAL} "Los archivos de instalación."
  ;LangString DESC_SecHelp ${LANG_SPANISHINTERNATIONAL} "Información de ayuda."
  LangString DESC_SecCS    ${LANG_SPANISHINTERNATIONAL} "Ańadir accesos directos al menú Inicio."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC0001} $(DESC_SEC0001)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecCS} $(DESC_SecCS)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

;Section /o -un.Main UNSEC0000
Section -un.Main UNSEC0000
  DetailPrint "Removing everything"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\*.*"
  RMDir  "$SMPROGRAMS\${PRODUCT_NAME}"
  DetailPrint "Removing registry info"
  DeleteRegKey HKLM "Software\Tesseract-OCR"
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${un.EnvVarUpdate} $0 "PATH" "R" HKLM $INSTDIR
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  DeleteRegValue HKLM "Environment" "TESSDATA_PREFIX"
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  # remove the Add/Remove information
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
  Delete "$INSTDIR\Uninstall.exe"
  DeleteRegValue HKLM "${REGKEY}" Path
  DeleteRegKey /IfEmpty HKLM "${REGKEY}\Components"
  DeleteRegKey /IfEmpty HKLM "${REGKEY}"
  RMDir /r "$INSTDIR"
SectionEnd

Function PageReinstall

FunctionEnd

Function PageLeaveReinstall

FunctionEnd

!macro REMOVE_REGKEY OLD_KEY
  StrCmp ${OLD_KEY} HKLM 0 +3
    DeleteRegKey HKLM "${REGKEY}"
    Goto End
  DeleteRegKey HKCU "${REGKEY}"
  End:
!macroend

Function .onInit
  Call PreventMultipleInstances
  ;RequestExecutionLevel admin
  !insertmacro MULTIUSER_INIT

  ; is tesseract already installed?
  ReadRegStr $R0 HKCU "${REGKEY}" "CurrentVersion"
  StrCpy $OLD_KEY HKCU
  StrCmp $R0 "" test1 test2
  test1:
    ReadRegStr $R0 HKLM "${REGKEY}" "CurrentVersion"
    StrCpy $OLD_KEY "$R0"
    StrCmp $R0 "" SkipUnInstall
  test2:
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "Tesseract-ocr version $R0 is installed (in $OLD_KEY)! Do you want to uninstall it first?$\nUninstall will delete all files in '$INSTDIR'!" \
       /SD IDYES IDNO SkipUnInstall IDYES UnInstall
  UnInstall:
    StrCmp $OLD_KEY "HKLM" UnInst_hklm
       DetailPrint "CurrentUser:"
       readRegStr $R1 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString"
       Goto try_uninstall
    UnInst_hklm:
       DetailPrint "UnInst_hklm"
       readRegStr $R1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString"
    try_uninstall:
      ClearErrors
      ExecWait '$R1 _?=$INSTDIR'$0
      ; Check if unstaller finished ok. If yes, then try to remove it from installer.
      StrCmp $0 0 0 +3
        !insertmacro REMOVE_REGKEY ${OLD_KEY}
        Goto SkipUnInstall
      messagebox mb_ok "Uninstaller failed:\n$0\n\nYou need to remove program manually."
  SkipUnInstall:
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to install ${PRODUCT_NAME} ${VERSION}?" \
    /SD IDYES IDNO no IDYES yes
  no:
    SetSilent silent
    Goto done
  yes:
    ;InitPluginsDir
    ;File /oname=$PLUGINSDIR\splash.bmp "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"
    ;File /oname=$PLUGINSDIR\splash.bmp "new.bmp"
    ;advsplash::show 1000 600 400 -1 $PLUGINSDIR\splash
    ;Pop $0          ; $0 has '1' if the user closed the splash screen early,
                    ; '0' if everything closed normal, and '-1' if some error occured.
    ;IfFileExists $INSTDIR\loadmain.exe PathGood
  done:
    ; Make selection based on System language ID
    System::Call 'kernel32::GetSystemDefaultLangID() i .r0'
    ;http://msdn.microsoft.com/en-us/library/dd318693%28v=VS.85%29.aspx
    StrCmp $0 "1078" Afrikaans
    StrCmp $0 "1052" Albanian
    StrCmp $0 "5121" Arabic
    StrCmp $0 "1068" Azerbaijani
    StrCmp $0 "1069" Basque
    StrCmp $0 "1059" Belarusian
    StrCmp $0 "1093" Bengali
    StrCmp $0 "1026" Bulgarian
    StrCmp $0 "1027" Catalan
    StrCmp $0 "1116" Cherokee
    StrCmp $0 "31748" Chinese_tra
    StrCmp $0 "4" Chinese_sim
    StrCmp $0 "26" Croatian
    StrCmp $0 "1029" Czech
    StrCmp $0 "1030" Danish
    StrCmp $0 "2067" Dutch
    StrCmp $0 "1061" Estonian
    StrCmp $0 "3079" German
    StrCmp $0 "1032" Greek
    StrCmp $0 "1035" Finnish
    StrCmp $0 "2060" French
    StrCmp $0 "1037" Hebrew
    StrCmp $0 "1081" Hindi
    StrCmp $0 "1038" Hungarian
    StrCmp $0 "1039" Icelandic
    StrCmp $0 "1057" Indonesian
    StrCmp $0 "1040" Italian
    StrCmp $0 "1041" Japanese
    StrCmp $0 "1099" Kannada
    StrCmp $0 "1042" Korean
    StrCmp $0 "1062" Latvian
    StrCmp $0 "1063" Lithuanian
    StrCmp $0 "1071" Macedonian
    StrCmp $0 "1100" Malayalam
    StrCmp $0 "2110" Malay
    StrCmp $0 "1082" Maltese
    StrCmp $0 "1044" Norwegian
    StrCmp $0 "1045" Polish
    StrCmp $0 "1046" Portuguese
    StrCmp $0 "1048" Romanian
    StrCmp $0 "1049" Russian
    StrCmp $0 "1051" Slovak
    StrCmp $0 "1060" Slovenian
    StrCmp $0 "11274" Spanish
    StrCmp $0 "2074" Serbian
    StrCmp $0 "1089" Swahili
    StrCmp $0 "2077" Swedish
    StrCmp $0 "1097" Tamil
    StrCmp $0 "1098" Telugu
    StrCmp $0 "1054" Thai
    StrCmp $0 "1055" Turkish
    StrCmp $0 "1058" Ukrainian
    StrCmp $0 "1066" Vietnamese

    Goto lang_end

    Afrikaans: !insertmacro SelectSection ${SecLang_afr}
            Goto lang_end
    Albanian: !insertmacro SelectSection ${SecLang_sqi}
            Goto lang_end
    Arabic: !insertmacro SelectSection ${SecLang_ara}
            Goto lang_end
    ;Assamese: !insertmacro SelectSection ${SecLang_asm}
    ;        Goto lang_end
    Azerbaijani: !insertmacro SelectSection ${SecLang_aze}
            Goto lang_end
    Basque: !insertmacro SelectSection ${SecLang_eus}
            Goto lang_end
    Belarusian: !insertmacro SelectSection ${SecLang_bel}
            Goto lang_end
    Bengali: !insertmacro SelectSection ${SecLang_ben}
            Goto lang_end
    Bulgarian: !insertmacro SelectSection ${SecLang_bul}
            Goto lang_end
    Catalan: !insertmacro SelectSection ${SecLang_cat}
            Goto lang_end
    Cherokee: !insertmacro SelectSection ${SecLang_chr}
            Goto lang_end
    Chinese_tra: !insertmacro SelectSection ${SecLang_chi_tra}
            Goto lang_end
    Chinese_sim: !insertmacro SelectSection ${SecLang_chi_sim}
            Goto lang_end
    Croatian: !insertmacro SelectSection ${SecLang_hrv}
            Goto lang_end
    Czech: !insertmacro SelectSection ${SecLang_ces}
            Goto lang_end
    Danish: !insertmacro SelectSection ${SecLang_dan}
            !insertmacro SelectSection ${SecLang_dan_frak}
            Goto lang_end
    Dutch: !insertmacro SelectSection ${SecLang_nld}
            Goto lang_end
    Estonian: !insertmacro SelectSection ${SecLang_hrv}
            Goto lang_end
    German: !insertmacro SelectSection ${SecLang_deu}
            !insertmacro SelectSection ${SecLang_deu_frak}
            Goto lang_end
    Greek: !insertmacro SelectSection ${SecLang_ell}
            !insertmacro SelectSection ${SecLang_grc}
            Goto lang_end
    Finnish: !insertmacro SelectSection ${SecLang_fin}
            !insertmacro SelectSection ${SecLang_frm}
            Goto lang_end
    French: !insertmacro SelectSection ${SecLang_fra}
            Goto lang_end
    Hebrew: !insertmacro SelectSection ${SecLang_heb}
            ;!insertmacro SelectSection ${SecLang_heb_com}
            Goto lang_end
    Hungarian: !insertmacro SelectSection ${SecLang_hin}
            Goto lang_end
    Hindi: !insertmacro SelectSection ${SecLang_hun}
            Goto lang_end
    Icelandic: !insertmacro SelectSection ${SecLang_isl}
            Goto lang_end
    Indonesian: !insertmacro SelectSection ${SecLang_ind}
            Goto lang_end
    Italian: !insertmacro SelectSection ${SecLang_ita}
            !insertmacro SelectSection ${SecLang_ita_old}
            Goto lang_end
    Japanese: !insertmacro SelectSection ${SecLang_jpn}
            Goto lang_end
    Kannada: !insertmacro SelectSection ${SecLang_kan}
            Goto lang_end
    Korean: !insertmacro SelectSection ${SecLang_kor}
            Goto lang_end
    Latvian: !insertmacro SelectSection ${SecLang_lav}
            Goto lang_end
    Lithuanian: !insertmacro SelectSection ${SecLang_lit}
            Goto lang_end
    Macedonian: !insertmacro SelectSection ${SecLang_mkd}
            Goto lang_end
    Malayalam: !insertmacro SelectSection ${SecLang_msa}
            Goto lang_end
    Malay: !insertmacro SelectSection ${SecLang_mal}
            Goto lang_end
    Maltese: !insertmacro SelectSection ${SecLang_mlt}
            Goto lang_end
    Norwegian: !insertmacro SelectSection ${SecLang_nor}
            Goto lang_end
    Polish: !insertmacro SelectSection ${SecLang_pol}
            Goto lang_end
    Portuguese: !insertmacro SelectSection ${SecLang_por}
            Goto lang_end
    Romanian: !insertmacro SelectSection ${SecLang_ron}
            Goto lang_end
    Russian: !insertmacro SelectSection ${SecLang_rus}
            Goto lang_end
    Slovak: !insertmacro SelectSection ${SecLang_slk}
            !insertmacro SelectSection ${SecLang_slk_frak}
            Goto lang_end
    Slovenian: !insertmacro SelectSection ${SecLang_slv}
            Goto lang_end
    Spanish: !insertmacro SelectSection ${SecLang_spa}
            !insertmacro SelectSection ${SecLang_spa_old}
            Goto lang_end
    Serbian: !insertmacro SelectSection ${SecLang_srp}
            Goto lang_end
    Swahili: !insertmacro SelectSection ${SecLang_swa}
            Goto lang_end
    Swedish: !insertmacro SelectSection ${SecLang_swe}
            !insertmacro SelectSection ${SecLang_swe_frak}
            Goto lang_end
    Tamil: !insertmacro SelectSection ${SecLang_tam}
            Goto lang_end
    Telugu: !insertmacro SelectSection ${SecLang_tel}
            Goto lang_end
    Thai: !insertmacro SelectSection ${SecLang_tha}
            Goto lang_end
    Turkish: !insertmacro SelectSection ${SecLang_tur}
            Goto lang_end
    Ukrainian: !insertmacro SelectSection ${SecLang_ukr}
            Goto lang_end
    Vietnamese: !insertmacro SelectSection ${SecLang_vie}

    lang_end:
FunctionEnd

Function un.onInit
   !insertmacro MULTIUSER_UNINIT
   ;!insertmacro SELECT_UNSECTION Main ${UNSEC0000}
   ;!insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK "Installation failed."
FunctionEnd

Function ShowReadme
  Exec "explorer.exe $INSTDIR\doc\README"
  ;BringToFront
FunctionEnd

; Prevent running multiple instances of the installer
Function PreventMultipleInstances
  Push $R0
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t ${PRODUCT_NAME}) ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running." /SD IDOK
    Abort
  Pop $R0
FunctionEnd
