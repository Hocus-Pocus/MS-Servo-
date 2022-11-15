;****************************************************************************
;
;          MS_Servo_V1.inc (header file for MS_Servo_V1.asm)  10/10/05
;
;         By Robert Hiebert with technical assistance from Dan Williams
;
;****************************************************************************

;****************************************************************************
;
; ------------------------- MS_Servo Hardware Wiring  ----------------------
;
;****************************************************************************
;
; ----- Power Terminal [ Port Name - Function - Terminal# ] -----
;
;               12 Volt input                      - Power Terminal Pin 1
;               Common ground input                - Power Terminal Pin 2
;               Servo Stbd 5V supply               - Power Terminal Pin 3
;  PTD5/T1CH1 - Servo Stbd signal                  - Power Terminal Pin 4
;               Servo Stbd common ground           - Power Terminal Pin 5
;               Servo Port 5V supply               - Power Terminal Pin 6
;  PTD4/T1CH0 - Servo Port signal                  - Power Terminal Pin 7
;               Servo Port common ground           - Power Terminal Pin 8
;
; ----- ADC outputs [ Port Name - Function - Pin# ] -----
;
;  VDD-AD - Vref Stbd 5V output          - Stbd DB15 Pin 10
;  VDD-AD - Vref Port 5V output          - Port DB15 Pin 10
;           Common ground                - Stbd and Port DB15s Pins  11,12,13
;
; ----- Inputs [ Port Name - Function - Pin# ] -----
;
;  PTB0/AD0  - ADC0 (not used)                             - No Pin
;  PTB1/AD1  - ADC1 (not used)                             - No Pin
;  PTB2/AD2  - Control Potentiometer Stbd                  - Stbd DB15 Pin 11
;  PTB3/AD3  - Control Potentiometer Port                  - Port DB15 Pin 11
;  PTB4/AD4  - Battery Voltage/Boot Loader Entry           - No Pin
;  PTB5/AD5  - ADC5 (not used)                             - No Pin
;  PTB6/AD6  - ADC6 (not used)                             - No Pin
;  PTB7/AD7  - ADC7 (not used)                             - No Pin
;  IRQ       - external interrupt (not used)               - No Pin
;
; ----- Outputs [Port Name - Function - Pin#] -----
;
;  PTA0      - Input "A"                                   - SN7448 Pin 7
;  PTA1      - Input "B"                                   - SN7448 Pin 1
;  PTA2      - Input "C"                                   - SN7448 Pin 2
;  PTA3      - Input "D"                                   - SN7448 Pin 4
;  PTA4      - Stbd LSD display common cathode driver base - No Pin
;  PTA5      - Stbd MSD display common cathode driver base - No Pin
;  PTA6      - Port LSD display common cathode driver base - No Pin
;  PTA7      - Port MSD display common cathode driver base - No Pin
;  PTC0       - (not used)                                 - No Pin
;  PTC1       - (not used)                                 - No Pin
;  PTC2       - (not used)                                 - No Pin
;  PTC3       - (not used)                                 - No Pin
;  PTC4       - (not used)                                 - No Pin
;  PTD0/SS    - (not used)                                 - No Pin
;  PTD1/MISO  - (not used)                                 - No Pin
;  PTD2/MOSI  - (not used)                                 - No Pin
;  PTD3/SPSCK - Program Loop Counter LED driver base       - No Pin
;
; ----- Communications [ Port Name - Function - Pin# ] -----
;
;  PTE0/TxD       - SCI receive data input        - MAX 232 Pin 11 (T1 in)
;  PTE1/RxD       - SCI transmit data output      - MAX 232 Pin 12 (R1 out)
;  MAX 232 Pin 14 - T1 out                        - DB9 Pin 2
;  MAX 232 Pin 13 - R1 in                         - DB9 Pin 3
;  MAX 232 Pin 16 - VCC                           - DB9 Pin 1
;  MAX 232 Pin 15 - Ground                        - DB9 Pins 5,9

;
; ----- SN7448 Outputs [ Pin# - Function - Pin# ] -----
;
;  SN7448 Pin 9  - Segment "e"               - Stbd and Port DB15s Pin 3
;  SN7448 Pin 10 - Segment "d"               - Stbd and Port DB15s Pin 2
;  SN7448 Pin 11 - Segment "c"               - Stbd and Port DB15s Pin 14
;  SN7448 Pin 12 - Segment "b"               - Stbd and Port DB15s Pin 7
;  SN7448 Pin 13 - Segment "a"               - Stbd and Port DB15s Pin 8
;  SN7448 Pin 14 - Segment "g"               - Stbd and Port DB15s Pin 15
;  SN7448 Pin 15 - Segment "f"               - Stbd and Port DB15s Pin 4
;
; ----- Common Cathode Driver Outputs [ Function - Pin# ] -----
;
;  Stbd LSD display common cathode driver collector    - Stbd DB15 Pin 6
;  Stbd MSD display common cathode driver collector    - Stbd DB15 Pin 5
;  Port LSD display common cathode driver collector    - Port DB15 Pin 6
;  Port MSD display common cathode driver collector    - Port DB15 Pin 5
;
;****************************************************************************


;****************************************************************************
; ------------------------ Output Port Equates ------------------------------
;****************************************************************************

SLSD        equ 4     ; Stbd LSD common cathode driver base on PTA4
SMSD        equ 5     ; Stbd MSD common cathode driver base on PTA5
PLSD        equ 6     ; Port LSD common cathode driver base on PTA6
PMSD        equ 7     ; Port MSD common cathode driver base on PTA7
LoopFrq     equ 3     ; Loop frequency counter on PTD3
SrvS        equ 5     ; Servo Stbd signal on PTD5
SrvP        equ 4     ; Servo Port signal on PTD4


;****************************************************************************
; ---------------- "inputs" Operating Status bit field equates --------------
;****************************************************************************

clk4        equ 0     ; 1 = 0.004S   clock tick flag   0 = "clk4" cleared
clkS        equ 1     ; 1 = 1.0S clock tick flag       0 = "clkS" cleared
adcc        equ 2     ; 1 = ADC complete flag          0 = "adcc" cleared
pwp         equ 3     ; 1 = TIM1 50 HZ timer overflow  0 = "pwp" cleared

;****************************************************************************
; ----------------- RAM Variables (512 bytes available) ---------------------
; I/O registers from $0000 to $0039 (decimal 0 to 63)
; Direct page addressing from $0000 to $00FF (decimal 0 to 255)
; Ram end at $023F (decimal 575)
;****************************************************************************

;Memory Location $0040 (decimal 64)

ms_ram_start:

;****************************************************************************
; ------------------ RS232 Real Time Download Variables --------------------
;****************************************************************************

secH:         ds 1     ; Seconds counter, Hi byte
secL:         ds 1     ; Seconds counter, Lo byte
PotSpos:      ds 1     ; Control pot Stbd position, 8 bit ADC reading
PotPpos:      ds 1     ; Control pot Port position, 8 bit ADC reading
Bat:          ds 1     ; Battery Voltage, 8 bit ADC reading
PotSpct:      ds 1     ; PotS % of full voltage (0-99)
PotPpct:      ds 1     ; PotP % of full voltage (0-99)
Volts:        ds 1     ; Battery voltage to 0.1V resolution
SBCD:         ds 1     ; PotSpct expressed in BCD
PBCD:         ds 1     ; PotPpct expressed in BCD
SLSDBCD:      ds 1     ; Stbd Least Significant Digit BCD value
SMSDBCD:      ds 1     ; Stbd Most Significant Digit BCD value
PLSDBCD:      ds 1     ; Port Least Significant Digit BCD value
PMSDBCD:      ds 1     ; Port Most Significant Digit BCD value
SSpwMnH:      ds 1     ; Servo S OC value at open choke Hi byte
SSpwMnL:      ds 1     ; Servo S OC value at open choke Lo byte

;Memory Location $0050 (decimal 80)

SSpwMxH:      ds 1     ; Servo S OC value at closed choke Hi byte
SSpwMxL:      ds 1     ; Servo S OC value at closed choke Lo byte
SSpwSpnH:     ds 1     ; Servo S span Hi byte
SSpwSpnL:     ds 1     ; Servo 0 span Lo byte (SSpwMxH:SSpwMxL -
                       ; SSpwMnH:SSpwMnL = SSpwSpnH:SSpwSpnL)
SSmulH:       ds 1     ; Servo S multiplicand Hi byte
SSmulM:       ds 1     ; Servo S multiplicand Mid byte
SSmulL:       ds 1     ; Servo S multiplicand Lo byte
                       ;(SSpwSpnH:SSpwSpnL * PotSpos = SSmulH:SSmulM:SSmulL)
SSposH:       ds 1     ; Servo S commanded position Hi byte
SSposL:       ds 1     ; Servo S commanded position Lo byte
                       ;(SSmulH:SSmulM:SSmulL / 256 = SSposH:SSposL)
SrvSpwH:      ds 1     ; Servo S OC for commanded position Hi byte
SrvSpwL:      ds 1     ; Servo S OC for commanded position Lo byte
                       ;(SSposH:SSposL + SSpwMnH:SSpwMnL = SrvSpwH:SrvSpwL)
SPpwMnH:      ds 1     ; Servo P OC value at open choke Hi byte
SPpwMnL:      ds 1     ; Servo P OC value at open choke Lo byte
SPpwMxH:      ds 1     ; Servo P OC value at closed choke Hi byte
SPpwMxL:      ds 1     ; Servo P OC value at closed choke Lo byte
SPpwSpnH:     ds 1     ; Servo P span Hi byte

;Memory Location $0060 (decimal 96)

SPpwSpnL:     ds 1     ; Servo P span Lo byte (SPpwMxH:SPpwMxL -
                       ; SPpwMnH:SPpwMnL = SPpwSpnH:SPpwSpnL)
SPmulH:       ds 1     ; Servo P multiplicand Hi byte
SPmulM:       ds 1     ; Servo P multiplicand Mid byte
SPmulL:       ds 1     ; Servo P multiplicand Lo byte
                       ;(SPpwSpnH:SPpwSpnL * PotPpos = SPmulH:SPmulM:SPmulL)
SPposH:       ds 1     ; Servo P commanded position Hi byte
SPposL:       ds 1     ; Servo P commanded position Lo byte
                       ;(SPmulH:SPmulM:SPmulL / 256 = SPposH:SPposL)
SrvPpwH:      ds 1     ; Servo P OC for commanded position Hi byte
SrvPpwL:      ds 1     ; Servo P OC for commanded position Lo byte
                       ;(SPposH:SPposL + SPpwMnH:SPpwMnL = SrvPpwH:SrvPpwL)


;****************************************************************************
; This marks the end of the real time download variables, 40 in total
;****************************************************************************

;****************************************************************************
; ----------------------- Time Clock Variables ------------------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

uSx100:         ds 1	 ; 100 Microseconds counter
mS:             ds 1	 ; 1 Millisecond counter
mSx4:           ds 1     ; 4 Milliseconds counter
;*secL:           ds 1     ; Seconds counter, Lo byte
;*secH:           ds 1     ; Seconds counter, Hi byte


;****************************************************************************
; --------------------- 8 bit ADC input Variables --------------------------
; ----------------- (ordered list from "ADC0" to "Bat") --------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

;*PotSpos:      ds 1     ; Control pot S position, 8 bit ADC reading
;*PotPpos:      ds 1     ; Control pot P position, 8 bit ADC reading
;*Bat:          ds 1     ; Battery Voltage, 8 bit ADC reading
adsel:          ds 1     ; ADC Selector Variable

;****************************************************************************
; --------------------- ADC Conversion Variables --------------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

;*PotSPct:      ds 1     ; PotS % of full voltage (0-99)
;*PotPPct:      ds 1     ; PotP % of full voltage (0-99)
;*Volts:        ds 1     ; Battery voltage to 0.1V resolution

;****************************************************************************
; ------------------- Display Calculation Variables ------------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

;*SBCD:         ds 1     ; PotSpct expressed in BCD
;*PBCD:         ds 1     ; PotPpct expressed in BCD
;*SLSDBCD:      ds 1     ; Stbd Least Significant Digit BCD value
;*SMSDBCD:      ds 1     ; Stbd Most Significant Digit BCD value
;*PLSDBCD:      ds 1     ; Port Least Significant Digit BCD value
;*PMSDBCD:      ds 1     ; Port Most Significant Digit BCD value

;****************************************************************************
; ------------------- Servo PW Calculation Variables ------------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

;*SSpwMnH:      ds 1     ; Servo S OC value at open choke Hi byte
;*SSpwMnL:      ds 1     ; Servo S OC value at open choke Lo byte
;*SSpwMxH:      ds 1     ; Servo S OC value at closed choke Hi byte
;*SSpwMxL:      ds 1     ; Servo S OC value at closed choke Lo byte
;*SSpwSpnH:     ds 1     ; Servo S span Hi byte
;*SSpwSpnL:     ds 1     ; Servo 0 span Lo byte (SSpwMxH:SSpwMxL -
                       ; SSpwMnH:SSpwMnL = SSpwSpnH:SSpwSpnL)
;*SSmulH:       ds 1     ; Servo S multiplicand Hi byte
;*SSmulM:       ds 1     ; Servo S multiplicand Mid byte
;*SSmulL:       ds 1     ; Servo S multiplicand Lo byte
                       ;(SSpwSpnH:SSpwSpnL * PotSpos = SSmulH:SSmulM:SSmulL)
;*SSposH:       ds 1     ; Servo S commanded position Hi byte
;*SSposL:       ds 1     ; Servo S commanded position Lo byte
                       ;(SSmulH:SSmulM:SSmulL / 256 = SSposH:SSposL)
;*SrvSpwH:      ds 1     ; Servo S OC for commanded position Hi byte
;*SrvSpwL:      ds 1     ; Servo S OC for commanded position Lo byte
                       ;(SSposH:SSposL + SSpwMnH:SSpwMnL = SrvSpwH:SrvSpwL)
;*SPpwMnH:      ds 1     ; Servo P OC value at open choke Hi byte
;*SPpwMnL:      ds 1     ; Servo P OC value at open choke Lo byte
;*SPpwMxH:      ds 1     ; Servo P OC value at closed choke Hi byte
;*SPpwMxL:      ds 1     ; Servo P OC value at closed choke Lo byte
;*SPpwSpnH:     ds 1     ; Servo P span Hi byte
;*SPpwSpnL:     ds 1     ; Servo P span Lo byte (SPpwMxH:SPpwMxL -
                       ; SPpwMnH:SPpwMnL = SPpwSpnH:SPpwSpnL)
;*SPmulH:       ds 1     ; Servo P multiplicand Hi byte
;*SPmulM:       ds 1     ; Servo P multiplicand Mid byte
;*SPmulL:       ds 1     ; Servo P multiplicand Lo byte
                       ;(SPpwSpnH:SPpwSpnL * PotPpos = SPmulH:SPmulM:SPmulL)
;*SPposH:       ds 1     ; Servo P commanded position Hi byte
;*SPposL:       ds 1     ; Servo P commanded position Lo byte
                       ;(SPmulH:SPmulM:SPmulL / 256 = SPposH:SPposL)
;*SrvPpwH:      ds 1     ; Servo P OC for commanded position Hi byte
;*SrvPpwL:      ds 1     ; Servo P OC for commanded position Lo byte
                       ;(SPposH:SPposL + SPpwMnH:SPpwMnL = SrvPpwH:SrvPpwL)

 ;****************************************************************************
; --------------------- Status Bit Field Variables --------------------------
; - NOTE! ";*"  denotes that this variable is listed with RS232 variables
;****************************************************************************

inputs:         ds 1     ; Input status bit field variable


;****************************************************************************
; ------------------------ Temporary variables ------------------------------
;****************************************************************************

tmp1          ds     1
tmp2          ds     1
tmp3          ds     1

 ;Memory Location $0070 (decimal 112)

tmp4          ds     1
tmp5          ds     1
tmp6          ds     1
tmp7          ds     1
tmp8          ds     1
tmp21         ds     1
local_tmp     ds     1

;****************************************************************************
; ------- Serial Communications Interface Parameters and Variables ---------
;****************************************************************************

txcnt:        ds 1     ; SCI transmitter count (incremented)
txgoal:       ds 1     ; SCI number of bytes to transmit
txmode:       ds 1     ; Transmit mode flag
rxoffset:     ds 1     ; Offset placeholder when receiving VE/constants
                       ; vis. SCI

;****************************************************************************
; --------------------- Flash Burner Routine Variables ----------------------
;****************************************************************************

burnSrc:      ds 2T    ; Burn routine variable
burnDst:      ds 2T    ; Burn routine variable
burnCount:    ds 1T    ; Burn routine variable

;Memory Location $0080 (decimal 128)

;****************************************************************************
; ----------------------------- Misc. Variables -----------------------------
;****************************************************************************

LoopCntr:      ds 1     ; Loop counter for main loop frequency check
dsel:          ds 1     ; Display sequencing counter
Spare1:        ds 1     ; Blank place holder for 16 byte increments
Spare2:        ds 1     ; Blank place holder for 16 byte increments
Spare3:        ds 1     ; Blank place holder for 16 byte increments
Spare4:        ds 1     ; Blank place holder for 16 byte increments
Spare5:        ds 1     ; Blank place holder for 16 byte increments
Spare6:        ds 1     ; Blank place holder for 16 byte increments
Spare7:        ds 1     ; Blank place holder for 16 byte increments
Spare8:        ds 1     ; Blank place holder for 16 byte increments
Spare9:        ds 1     ; Blank place holder for 16 byte increments
Spare10:       ds 1     ; Blank place holder for 16 byte increments
Spare11:       ds 1     ; Blank place holder for 16 byte increments
Spare12:       ds 1     ; Blank place holder for 16 byte increments
Spare13:       ds 1     ; Blank place holder for 16 byte increments
Spare14:       ds 1     ; Blank place holder for 16 byte increments

;Memory Location $0090 (decimal 144)

ms_ram_end:

;****************************************************************************
; -------------------- Flash Configuration constants ------------------------
;  "SSpwMnH" is entry point, everything is offset from this point.
;****************************************************************************

ms_rf_start:

SSpwMnH_F   rmb $01     ; Servo S OC value at open choke Hi byte (flash)
SSpwMnL_F   rmb $01     ; Servo S OC value at open choke Lo byte (flash)
SSpwMxH_F   rmb $01     ; Servo S OC value at closed choke Hi byte (flash)
SSpwMxL_F   rmb $01     ; Servo S OC value at closed choke Lo byte (flash)
SPpwMnH_F   rmb $01     ; Servo P OC value at open choke Hi byte (flash)
SPpwMnL_F   rmb $01     ; Servo P OC value at open choke Lo byte (flash)
SPpwMxH_F   rmb $01     ; Servo P OC value at closed choke Hi byte (flash)
SPpwMxL_F   rmb $01     ; Servo P OC value at closed choke Lo byte (flash)
Blank       rmb $40     ; 56 Blank place holders for 64 byte increments

;Memory Location $00D0 (decimal 208)

ms_rf_end:

;****************************************************************************
; ---------------------------- Misc. Equates --------------------------------
;****************************************************************************

ms_ram_size       equ {ms_ram_end-ms_ram_start}
ms_rf_size        equ {ms_rf_end-ms_rf_start}
ms_total_ram_size equ {ms_rf_end-ms_ram_start}




