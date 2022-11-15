;****************************************************************************
;
;                         MS_Servo_V1.asm 10/10/05
;
;       By Robert Hiebert with technical assistance from Dan Williams
;
;****************************************************************************

;****************************************************************************
; -------------------------------- Background ------------------------------
;
; - This was developed to control a servo operated choke on the Holley 4160
;   marine carburetor. OEM equipment on a 1993 Bayliner 3288 with twin Ford
;   351 CID Windsor engines, the original bimetal electric chokes were
;   difficult to set up for all conditions, and tended to run the engines
;   rich until fully warmed up. Manual chokes were impractical to install,
;   given the configuration and length of cables involved. This system uses
;   Hitec HS-311 servo motors, as used in model aircraft etc., to control
;   the choke plate angle. They run on a regulated 5 volt supply as part
;   of the controller unit. The chokes for both engines are controlled
;   individually by dash mounted pots. Each engine has a dash mounted 2x7
;   segment display to indicate percent of pot position, which is also
;   percent of choke position, from 0% to 99%. There is no automatic
;   control, or choke angle feed back. It is up to the operator to adjust
;   the throttle and choke angle to where the engine runs best at the
;   desired engine speed and given engine temperature. This assumes that
;   the ignition system is in a good state of tune, and that the idle
;   mixtures and idle speed throttle stop is set correctly.
;
;   The code follows the same format as the code used in Megasquirt and it's
;   derivitives and is extensively commented, as much for our benefit as
;   for those wishing to understand it for their modifications. It uses
;   "Megatune" for communication, and to change the flash configurable
;   constants.
;   None of this would be possible if not for the brilliant work of all of
;   those connected with the MS projects. In particular, Bruce Bowling,
;   Al Grippo, Magnus Bjelk, Tom Hafner, Lance Gardiner, Eric Fahlgren,
;   and a host of others I don't know of.
;
;****************************************************************************

*****************************************************************************
**
**   M E G A S Q U I R T - 2 0 0 1 - V2.00
**
**   (C) 2002 - B. A. Bowling And A. C. Grippo
**
**   This header must appear on all derivatives of this code.
**
*****************************************************************************

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

.header 'MS_Servo_V1'                ; Listing file title
.pagewidth 130                       ; Listing file width
.pagelength 90                       ; Listing file height

.nolist                              ; Turn off listing file
     include "gp32.equ"              ; Include HC 908 equates
.list                                ; Turn on listing file
     org      ram_start              ; Origin  Memory location $0040=64
     include "MS_Servo_V1.inc"       ; Include definitions for
                                     ; MS_Servo_V1.asm

;***************************************************************************
;
; Main Routine Here - Initialization and main loop
;
; Note: Org down 256 bytes below the "rom_start" point
;       because of erase bug in bootloader routine
;
; Note: Items commented out after the Start entry point are
;       taken care of in the Boot_R12.asm code
;
;***************************************************************************


	org	{rom_start + 256}  ; Origin at memory location
                                   ; $8000+256 = 32,768+256 = 33,024=$8100

Start:
	ldhx	#init_stack+1    ; Load index register with value in
                                 ; init_stack+1(Set the stack Pointer)
	txs                      ; Transfer value in index register Lo byte
                                 ; to stack
                                 ;(Move before burner to avoid conflict)

;* Note - uncomment this code if you do not use the Bootloader to initilize *
;       clra
;	sta	copctl
;	mov	#%00000001,config2
;	mov	#%00001001,config1
;	mov	#%00000001,config1
;	ldhx	#ram_last+1        ; Set the stack Pointer
;	txs                      ; to the bottom of RAM

;****************************************************************************
; - Set the phase lock loop for a bus frequency of 8.003584mhz
;  (Boot loader initially sets it at 7.3728mhz)
;****************************************************************************

;PllSet:
     bclr     BCS,PCTL       ; Select external Clock Reference
     bclr     PLLON,PCTL     ; Turn off PLL
     mov      #$02,PCTL      ; Move %00000010 into PLL Control Register
                             ;(PLL Interrupts Disabled)
                             ;(No change in lock condition(flag))
                             ;(PLL off)
                             ;(CGMXCLK divided by 2 drives CGMOUT)
                             ;(VCO pwr of 2 mult = 1(E=0))
                             ;(Prescale mult = 4(P=2))
     mov      #$03,PMSH      ; Move %00000011 into PLL Multiplier Select
                             ; Register Hi (Set N MSB)
     mov      #$D1,PMSL      ; Move %11010001 into PLL Multiplier Select
                             ; Register Lo (Set N LSB)($84 for 7.37 MHz)
     mov      #$D0,PMRS      ; Move %11010000 into PLL VCO Range Select
                             ; Register (Set L) ($C0 for 7.37 MHz)
     mov      #$01,PMDS      ; Move %00000001 into Reference Divider Select
                             ; Register (Set "RDS0" bit (default value of 1)
     bset     AUTO,PBWC      ; Set "Auto" bit of PLL Bandwidth Control Register
     bset     PLLON,PCTL     ; Turn on PLL

PLL_WAIT:
     brclr   LOCK,PBWC,PLL_WAIT     ; If "Lock" bit of PLL Bandwidth Control
                                    ; Register is clear, branch to PLL_WAIT:
     bset    BCS,PCTL               ; Set "BCS" bit of PLL Control Register
                                    ;(CGMXCLK divided by 2 drives CGMOUT)
                                    ;(Select VCO as base clock)

;****************************************************************************
; ------------- Set up the port data-direction registers --------------------
;               Set directions,
;               Preset state of pins to become outputs
;               Set all unused pins to outputs initialized Lo
;****************************************************************************

;****************************************************************************
; - Port A SN7448 Display Driver Control
;****************************************************************************

; Port A
     clr     PORTA           ; Clear Port A Data Register
                             ;(Preinit all pins low)
     lda     #$FF            ; Load accumulator with %11111111
                             ;(port direction setup 1 = output)
     sta     DDRA            ; Copy to Port A Data Direction Register
                             ; Set all as outputs (Port MSD,Port LSD,
                             ; Stbd LSD,Stbd MSD,"D","C","B","A")

;****************************************************************************
; - Set up ADC inputs
;****************************************************************************

; Port B
     clr     PORTB           ; Clear Port B Data Register
                             ;(Preinit all pins low)
     clr     DDRB            ; Clear Port B Data Direction Register
                             ;(Set as ADC inputs, "ADSEL" selects channel)

;****************************************************************************
; - Port C not used
;****************************************************************************

; Port C
     clr     PORTC           ; Clear Port C Data Register
                             ;(Preinit all pins low)
     lda     #$FF            ; Load accumulator with %11111111
                             ;(port direction setup 1 = output)
     sta     DDRC            ; Copy to Port C Data Direction Register
                             ;(Set all as outputs
                             ; NA,NA,NA,NA,NA,NA,NA,NA)

;****************************************************************************
; - Set Port D for servo control
;****************************************************************************

; Port D
     clr     PORTD           ; Clear Port D Data Register
                             ;(Preinit all pins low)
     lda     #$FF            ; Load accumulator with %11111111
                             ;(port direction setup 1 = output)
     sta     DDRD            ; Copy to Port D Data Direction Register
                             ;(Set all as outputs
                             ; NA,NA,Stbd Srv,Port Srv,LoopFrq,NA,NA,NA)

;****************************************************************************
; - Set up Port E.(The Motorola manual states that it is not necessarry to
;   set up Port E when SCI is enabled, but we'll do it anyway).
;****************************************************************************

; Port E
     clr     PORTE           ; Clear Port E Data Register (to avoid glitches)
     lda     #$01            ; Load accumulator with %00000001
                             ; (set up port directions, 1 = out)
                             ; (Serial Comm Port)
     sta     DDRE            ; Copy to Port E Data Direction Register


;****************************************************************************
; Set up TIM2 as a free running ~1us counter. Set Channel 0 output compare
; to generate the ~100us(0.1ms) clock tick interrupt vector "TIM2CH0_ISR:"
;****************************************************************************

     mov     #$33,T2SC       ; Move %00110011 into Timer2
                             ; Status and Control Register
                             ;(Disable interrupts, stop timer)
                             ;(Prescale and counter cleared))
                             ;(Prescale for bus frequency / 8)
     mov     #$FF,T2MODH     ; Move decimal 255 into T2 modulo reg Hi
     mov     #$FF,T2MODL     ; Move decimal 255 into T2 modulo reg Lo
                             ;(free running timer)
     mov     #$00,T2CH0H     ; Move decimal 0 into T1CH0 O/C register Hi
     mov     #$64,T2CH0L     ; Move decimal 100 into T1CH0 O/C register Lo
                             ;(~100uS)=(~0.1ms)
     mov     #$54,T2SC0      ; Move %01010100 into Timer2
                             ; channel 0 status and control register
                             ; (Output compare, interrupt enabled)
     mov     #$03,T2SC       ; Move %00000011 into Timer2
                             ; Status and Control Register
                             ; Disable overflow interrupts, counter active
                             ; Prescale for bus frequency / 8
                             ; 8,003584hz/8=1000448hz
                             ; = .0000009995sec


;****************************************************************************
; Set up TIM1 as a modulo count up 50 HZ timer (20mS period) with 1uS
; resolution, for servo signal control timing. Set channels 0 and 1 for
; output compare, pulsewidth control of servos. Mid point @ 1500 uS, full
; left @ 1100 uS, full right at 1900 uS.
; Servo Port on T1SC0 and Servo Stbd on T1SC1, initialize for 0 uS pulse
; width so that the servo doesn't move until it gets a valid signal.
; Interrupt vector "TIM1OV_ISR:"
;****************************************************************************

     mov     #$33,T1SC       ; Move %00110011 into Timer1
                             ; Status and Control Register
                             ;(Disable interrupts, stop timer)
                             ;(Prescale and counter cleared))
                             ;(Prescale for bus frequency / 8)
     mov     #$4E,T1MODH     ; Move decimal 78 into T1 modulo reg Hi
     mov     #$20,T1MODL     ; Move decimal 32 into T1 modulo reg Lo
                             ;(20,000 x 1uS = 20mS)
     clr     T1CH0H          ; Clear T1CH0 register Hi
     clr     T1CH0L          ; Clear T1CH0 register Lo
     clr     T1CH1H          ; Clear T1CH1 register Hi
     clr     T1CH1L          ; Clear T1CH1 register Lo
     mov     #$1E,T1SC0      ; Move %00011110 into Timer1
                             ; Channel 0 Status and Control Register
                             ;(Channel 0 interrupt requests disabled,)
                             ;(Buffered OC disabled, set output on compare)
                             ;(toggle in overflow)
     mov     #$1E,T1SC1      ; Move %000111110 into Timer1
                             ; Channel 1 Status and Control Register
                             ;(Channel 1 interrupt requests disabled,)
                             ;(Buffered OC disabled, set output on compare)
                             ;(toggle in overflow)
     mov     #$43,T1SC       ; Move %01000011 into Timer1
                             ; Status and Control Register
                             ; Enable overflow interrupts, counter active
                             ; Prescale for bus frequency / 8
                             ; 8,003584hz/8=1000448hz
                             ; = .0000009995sec


;****************************************************************************
; - Set up Serial Communications Interface Module
;****************************************************************************

     lda      #$30           ; Load accumulator with %110000
     sta      SCBR           ; Copy to SCI Baud Rate Register
                             ; 8003584/(64*13*1)=9619.7 baud
     bset     ensci,SCC1     ; Set enable SCI bit of SCI Control Register 1
                             ; (Enable SCI)
     bset     RE,SCC2        ; Set receiver enable bit of SCI Control Reg. 2
                             ; (Enable receiver)
     bset     SCRIE,SCC2     ; Set SCI receive interrupt enable bit of
                             ; SCI Control Register 2 (Enable Rcv. Interrupt)
     lda      SCS1           ; Load accumulator with SCI Status Register 1
                             ; (Clear SCI transmitter Empty Bit)
     clr      txcnt          ; Clear SCI transmitter count
                             ; (incremented)(characters transmitted)
     clr      txgoal         ; Clear SCI number of bytes to transmit
                             ; (characters to be transmitted)


;****************************************************************************
; - Load the configurable constants from Flash to RAM
;****************************************************************************

     clrh                        ; Clear index register Hi byte
     clrx                        ; Clear index register Lo byte

load_ram:
     lda     ms_rf_start_f,x     ; Load accumulator with value in
                                 ; "ms_rf_start_f" table, offset in index
                                 ; register Lo byte
     sta     ms_rf_start,x       ; Copy to "ms_rf_start" table, offset in
                                 ; index register Lo byte
     aix     #1                  ; Add immediate value (1)to index register
                                 ; H:X<_(H:X)+(16<<M)
     cphx    #ms_rf_size         ; Compare index register with memory
                                 ; (H:X)-(M:M+$0001)
     bne     load_ram            ; If the Z bit of CCR is clear, branch to
                                 ; load_ram:


;****************************************************************************
; - Clear all variables
;****************************************************************************

     clr     secH       ; Seconds counter, Hi byte
     clr     secL       ; Seconds counter, Lo byte
     clr     PotSpos    ; Control pot Stbd position, 8 bit ADC reading
     clr     PotPpos    ; Control pot Port position, 8 bit ADC reading
     clr     Bat        ; Battery Voltage, 8 bit ADC reading
     clr     PotSpct    ; PotS % of full voltage (0-99)
     clr     PotPpct    ; PotP % of full voltage (0-99)
     clr     Volts      ; Battery voltage to 0.1V resolution
     clr     SBCD       ; PotSpct expressed in BCD
     clr     PBCD       ; PotPpct expressed in BCD
     clr     SLSDBCD    ; Stbd Least Significant Digit BCD value
     clr     SMSDBCD    ; Stbd Most Significant Digit BCD value
     clr     PLSDBCD    ; Port Least Significant Digit BCD value
     clr     PMSDBCD    ; Port Most Significant Digit BCD value
     clr     SSpwMnH    ; Servo S OC value at open choke Hi byte
     clr     SSpwMnL    ; Servo S OC value at open choke Lo byte
     clr     SSpwMxH    ; Servo S OC value at closed choke Hi byte
     clr     SSpwMxL    ; Servo S OC value at closed choke Lo byte
     clr     SSpwSpnH   ; Servo S span Hi byte
     clr     SSpwSpnL   ; Servo 0 span Lo byte (SSpwMxH:SSpwMxL -
                        ; SSpwMnH:SSpwMnL = SSpwSpnH:SSpwSpnL)
     clr     SSmulH     ; Servo S multiplicand Hi byte
     clr     SSmulM     ; Servo S multiplicand Mid byte
     clr     SSmulL     ; Servo S multiplicand Lo byte
                        ;(SSpwSpnH:SSpwSpnL * PotSpos = SSmulH:SSmulM:SSmulL)
     clr     SSposH     ; Servo S commanded position Hi byte
     clr     SSposL     ; Servo S commanded position Lo byte
                        ;(SSmulH:SSmulM:SSmulL / 256 = SSposH:SSposL)
     clr     SrvSpwH    ; Servo S OC for commanded position Hi byte
     clr     SrvSpwL    ; Servo S OC for commanded position Lo byte
                        ;(SSposH:SSposL + SSpwMnH:SSpwMnL = SrvSpwH:SrvSpwL)
     clr     SPpwMnH    ; Servo P OC value at open choke Hi byte
     clr     SPpwMnL    ; Servo P OC value at open choke Lo byte
     clr     SPpwMxH    ; Servo P OC value at closed choke Hi byte
     clr     SPpwMxL    ; Servo P OC value at closed choke Lo byte
     clr     SPpwSpnH   ; Servo P span Hi byte
     clr     SPpwSpnL   ; Servo P span Lo byte (SPpwMxH:SPpwMxL -
                        ; SPpwMnH:SPpwMnL = SPpwSpnH:SPpwSpnL)
     clr     SPmulH     ; Servo P multiplicand Hi byte
     clr     SPmulM     ; Servo P multiplicand Mid byte
     clr     SPmulL     ; Servo P multiplicand Lo byte
                        ;(SPpwSpnH:SPpwSpnL * PotPpos = SPmulH:SPmulM:SPmulL)
     clr     SPposH     ; Servo P commanded position Hi byte
     clr     SPposL     ; Servo P commanded position Lo byte
                        ;(SPmulH:SPmulM:SPmulL / 256 = SPposH:SPposL)
     clr     SrvPpwH    ; Servo P OC for commanded position Hi byte
     clr     SrvPpwL    ; Servo P OC for commanded position Lo byte
                        ;(SPposH:SPposL + SPpwMnH:SPpwMnL = SrvPpwH:SrvPpwL)
     clr     uSx100     ; 100 Microseconds counter
     clr     mS         ; 1 Millisecond counter
     clr     mSx4       ; 4 Milliseconds counter
     clr     adsel      ; ADC Selector Variable
     clr     tmp1       ; Temporary variable
     clr     tmp2       ; Temporary variable
     clr     tmp3       ; Temporary variable
     clr     tmp4       ; Temporary variable
     clr     tmp5       ; Temporary variable
     clr     tmp6       ; Temporary variable
     clr     tmp7       ; Temporary variable
     clr     tmp8       ; Temporary variable
     clr     tmp21      ; Temporary variable
     clr     local_tmp  ; Temporary variable
     clr     txcnt      ; SCI transmitter count (incremented)
     clr     txgoal     ; SCI number of bytes to transmit
     clr     txmode     ; Transmit mode flag
     clr     rxoffset   ; Offset placeholder when receiving VE/constants
     clr     burnSrc    ; Burn routine variable
     clr     burnDst    ; Burn routine variable
     clr     burnCount  ; Burn routine variable
     clr     LoopCntr   ; Loop counter for main loop frequency check
     clr     dsel       ; Display sequencing counter
     clr     Spare1     ; Blank place holder for 16 byte increments
     clr     Spare2     ; Blank place holder for 16 byte increments
     clr     Spare3     ; Blank place holder for 16 byte increments
     clr     Spare4     ; Blank place holder for 16 byte increments
     clr     Spare5     ; Blank place holder for 16 byte increments
     clr     Spare6     ; Blank place holder for 16 byte increments
     clr     Spare7     ; Blank place holder for 16 byte increments
     clr     Spare8     ; Blank place holder for 16 byte increments
     clr     Spare9     ; Blank place holder for 16 byte increments
     clr     Spare10    ; Blank place holder for 16 byte increments
     clr     Spare11    ; Blank place holder for 16 byte increments
     clr     Spare12    ; Blank place holder for 16 byte increments
     clr     Spare13    ; Blank place holder for 16 byte increments
     clr     Spare14    ; Blank place holder for 16 byte increments


;****************************************************************************
; - Copy the Servo Min and Max pulse width values from RAM to direct page
;   (just in case the program expands to place these out of direct page)
;****************************************************************************

     lda     SSpwMnH_F     ; Servo S OC value at open choke Hi byte (flash)
     sta     SSpwMnH       ; Servo S OC value at open choke Hi byte
     lda     SSpwMnL_F     ; Servo S OC value at open choke Lo byte (flash)
     sta     SSpwMnL       ; Servo S OC value at open choke Lo byte
     lda     SSpwMxH_F     ; Servo S OC value at closed choke Hi byte (flash)
     sta     SSpwMxH       ; Servo S OC value at closed choke Hi byte
     lda     SSpwMxL_F     ; Servo S OC value at closed choke Lo byte (flash)
     sta     SSpwMxL       ; Servo S OC value at closed choke Lo byte
     lda     SPpwMnH_F     ; Servo P OC value at open choke Hi byte (flash)
     sta     SPpwMnH       ; Servo P OC value at open choke Hi byte
     lda     SPpwMnL_F     ; Servo P OC value at open choke Lo byte (flash)
     sta     SPpwMnL       ; Servo P OC value at open choke Lo byte
     lda     SPpwMxH_F     ; Servo P OC value at closed choke Hi byte (flash)
     sta     SPpwMxH       ; Servo P OC value at closed choke Hi byte
     lda     SPpwMxL_F     ; Servo P OC value at closed choke Lo byte (flash)
     sta     SPpwMxL       ; Servo P OC value at closed choke Lo byte

;****************************************************************************
; - Calculate the Servo pulse width spans
;   SSpwMxH:SSpwMxL - SSpwMnH:SSpwMnL = SSpwSpnH:SSpwSpnL
;   SPpwMxH:SPpwMxL - SPpwMnH:SPpwMnL = SPpwSpnH:SPpwSpnL
;****************************************************************************

     lda     SSpwMxL     ; Load accumulato with value in "SSpwMxL"
     sub     SSpwMnL     ; Subtract A<-(A)-(M)
     sta     SSpwSpnL    ; Copy result to "SSpwSpnL"
     lda     SSpwMxH     ; Load accumulator with value in "SSpwMxH"
     sbc     SSpwMnH     ; Subtract with carry A<-(A)-(M)-(C)
     sta     SSpwSpnH    ; Copy result to "SSpwSpnH"
     lda     SPpwMxL     ; Load accumulato with value in "SPpwMxL"
     sub     SPpwMnL     ; Subtract A<-(A)-(M)
     sta     SPpwSpnL    ; Copy result to "SPpwSpnL"
     lda     SPpwMxH     ; Load accumulator with value in "SPpwMxH"
     sbc     SPpwMnH     ; Subtract with carry A<-(A)-(M)-(C)
     sta     SPpwSpnH    ; Copy result to "SPpwSpnH"

;****************************************************************************
; - Set up clock source for ADC
;   Do an initial conversion just to stabilize the ADC
;****************************************************************************

Stb_ADC:
     lda     #$70                 ; Load accumulator with %01110000
     sta     ADCLK                ; Copy to ADC Clock Register
                                  ;( bus clock/8 = ~1mhz )
     lda     #$02                 ; Load accumulator with %00000010
                                  ;(one conversion, no interrupt, chan AD2)
     sta     ADSCR                ; Copy to ADC Status and Control Register

ADCWait:
     brclr   coco,ADSCR,ADCWait   ; If "conversions complete flag" bit of
                                  ; ADC Status and Control Register is clear
                                  ; branch to ADCWait lable
                                  ;(keep looping while COnversion
                                  ; COmplete flag = 0)
     lda     ADR                  ; Load accumulator with value in ADC Result
                                  ; Variable (read value from ADc Result)
     sta     PotSpos              ; Copy to Control Pot Stbd position,
                                  ; 8 bit ADC reading

;****************************************************************************
; - Now get valid ADC readings for Pot positions and battery voltage
;****************************************************************************

     lda     #$02                 ; Load accumulator with %00000010
                                  ;(one conversion, no interrupt, chan AD2)
     sta     ADSCR                ; Copy to ADC Status and Control Register

ADCWait1:
     brclr   coco,ADSCR,ADCWait1  ; If "conversions complete flag" bit of
                                  ; ADC Status and Control Register is clear
                                  ; branch to ADCWait1:
                                  ;(keep looping while COnversion
                                  ; COmplete flag = 0)
     lda     ADR                  ; Load accumulator with value in ADC Result
                                  ; Variable (read value from ADc Result)
     sta     PotSpos              ; Copy to Control Pot Stbd position,
                                  ; 8 bit ADC reading
     lda     #$03                 ; Load accumulator with %00000011
                                  ;(one conversion, no interrupt, chan AD3)
     sta     ADSCR                ; Copy to ADC Status and Control Register

ADCWait2:
     brclr   coco,ADSCR,ADCWait2  ; If "conversions complete flag" bit of
                                  ; ADC Status and Control Register is clear
                                  ; branch to ADCWait2:
                                  ;(keep looping while COnversion
                                  ; COmplete flag = 0)
     lda     ADR                  ; Load accumulator with value in ADC Result
                                  ; Variable (read value from ADc Result)
     sta     PotPpos              ; Copy to Control Pot Port position,
                                  ; 8 bit ADC reading
     lda     #$04                 ; Load accumulator with %00000100
                                  ;(one conversion, no interrupt, chan AD4)
     sta     ADSCR                ; Copy to ADC Status and Control Register

ADCWait3:
     brclr   coco,ADSCR,ADCWait3  ; If "conversions complete flag" bit of
                                  ; ADC Status and Control Register is clear
                                  ; branch to ADCWait3:
                                  ;(keep looping while COnversion
                                  ; COmplete flag = 0)
     lda     ADR                  ; Load accumulator with value in ADC Result
                                  ; Variable (read value from ADc Result)
     sta     Bat                  ; Copy to Battery Voltage 8 bit ADC reading
;;     mov     #$02,adsel           ; Move decimal 2 to ADC channel selector
     clr     adsel                ; Clear ADC channel selector variable


;****************************************************************************
;- Enable Interrupts
;****************************************************************************

     cli                          ; Clear intrupt mask
                                  ;( Turn on all interrupts now )


;****************************************************************************
;****************************************************************************
;********************    M A I N  E V E N T  L O O P     ********************
;****************************************************************************
;****************************************************************************

;****************************************************************************
; - Toggle pin 3 on Port D each program loop so frequency can be checked
;   with a frequency meter or scope. (for program developement)
;****************************************************************************

LOOPER:
     com     LoopCntr         ; Ones compliment "LoopCntr"
                              ;(flip state of "LoopCntr")
     bne     SET_LOOPCHK      ; If the Z bit of CCR is clear, branch
                              ; to SET_LOOPCHK
     bclr    LoopFrq,PORTD    ; Clear bit 3 of Port D (Program Loop LED)
     bra     LOOPCHK_DONE     ; Branch to LOOPCHK_DONE:

SET_LOOPCHK:
     bset    LoopFrq,PORTD    ; Set bit 3 of Port D (Program Loop LED)

LOOPCHK_DONE:


;****************************************************************************
; - Update the ADC readings and conversions. This is done only once per ADC
;   conversion completion, in the first pass through the main loop after the
;   ADC_ISR Interrupt routine has been completed.
;****************************************************************************

     brset   adcc,inputs,ADC_LOOKUPS  ; If "adcc" bit of "inputs" variable
                                      ; is set, branch to ADC_LOOKUPS:
     jmp     NO_ADC_PASS              ; Jump to NO_ADC_PASS:

ADC_LOOKUPS:

;****************************************************************************
; - Calculate the percent of total voltage read from Pot S and Pot P, and
;   store as "PotSpct" and "PotPpct". This is a linear interpolation, with the
;   "PotSpos" and "PotPpos" values ranging from 0 to 255, and "PotSpct" and
;   "PotPpct" values ranging from 0 to 99. (to fit in a 2x7 segment display)
;
; Method where: (Pot P is calculated in a similar fashion)
;
; PotSpos  = Stbd Pot ADC reading
; PotSpct  = Stbd Pot percent of total voltage (0-99)
;
;   PotSpos * 100 / 256 = PotSpct
;
;****************************************************************************

;****************************************************************************
; - Stbd pot calculations
;****************************************************************************

POTSP_CALC:
     lda     PotSpos        ; Load accumulator with value in "PotSpos"
     cmp     #$01           ; Compare value in accumulator with decimal 1
     bls     POTS_LOW       ; If A<=decimal 1, branch to POTS_LOW:
     cmp     #$FD           ; Compare value in accumulator with decimal 253
     bhs     POTS_HI        ; If A>= decimal 253, branch to POTS_HI:

;     clrh
;     clrx
     ldx     #$64         ; Load index register Lo byte with decimal 100
     mul                  ; Multiply (X:A)<-(X)*(A)
     pshx                 ; Push value in index register Lo byte to stack
     pulh                 ; Pull value from stack to index register Hi byte
     ldx     #$FF         ; Load index register Lo byte with decimal 255
     div                  ; Divide (A)<-(H:A)/(X);(H)rem
     jsr     DIVROUND     ; Jump to "DIVROUND" subroutine,(round result)
     sta     PotSpct      ; Copy result to "PotSpct"

     bra     S_BCD_CALC     ; Branch to S_BCD_CALC:

POTS_LOW:
     mov     #$00,PotSpct   ; Move decimal 0 to "PotSpct"
     bra     S_BCD_CALC     ; Branch to S_BCD_CALC:

POTS_HI:
     mov     #$63,PotSpct   ; Move decimal 99 to "PotSpct"

;****************************************************************************
; - Determine the BCD value of "PotSpct" by looking up the equivalent value
;   in the "DecBCD" table.
;****************************************************************************

S_BCD_CALC:
     clrh                 ; Clear index register Hi byte
     clrx                 ; Clear index register Lo byte
     lda     PotSpct      ; Load accumulator with value in "PotSpct"
     tax                  ; Copy to index register Lo byte
     lda     DecBCD,x     ; Load accumulator with value in "DecBCD"
                          ; table, offset in index register Lo byte
     sta     SBCD         ; Copy to "PotSpct" expressed in BCD variable

;****************************************************************************
; - Determine the BCD value for the Stbd display, Least Significant Digit
;****************************************************************************

S_LSD_CALC:

     lda     SBCD        ; Load accumulator with value in "SBCD"
     nsa                 ; Nibble swap accumulator (Lo nibble now Hi nibble)
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
                         ;(these 5 instructions clear the Hi nibble
     ora     #$10        ; Logical "or" value in accumulator with 00010000
                         ;(result is low nibble BCD with bit 4 set to trigger
                         ; Stbd LSD common cathode driver transistor
     sta     SLSDBCD     ; Copy to Stbd Least Significant Digit BCD value

;****************************************************************************
; - Determine the BCD value for the Stbd display, Most Significant Digit
;****************************************************************************

     lda     SBCD        ; Load accumulator with value in "SBCD"
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
                         ;(these 4 instructions move the value in the Hi
                         ; nibble to the low nibble and clear the Hi nibble
     ora     #$20        ; Logical "or" value in accumulator with 00100000
                         ;(result is low nibble BCD with bit 5 set to trigger
                         ; Stbd MSD common cathode driver transistor
     sta     SMSDBCD     ; Copy to Stbd Most Significant Digit BCD value

;****************************************************************************
; - Port pot calculations
;****************************************************************************

POTPP_CALC:
     lda     PotPpos        ; Load accumulator with value in "PotPpos"
     cmp     #$01           ; Compare value in accumulator with decimal 1
     bls     POTP_LOW       ; If A<=decimal 1, branch to POTP_LOW:
     cmp     #$FD           ; Compare value in accumulator with decimal 253
     bhs     POTP_HI        ; If A>= decimal 253, branch to POTP_HI:


;     clrh
;     clrx
     ldx     #$64         ; Load index register Lo byte with decimal 100
     mul                  ; Multiply (X:A)<-(X)*(A)
     pshx                 ; Push value in index register Lo byte to stack
     pulh                 ; Pull value from stack to index register Hi byte
     ldx     #$FF         ; Load index register Lo byte with decimal 255
     div                  ; Divide (A)<-(H:A)/(X);(H)rem
     jsr     DIVROUND     ; Jump to "DIVROUND" subroutine,(round result)
     sta     PotPpct      ; Copy result to "PotPpct"

     bra     P_BCD_CALC     ; Branch to P_BCD_CALC:


POTP_LOW:
     mov     #$00,PotPpct   ; Move decimal 0 to "PotPpct"
     bra     P_BCD_CALC     ; Branch to P_BCD_CALC:

POTP_HI:
     mov     #$63,PotPpct   ; Move decimal 99 to "PotPpct"


;****************************************************************************
; - Determine the BCD value of "PotPpct" by looking up the equivalent value
;   in the "DecBCD" table.
;****************************************************************************

P_BCD_CALC:
     clrh                 ; Clear index register Hi byte
     clrx                 ; Clear index register Lo byte
     lda     PotPpct      ; Load accumulator with value in "PotPpct"
     tax                  ; Copy to index register Lo byte
     lda     DecBCD,x     ; Load accumulator with value in "DecBCD"
                          ; table, offset in index register Lo byte
     sta     PBCD         ; Copy to "PotPpct" expressed in BCD variable

;****************************************************************************
; - Determine the BCD value for the Port display, Least Significant Digit
;****************************************************************************

P_LSD_CALC:

     lda     PBCD        ; Load accumulator with value in "PBCD"
     nsa                 ; Nibble swap accumulator (Lo nibble now Hi nibble)
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
                         ;(these 5 instructions clear the Hi nibble
     ora     #$40        ; Logical "or" value in accumulator with 01000000
                         ;(result is low nibble BCD with bit 4 set to trigger
                         ; Port LSD common cathode driver transistor
     sta     PLSDBCD     ; Copy to Port Least Significant Digit BCD value

;****************************************************************************
; - Determine the BCD value for the Port display, Most Significant Digit
;****************************************************************************

     lda     PBCD        ; Load accumulator with value in "PBCD"
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
     lsra                ; Logical shift right accumulator
                         ;(these 4 instructions move the value in the Hi
                         ; nibble to the low nibble and clear the Hi nibble
     ora     #$80        ; Logical "or" value in accumulator with 10000000
                         ;(result is low nibble BCD with bit 5 set to trigger
                         ; Port MSD common cathode driver transistor
     sta     PMSDBCD     ; Copy to Port Most Significant Digit BCD value


;****************************************************************************
; - Determine system voltage by looking up the equivalent voltage for "BAT"
;   in the "BatVolt" table.
;****************************************************************************

VOLTS_CALC:
     clrh                    ; Clear index register Hi byte
     clrx                    ; Clear index register Lo byte
     lda     Bat             ; Load accumulator with value in Battery
                             ; Voltage 8 bit ADC reading
     tax                     ; Copy to index register Lo byte
     lda     BatVolt,x       ; Load accumulator with value in "BatVolt"
                             ; table, offset in index register Lo byte
     sta     Volts           ; Copy to Battery Voltage to 0.1V resolution
     inc     adsel
     bclr    adcc,inputs     ; Clear "adcc" bit of "inputs" variable

NO_ADC_PASS:

;****************************************************************************
; - Update the displays. This is done at a frequency of 100 HZ. Every 10Ms,
;   in the first pass through the main loop after the 10mS clock tick has
;   ocurred. The display sequences between Stbd Least Significant Digit,
;   Stbd Most Significant Digit, Port Least Significant Digit, and Port Most
;   Significant Digit.
;****************************************************************************

     brset   clk4,inputs,DISP_SEQ     ; If "clk4" bit of "inputs" variable
                                      ; is set, branch to DISP_SEQ:
     jmp     NO_DISP_PASS             ; Jump to NO_DISP_PASS:

DISP_SEQ:
     lda     dsel                ; Load accumulator with value in Display
                                 ; Sequence Counter variable
     cbeqa   #$01,SET_SMSD       ; Compare value in accumulator with decimal
                                 ; 1, if equal, branch to SET_SMSD:
     cbeqa   #$02,SET_PLSD       ; Compare value in accumulator with decimal
                                 ; 2, if equal, branch to SET_PLSD:
     cbeqa   #$03,SET_PMSD       ; Compare value in accumulator with decimal
                                 ; 3, if equal, branch to SET_PMSD:
     mov     SLSDBCD,PORTA       ; Move value in Stbd Least Significant Digit
                                 ; BCD variable to Port A Data Register
     bra     DISP_SEQ_DONE       ; Branch to DISP_SEQ_DONE:

SET_SMSD:
     mov     SMSDBCD,PORTA       ; Move value in Stbd Most Significant Digit
                                 ; BCD variable to Port A Data Register
     bra     DISP_SEQ_DONE       ; Branch to DISP_SEQ_DONE:

SET_PLSD:
     mov     PLSDBCD,PORTA       ; Move value in Port Least Significant Digit
                                 ; BCD variable to Port A Data Register
     bra     DISP_SEQ_DONE       ; Branch to DISP_SEQ_DONE:

SET_PMSD:
     mov     PMSDBCD,PORTA       ; Move value in Port Most Significant Digit
                                 ; BCD variable to Port A Data Registe
DISP_SEQ_DONE:
     inc     dsel                ; Increment "dsel"
     bclr   clk4,inputs          ; Clear "clk4" bit of "inputs" variable

NO_DISP_PASS:

;****************************************************************************
; - Calculate the output compare values for Servo pulse widths.
;   This is done only once per Tim1 modulo rollover at 50 HZ, in the first
;   pass through the main loop after the TIM1OV_ISR Interrupt routine has
;   been completed.
;****************************************************************************

;****************************************************************************
; - The Hitec HS-311 servos operate at centre of travel with a 1500uS
;   pulse width signal, at a frequency of 50 HZ. Full right travel is at
;   1900uS, and full left travel is at 1100uS. TIM1 is set up as a modulo
;   count up 50 HZ timer (20mS period) with 1uS resolution, for servo signal
;   control timing. Channels 0 and 1 are set up for output compare,
;   pulsewidth control of servos. Servo Port on T1SC0 and Servo Stbd on T1SC1.
;
;   Position of the choke plate angles are proportional to the control pot
;   position, and it is necessary to "calibrate" the system when first placed
;   into service. The maximum pulse width of 1900uS and minimum pulse width of
;   1100uS results in a span of 800uS. These are the figures entered in the
;   max and min variables for each servo as a starting point. The
;   control pots are set to their mid point position, which should result in
;   choke angles being close to mid point if the mechanical installation was
;   correct. The pots are carefully moved CCW until the choke plates are just
;   wide open. Using "Megatune" the servo output compare value is recorded
;   as the minimum pulse width value. The pots are then moved CW until the
;   plates are just closed. Using "Megatune" again, the servo output compare
;   value is recorded as the maximum pulse width value. These new figures
;   are now enterd in the appropriate variables. Span is calculated only
;   once, at each start up.
;   The pot position * span / 256 = servo position. Servo position
;   + minimum pulse width value = commanded position pulse width.
;
; - Method for Servo Stbd, Servo Port being similar, where:
;
;   PotSpos  = Control pot Stbd position, 8 bit ADC reading
;   SSpwMnH  = Servo S OC value at open choke Hi byte
;   SSpwMnL  = Servo S OC value at open choke Lo byte
;   SSpwMxH  = Servo S OC value at closed choke Hi byte
;   SSpwMxL  = Servo S OC value at closed choke Lo byte
;   SSpwSpnH = Servo S span Hi byte
;   SSpwSpnL = Servo S span Lo byte
;   SSmulH   = Servo S multiplicand Hi byte
;   SSmulM   = Servo S multiplicand Mid byte
;   SSmulL   = Servo S multiplicand Lo byte
;   SSposH   = Servo S commanded position Hi byte
;   SSposL   = Servo S commanded position Lo byte
;   SrvSpwH  = Servo S OC for commanded position Hi byte
;   SrvSpwL  = Servo S OC for commanded position Lo byte
;
;   SSpwMxH:SSpwMxL - SSpwMnH:SSpwMnL = SSpwSpnH:SSpwSpnL
;   (This calculation is done at start up after the flash constants are
;   loaded into RAM, and copied to direct page)
;
;   SSpwSpnH:SSpwSpnL * PotSpos = SSmulH:SSmulM:SSmulL
;
;   SSmulH:SSmulM:SSmulL / 256 = SSposH:SSposL
;
;   SSposH:SSposL + SSpwMnH:SSpwMnL = SrvSpwH:SrvSpwL
;
;****************************************************************************

;****************************************************************************
;
; ------------- UMUL32 16 x 16 Unsigned Multiply Subroutine -----------------
;
;     tmp8...tmp5 = tmp4:tmp3 * tmp2:tmp1
;
;               tmp3*tmp1
;   +      tmp4*tmp1
;   +      tmp3*tmp2
;   + tmp4*tmp2
;   = ===================
;     tmp8 tmp7 tmp6 tmp5
;
;****************************************************************************

     brset   pwp,inputs,PW_CALCS     ; If "pwp" bit of "inputs" variable
                                     ; is set, branch to PW_CALCS:
     jmp     NO_PW_CALCS             ; Jump to NO_PW_CALCS:


;****************************************************************************
; - Calculate OC value for Servo S position. First, multiply the span by pot,
;   position.
;   SSpwSpnH:SSpwSpnL * PotSpos = SSmulH:SSmulM:SSmulL
;****************************************************************************

PW_CALCS:
     mov     PotSpos,tmp1      ; Copy value in "PotSpos" to tmp1
     clr     tmp2              ; Clear tmp2
     mov     SSpwSpnL,tmp3     ; Copy value in "SSpwSpnL" to tmp3
     mov     SSpwSpnH,tmp4     ; Copy value in "SSpwSpnL" to tmp3
     jsr     UMUL32            ; Jump to subroutine at UMUL32:
                               ;(Result in tmp7:tmp6:tmp5
     mov     tmp5,SSmulL       ; Copy value in tmp5 to "SSmulL"
     mov     tmp6,SSmulM       ; Copy value in tmp6 to "SSmulM"
     mov     tmp7,SSmulH       ; Copy value in tmp7 to "SSmulH"

;****************************************************************************
; - Next, divide the product by 256. This is done by deleting the LSB, but
;   first, see if the quotient should be rounded up, as this method rounds
;   down.
;   SSmulH:SSmulM:SSmulL / 256 = SSposH:S0posL
;****************************************************************************

     lda     SSmulL          ; Load accumulator with value in "SSmulL"
     cmp     #$80            ; Compare value in accumulator with decimal 128
     ble     SS_RND_DONE     ; If A<=M, branch to SS_RND_DONE:
     inc     SSmulM          ; Increment value in "SSmulM"

SS_RND_DONE:
     mov     SSmulM,SSposL   ; Copy value in "SSmulM" to "SSposL"
     mov     SSmulH,SSposH   ; Copy value in "SSmulH" to "SSposH"

;****************************************************************************
; - Now, add the servo position variable with the pulse width minimum
;   variable to get the commanded pulse width value.
;   SSposH:SSposL + SSpwMnH:SSpwMnL = SrvSpwH:SrvSpwL
;****************************************************************************

     lda     SSposL         ; Load accumulator with value in "SSposL"
     add     SSpwMnL        ; Add without Carry A<-(A)+(M)
                            ;(SSposL + SSpwMnL)
     tax                    ; Transfer result in accumulator to index
                            ; register Lo byte
     lda     SSposH         ; Load accumulator with value in "SSposH"
     adc     SSpwMnH        ; Add with Carry A<-(A)+(M)
                            ;(SSposH + SSpwMnH)
     sta     SrvSpwH        ; Copy to Servo S O/C value Hi byte
     stx     SrvSpwL        ; Copy to Servo S O/C value Lo byte

;****************************************************************************
; - Calculate OC value for Servo P position. First, multiply the span by pot,
;   position.
;   SPpwSpnH:SPpwSpnL * PotPpos = SPmulH:SPmulM:SPmulL
;****************************************************************************

     mov     PotPpos,tmp1      ; Copy value in "PotPpos" to tmp1
     clr     tmp2              ; Clear tmp2
     mov     SPpwSpnL,tmp3     ; Copy value in "SPpwSpnL" to tmp3
     mov     SPpwSpnH,tmp4     ; Copy value in "SPpwSpnL" to tmp3
     jsr     UMUL32            ; Jump to subroutine at UMUL32:
                               ;(Result in tmp7:tmp6:tmp5
     mov     tmp5,SPmulL       ; Copy value in tmp5 to "SPmulL"
     mov     tmp6,SPmulM       ; Copy value in tmp6 to "SPmulM"
     mov     tmp7,SPmulH       ; Copy value in tmp7 to "SPmulH"

;****************************************************************************
; - Next, divide the product by 256. This is done by deleting the LSB, but
;   first, see if the quotient should be rounded up, as this method rounds
;   down.
;   SPmulH:SPmulM:SPmulL / 256 = SPposH:SPposL
;****************************************************************************

     lda     SPmulL          ; Load accumulator with value in "SPmulL"
     cmp     #$80            ; Compare value in accumulator with decimal 128
     ble     SP_RND_DONE     ; If A<=M, branch to SP_RND_DONE:
     inc     SPmulM          ; Increment value in "SPmulM"

SP_RND_DONE:
     mov     SPmulM,SPposL   ; Copy value in "SPmulM" to "SPposL"
     mov     SPmulH,SPposH   ; Copy value in "SPmulH" to "SPposH"

;****************************************************************************
; - Now, add the servo position variable with the pulse width minimum
;   variable to get the commanded pulse width value.
;   SPposH:SPposL + SPpwMnH:SPpwMnL = SrvPpwH:SrvPpwL
;****************************************************************************

     lda     SPposL         ; Load accumulator with value in "SPposL"
     add     SPpwMnL        ; Add without Carry A<-(A)+(M)
                            ;(SPposL + SPpwMnL)
     tax                    ; Transfer result in accumulator to index
                            ; register Lo byte
     lda     SPposH         ; Load accumulator with value in "SPposH"
     adc     SPpwMnH        ; Add with Carry A<-(A)+(M)
                            ;(SPposH + SPpwMnH)
     sta     SrvPpwH        ; Copy to Servo P O/C value Hi byte
     stx     SrvPpwL        ; Copy to Servo P O/C value Lo byte
     bclr    pwp,inputs     ; Clear "pwp" bit of "inputs" variable

NO_PW_CALCS:

LOOP_END:
     jmp     LOOPER    ; Jump to LOOPER: (End of Main Loop!!!)


;****************************************************************************
;
; * * * * * * * * * * * * * * Interrupt Section * * * * * * * * * * * * * *
;
; NOTE!!! If the interrupt service routine modifies the H register, or uses
; the indexed addressing mode, save the H register (pshh) and then restore
; it (pulh) prior to exiting the routine
;
;****************************************************************************

;****************************************************************************
;
; -------- Following interrupt service routines in priority order ----------
;
;
; TIM1OV_ISR:  - TIM1 Overflow ($4E20 * 1uS) 20mS (50 HZ) servo period
;
; TIM2CH0_ISR: - TIM2 CH0 output compare ($0064 * 1uS) (100us Timer Tick)
;
; SCIRCV_ISR:  - SCI receive
;
; SCITX_ISR:   - SCI transmit
;
; ADC_ISR:     - ADC Conversion Complete
;
;****************************************************************************

;****************************************************************************
;============================================================================
; - TIM1 Overflow interrupt (50 HZ servo period)
;   Stop and clear timer
;   Load 50 HZ modulo to T1SC
;   Load new pulse width values to channel registers
;   Enable overflow interrupts and restart timer
;============================================================================
;****************************************************************************

TIM1OV_ISR:
     bset     pwp,inputs     ; Set "pwp" bit of "inputs" variable
     pshh                    ; Push index register Hi byte on to stack
     lda     T1SC            ; Load accumulator with value in TIM1 Status
                             ; and Control Register (Arm TOF flag clear)
     bclr    TOF,T1SC        ; Clear TOF bit of TIM1 Status and
                             ; Control Register
     mov     #$33,T1SC       ; Move %00110011 into Timer1
                             ; Status and Control Register
                             ;(Disable interrupts, stop timer)
                             ;(Prescale and counter cleared))
                             ;(Prescale for bus frequency / 8)
     mov     #$4E,T1MODH     ; Move decimal 78 into T1 modulo reg Hi
     mov     #$20,T1MODL     ; Move decimal 32 into T1 modulo reg Lo
     mov     SrvPpwH,T1CH0H  ; Move value in SrvPpwH to T1CH0 register Hi
                             ; byte (servo P OC hy byte)
     mov     SrvPpwL,T1CH0L  ; Move value in SrvPpwL to T1CH0 register Lo
                             ; byte (servo P OC lo byte)
     mov     SrvSpwH,T1CH1H  ; Move value in SrvSpwH to T1CH1 register Hi
                             ; byte (servo S OC hy byte)
     mov     SrvSpwL,T1CH1L  ; Move value in SrvSpwL to T1CH1 register Lo
                             ; byte (servo S OC lo byte)
     mov     #$43,T1SC       ; Move %01000011 into Timer1
                             ; Status and Control Register
                             ; Enable overflow interrupts, counter active
                             ; Prescale for bus frequency / 8
                             ; 8,003584hz/8=1000448hz
                             ; = .0000009995sec
     pulh                    ; Pull value from stack to index register
                             ; Hi byte
     rti                     ; Return from interrupt


;****************************************************************************
;============================================================================
; - TIM2 CH0 Interrupt (100 uS clock tick)
; - Generate time rates:
;   100 Microseconds,(just to get things started)
;   1 Millisecond,(for ADC conversions)
;   4 Milliseconds,(250hz clock tick for display alternation)
;   Seconds,(because we can)
;============================================================================
;****************************************************************************

TIM2CH0_ISR:
     pshh                  ; Push value in index register Hi byte to stack
     lda     T2SC0         ; Load accumulator with value in TIM2 CH0 Status
                           ; and Control Register (Arm CHxF flag clear)
     bclr    CHxF,T2SC0    ; Clear CHxF bit of TIM2 CH0 Status and
                           ; Control Register
     ldhx    T2CH0H        ; Load index register with value in TIM2 CH0
                           ; register H:L (output compare value)
     aix     #$64          ; Add decimal 100 (100 uS)
     sthx    T2CH0H        ; Copy result to TIM2 CH0 register
                           ;(new output compare value)


;============================================================================
;********************** 100 Microsecond section *****************************
;============================================================================

;****************************************************************************
; - Increment 100 Microsecond counter
;****************************************************************************

INC_cuS:
     inc     uSx100               ; Increment 100 uS counter
     lda     uSx100               ; Load accumulator with 100 uS counter
     cmp     #$0A                 ; Compare it with decimal 10
     beq     FIRE_ADC             ; If Z bit of CCR is set, branch to
                                  ; FIRE_ADC:(uSx100 = 10)
     jmp     TIM2CH0_ISR_DONE     ; Jump to TIM2CH0_ISR_DONE:

;============================================================================
;************************* millisecond section ******************************
;============================================================================

;****************************************************************************
; - Fire off another ADC conversion, channel is pointed to by "adsel"
;****************************************************************************

FIRE_ADC:
     lda     adsel          ; Load accumulator with value in ADC Channel Selector
     cmp     #$03           ; Compare value in accumulator with decimal 3
     bhs     ROLL_ADSEL     ; If "adsel >= decimal 3, branch to ROLL_ADSEL:
     bra     ADSEL_OK       ; Branch to ADSEL_OK:

ROLL_ADSEL:
     clr     adsel          ; Clear "adsel"

ADSEL_OK:
     lda     adsel          ; Load accumulator with ADC Selector Variable
     add     #$02           ; Add A<-A+M (first ADC is channel 2)
     ora     #%01000000     ; Inclusive "or" with %01000000 and ADC Selector
                            ; Variable ( result in accumulator )
                            ;(Enables interupt with channel selected)
     sta     ADSCR          ; Copy result to ADC Status and Control Register

;****************************************************************************
; - Increment millisecond counter
;****************************************************************************

INC_mS:
     clr     uSx100              ; Clear 100 Microsecond counter
     inc     mS                  ; Increment Millisecond counter
     lda     mS                  ; Load accumulator with value in
                                 ; Millisecond counter
     cmp     #$04                ; Compare it with decimal 4
     beq     DO_250HZ            ; If Z bit of CCR is set, branch to
                                 ; DO_250HZ:(mS = 4)
     jmp     TIM2CH0_ISR_DONE    ; Jump to TIM2CH0_ISR_DONE:

;============================================================================
;************************** 4 Millisecond section **************************
;============================================================================

;****************************************************************************
; - Increment display sequencing counter
;****************************************************************************

DO_250HZ:
     bset    clk4,inputs      ; Set "clk4" bit of "inputs" variable
     lda     dsel             ; Load accumulator with value in "dsel"
     and     #$03             ; Logical "AND" accumulator with $00000111
     sta     dsel             ; Copy result to "dsel"
                              ;(This returns the same value as "dsel" until
                              ; "dsel"=4, when it is cleared)

;****************************************************************************
; - Increment 4 millisecond counter
;****************************************************************************

INC_MSx4:
     clr     mS                  ; Clear Millisecond counter
     inc     mSx4                ; Increment 4 Millisecond counter
     lda     mSx4                ; Load accumulator with value in
                                 ; 4 Millisecond counter
     cmp     #$FA                ; Compare it with decimal 250
     beq     INC_S               ; If Z bit of CCR is set, branch to
                                 ; INC_S:(mSx10 x 100 = 1000mS = 1Sec)
     jmp     TIM2CH0_ISR_DONE    ; Jump to TIM2CH0_ISR_DONE:


;============================================================================
;**************************** Seconds section *******************************
;============================================================================

;****************************************************************************
; - Increment seconds counter
;****************************************************************************

INC_S:
     bset    clkS,inputs         ; Set "clkS" bit of "inputs" variable
     clr     mSx4                ; Clear 4 Millisecond counter
     inc     secl                ; Increment "Seconds" Lo byte variable
     bne     TIM2CH0_ISR_DONE    ; If the Z bit of CCR is clear, branch
                                 ; to TIM2CH0_ISR_DONE:
     inc     sech                ; Increment "Seconds" Hi byte variable

TIM2CH0_ISR_DONE:
     pulh                  ; Pull value from stack to index register Hi byte
     rti                   ; Return from interrupt

;****************************************************************************
;
; -------------------- Serial Communications Interface ----------------------
;
; Communications is established when the PC communications program sends
; a command character - the particular character sets the mode:
;
; "A" = send all of the realtime variables via txport.
; "V" = send the Constants and spares via txport (64 bytes)
; "W"+<offset>+<newbyte> = receive new constant byte value and store in
;       offset location
; "B" = jump to flash burner routine and all constant values in
;       RAM into flash
; "C" = Test communications - echo back SECL
; "Q" = Send over Embedded Code Revision Number (divide number by 10
;  - i.e. $21T is rev 2.1)
;
; txmode:
;              01 = Sending realtime data
;              02 = ?
;              03 = Sending Constant
;              04 = ?
;              05 = Getting offset
;              06 = Getting data
;
;***************************************************************************

SCIRCV_ISR:
     pshh                 ; Push value in index register Hi byte to Stack
     lda     SCS1         ; Load accumulator with value in "SCS1"
                          ;(Clear the SCRF bit by reading this register)
     lda     txmode       ; Load accumulator with value in "txmode" variable
                          ;(Check if we are in the middle of a receive
                          ; new VE/constant)
     cmp     #$05         ; Compare with decimal 5
     beq     TXMODE_5     ; If the Z bit of CCR is set, branch to TXMODE_5:
     cmp     #$06         ; Compare with decimal 6
     beq     TXMODE_6     ; If the Z bit of CCR is set, branch to TXMODE_6:
     bra     CHECK_TXCMD  ; Branch to CHECK_TXCMD:

TXMODE_5:
     mov     SCDR,rxoffset   ; Move value in "SCDR" to "rxoffset"
     inc     txmode          ; (continue to next mode)
     jmp     DONE_RCV        ; Jump to DONE_RCV:

TXMODE_6:
     clrh                 ; Clear index register Hi byte
     lda     rxoffset     ; Load accumulator with value in "rxoffset"
     tax                  ; Transfer value in accumulator to index register
                          ; Lo byte
     lda     SCDR         ; Load accumulator with value in "SCDR"
     sta     SSpwMnH_F,x   ; Copy to SSpwMnH_F, offset in index register Lo byte
                          ;(Write data to SSpwMnH_F + offset)
     clr     txmode       ; Clear "txmode" variable
     jmp     DONE_RCV     ; Jump to DONE_RCV:

CHECK_TXCMD:
     lda     SCDR       ; Load accumulator with value in "SCDR"
                        ;(Get the command byte)
     cmp     #$41       ; Compare it with decimal 65 = ASCII "A"
                        ;(Is the recieve character a big "A" ->
                        ; Download real-time variables?)
     beq     MODE_A     ; If the Z bit of CCR is set, branch to Mode_A:
     cmp     #$42       ; Compare it with decimal 66 = ASCII "B"
     beq     MODE_B     ; If the Z bit of CCR is set, branch to Mode_B:
     cmp     #$43       ; Compare it with decimal 67 = ASCII "C"
     beq     MODE_C     ; If the Z bit of CCR is set, branch to Mode_C:
     cmp     #$56       ; Compare it with decimal 86 = ASCII "V"
     beq     MODE_V     ; If the Z bit of CCR is set, branch to Mode_V:
     cmp     #$57       ; Compare it with decimal 87 = ASCII "W"
     beq     MODE_W     ; If the Z bit of CCR is set, branch to Mode_W:
     cmp     #$51       ; Compare it with decimal 81 = ASCII "Q"
     beq     MODE_Q     ; If the Z bit of CCR is set, branch to Mode_Q:

MODE_A
     clr     txcnt          ; Clear "txcnt"
     lda     #$01           ; Load accumulator with decimal 1
     sta     txmode         ; Copy to "txmode" variable
     lda     #$29           ; Load accumulator with decimal 41
                            ;(Set this for 1 more than the number of bytes
                            ; to send)
                            ; Show all variables(for Megachat)
     sta     txgoal         ; Copy to "txgoal" variable
     bset    TE,SCC2        ; Set "TE" bit of SCC2 (Enable Transmit)
     bset    SCTIE,SCC2     ; Set "SCTIE" bit of SCC2
                            ;(Enable transmit interrupt)
     bra     DONE_RCV       ; Branch to DONE_RCV:

MODE_B:
     jsr     burnConst     ; Jump to "burnConst" subroutine
     clr     txmode        ; Clear "txmode" variable
     bra     DONE_RCV      ; Branch to DONE_RCV:

MODE_C:
     clr     txcnt          ; Clear "txcnt"
                            ; (Just send back SECL variable to test comm port)
     lda     #$01           ; Load accumulator with decimal 1
     sta     txmode         ; Copy to "txmode" variable
     lda     #$2            ; Load accumulator with decimal 2
     sta     txgoal         ; Copy to "txgoal" variable
     bset    TE,SCC2        ; Set "TE" bit of SCC2 (Enable Transmit)
     bset    SCTIE,SCC2     ; Set "SCTIE" bit of SCC2
                            ;(Enable transmit interrupt)
     bra     DONE_RCV       ; Branch to DONE_RCV:

MODE_V:
     clr     txcnt          ; Clear "txcnt"
     lda     #$03           ; Load accumulator with decimal 3
     sta     txmode         ; Copy to "txmode" variable
     lda     #$09           ; Load accumulator with decimal 9
                            ;(Set this for 1 more than the number of bytes
                            ; to send)
                            ;(Send 8 bytes, Stbd PW Min Hi:Lo,
                            ; Stbd PW Max Hi:Lo, Port PW Min Hi:Lo,
                            ; Port PW Max Hi:Lo)
     sta     txgoal         ; Copy to "txgoal" variable
     bset    TE,SCC2        ; Set "TE" bit of SCC2 (Enable Transmit)
     bset    SCTIE,SCC2     ; Set "SCTIE" bit of SCC2
                            ;(Enable transmit interrupt)
     bra     DONE_RCV       ; Branch to DONE_RCV:

MODE_W:
     lda     #$05         ; Load accumulator with decimal 5
     sta     txmode       ; Copy to "txmode" variable
     bra     DONE_RCV     ; Branch to DONE_RCV:

MODE_Q:
     clr     txcnt          ; Clear "txcnt"
                            ; (Just send back SECL variable to test comm port)
     lda     #$05           ; Load accumulator with decimal 5
     sta     txmode         ; Copy to "txmode" variable
     lda     #$2            ; Load accumulator with decimal 2
     sta     txgoal         ; Copy to "txgoal" variable
     bset    TE,SCC2        ; Set "TE" bit of SCC2 (Enable Transmit)
     bset    SCTIE,SCC2     ; Set "SCTIE" bit of SCC2
                            ;(Enable transmit interrupt)

DONE_RCV
     pulh                 ; Pull value from Stack to index register Hi byte
     rti                  ; Return from interrupt

;****************************************************************************
;----------------- Transmit Character Interrupt Handler --------------------
;****************************************************************************

SCITX_ISR:
     pshh                  ; Push value in index register Hi byte to Stack
     lda     SCS1          ; Load accumulator with value in "SCS1"
                           ; (Clear the SCRF bit by reading this register)
     clrh                  ; Clear index register Hi byte
     lda     txcnt         ; Load accumulator with value in "txcnt" variable
     tax                   ; Transfer value in accumulator to index register
                           ; Lo byte
     lda     txmode        ; Load accumulator with value in "txmode" variable
     cmp     #$05          ; Compare it with decimal 5
     beq     IN_Q_MODE     ; If the Z bit of CCR is set, branch to IN_Q_MODE:
     cmp     #$03          ; Compare it with decimal 3
     beq     IN_V_MODE     ; If the Z bit of CCR is set, branch to IN_V_MODE:

IN_A_OR_C_MODE:
     lda     secH,X        ; Load accumulator with value in address "secH",
                           ; offset in index register Lo byte
     bra     CONT_TX       ; Branch to CONT_TX:

IN_V_MODE
     lda     SSpwMnH_F,x   ; Load accumulator with value in address
                           ; "SSpwMnH_F", offset in index register Lo byte
     bra     CONT_TX       ; Branch to CONT_TX:

IN_Q_MODE
     lda     REVNUM,X   ; Load accumulator with value in address "REVNUM",
                        ; offset in index register Lo byte

CONT_TX:
     sta     SCDR           ; Copy to "SCDR" variable (Send char)
     lda     txcnt          ; Load accumulator with value in "txcnt" variable
     inca                   ; Increment value in accumulator
                            ;(Increase number of chars sent)
     sta     txcnt          ; Copy to "txcnt" variable
     cmp     txgoal         ; Compare it to value in "txgoal" (Check if done)
     bne     DONE_XFER      ; If the Z bit of CCR is clear, branch to DONE_XFER:
                            ;(Branch if NOT done to DONE_XFER !?!?!)
     clr     txcnt          ; Clear "txcnt"
     clr     txgoal         ; Clear "txgoal"
     clr     txmode         ; Clear "txmode"
     bclr    TE,SCC2        ; Clear "TE" bit of SCC2 (Disable Transmit)
     bclr    SCTIE,SCC2     ; Clear "SCTIE" bit of SCC2
                            ;(Disable transmit interrupt)

DONE_XFER
     pulh                   ; Pull value from Stack to index register Hi byte
     rti                    ; Return from interrupt


;****************************************************************************
; - ADC conversion complete Interrupt
;   ADC channel is set by "adsel" variable which starts at 2. This reads
;   channel 2, which is "PotSpos". When the conversion complete interrupt is
;   requested the current value in "PotSpos" is averaged with the result of
;   the ADC in the ADC Data Register (ADR) and stored as current "PotSpos"
;   This is to smooth out ADC "jitter". The "adsel" variable is then
;   incremented to the next channel and the process repeats until the 3
;   channels are read, at which time, "adsel" is set at 2 to start the
;   sequence again.
;****************************************************************************


ADC_ISR:
     bset    adcc,inputs  ; Set "adcc" bit of "inputs" variable
     pshh              ; Push index register Hi byte on to stack
                       ;(Do this because processor does not stack H)
     clrh              ; Clear index register Hi byte
     lda     adsel     ; Load accumulator with value in ADC Channel Selector
     tax               ; Transfer value in accumulator to index register Lo
     lda     ADR       ; Load accumulator with value in ADC Data Register
                       ;(this also clears conversion complete and
                       ; interrupt enable bit)
     add     PotSpos,x ; Add ADR and PotSpos,x (Add the two values)
     rora              ; Rotate right through carry (Divide by 2)
     sta     PotSpos,x ; Copy result to address PotSpos,x
     pulh              ; Pull value from stack to index register Hi byte
     rti               ; Return from interrupt


;**************************************************************************
;==========================================================================
;- Dummy ISR vector - there just to keep the assembler happy
;==========================================================================
;**************************************************************************

Dummy:
     rti     ; Return from interrupt

;***************************************************************************
;
; ---------------------------- SUBROUTINES --------------------------------
;
;  - Round after division routine
;  - 16 x 16 multiply routine
;
;***************************************************************************


;****************************************************************************
; ----------  ----- ROUND after div (unsigned) Subroutine -------------------
;
;  1)  check for div overflow (carry set), rail result if detected
;  2)  if (remainder * 2) > divisor then     ; was remainder > (divisor / 2)
;  2a)    increment result, rail if over-flow
;
;****************************************************************************

DIVROUND:
     bcs     DIVROUND0     ; If C bit of CCR is set, branch to DIVROUND0:
                           ; (div overflow? yes, branch)
     stx     local_tmp     ; Copy value in index register Lo byte to
                           ; local_tmp variable (divisor)
     pshh                  ; Push value in index register Hi byte onto
                           ; stack (retrieve remainder)
     pulx                  ; Pull value on stack to index register Lo byte
     lslx                  ; Logical shift left index register lo byte (* 2)
     bcs     DIVROUND2     ; If C bit of CCR is set, branch to DIVROUND2:
                           ;(over-flow on left-shift, (remainder * 2) > $FF)
     cpx     local_tmp     ; Compare value in local_tmp variable with value
                           ; in index register Lo byte
                           ;(compare (remainder * 2) to divisor)
     blo     DIVROUND1     ; If lower, branch to DIVROUND1:


DIVROUND2:
     inca                   ; Increment accumulator (round-up result)
     bne      DIVROUND1     ; If Z bit of CCR is clear, branch to DIVROUND1:
                            ; (result roll over? no, branch)


DIVROUND0:
     lda     #$FF     ; Load accumulator with decimal 255 (rail result)


DIVROUND1:
     rts              ; return from subroutine


;****************************************************************************
;
; ------------------- 16 x 16 Unsigned Multiply Subroutine -----------------
;
;     tmp8...tmp5 = tmp4:tmp3 * tmp2:tmp1
;
;               tmp3*tmp1
;   +      tmp4*tmp1
;   +      tmp3*tmp2
;   + tmp4*tmp2
;   = ===================
;     tmp8 tmp7 tmp6 tmp5
;
;****************************************************************************

UMUL32:
     lda     tmp1        ; Load accumulator with value in tmp1 variable
     ldx     tmp3        ; Load index register Lo byte with value in tmp3
     mul                 ; Multiply X:A<-(X)*(A)
     sta     tmp5        ; Ccopy result to tmp5
     stx     tmp6        ; Copy value in index register Lo byte to tmp6
;
     lda     tmp2        ; Load accumulator with value in tmp2
     ldx     tmp4        ; Load index register Lo byte with value in tmp4
     mul                 ; Multiply X:A<-(X)*(A)
     sta     tmp7        ; Copy result to tmp7
     stx     tmp8        ; Copy value in index register Lo byte to tmp8
;
     lda     tmp1        ; Load accumulator with value in tmp1
     ldx     tmp4        ; Load index register Lo byte with value in tmp4
     mul                 ; Multiply X:A<-(X)*(A)
     add     tmp6        ; Add without carry, A<-(A)+(M)
     sta     tmp6        ; Copy result to tmp6
     txa                 ; Transfer value in index register Lo byte
                         ; to accumulator
     adc     tmp7        ; Add with carry, A<-(A)+(M)+(C)
     sta     tmp7        ; Copy result to tmp7
     bcc     UMUL32a     ; If C bit of CCR is clear, branch to UMUL32a:
     inc     tmp8        ; Increment value in tmp8


UMUL32a:
     lda     tmp2        ; Load accumulator with value in tmp2
     ldx     tmp3        ; Load index register Lo byte with value in tmp3
     mul                 ; Multiply X:A<-(X)*(A)
     add     tmp6        ; Add without carry, A<-(A)+(M)
     sta     tmp6        ; Copy result to tmp6
     txa                 ; Transfer value in index register Lo byte
                         ; to accumulator
     adc     tmp7        ; Add with carry, A<-(A)+(M)+(C)
     sta     tmp7        ; Copy result to tmp7
     bcc     UMUL32b     ; If C bit of CCR is clear, branch to UMUL32b:
     inc     tmp8        ; increment value in tmp8 variable


UMUL32b:
      rts                ; return from subroutine


;***************************************************************************
; - Flash Burn routine goes here
;***************************************************************************

     include "burner.asm"         ; Include Flash Burner routine

;****************************************************************************
;-------------------Constants not possible to burn--------------------------
;****************************************************************************

        org     $E000      ; (57344)


REVNUM:
      db 10T        ; Revision 1.0

Signature:
         db 10T     ; For Megatune


;****************************************************************************
; - Flash Configuration Constants (copied into RAM at start up)
;****************************************************************************

        org     $E100      ; SE100 to $E1C0 (57600 to 57792)

ms_rf_start_f:

;****************************************************************************
; - Servo travel pulse width limits
;   These are used to calibrate the individual servo travel pulse widths.
;   Initial settings are for full travel which is 1100uS min ($04:4C), and
;   1900uS Max ($07:6C). The burner routine burns 64 bytes at a time
;****************************************************************************

     db     $04     ;SSpwMnH_F (Servo S OC value at open choke Hi byte)
     db     $4C     ;SSpwMnL_F (Servo S OC value at open choke Lo byte)
     db     $07     ;SSpwMxH_F (Servo S OC value at closed choke Hi byte)
     db     $6C     ;SSpwMxL_F (Servo S OC value at closed choke Lo byte)
     db     $04     ;SPpwMnH_F (Servo P OC value at open choke Hi byte)
     db     $4C     ;SPpwMnL_F (Servo P OC value at open choke Lo byte)
     db     $07     ;SPpwMxH_F (Servo P OC value at closed choke Hi byte)
     db     $6C     ;SPpwMxL_F (Servo P OC value at closed choke Lo byte)


;****************************************************************************
; - Place holders for future use
;****************************************************************************

    db     $00      ; blank_0
    db     $00      ; blank_1
    db     $00      ; blank_2
    db     $00      ; blank_3
    db     $00      ; blank_4
    db     $00      ; blank_5
    db     $00      ; blank_6
    db     $00      ; blank_7
    db     $00      ; blank_8
    db     $00      ; blank_9
    db     $00      ; blank_10
    db     $00      ; blank_11
    db     $00      ; blank_12
    db     $00      ; blank_13
    db     $00      ; blank_14
    db     $00      ; blank_15
    db     $00      ; blank_16
    db     $00      ; blank_17
    db     $00      ; blank_18
    db     $00      ; blank_19
    db     $00      ; blank_20
    db     $00      ; blank_21
    db     $00      ; blank_22
    db     $00      ; blank_23
    db     $00      ; blank_24
    db     $00      ; blank_25
    db     $00      ; blank_26
    db     $00      ; blank_27
    db     $00      ; blank_28
    db     $00      ; blank_29
    db     $00      ; blank_30
    db     $00      ; blank_31
    db     $00      ; blank_32
    db     $00      ; blank_33
    db     $00      ; blank_34
    db     $00      ; blank_35
    db     $00      ; blank_36
    db     $00      ; blank_37
    db     $00      ; blank_38
    db     $00      ; blank_39
    db     $00      ; blank_40
    db     $00      ; blank_41
    db     $00      ; blank_42
    db     $00      ; blank_43
    db     $00      ; blank_44
    db     $00      ; blank_45
    db     $00      ; blank_46
    db     $00      ; blank_47
    db     $00      ; blank_48
    db     $00      ; blank_49
    db     $00      ; blank_50
    db     $00      ; blank_51
    db     $00      ; blank_52
    db     $00      ; blank_53
    db     $00      ; blank_54
    db     $00      ; blank_55


ms_rf_end_f:

;***************************************************************************
; - Boot Loader routine goes here
;***************************************************************************

     include "boot_r12.asm"       ; Include Boot Loader routine

;****************************************************************************
; - Lookup Tables
;****************************************************************************

     org     $F000     ; $F000 to $F600 (61440 to 62976)

     include "BatVolt.inc"   ; table=BatVolt:,    offset=BAT,  result=Volts
     include "DecBCD.inc"    ; table=DecBCD:,     offset=Dec,  result=BCD


;***************************************************************************
; - Start of bootloader-defined jump table/vector
;***************************************************************************

     org     $FAC3              ; start bootloader-defined jump table/vector
                                ;(64195)
     db      $12                ; scbr regi init value
     db      %00000001          ; config1
     db      %00000001          ; config2
     dw      {rom_start + 256}  ; megasquirt code start
     dw      $FB00              ; bootloader start(64256)

;****************************************************************************
; - Vector table (origin vec_timebase)
;****************************************************************************

        db      $CC
	dw	Dummy          ;Time Base Vector
        db      $CC
	dw	ADC_ISR        ;ADC Conversion Complete
        db      $CC
	dw	Dummy          ;Keyboard Vector
        db      $CC
	dw	SCITX_ISR      ;SCI Transmit Vector
        db      $CC
	dw	SCIRCV_ISR     ;SCI Receive Vector
        db      $CC
	dw	Dummy          ;SCI Error Vector
        db      $CC
	dw	Dummy          ;SPI Transmit Vector
        db      $CC
	dw	Dummy          ;SPI Receive Vector
        db      $CC
	dw    Dummy          ;TIM2 Overflow Vector
        db      $CC
	dw    Dummy          ;TIM2 Ch1 Vector
        db      $CC
	dw	TIM2CH0_ISR    ;TIM2 Ch0 Vector
        db      $CC
	dw	TIM1OV_ISR     ;TIM1 Overflow Vector
        db      $CC
	dw	Dummy          ;TIM1 Ch1 Vector
        db      $CC
	dw	Dummy          ;TIM1 Ch0 Vector
        db      $CC
	dw	Dummy          ;PLL Vector
        db      $CC
	dw	Dummy          ;IRQ Vector
        db      $CC
	dw	Dummy          ;SWI Vector
        db      $CC
	dw	Start          ;Reset Vector

	end

