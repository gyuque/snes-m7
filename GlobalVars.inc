.define gBenchmarkOut                    $0040 ; ++

; Temporary Area ======================================================
.define gRenderFinished                  $00A8 ; ++
.define gGlobalCount                     $00AA ; ++

.define gAssetOffsetTemp                 $00B0 ; ++
.define gAssetBankTemp                   $00B2 ; ++

.define gPadState                        $00B8 ; ++
.define gRotAngle                        $00BA ; ++

.define gTransSin                        $00C0 ; ++
.define gTransCos                        $00C2 ; ++
.define gTransNSin                       $00C4 ; ++

.define gTransScaleX                     $00C8 ; ++
.define gTransScaleY                     $00CA ; ++
.define gSinTableOfs                     $00CC ; ++


.define gPositionX                       $00D0 ; ++
.define gPositionY                       $00D2 ; ++
.define gScrollX                         $00D4 ; ++
.define gScrollY                         $00D6 ; ++
.define gTransCX                         $00D8 ; ++
.define gTransCY                         $00DA ; ++

.define gTransTestA                      $00E0 ; ++
.define gTransTestB                      $00E2 ; ++
.define gTransTestC                      $00E4 ; ++
.define gTransTestD                      $00E6 ; ++

.define gPlayerVX                        $00F0 ; ++
.define gPlayerVY                        $00F2 ; ++
.define gPlayerFrameCount                $00F8 ; ++
.define gPlayerTileBase                  $00FA ; ++

; 0180h-018Fh
.define gVScrollHDMATable                $0180

; 0190h-019Fh
.define gHScrollHDMATable                $0190

; 0200h - 02FFh
.define gHDMATable_TrA                   $0200

; 0300h - 03FFh
.define gHDMATable_TrB                   $0300

; 0400h - 04FFh
.define gHDMATable_TrC                   $0400

; 0500h - 05FFh
.define gHDMATable_TrD                   $0500

; VRAM Addresses
.define kMap1StartW  #$6800
.define   kMap1StartHi  #$68
.define   kMap1StartLo  #$00

.define kMap2StartW  #$7000
.define   kMap2StartHi  #$70
.define   kMap2StartLo  #$00

.define kMap3StartW  #$7800
.define   kMap3StartHi  #$78
.define   kMap3StartLo  #$00

.define kRotateCenterY #186
